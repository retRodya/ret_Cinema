local addonName, ns = ...

ns.retColor = "|cff9acd32"
function ns.ColorRet(text)
    -- Idempotent: rendering a title twice must not nest color escapes.
    text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%xret_|r", "ret_")
    return (text:gsub("ret_", ns.retColor .. "ret_|r"))
end
ns.title = ns.ColorRet("ret_Cinema")
BINDING_HEADER_RETCINEMA = ns.title
BINDING_NAME_RETCINEMA_HIDEUI = "HideUI"
BINDING_NAME_RETCINEMA_LETTERBOX = "Letterbox"
BINDING_NAME_RETCINEMA_COMBINED = "Combined Lens"
BINDING_NAME_RETCINEMA_CAMERA = "CameraShift"
for index = 2, 5 do _G["BINDING_NAME_RETCINEMA_COMBINED" .. index] = "Combined Lens " .. index end

ns.icon = 136034
function ns.GetDescription()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getter and getter(addonName, "Notes") or ""
end
ns.effects = {
    { id = "hideui", name = "HideUI", description = "Hide the UI and world names for clean screenshots.", hint = "Assign a Lens button in the Lens tab." },
    { id = "letterbox", name = "Letterbox", description = "Frame your view with cinematic letterboxes.", hint = "Letterboxes - black bars at the top and bottom of the screen." },
    { id = "camerashift", name = "CameraShift", description = "Set a horizontal camera offset and toggle it with a Lens button.", hint = " " },
    { id = "fov", name = "FOV", description = "Adjust your field of view.", hint = "Under consideration. This Effect is not available yet.", underConsideration = true },
    { id = "smoothmotion", name = "SmoothMotion", description = "SmoothMotion", hint = "Under consideration. This Effect is not available yet.", underConsideration = true },
}
ns.generalHint = "Turn on the Permanent Effect as well as applying this Effect to your Lens."
ns.lens = { description = "Assign Lens buttons to Effects.", hint = "Effects can be added to Combined Lens buttons." }
ns.actions = {
    { effect = "hideui", binding = "RETCINEMA_HIDEUI", command = "hideui", run = function() RetCinema_ToggleUI() end },
    { effect = "letterbox", binding = "RETCINEMA_LETTERBOX", command = "showletterbox", run = function() RetCinema_ToggleLetterbox() end },
    -- Keep the binding ID so existing camera shortcuts survive the rename.
    { effect = "camerashift", binding = "RETCINEMA_CAMERA", command = "camerashift", run = function() RetCinema_ToggleCameraShift() end },
}

local bars, topBar, bottomBar, minimapButton
local letterboxShown = false
local barHeight = 0
local animationTarget
local animationDuration = 0.3
local cameraAnimationDuration = 0.35
local events = CreateFrame("Frame")
local uiHidden, visibilityHooked = false, false
local cameraShiftActive = false
local uiRestoreShown = true
local cameraAnimator, escapeHandler
local combinedStates = {}
local cameraLensRestore, cameraReturnValues, pendingStartup
local operationDepth, restoringAll, exitingAll = 0, false, false
local SyncScreen, CreateBars

function ns.UpdateEscapeHandler()
    if not ns.db or operationDepth > 0 then return end
    local active = uiHidden or letterboxShown or cameraShiftActive or next(combinedStates) ~= nil
    if active and not escapeHandler then
        -- Independent of UIParent, so Escape also works with the whole UI hidden.
        escapeHandler = CreateFrame("Frame", "RetCinemaEscapeHandler")
        escapeHandler:SetSize(1, 1)
        escapeHandler:SetPoint("CENTER", UIParent, "CENTER")
        escapeHandler:EnableMouse(false)
        -- Native special-window closes also happen during unrelated game actions.
        -- Only an actual Escape key press should end a mode.
        escapeHandler:SetPropagateKeyboardInput(true)
        escapeHandler:EnableKeyboard(true)
        escapeHandler:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then ns.RestoreAll() end
        end)
    end
    if escapeHandler then
        escapeHandler:SetShown(not not active)
    end
end

function ns.IsEffectEnabled(id) return ns.db and ns.db.effects[id] == true end
function ns.IsAppliedToLens(id) return ns.db and ns.db.lensEffects[id] == true end
function ns.IsActionEnabled(action)
    return ns.IsEffectEnabled(action.effect) and ns.IsAppliedToLens(action.effect)
end
function ns.HasLensEffects()
    for _, action in ipairs(ns.actions) do if ns.IsActionEnabled(action) then return true end end
    return false
end

local function UpdateEvents()
    for _, event in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_LOGOUT", "PLAYER_LOGIN" }) do
        events:UnregisterEvent(event)
    end
    if pendingStartup then events:RegisterEvent("PLAYER_LOGIN") end
    if bars and ns.IsEffectEnabled("letterbox") then
        events:RegisterEvent("UI_SCALE_CHANGED")
        events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    end
    if ns.db and (ns.db.hiddenCVars or ns.db.cameraRestore) then events:RegisterEvent("PLAYER_LOGOUT") end
    ns.UpdateEscapeHandler()
end

function ns.GetCVar(name)
    local getter = C_CVar and C_CVar.GetCVar or GetCVar
    if not getter then return end
    local ok, value = pcall(getter, name)
    if ok then return value end
end
local function WriteCVar(name, value)
    local setter = C_CVar and C_CVar.SetCVar or SetCVar
    if not setter or ns.GetCVar(name) == nil then return false end
    local ok, result = pcall(setter, name, tostring(value))
    return ok and result ~= false
end
local function RestoreCVars(values)
    if type(values) ~= "table" then return end
    for name, value in pairs(values) do WriteCVar(name, value) end
end

function ns.Print(message)
    print(ns.title .. ": " .. ns.ColorRet(message))
end

local function UpdateBars()
    if not bars then return end
    local height = math.max(0.01, bars:GetHeight() * barHeight / 100)
    topBar:SetHeight(height)
    bottomBar:SetHeight(height)
    bars:SetShown(ns.IsEffectEnabled("letterbox") and (barHeight > 0 or animationTarget ~= nil))
end

local function UpdateLetterboxVisibility(immediate)
    local target = 0
    if ns.IsEffectEnabled("letterbox") then
        target = letterboxShown and ns.db.letterboxHeight or
            (ns.db.permanentLetterbox and ns.db.permanentLetterboxHeight or 0)
    end
    if target > 0 then CreateBars() end
    if not bars then return end
    bars:SetScript("OnUpdate", nil)
    animationTarget = nil
    if immediate or not ns.db.enableAnimation or barHeight == target then
        barHeight = target
        UpdateBars()
        ns.UpdateEscapeHandler()
        return
    end

    -- Start from the current height so reversing an unfinished animation never jumps.
    local start, elapsed = barHeight, 0
    local span = math.max(start, target, ns.db.letterboxHeight,
        ns.db.permanentLetterbox and ns.db.permanentLetterboxHeight or 0)
    local duration = animationDuration * math.abs(target - start) / span
    animationTarget = target
    bars:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local progress = math.min(1, elapsed / duration)
        local eased = progress * progress * (3 - 2 * progress)
        barHeight = start + (target - start) * eased
        if progress == 1 then
            animationTarget = nil
            self:SetScript("OnUpdate", nil)
        end
        UpdateBars()
        if progress == 1 then ns.UpdateEscapeHandler() end
    end)
    UpdateBars()
end

SyncScreen = function()
    if not bars then return end
    -- An independent parent keeps the bars visible when screenshot mode hides UIParent.
    bars:SetScale(UIParent:GetScale())
    bars:ClearAllPoints()
    bars:SetAllPoints(UIParent)
    UpdateBars()
end

function ns.SetLetterboxAnimation(enabled)
    ns.db.enableAnimation = not not enabled
    UpdateLetterboxVisibility()
end

local function NumberInRange(value, low, high)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return end
    return math.floor(math.max(low, math.min(high, value)) * 10 + 0.5) / 10
end
function ns.SetLetterboxHeight(value, permanent)
    local rounded = NumberInRange(value, 0, 25)
    if not rounded then return false end
    local field = permanent and "permanentLetterboxHeight" or "letterboxHeight"
    if ns.db[field] == rounded then return true end
    ns.db[field] = rounded
    if (permanent and not letterboxShown) or (not permanent and letterboxShown) then
        UpdateLetterboxVisibility()
    end
    return true
end
function ns.SetPermanentLetterbox(enabled)
    ns.db.permanentLetterbox = not not enabled
    if not letterboxShown then UpdateLetterboxVisibility() end
end

function RetCinema_ToggleLetterbox()
    if not ns.IsEffectEnabled("letterbox") or not ns.IsAppliedToLens("letterbox") then return end
    exitingAll = false
    letterboxShown = not letterboxShown
    UpdateLetterboxVisibility()
    ns.UpdateEscapeHandler()
end

function ns.CombinedBinding(index)
    return index == 1 and "RETCINEMA_COMBINED" or "RETCINEMA_COMBINED" .. index
end
function ns.GetCombinedCount() return ns.db.combinedLensCount end
local function UpdateCombinedBindingName()
    BINDING_NAME_RETCINEMA_COMBINED = ns.GetCombinedCount() > 1 and "Combined Lens 1" or "Combined Lens"
end
function ns.GetCombinedActions(index)
    index = index or 1
    if index == 1 then return ns.db.combinedActions end
    local lens = ns.db.extraCombinedLenses[index]
    return lens and lens.actions
end
function ns.GetCombinedExitAll(index)
    if index == 1 then return ns.db.combinedAsEsc end
    return ns.db.extraCombinedLenses[index].exitAll
end
function ns.SetCombinedExitAll(index, enabled)
    if index == 1 then ns.db.combinedAsEsc = not not enabled
    elseif ns.db.extraCombinedLenses[index] then ns.db.extraCombinedLenses[index].exitAll = not not enabled end
end
function ns.AddCombinedLens()
    if ns.GetCombinedCount() >= 5 then return false end
    ns.db.combinedLensCount = ns.GetCombinedCount() + 1
    UpdateCombinedBindingName()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
    return true
end
function ns.SetCombinedAction(binding, enabled, index)
    local actions = ns.GetCombinedActions(index)
    if not actions then return end
    for _, action in ipairs(ns.actions) do
        if action.binding == binding then
            actions[binding] = not not enabled
            return
        end
    end
end

function ns.HasCombinedActions(index)
    local actions = ns.GetCombinedActions(index)
    if not actions then return false end
    for _, action in ipairs(ns.actions) do
        if ns.IsActionEnabled(action) and actions[action.binding] then return true end
    end
    return false
end

function RetCinema_ToggleCombined(index)
    index = index or 1
    if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > ns.GetCombinedCount() then return end
    if combinedStates[index] and ns.GetCombinedExitAll(index) then ns.RestoreAll(); return end
    if not combinedStates[index] and not ns.HasCombinedActions(index) then return end
    exitingAll = false
    local function IsActive(action)
        if action.effect == "hideui" then return uiHidden end
        if action.effect == "letterbox" then return letterboxShown end
        return ns.IsCameraShiftActive()
    end
    operationDepth = operationDepth + 1
    if combinedStates[index] then
        local previous = combinedStates[index]
        combinedStates[index] = nil
        for _, saved in ipairs(previous) do
            if ns.IsActionEnabled(saved.action) and IsActive(saved.action) ~= saved.active then saved.action.run() end
        end
    else
        local selected = {}
        for _, action in ipairs(ns.actions) do
            if ns.IsActionEnabled(action) and ns.GetCombinedActions(index)[action.binding] then
                selected[#selected + 1] = { action = action, active = IsActive(action) }
            end
        end
        if #selected > 0 then
            combinedStates[index] = selected
            for _, saved in ipairs(selected) do saved.action.run() end
        end
    end
    operationDepth = operationDepth - 1
    ns.UpdateEscapeHandler()
end

function RetCinema_RunBinding(binding)
    for _, action in ipairs(ns.actions) do
        if action.binding == binding and ns.IsActionEnabled(action) then action.run(); return end
    end
end

-- Screenshot mode alone leaves native world names visible on some clients.
local nameCVars = {
    "UnitNameOwn", "UnitNameNPC", "UnitNameHostleNPC", "UnitNameFriendlySpecialNPCName",
    "UnitNameInteractiveNPC", "UnitNameNonCombatCreatureName", "UnitNameFriendlyPlayerName",
    "UnitNameEnemyPlayerName", "UnitNameFriendlyMinionName", "UnitNameEnemyMinionName",
    "UnitNameFriendlyPetName", "UnitNameEnemyPetName", "UnitNameFriendlyGuardianName",
    "UnitNameEnemyGuardianName", "UnitNameFriendlyTotemName", "UnitNameEnemyTotemName",
    "UnitNameFriendlyCreationName", "UnitNameEnemyCreationName", "UnitNameCompanionName",
    "UnitNamePlayerGuild", "UnitNameGuildTitle", "UnitNamePlayerPVPTitle", "UnitNameFocused",
    "ShowQuestUnitCircles", "SoftTargetIconEnemy", "SoftTargetIconFriend", "SoftTargetIconInteract",
}
local function RestoreNames()
    RestoreCVars(ns.db.hiddenCVars)
    ns.db.hiddenCVars = nil
    uiHidden = false
    UpdateEvents()
end
function ns.RestoreUI()
    if not ns.db then return end
    operationDepth = operationDepth + 1
    local restoreVisibility, shown = uiHidden, uiRestoreShown
    RestoreNames()
    if restoreVisibility then
        if SetUIVisibility then SetUIVisibility(shown) else UIParent:SetShown(shown) end
    end
    operationDepth = operationDepth - 1
    UpdateEvents()
end
function RetCinema_ToggleUI()
    if not ns.IsEffectEnabled("hideui") or not ns.IsAppliedToLens("hideui") then return end
    exitingAll = false
    if uiHidden then
        ns.RestoreUI()
        return
    end
    if not visibilityHooked then
        UIParent:HookScript("OnShow", function()
            if uiHidden and operationDepth == 0 then
                -- Combat and camera controls must not cancel screenshot mode.
                if SetUIVisibility then SetUIVisibility(false) else UIParent:Hide() end
            end
        end)
        visibilityHooked = true
    end
    ns.db.hiddenCVars = {}
    uiRestoreShown = UIParent:IsShown()
    for _, name in ipairs(nameCVars) do
        local value = ns.GetCVar(name)
        if value ~= nil then
            ns.db.hiddenCVars[name] = value
            WriteCVar(name, "0")
        end
    end
    uiHidden = true
    operationDepth = operationDepth + 1
    UpdateEvents()
    if SetUIVisibility then SetUIVisibility(false) else UIParent:Hide() end
    operationDepth = operationDepth - 1
    UpdateEvents()
end

function ns.CameraAvailable() return ns.GetCVar("test_cameraOverShoulder") ~= nil end
local cameraCVars = { "test_cameraOverShoulder", "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement" }
local warningHooked, cameraWriteInProgress, cameraWriteAt, cameraWarningConsent
local function InstallCameraWarningGuard()
    if warningHooked or not hooksecurefunc or not StaticPopup_Show or not StaticPopup_Hide then return end
    warningHooked = true
    -- This warning has no acceptance API: Blizzard's Accept button only dismisses it.
    -- Dismiss only camera warnings immediately following our own consented writes.
    hooksecurefunc("StaticPopup_Show", function(which)
        local recentWrite = cameraWriteInProgress or
            (GetTime and cameraWriteAt and GetTime() - cameraWriteAt < 0.1)
        if which == "EXPERIMENTAL_CVAR_WARNING" and cameraWarningConsent and recentWrite then
            StaticPopup_Hide(which)
        end
    end)
end
local function WriteCameraCVar(name, value)
    if ns.GetCVar(name) == tostring(value) then return true end
    if ns.db.cameraConsent then
        cameraWarningConsent = true
        InstallCameraWarningGuard()
    end
    cameraWriteInProgress = true
    cameraWriteAt = GetTime and GetTime() or nil
    local ok = WriteCVar(name, value)
    cameraWriteInProgress = false
    return ok
end
local function CaptureCamera()
    local values = {}
    for _, name in ipairs(cameraCVars) do values[name] = ns.GetCVar(name) end
    return values
end
local function RestoreCameraValues(values)
    for name, value in pairs(values or {}) do WriteCameraCVar(name, value) end
end
local function StopCameraAnimation()
    if cameraAnimator then cameraAnimator:SetScript("OnUpdate", nil); cameraAnimator:Hide() end
end
local function AnimateCamera(target, complete, immediate)
    StopCameraAnimation()
    local start = tonumber(ns.GetCVar("test_cameraOverShoulder"))
    target = tonumber(target)
    if not start or not target or immediate or math.abs(start - target) < 0.0001 then
        if target then WriteCameraCVar("test_cameraOverShoulder", target) end
        if complete then complete() end
        return
    end
    if not cameraAnimator then
        cameraAnimator = CreateFrame("Frame", "RetCinemaCameraAnimator")
        cameraAnimator:SetSize(1, 1)
        cameraAnimator:SetPoint("CENTER", UIParent, "CENTER")
        cameraAnimator:EnableMouse(false)
    end
    local elapsed = 0
    cameraAnimator:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        local progress = math.min(1, elapsed / cameraAnimationDuration)
        local eased = progress * progress * (3 - 2 * progress)
        WriteCameraCVar("test_cameraOverShoulder", start + (target - start) * eased)
        if progress == 1 then
            StopCameraAnimation()
            WriteCameraCVar("test_cameraOverShoulder", target)
            if complete then complete() end
        end
    end)
    cameraAnimator:Show()
end
local function PermanentCameraActive()
    return ns.IsEffectEnabled("camerashift") and ns.db.permanentCameraShift and
        ns.db.cameraConsent and ns.CameraAvailable()
end
local function ReturnOriginalCamera(immediate)
    cameraShiftActive = false
    local previous = ns.db.cameraRestore
    if not previous then StopCameraAnimation(); UpdateEvents(); return end
    cameraLensRestore, cameraReturnValues = nil, previous
    AnimateCamera(previous.test_cameraOverShoulder, function()
        RestoreCameraValues(previous)
        ns.db.cameraRestore, cameraReturnValues = nil, nil
        UpdateEvents()
    end, immediate)
    UpdateEvents()
end
local function ApplyCamera(immediate)
    local target
    if cameraShiftActive then target = ns.db.cameraOffset
    elseif PermanentCameraActive() then target = ns.db.permanentCameraOffset end
    if target == nil then
        local previous = cameraLensRestore or cameraReturnValues or ns.db.cameraRestore
        cameraShiftActive = false
        cameraLensRestore, cameraReturnValues = nil, previous
        if not previous then StopCameraAnimation(); UpdateEvents(); return end
        AnimateCamera(previous.test_cameraOverShoulder, function()
            RestoreCameraValues(previous)
            ns.db.cameraRestore, cameraReturnValues = nil, nil
            UpdateEvents()
        end, immediate)
        UpdateEvents()
        return
    end
    if not ns.db.cameraRestore then ns.db.cameraRestore = CaptureCamera() end
    for index = 2, #cameraCVars do
        local name = cameraCVars[index]
        if target ~= 0 then WriteCameraCVar(name, "0") end
    end
    AnimateCamera(target, function()
        if target == 0 then
            for index = 2, #cameraCVars do
                local name = cameraCVars[index]
                local value = ns.db.cameraRestore and ns.db.cameraRestore[name]
                if value then WriteCameraCVar(name, value) end
            end
        end
        if not cameraShiftActive then cameraLensRestore, cameraReturnValues = nil, nil end
        UpdateEvents()
    end, immediate)
    UpdateEvents()
end
local function RestoreCamera(immediate)
    cameraShiftActive = false
    if PermanentCameraActive() then
        cameraLensRestore, cameraReturnValues = nil, nil
    end
    ApplyCamera(immediate)
end
function ns.IsCameraShiftActive() return cameraShiftActive end
function ns.SetCameraOffset(value, permanent)
    local rounded = NumberInRange(value, -15, 15)
    if not rounded then return false end
    local field = permanent and "permanentCameraOffset" or "cameraOffset"
    if ns.db[field] == rounded then return true end
    ns.db[field] = rounded
    if (permanent and not cameraShiftActive and PermanentCameraActive()) or
        (not permanent and cameraShiftActive) then ApplyCamera() end
    return true
end
function ns.SetPermanentCameraShift(enabled)
    ns.db.permanentCameraShift = not not enabled
    if not enabled and cameraShiftActive then cameraLensRestore = ns.db.cameraRestore end
    if not cameraShiftActive then ApplyCamera() end
end
function ns.SetCameraConsent(enabled)
    ns.db.cameraConsent = not not enabled
    if enabled then
        cameraWarningConsent = true
        if PermanentCameraActive() then ApplyCamera() end
    else ReturnOriginalCamera(true) end
end
function RetCinema_ToggleCameraShift()
    if not ns.IsEffectEnabled("camerashift") or not ns.IsAppliedToLens("camerashift") then return end
    if not ns.CameraAvailable() then ns.Print("CameraShift is not supported by this client."); return end
    if not ns.db.cameraConsent then
        ns.Print("Allow experimental camera features in Effect > CameraShift first.")
        return
    end
    exitingAll = false
    if cameraShiftActive then RestoreCamera()
    else
        cameraLensRestore = cameraReturnValues or CaptureCamera()
        cameraShiftActive = true
        ApplyCamera()
    end
end
function ns.RestoreAll()
    if not ns.db or restoringAll or exitingAll then return end
    restoringAll, exitingAll = true, true
    operationDepth = operationDepth + 1
    combinedStates = {}
    if letterboxShown then
        letterboxShown = false
        UpdateLetterboxVisibility()
    end
    ns.RestoreUI()
    if cameraShiftActive then RestoreCamera() end
    operationDepth = operationDepth - 1
    restoringAll = false
    UpdateEvents()
end
local function ForgetCombinedEffect(id)
    for lens, state in pairs(combinedStates) do
        for index = #state, 1, -1 do
            if state[index].action.effect == id then table.remove(state, index) end
        end
        if #state == 0 then combinedStates[lens] = nil end
    end
end
function ns.SetApplyToLens(id, enabled)
    if ns.db.lensEffects[id] == nil then return end
    ns.db.lensEffects[id] = not not enabled
    if not enabled then
        ForgetCombinedEffect(id)
        if id == "hideui" then ns.RestoreUI()
        elseif id == "letterbox" and letterboxShown then letterboxShown = false; UpdateLetterboxVisibility()
        elseif id == "camerashift" and cameraShiftActive then RestoreCamera() end
    end
    UpdateEvents()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
end
function ns.SetEffectEnabled(id, enabled)
    if ns.db.effects[id] == nil then return end
    ns.db.effects[id] = not not enabled
    if not enabled then
        ForgetCombinedEffect(id)
        if id == "hideui" then ns.RestoreUI()
        elseif id == "letterbox" then
            letterboxShown = false
            UpdateLetterboxVisibility(true)
            if bars then bars:SetScript("OnSizeChanged", nil) end
        elseif id == "camerashift" then ReturnOriginalCamera(true) end
    elseif id == "letterbox" then
        if bars then bars:SetScript("OnSizeChanged", UpdateBars); SyncScreen() end
        UpdateLetterboxVisibility()
    elseif id == "camerashift" and PermanentCameraActive() then ApplyCamera() end
    UpdateEvents()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
end
local function PositionMinimapButton()
    if not minimapButton then return end
    local angle = math.rad(ns.db.minimapAngle)
    local radius = Minimap:GetWidth() / 2 + 8
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function ns.SetMinimapButton(shown)
    ns.db.showMinimapButton = not not shown
    minimapButton:SetShown(ns.db.showMinimapButton)
end

local function CreateMinimapButton()
    minimapButton = CreateFrame("Button", "RetCinemaMinimapButton", Minimap)
    minimapButton:SetSize(31, 31)
    minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.icon)
    icon:SetSize(19, 19)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    minimapButton:SetScript("OnClick", function()
        GameTooltip:Hide()
        RetCinema_OpenSettings()
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(ns.title)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnDragStart", function(self)
        -- Runs only while the user is dragging the icon, never while idle.
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx then return end
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            ns.db.minimapAngle = math.deg(math.atan2(y / scale - my, x / scale - mx))
            PositionMinimapButton()
        end)
    end)
    local function StopDrag(self) self:SetScript("OnUpdate", nil) end
    minimapButton:SetScript("OnDragStop", StopDrag)
    minimapButton:SetScript("OnHide", StopDrag)
    PositionMinimapButton()
    ns.SetMinimapButton(ns.db.showMinimapButton)
end

CreateBars = function()
    if bars then return end
    bars = CreateFrame("Frame", "RetCinemaLetterbox")
    bars:Hide()
    bars:SetFrameStrata("BACKGROUND")
    bars:SetFrameLevel(0)
    bars:EnableMouse(false)
    topBar = bars:CreateTexture(nil, "BACKGROUND")
    bottomBar = bars:CreateTexture(nil, "BACKGROUND")
    for _, texture in ipairs({ topBar, bottomBar }) do texture:SetColorTexture(0, 0, 0, 1) end
    topBar:SetPoint("TOPLEFT")
    topBar:SetPoint("TOPRIGHT")
    bottomBar:SetPoint("BOTTOMLEFT")
    bottomBar:SetPoint("BOTTOMRIGHT")
    SyncScreen()
    bars:SetScript("OnSizeChanged", UpdateBars)
    UpdateEvents()
end

local function StartPermanentEffects()
    pendingStartup = nil
    UpdateLetterboxVisibility(true)
    if PermanentCameraActive() then ApplyCamera(true) end
    UpdateEvents()
end

function ns.ApplyProfilePreferences(settings)
    operationDepth = operationDepth + 1
    combinedStates = {}
    ns.RestoreUI()
    ReturnOriginalCamera(true)
    cameraLensRestore, cameraReturnValues = nil, nil
    letterboxShown, barHeight, animationTarget = false, 0, nil
    if bars then
        bars:SetScript("OnUpdate", nil)
        bars:SetScript("OnSizeChanged", nil)
        bars:Hide()
    end
    for key, value in pairs(settings) do ns.db[key] = value end
    UpdateCombinedBindingName()
    if bars and ns.IsEffectEnabled("letterbox") then
        bars:SetScript("OnSizeChanged", UpdateBars)
        SyncScreen()
    end
    ns.SetMinimapButton(ns.db.showMinimapButton)
    PositionMinimapButton()
    exitingAll = false
    operationDepth = operationDepth - 1
    StartPermanentEffects()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
end

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        ret_CinemaDB = type(ret_CinemaDB) == "table" and ret_CinemaDB or {}
        ns.db = ret_CinemaDB
        if type(ns.db.showMinimapButton) ~= "boolean" then ns.db.showMinimapButton = true end
        ns.db.minimapAngle = tonumber(ns.db.minimapAngle) or 220
        ns.db.letterboxHeight = NumberInRange(ns.db.letterboxHeight, 0, 25) or 10
        ns.db.permanentLetterboxHeight = NumberInRange(ns.db.permanentLetterboxHeight, 0, 25) or 10
        ns.db.cameraOffset = NumberInRange(ns.db.cameraOffset, -15, 15) or 1.5
        ns.db.permanentCameraOffset = NumberInRange(ns.db.permanentCameraOffset, -15, 15) or 1.5
        ns.db.permanentLetterbox = ns.db.permanentLetterbox == true
        ns.db.permanentCameraShift = ns.db.permanentCameraShift == true
        ns.db.cameraConsent = ns.db.cameraConsent == true
        if type(ns.db.enableAnimation) ~= "boolean" then ns.db.enableAnimation = true end
        local oldEffects = type(ns.db.modules) == "table" and ns.db.modules or {}
        if type(ns.db.effects) ~= "table" then ns.db.effects = {} end
        if oldEffects.camerashift == nil then oldEffects.camerashift = oldEffects.camera end
        for _, effect in ipairs(ns.effects) do
            if type(ns.db.effects[effect.id]) ~= "boolean" then
                ns.db.effects[effect.id] = oldEffects[effect.id] ~= false
            end
        end
        ns.db.modules = nil
        if type(ns.db.lensEffects) ~= "table" then ns.db.lensEffects = {} end
        for _, action in ipairs(ns.actions) do
            if type(ns.db.lensEffects[action.effect]) ~= "boolean" then ns.db.lensEffects[action.effect] = true end
        end
        ns.db.lensEffects.smoothmotion = false -- No runtime action while this effect is in development.
        ns.db.lensEffects.fov = false
        if type(ns.db.combinedActions) ~= "table" then ns.db.combinedActions = {} end
        for _, action in ipairs(ns.actions) do
            ns.db.combinedActions[action.binding] = ns.db.combinedActions[action.binding] == true
        end
        ns.db.cameraEnabled = nil
        ns.db.combinedAsEsc = ns.db.combinedAsEsc == true
        ns.db.combinedLensCount = math.floor(NumberInRange(ns.db.combinedLensCount, 1, 5) or 1)
        if type(ns.db.extraCombinedLenses) ~= "table" then ns.db.extraCombinedLenses = {} end
        for index = 2, 5 do
            local lens = ns.db.extraCombinedLenses[index]
            if type(lens) ~= "table" then lens = {}; ns.db.extraCombinedLenses[index] = lens end
            lens.exitAll = lens.exitAll == true
            if type(lens.actions) ~= "table" then lens.actions = {} end
            for _, action in ipairs(ns.actions) do lens.actions[action.binding] = lens.actions[action.binding] == true end
        end
        UpdateCombinedBindingName()
        ns.db.showSecondBinding = nil
        -- Recover the original camera before reapplying any saved permanent effect.
        RestoreNames()
        ReturnOriginalCamera(true)
        ns.Profiles.Initialize()
        CreateMinimapButton()
        ns.RegisterSettings()
        if IsLoggedIn and IsLoggedIn() then StartPermanentEffects()
        else pendingStartup = true; UpdateEvents() end
    elseif event == "PLAYER_LOGOUT" then
        ns.Profiles.Save()
        RestoreNames()
        ReturnOriginalCamera(true)
    elseif event == "PLAYER_LOGIN" then
        StartPermanentEffects()
    else
        SyncScreen()
        PositionMinimapButton()
    end
end)
SLASH_RETCINEMA1 = "/retcinema"
SLASH_RETCINEMA2 = "/retcin"
SlashCmdList.RETCINEMA = function(message)
    local command = (message or ""):match("^%s*(%S*)"):lower()
    if command == "" then
        RetCinema_OpenSettings()
    elseif command == "combinedlens" or command:match("^combinedlens[1-5]$") then
        RetCinema_ToggleCombined(tonumber(command:match("(%d)$")) or 1)
    else
        for _, action in ipairs(ns.actions) do
            if command == action.command then action.run(); return end
        end
        ns.Print("Commands: /retcin, /retcin hideui, /retcin showletterbox, /retcin camerashift, /retcin combinedlens (or combinedlens1 through combinedlens5)")
    end
end
