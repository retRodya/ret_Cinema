local addonName, ns = ...

BINDING_HEADER_RETCINEMA = "ret_Cinema"
BINDING_NAME_RETCINEMA_HIDEUI = "Hide UI"
BINDING_NAME_RETCINEMA_LETTERBOX = "Show Letterbox"
BINDING_NAME_RETCINEMA_COMBINED = "Combined Key"
BINDING_NAME_RETCINEMA_CAMERA = "Camera Shift"

ns.icon = 136034
function ns.GetDescription()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getter and getter(addonName, "Notes") or ""
end
ns.modules = {
    { id = "hideui", name = "Hide UI", description = "Hide the UI and world names for clean screenshots.", hint = "Assign a key in the Keybindings tab." },
    { id = "letterbox", name = "Letterbox", description = "Frame your view with cinematic letterboxes.", hint = "Letterboxes - black bars at the top and bottom of the screen." },
    { id = "camerashift", name = "Camera Shift", description = "Set a horizontal camera offset and toggle it with a keybinding.", hint = " " },
    { id = "smoothmotion", name = "Smooth Motion", description = "Smooth Motion", hint = "Under development." },
    { id = "keybindings", name = "Keybindings", description = "Assign keys to Modules.", hint = "Modules can be combined into one key below" },
}
ns.actions = {
    { module = "hideui", binding = "RETCINEMA_HIDEUI", command = "hideui", run = function() RetCinema_ToggleUI() end },
    { module = "letterbox", binding = "RETCINEMA_LETTERBOX", command = "showletterbox", run = function() RetCinema_ToggleLetterbox() end },
    -- Keep the binding ID so existing camera shortcuts survive the rename.
    { module = "camerashift", binding = "RETCINEMA_CAMERA", command = "camerashift", run = function() RetCinema_ToggleCameraShift() end },
}

local bars, topBar, bottomBar, minimapButton
local letterboxShown = false
local barProgress = 0
local animationTarget
local animationDuration = 0.3
local cameraAnimationDuration = 0.35
local events = CreateFrame("Frame")
local uiHidden, visibilityHooked = false, false
local cameraShiftActive = false
local uiRestoreShown = true
local cameraAnimator, escapeHandler, combinedState
local operationDepth, restoringAll, exitingAll = 0, false, false
local SyncScreen, CreateBars

function ns.UpdateEscapeHandler()
    if not ns.db or operationDepth > 0 then return end
    local active = uiHidden or letterboxShown or cameraShiftActive or animationTarget ~= nil or
        ns.db.cameraRestore ~= nil or combinedState ~= nil
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

function ns.IsModuleEnabled(id) return ns.db and ns.db.modules[id] == true end
function ns.IsActionEnabled(action) return ns.IsModuleEnabled(action.module) end
function ns.HasEnabledActionModules()
    for _, action in ipairs(ns.actions) do
        if ns.IsModuleEnabled(action.module) then return true end
    end
    return false
end

local function SyncKeybindingsModule()
    ns.db.modules.keybindings = ns.HasEnabledActionModules()
end

local function UpdateEvents()
    for _, event in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_LOGOUT", "PLAYER_LOGIN" }) do
        events:UnregisterEvent(event)
    end
    if bars and ns.IsModuleEnabled("letterbox") then
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
    print("|cffffd100ret_Cinema:|r " .. message)
end

local function UpdateBars()
    if not bars then return end
    local height = math.max(0.01, bars:GetHeight() * ns.db.letterboxHeight / 100 * barProgress)
    topBar:SetHeight(height)
    bottomBar:SetHeight(height)
    bars:SetShown(ns.IsModuleEnabled("letterbox") and ns.db.letterboxHeight > 0 and (barProgress > 0 or animationTarget ~= nil))
end

local function UpdateLetterboxVisibility()
    if not ns.IsModuleEnabled("letterbox") then return end
    if letterboxShown then CreateBars() end
    if not bars then return end
    local target = letterboxShown and ns.db.letterboxHeight > 0 and 1 or 0
    bars:SetScript("OnUpdate", nil)
    animationTarget = nil
    if not ns.db.enableAnimation or ns.db.letterboxHeight == 0 or barProgress == target then
        barProgress = target
        UpdateBars()
        ns.UpdateEscapeHandler()
        return
    end

    -- Start from the current height so reversing an unfinished animation never jumps.
    local start, elapsed = barProgress, 0
    local duration = animationDuration * math.abs(target - start)
    animationTarget = target
    bars:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local progress = math.min(1, elapsed / duration)
        local eased = progress * progress * (3 - 2 * progress)
        barProgress = start + (target - start) * eased
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

function ns.SetLetterboxHeight(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return false end
    local rounded = math.floor(math.max(0, math.min(25, value)) * 10 + 0.5) / 10
    if ns.db.letterboxHeight == rounded then return true end
    ns.db.letterboxHeight = rounded
    UpdateLetterboxVisibility()
    return true
end

function RetCinema_ToggleLetterbox()
    if not ns.IsModuleEnabled("letterbox") then return end
    exitingAll = false
    letterboxShown = not letterboxShown
    UpdateLetterboxVisibility()
    ns.UpdateEscapeHandler()
end

function ns.SetCombinedAction(binding, enabled)
    for _, action in ipairs(ns.actions) do
        if action.binding == binding then
            ns.db.combinedActions[binding] = not not enabled
            return
        end
    end
end

function ns.HasCombinedActions()
    for _, action in ipairs(ns.actions) do
        if ns.IsActionEnabled(action) and ns.db.combinedActions[action.binding] then return true end
    end
    return false
end

function ns.GetCombinedCommands()
    local commands = {}
    for _, action in ipairs(ns.actions) do
        if ns.IsActionEnabled(action) and ns.db.combinedActions[action.binding] then
            commands[#commands + 1] = "/retcin " .. action.command
        end
    end
    return table.concat(commands, "\n")
end

function RetCinema_ToggleCombined()
    if not ns.IsModuleEnabled("keybindings") then return end
    if combinedState and ns.db.combinedAsEsc then ns.RestoreAll(); return end
    exitingAll = false
    local function IsActive(action)
        if action.module == "hideui" then return uiHidden end
        if action.module == "letterbox" then return letterboxShown end
        return cameraShiftActive
    end
    operationDepth = operationDepth + 1
    if combinedState then
        local previous = combinedState
        combinedState = nil
        for _, saved in ipairs(previous) do
            if ns.IsActionEnabled(saved.action) and IsActive(saved.action) ~= saved.active then saved.action.run() end
        end
    else
        local selected = {}
        for _, action in ipairs(ns.actions) do
            if ns.IsActionEnabled(action) and ns.db.combinedActions[action.binding] then
                selected[#selected + 1] = { action = action, active = IsActive(action) }
            end
        end
        if #selected > 0 then
            combinedState = selected
            for _, saved in ipairs(selected) do saved.action.run() end
        end
    end
    operationDepth = operationDepth - 1
    ns.UpdateEscapeHandler()
end

function RetCinema_RunBinding(binding)
    if not ns.IsModuleEnabled("keybindings") then return end
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
    if not ns.IsModuleEnabled("hideui") then return end
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
local function StopCameraAnimation()
    if cameraAnimator then cameraAnimator:SetScript("OnUpdate", nil); cameraAnimator:Hide() end
end
local function AnimateCamera(target, complete, immediate)
    StopCameraAnimation()
    local start = tonumber(ns.GetCVar("test_cameraOverShoulder"))
    target = tonumber(target)
    if not start or not target or immediate or math.abs(start - target) < 0.0001 then
        if target then WriteCVar("test_cameraOverShoulder", target) end
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
        WriteCVar("test_cameraOverShoulder", start + (target - start) * eased)
        if progress == 1 then
            StopCameraAnimation()
            WriteCVar("test_cameraOverShoulder", target)
            if complete then complete() end
        end
    end)
    cameraAnimator:Show()
end
local function RestoreCamera(immediate)
    cameraShiftActive = false
    local previous = ns.db.cameraRestore
    if not previous then StopCameraAnimation(); UpdateEvents(); return end
    AnimateCamera(previous.test_cameraOverShoulder, function()
        RestoreCVars(previous)
        ns.db.cameraRestore = nil
        UpdateEvents()
    end, immediate)
    UpdateEvents()
end
local function ApplyCamera()
    if not ns.IsModuleEnabled("camerashift") or not cameraShiftActive or not ns.CameraAvailable() then return end
    if not ns.db.cameraRestore then
        ns.db.cameraRestore = {}
        for _, name in ipairs(cameraCVars) do ns.db.cameraRestore[name] = ns.GetCVar(name) end
    end
    -- Keep centering suppressed until the offset has finished returning to zero.
    for index = 2, #cameraCVars do
        local name = cameraCVars[index]
        if ns.db.cameraOffset ~= 0 then WriteCVar(name, "0") end
    end
    AnimateCamera(ns.db.cameraOffset, function()
        if cameraShiftActive and ns.db.cameraOffset == 0 then
            for index = 2, #cameraCVars do
                local name = cameraCVars[index]
                local value = ns.db.cameraRestore and ns.db.cameraRestore[name]
                if value then WriteCVar(name, value) end
            end
        end
    end)
    UpdateEvents()
end
local function SetCameraShiftActive(enabled)
    if not ns.IsModuleEnabled("camerashift") then return end
    if enabled and not ns.CameraAvailable() then
        ns.Print("Camera offset is not supported by this client.")
        return
    end
    cameraShiftActive = not not enabled
    if cameraShiftActive then ApplyCamera() else RestoreCamera() end
end
function ns.IsCameraShiftActive() return cameraShiftActive end
function ns.SetCameraOffset(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return false end
    local rounded = math.floor(math.max(-15, math.min(15, value)) * 10 + 0.5) / 10
    if ns.db.cameraOffset == rounded then return true end
    ns.db.cameraOffset = rounded
    ApplyCamera()
    return true
end
function RetCinema_ToggleCameraShift()
    exitingAll = false
    if ns.IsModuleEnabled("camerashift") then SetCameraShiftActive(not cameraShiftActive) end
end
function ns.RestoreAll()
    if not ns.db or restoringAll or exitingAll then return end
    restoringAll = true
    exitingAll = true
    operationDepth = operationDepth + 1
    combinedState = nil
    letterboxShown = false
    UpdateLetterboxVisibility()
    ns.RestoreUI()
    RestoreCamera()
    operationDepth = operationDepth - 1
    restoringAll = false
    UpdateEvents()
end
function ns.SetModuleEnabled(id, enabled)
    if not ns.db or ns.db.modules[id] == nil then return end
    if id ~= "keybindings" then ns.db.modules[id] = not not enabled end
    SyncKeybindingsModule()
    if not ns.HasEnabledActionModules() then combinedState = nil end
    if not enabled then
        if id == "hideui" then ns.RestoreUI()
        elseif id == "letterbox" then
            letterboxShown, barProgress, animationTarget = false, 0, nil
            if bars then
                bars:SetScript("OnUpdate", nil)
                bars:SetScript("OnSizeChanged", nil)
                bars:Hide()
            end
        elseif id == "camerashift" then RestoreCamera(true) end
    elseif id == "letterbox" and bars then
        bars:SetScript("OnSizeChanged", UpdateBars)
        SyncScreen()
    end
    UpdateEvents()
    if ns.RefreshModuleSettings then ns.RefreshModuleSettings() end
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
        GameTooltip:SetText("ret_Cinema")
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

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        ret_CinemaDB = type(ret_CinemaDB) == "table" and ret_CinemaDB or {}
        ns.db = ret_CinemaDB
        if type(ns.db.showMinimapButton) ~= "boolean" then ns.db.showMinimapButton = true end
        ns.db.minimapAngle = tonumber(ns.db.minimapAngle) or 220
        ns.db.letterboxHeight = tonumber(ns.db.letterboxHeight) or 10
        if type(ns.db.enableAnimation) ~= "boolean" then ns.db.enableAnimation = true end
        if type(ns.db.modules) ~= "table" then ns.db.modules = {} end
        if ns.db.modules.camerashift == nil and type(ns.db.modules.camera) == "boolean" then
            ns.db.modules.camerashift = ns.db.modules.camera
        end
        ns.db.modules.camera = nil
        for _, module in ipairs(ns.modules) do
            if type(ns.db.modules[module.id]) ~= "boolean" then ns.db.modules[module.id] = true end
        end
        SyncKeybindingsModule()
        if type(ns.db.combinedActions) ~= "table" then ns.db.combinedActions = {} end
        for _, action in ipairs(ns.actions) do
            ns.db.combinedActions[action.binding] = ns.db.combinedActions[action.binding] == true
        end

        ns.db.cameraOffset = math.max(-15, math.min(15, tonumber(ns.db.cameraOffset) or 1.5))
        ns.db.cameraEnabled = nil -- Camera Shift starts inactive; its first toggle captures the live offset.
        ns.db.combinedAsEsc = ns.db.combinedAsEsc == true
        ns.db.showSecondBinding = nil -- Secondary slots now follow each action's primary binding.
        ns.db.letterboxHeight = math.max(0, math.min(25, ns.db.letterboxHeight))
        -- Recover original settings after a reload or an interrupted session.
        RestoreNames()
        RestoreCamera(true)
        CreateMinimapButton()
        ns.RegisterSettings()
    elseif event == "PLAYER_LOGOUT" then
        RestoreNames()
        RestoreCamera(true)
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
    elseif command == "combined" then
        RetCinema_ToggleCombined()
    else
        for _, action in ipairs(ns.actions) do
            if command == action.command then action.run(); return end
        end
        ns.Print("Commands: /retcin, /retcin hideui, /retcin showletterbox, /retcin camerashift, /retcin combined")
    end
end
