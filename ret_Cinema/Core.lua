local addonName, ns = ...

ns.retColor = "|cff9acd32"
function ns.ColorRet(text)
    -- Idempotent: rendering a title twice must not nest color escapes.
    text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%xret_|r", "ret_")
    return (text:gsub("ret_", ns.retColor .. "ret_|r"))
end
ns.title = ns.ColorRet("ret_|cff40c7ebCinema|r")
BINDING_HEADER_RETCINEMA = ns.title
BINDING_NAME_RETCINEMA_HIDEUI = "HideUI"
BINDING_NAME_RETCINEMA_LETTERBOX = "Letterbox"
BINDING_NAME_RETCINEMA_COMBINED = "Combined Lens"
BINDING_NAME_RETCINEMA_CAMERA = "CameraShift"
BINDING_NAME_RETCINEMA_FOV = "FOV"
for index = 2, 5 do _G["BINDING_NAME_RETCINEMA_COMBINED" .. index] = "Combined Lens " .. index end

ns.icon = 136034
function ns.GetDescription()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getter and getter(addonName, "Notes") or ""
end
function ns.GetVersion()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getter and getter(addonName, "Version") or ""
end
ns.effects = {
    { id = "hideui", name = "HideUI", description = "Hide the UI and world names for clean screenshots.", hint = "Assign a Lens button in the Lens tab." },
    { id = "letterbox", name = "Letterbox", description = "Frame your view with cinematic letterboxes.", hint = "Letterboxes - black bars at the top and bottom of the screen." },
    { id = "camerashift", name = "CameraShift", description = "Set a horizontal camera offset and toggle it with a Lens button.", hint = " " },
    { id = "fov", name = "FOV", description = "Adjust your field of view.", hint = "Use a permanent field of view or apply a different view to your Lens." },
    { id = "smoothmotion", name = "SmoothMotion", description = "SmoothMotion", hint = "Under consideration. This Effect is not available yet.", underConsideration = true },
}
ns.generalHint = "Turn on the Permanent Effect as well as applying this Effect to your Lens."
ns.lens = { description = "Assign Lens buttons to Effects.", hint = "Effects can be added to Combined Lens buttons." }
ns.actions = {
    { effect = "hideui", binding = "RETCINEMA_HIDEUI", command = "hideui", run = function() RetCinema_ToggleUI() end },
    { effect = "letterbox", binding = "RETCINEMA_LETTERBOX", command = "showletterbox", run = function() RetCinema_ToggleLetterbox() end },
    -- Keep the binding ID so existing camera shortcuts survive the rename.
    { effect = "camerashift", binding = "RETCINEMA_CAMERA", command = "camerashift", run = function() RetCinema_ToggleCameraShift() end },
    { effect = "fov", binding = "RETCINEMA_FOV", command = "fov", run = function() RetCinema_ToggleFOV() end },
}

ns.advancedOptions = {
    { id = "hideInterface", group = "HideUI", name = "Don't hide interface elements" },
    { id = "hideNames", group = "HideUI", name = "Don't hide creature names" },
    { id = "letterboxOpacity", group = "Letterbox", name = "Custom Letterbox transparency" },
    { id = "letterboxSpeed", group = "Letterbox", name = "Custom Letterbox animation speed" },
    { id = "letterboxFull", group = "Letterbox", name = "Allow bar height up to 50%" },
    { id = "cameraSpeed", group = "CameraShift", name = "Custom CameraShift animation speed" },
    { id = "cameraHeadMovement", group = "CameraShift", name = "Head bob" },
    { id = "cameraTargetFocus", group = "CameraShift", name = "Follow the target" },
    { id = "fovSpeed", group = "FOV", name = "Custom FOV animation speed", version = 8 },
    { id = "secondButton", group = "Lens", name = "Additional keybind button" },
    { id = "moreCombined", group = "Lens", name = "Combined Lenses up to 5" },
    { id = "roleplay", group = "LiteRP", name = "LiteRP", experimental = true },
}
function ns.Advanced(id)
    return ns.db and ns.db.advancedCinematographer and ns.db.advanced and ns.db.advanced[id] == true
end
function ns.LetterboxMaximum() return ns.Advanced("letterboxFull") and 50 or 25 end
ns.runtimeSettings = {}
ns.settingSpecs = {
    { effect = "hideui", key = "hideInterface", label = "Don't hide interface elements", default = true, inverted = true, advanced = "hideInterface" },
    { effect = "hideui", key = "hideNames", label = "Don't hide creature names", default = true, inverted = true, advanced = "hideNames" },
    { effect = "letterbox", key = "letterboxOpacity", label = "Bar opacity", default = 1, low = 0, high = 1, advanced = "letterboxOpacity" },
    { effect = "letterbox", key = "letterboxDuration", label = "Animation duration (seconds)", default = 0.3, low = 0.1, high = 5, advanced = "letterboxSpeed" },
    { effect = "fov", key = "fovDuration", label = "Animation duration (seconds)", default = 0.35, low = 0.1, high = 5, advanced = "fovSpeed", version = 8 },
    { effect = "camerashift", key = "cameraDuration", label = "Animation duration (seconds)", default = 0.35, low = 0.1, high = 5, advanced = "cameraSpeed" },
    { effect = "camerashift", key = "cameraHeadMovement", label = "Head bob", default = false, cvar = "test_cameraHeadMovementStrength", advanced = "cameraHeadMovement" },
    { effect = "camerashift", key = "cameraTargetFocus", label = "Follow the target", default = false, cvar = "test_cameraTargetFocusEnemyEnable", advanced = "cameraTargetFocus",
        tooltip = "Enable native target focus in and out of combat. Friendly-target tracking depends on the game client." },
}
function ns.SetEffectSetting(key, value, permanent, index)
    if index ~= nil and (type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > ns.GetCombinedCount()) then return false end
    local source = index and index > 1 and ns.db.extraCombinedLenses[index] or ns.db
    if not source then return false end
    for _, spec in ipairs(ns.settingSpecs) do
        if spec.key == key then
            if spec.advanced and not ns.Advanced(spec.advanced) then return false end
            if type(spec.default) == "boolean" then value = value == true
            else
                value = tonumber(value)
                if not value or value ~= value or value < spec.low or value > spec.high then return false end
            end
            local field = permanent and "permanent" .. key:sub(1, 1):upper() .. key:sub(2) or key
            source[field] = value
            if not index then
                if spec.effect == "letterbox" then ns.UpdateLetterboxVisibility()
                elseif spec.effect == "camerashift" then ns.RefreshCamera()
                elseif spec.effect == "fov" then ns.UpdateFOV()
                end
            end
            return true
        end
    end
    return false
end
function ns.EffectSettings(effect, permanent, index)
    local source = index and index > 1 and ns.db.extraCombinedLenses[index] or ns.db
    local prefix = permanent and "permanent" or ""
    local function read(key, fallback)
        local field = prefix ~= "" and prefix .. key:sub(1, 1):upper() .. key:sub(2) or key
        local value = source[field]
        if value == nil then value = fallback end
        return value
    end
    if effect == "hideui" then return {
        hideInterface = not ns.Advanced("hideInterface") or read("hideInterface", true),
        hideNames = not ns.Advanced("hideNames") or read("hideNames", true),
    } end
    if effect == "letterbox" then return {
        opacity = ns.Advanced("letterboxOpacity") and read("letterboxOpacity", 1) or 1,
        duration = ns.Advanced("letterboxSpeed") and read("letterboxDuration", 0.3) or 0.3,
    } end
    if effect == "fov" then return {
        duration = ns.Advanced("fovSpeed") and read("fovDuration", 0.35) or 0.35,
    } end
    if effect == "camerashift" then return {
        duration = ns.Advanced("cameraSpeed") and read("cameraDuration", 0.35) or 0.35,
        headMovement = ns.Advanced("cameraHeadMovement") and read("cameraHeadMovement", false) or false,
        targetFocus = ns.Advanced("cameraTargetFocus") and read("cameraTargetFocus", false) or false,
    } end
    return {}
end

local bars, topBar, bottomBar, minimapButton
local letterboxShown = false
local letterboxLensHeight, cameraLensOffset
local barHeight = 0
local animationTarget
local events = CreateFrame("Frame")
local uiHidden, visibilityHooked = false, false
local cameraShiftActive = false
local uiRestoreShown, uiRestoreAlpha = true, nil
local interfaceSuppressed = false
local cameraAnimator, fovAnimator, escapeHandler
local combinedStates = {}
local cameraLensRestore, cameraReturnValues, pendingStartup
local cameraLastDuration, cameraReturnDuration
local operationDepth, restoringAll, exitingAll = 0, false, false
local SyncScreen, CreateBars, UpdateBars
local SetActionState
local function RoleplayOwns(effect)
    return ns.IsRoleplayEffectOwned and ns.IsRoleplayEffectOwned(effect)
end

function ns.UpdateEscapeHandler()
    if not ns.db or operationDepth > 0 then return end
    local active = uiHidden or letterboxShown or cameraShiftActive or ns.fovActive or next(combinedStates) ~= nil
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
            if key == "ESCAPE" then ns.RestoreAll(true) end
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
    local barsActive = bars and ns.IsEffectEnabled("letterbox") and (barHeight > 0 or animationTarget ~= nil)
    if bars then bars:SetScript("OnSizeChanged", barsActive and UpdateBars or nil) end
    if barsActive then
        events:RegisterEvent("UI_SCALE_CHANGED")
        events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    end
    if ns.db and (ns.db.hiddenCVars or ns.db.cameraRestore or ns.db.fovRestore) then events:RegisterEvent("PLAYER_LOGOUT") end
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

UpdateBars = function()
    if not bars then return end
    local height = math.max(0.01, bars:GetHeight() * barHeight / 100)
    topBar:SetHeight(height)
    bottomBar:SetHeight(height)
    bars:SetShown(ns.IsEffectEnabled("letterbox") and (barHeight > 0 or animationTarget ~= nil))
end

local function UpdateLetterboxVisibility(immediate, returnDuration)
    immediate = immediate or not ns.IsEffectEnabled("letterbox")
    local target = 0
    if ns.IsEffectEnabled("letterbox") then
        target = letterboxShown and (letterboxLensHeight or ns.db.letterboxHeight) or
            (ns.db.permanentLetterbox and ns.db.permanentLetterboxHeight or 0)
    end
    target = math.min(target, ns.LetterboxMaximum())
    if ns.logoutBarHeight then target = ns.logoutBarHeight end
    if target > 0 then CreateBars(); SyncScreen() end
    if not bars then return end
    local options = letterboxShown and (ns.runtimeSettings.letterbox or ns.EffectSettings("letterbox")) or ns.EffectSettings("letterbox", ns.db.permanentLetterbox)
    if not letterboxShown and not ns.db.permanentLetterbox then options = { opacity = 1, duration = 0.3 } end
    bars:SetAlpha(ns.logoutBarHeight and 1 or options.opacity)
    bars:SetScript("OnUpdate", nil)
    animationTarget = nil
    if immediate or barHeight == target then
        barHeight = target
        UpdateBars()
        UpdateEvents()
        return
    end

    -- Start from the current height so reversing an unfinished animation never jumps.
    local start, elapsed = barHeight, 0
    local span = math.max(start, target, ns.db.letterboxHeight,
        ns.db.permanentLetterbox and ns.db.permanentLetterboxHeight or 0)
    local duration = returnDuration or options.duration * math.abs(target - start) / span
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
        if progress == 1 then UpdateEvents() end
    end)
    UpdateBars()
    UpdateEvents()
end
ns.UpdateLetterboxVisibility = UpdateLetterboxVisibility
function ns.GetLetterboxCurrentHeight() return barHeight end
function ns.SetLogoutBarHeight(value, quickReturn)
    local wasVisible = barHeight > 0
    local first = ns.logoutBarHeight == nil
    ns.logoutBarHeight = value
    if value == nil then UpdateLetterboxVisibility(false, quickReturn and 0.15 or nil); return end
    CreateBars()
    if not bars then return end
    if first then SyncScreen() end
    bars:SetScript("OnUpdate", nil)
    animationTarget = nil
    barHeight = math.max(0, math.min(50, value))
    bars:SetAlpha(1)
    UpdateBars()
    if wasVisible ~= (barHeight > 0) then UpdateEvents() end
end

SyncScreen = function()
    if not bars then return end
    -- An independent parent keeps the bars visible when screenshot mode hides UIParent.
    bars:SetScale(UIParent:GetScale())
    bars:ClearAllPoints()
    bars:SetAllPoints(UIParent)
    UpdateBars()
end

local function NumberInRange(value, low, high)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return end
    return math.floor(math.max(low, math.min(high, value)) * 10 + 0.5) / 10
end
function ns.SetLetterboxHeight(value, permanent)
    local rounded = NumberInRange(value, 0, ns.LetterboxMaximum())
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

function RetCinema_ToggleLetterbox(value)
    if operationDepth == 0 and RoleplayOwns("letterbox") then return end
    if not ns.IsEffectEnabled("letterbox") or not ns.IsAppliedToLens("letterbox") then return end
    if operationDepth == 0 and ns.CancelRoleplay and not ns.IsRoleplayActive() then ns.CancelRoleplay() end
    exitingAll = false
    if operationDepth == 0 then ns.runtimeSettings.letterbox = nil end
    if value ~= nil then
        letterboxLensHeight = NumberInRange(value, 0, ns.LetterboxMaximum())
        letterboxShown = true
    else letterboxShown, letterboxLensHeight = not letterboxShown, nil end
    UpdateLetterboxVisibility()
    ns.UpdateEscapeHandler()
end

function ns.CombinedBinding(index)
    return index == 1 and "RETCINEMA_COMBINED" or "RETCINEMA_COMBINED" .. index
end
function ns.CombinedLimit() return ns.Advanced("moreCombined") and 5 or 3 end
function ns.GetCombinedCount() return math.min(ns.db.combinedLensCount, ns.CombinedLimit()) end
local function UpdateCombinedBindingName()
    BINDING_NAME_RETCINEMA_COMBINED = ns.GetCombinedCount() > 1 and "Combined Lens 1" or "Combined Lens"
end
function ns.GetCombinedActions(index)
    index = index or 1
    if index == 1 then return ns.db.combinedActions end
    local lens = ns.db.extraCombinedLenses[index]
    return lens and lens.actions
end
local combinedValueFields = {
    letterbox = { value = "letterboxHeight", low = 0, high = 25 },
    camerashift = { value = "cameraOffset", low = -15, high = 15 },
    fov = { value = "fov", low = 1, high = 179 },
}
function ns.GetCombinedEffectValue(index, effect)
    local field = combinedValueFields[effect]
    if not field then return end
    local lens = ns.db.extraCombinedLenses[index]
    return index > 1 and lens and lens[field.value] or ns.db[field.value]
end
function ns.SetCombinedEffectValue(index, effect, value)
    local field, lens = combinedValueFields[effect], ns.db.extraCombinedLenses[index]
    if not field or type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > ns.GetCombinedCount() or (index > 1 and not lens) then return false end
    local low, high = field.low, field.high
    if effect == "letterbox" then high = ns.LetterboxMaximum()
    elseif effect == "fov" then low, high = ns.FOVRange() end
    local rounded = NumberInRange(value, low, high)
    if not rounded then return false end
    if index == 1 then ns.db[field.value] = rounded else lens[field.value] = rounded end
    return true
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
    if ns.GetCombinedCount() >= ns.CombinedLimit() then return false end
    ns.db.combinedLensCount = ns.GetCombinedCount() + 1
    UpdateCombinedBindingName()
    ns.UpdateTrigger()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
    return true
end
function ns.SetCombinedAction(binding, enabled, index)
    local actions = ns.GetCombinedActions(index)
    if not actions then return end
    for _, action in ipairs(ns.actions) do
        if action.binding == binding then
            actions[binding] = not not enabled
            ns.UpdateTrigger()
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

local function IsActionActive(action)
    if action.effect == "hideui" then return uiHidden end
    if action.effect == "letterbox" then return letterboxShown end
    if action.effect == "camerashift" then return ns.IsCameraShiftActive() end
    return ns.fovActive == true
end
local function RestoreCombined(index)
    local previous = combinedStates[index]
    combinedStates[index] = nil
    if not previous then return end
    for _, saved in ipairs(previous) do
        if ns.IsActionEnabled(saved.action) and not RoleplayOwns(saved.action.effect) then SetActionState(saved.action, saved.active, saved.value, saved.options) end
    end
end
function ns.RemoveCombinedLens()
    local index = ns.GetCombinedCount()
    if index <= 1 or InCombatLockdown() then return false end
    operationDepth = operationDepth + 1
    -- Deleting a lens restores its own snapshot, irrespective of Escape Button.
    RestoreCombined(index)
    operationDepth = operationDepth - 1
    -- Hide this slot; its preferences and native game bindings survive re-adding it.
    ns.db.combinedLensCount = index - 1
    ns.UpdateTrigger()
    UpdateCombinedBindingName()
    ns.UpdateEscapeHandler()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
    return true
end
function RetCinema_ToggleCombined(index)
    index = index or 1
    if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > ns.GetCombinedCount() then return end
    local exitAll = ns.GetCombinedExitAll(index)
    -- RP-owned Effects cannot be changed by Lens shortcuts. Unrelated Effects
    -- can still toggle, while the saved Escape Button preference is retained.
    if ns.IsRoleplayActive and ns.IsRoleplayActive() then exitAll = false end
    if combinedStates[index] and exitAll then
        -- A different button can remove the last unrelated effect. Compare the
        -- effective scene, rather than requiring two consecutive key presses.
        local onlyThisLens = true
        for _, action in ipairs(ns.actions) do
            local wanted = ns.IsActionEnabled(action) and ns.GetCombinedActions(index)[action.binding] == true
            if IsActionActive(action) ~= wanted then onlyThisLens = false; break end
            if wanted then
                local current = action.effect == "letterbox" and (letterboxLensHeight or ns.db.letterboxHeight) or
                    action.effect == "camerashift" and (cameraLensOffset or ns.db.cameraOffset) or
                    action.effect == "fov" and (ns.fovLensValue or ns.db.fov)
                if current and current ~= ns.GetCombinedEffectValue(index, action.effect) then onlyThisLens = false; break end
                local actual = ns.runtimeSettings[action.effect] or ns.EffectSettings(action.effect)
                for key, value in pairs(ns.EffectSettings(action.effect, false, index)) do
                    if actual[key] ~= value then onlyThisLens = false; break end
                end
            end
        end
        if onlyThisLens then ns.RestoreAll(); return end
        ns.RestoreAll()
    end
    if not combinedStates[index] and not ns.HasCombinedActions(index) then return end
    if ns.CancelRoleplay and not ns.IsRoleplayActive() then ns.CancelRoleplay() end
    exitingAll = false
    operationDepth = operationDepth + 1
    if combinedStates[index] and not exitAll then
        RestoreCombined(index)
    else
        local selected = {}
        for _, action in ipairs(ns.actions) do
            if ns.IsActionEnabled(action) and ns.GetCombinedActions(index)[action.binding] and not RoleplayOwns(action.effect) then
                local value
                if action.effect == "letterbox" then value = letterboxLensHeight
                elseif action.effect == "camerashift" then value = cameraLensOffset
                elseif action.effect == "fov" then value = ns.fovLensValue end
                selected[#selected + 1] = { action = action, active = IsActionActive(action), value = value,
                    options = ns.runtimeSettings[action.effect] }
            end
        end
        if #selected > 0 then
            combinedStates[index] = selected
            for _, saved in ipairs(selected) do
                local value = ns.GetCombinedEffectValue(index, saved.action.effect)
                if exitAll or value ~= nil or not saved.active then
                    SetActionState(saved.action, true, value, ns.EffectSettings(saved.action.effect, false, index))
                else SetActionState(saved.action, false) end
            end
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
    local restoreVisibility, shown = interfaceSuppressed, uiRestoreShown
    interfaceSuppressed = false
    RestoreNames()
    if restoreVisibility then
        if uiRestoreAlpha ~= nil then
            UIParent:SetAlpha(uiRestoreAlpha); uiRestoreAlpha = nil
            if not shown then if SetUIVisibility then SetUIVisibility(false) else UIParent:Hide() end end
        elseif SetUIVisibility then SetUIVisibility(shown) else UIParent:SetShown(shown) end
    end
    operationDepth = operationDepth - 1
    UpdateEvents()
end
function RetCinema_ToggleUI()
    if operationDepth == 0 and RoleplayOwns("hideui") then return end
    if not ns.IsEffectEnabled("hideui") or not ns.IsAppliedToLens("hideui") then return end
    if operationDepth == 0 and ns.CancelRoleplay and not ns.IsRoleplayActive() then ns.CancelRoleplay() end
    exitingAll = false
    if uiHidden then
        ns.RestoreUI()
        return
    end
    if operationDepth == 0 then ns.runtimeSettings.hideui = nil end
    local options = ns.runtimeSettings.hideui or ns.EffectSettings("hideui")
    if not visibilityHooked then
        UIParent:HookScript("OnShow", function()
            if uiHidden and interfaceSuppressed and operationDepth == 0 then
                -- Combat and camera controls must not cancel screenshot mode.
                if uiRestoreAlpha ~= nil then UIParent:SetAlpha(0)
                elseif SetUIVisibility then SetUIVisibility(false) else UIParent:Hide() end
            end
        end)
        visibilityHooked = true
    end
    ns.db.hiddenCVars = {}
    uiRestoreShown = UIParent:IsShown()
    for _, name in ipairs(options.hideNames and nameCVars or {}) do
        local value = ns.GetCVar(name)
        if value ~= nil then
            ns.db.hiddenCVars[name] = value
            WriteCVar(name, "0")
        end
    end
    uiHidden = true
    interfaceSuppressed = options.hideInterface
    operationDepth = operationDepth + 1
    UpdateEvents()
    if interfaceSuppressed then
        if ns.IsRoleplayLogoutActive and ns.IsRoleplayLogoutActive() then
            -- Hiding UIParent fires native popup OnHide callbacks, which cancel
            -- logout. Fade the interface instead while this countdown owns it.
            uiRestoreAlpha = UIParent:GetAlpha()
            UIParent:SetAlpha(0)
        elseif SetUIVisibility then SetUIVisibility(false) else UIParent:Hide() end
    end
    operationDepth = operationDepth - 1
    UpdateEvents()
end

function ns.CameraAvailable() return ns.GetCVar("test_cameraOverShoulder") ~= nil end
local cameraCVars = { "test_cameraOverShoulder", "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement",
    "test_cameraHeadMovementStrength", "test_cameraTargetFocusEnemyEnable", "test_cameraTargetFocusInteractEnable", "CameraFollowTargetCombat" }
local warningHooked, cameraWriteInProgress, cameraWriteAt, cameraWarningConsent
local function InstallCameraWarningGuard()
    if warningHooked or not hooksecurefunc or not StaticPopup_Show or not StaticPopup_Hide then return end
    warningHooked = true
    -- This warning has no acceptance API: Blizzard's Accept button only dismisses it.
    -- Dismiss only camera warnings immediately following our own consented writes.
    hooksecurefunc("StaticPopup_Show", function(which)
        if which ~= "EXPERIMENTAL_CVAR_WARNING" or not cameraWarningConsent then return end
        local recentWrite = cameraWriteInProgress or
            (GetTime and cameraWriteAt and GetTime() - cameraWriteAt < 0.1)
        if recentWrite then
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
    local options = cameraShiftActive and (ns.runtimeSettings.camerashift or ns.EffectSettings("camerashift")) or ns.EffectSettings("camerashift", true)
    local duration = cameraReturnDuration or options.duration
    cameraLastDuration = duration
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
        local progress = math.min(1, elapsed / duration)
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
    cameraReturnDuration = cameraLastDuration
    cameraShiftActive = false
    cameraLensOffset = nil
    local previous = ns.db.cameraRestore
    if not previous then cameraReturnDuration = nil; StopCameraAnimation(); UpdateEvents(); return end
    cameraLensRestore, cameraReturnValues = nil, previous
    AnimateCamera(previous.test_cameraOverShoulder, function()
        RestoreCameraValues(previous)
        ns.db.cameraRestore, cameraReturnValues = nil, nil
        cameraReturnDuration = nil
        UpdateEvents()
    end, immediate)
    UpdateEvents()
end
local function ApplyCamera(immediate)
    local target
    if cameraShiftActive then target = cameraLensOffset or ns.db.cameraOffset
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
    local options = cameraShiftActive and (ns.runtimeSettings.camerashift or ns.EffectSettings("camerashift")) or ns.EffectSettings("camerashift", true)
    local needsMotion = target ~= 0 or options.headMovement or options.targetFocus
    for index = 2, 3 do
        local name = cameraCVars[index]
        if needsMotion then WriteCameraCVar(name, "0") end
    end
    local original = ns.db.cameraRestore
    if ns.Advanced("cameraHeadMovement") then
        WriteCameraCVar("test_cameraHeadMovementStrength", options.headMovement and "1" or "0")
    elseif original.test_cameraHeadMovementStrength then
        WriteCameraCVar("test_cameraHeadMovementStrength", original.test_cameraHeadMovementStrength)
    end
    for _, name in ipairs({ "test_cameraTargetFocusEnemyEnable", "test_cameraTargetFocusInteractEnable" }) do
        if ns.Advanced("cameraTargetFocus") then WriteCameraCVar(name, options.targetFocus and "1" or "0")
        elseif original[name] then WriteCameraCVar(name, original[name]) end
    end
    -- This native gate otherwise limits locked-target tracking to combat.
    -- Restore the exact preference whenever this layer no longer uses focus.
    if original.CameraFollowTargetCombat then
        WriteCameraCVar("CameraFollowTargetCombat", options.targetFocus and "0" or original.CameraFollowTargetCombat)
    end
    AnimateCamera(target, function()
        if not needsMotion then
            for index = 2, 3 do
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
    cameraReturnDuration = cameraLastDuration
    cameraShiftActive = false
    cameraLensOffset = nil
    if PermanentCameraActive() then
        cameraLensRestore, cameraReturnValues = nil, nil
    end
    ApplyCamera(immediate)
    -- AnimateCamera captures the duration, so later setting edits use their own value.
    cameraReturnDuration = nil
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
function ns.RefreshCamera() if cameraShiftActive or PermanentCameraActive() then ApplyCamera() end end
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
function RetCinema_ToggleCameraShift(value)
    if operationDepth == 0 and RoleplayOwns("camerashift") then return end
    if not ns.IsEffectEnabled("camerashift") or not ns.IsAppliedToLens("camerashift") then return end
    if not ns.CameraAvailable() then ns.Print("CameraShift is not supported by this client."); return end
    if not ns.db.cameraConsent then
        ns.Print("Enable CameraShift on the ret_Cinema page first.")
        return
    end
    if operationDepth == 0 and ns.CancelRoleplay and not ns.IsRoleplayActive() then ns.CancelRoleplay() end
    exitingAll = false
    if operationDepth == 0 then ns.runtimeSettings.camerashift = nil end
    if cameraShiftActive and value == nil then RestoreCamera()
    else
        cameraReturnDuration = nil
        if not cameraShiftActive then cameraLensRestore = cameraReturnValues or CaptureCamera() end
        cameraLensOffset = value ~= nil and NumberInRange(value, -15, 15) or nil
        cameraShiftActive = true
        ApplyCamera()
    end
end
function ns.FOVRange()
    if GetCameraFOVDefaults then
        local _, low, high = GetCameraFOVDefaults()
        if type(low) == "number" and type(high) == "number" and low < high then return low, high end
    end
    return 60, 90
end
function ns.FOVDefault()
    local low, high = ns.FOVRange()
    local value = GetCameraFOVDefaults and GetCameraFOVDefaults() or tonumber(ns.GetCVar("cameraFov")) or 90
    return NumberInRange(value, low, high) or high
end
function ns.FOVAvailable() return ns.GetCVar("cameraFov") ~= nil end
local function StopFOVAnimation()
    if fovAnimator then fovAnimator:SetScript("OnUpdate", nil); fovAnimator:Hide() end
end
local fovLastDuration = 0.35
function ns.UpdateFOV(immediate)
    if not ns.db then return end
    StopFOVAnimation()
    local target
    if ns.IsEffectEnabled("fov") and ns.FOVAvailable() then
        if ns.fovActive then target = ns.fovLensValue or ns.db.fov
        elseif ns.db.permanentFOV then target = ns.db.permanentFov end
    end
    local restoring = target == nil
    local duration = restoring and fovLastDuration or
        (ns.fovActive and (ns.runtimeSettings.fov or ns.EffectSettings("fov")) or ns.EffectSettings("fov", true)).duration
    if not restoring then fovLastDuration = duration end
    if target then
        if not ns.db.fovRestore then ns.db.fovRestore = ns.GetCVar("cameraFov") end
        local low, high = ns.FOVRange()
        target = NumberInRange(target, low, high)
    else target = tonumber(ns.db.fovRestore) end
    if not target then UpdateEvents(); return end
    local start = tonumber(ns.GetCVar("cameraFov"))
    local function Complete()
        WriteCVar("cameraFov", restoring and ns.db.fovRestore or target)
        if restoring then ns.db.fovRestore = nil end
        UpdateEvents()
    end
    if immediate or not start or math.abs(start - target) < 0.0001 then Complete()
    else
        if not fovAnimator then fovAnimator = CreateFrame("Frame", "RetCinemaFOVAnimator") end
        local elapsed = 0
        fovAnimator:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            local progress = math.min(1, elapsed / duration)
            local eased = progress * progress * (3 - 2 * progress)
            WriteCVar("cameraFov", start + (target - start) * eased)
            if progress == 1 then StopFOVAnimation(); Complete() end
        end)
        fovAnimator:Show()
    end
    UpdateEvents()
end
function ns.ReturnOriginalFOV()
    StopFOVAnimation()
    fovLastDuration = 0.35
    ns.fovActive, ns.fovLensValue = false, nil
    if ns.db.fovRestore then WriteCVar("cameraFov", ns.db.fovRestore); ns.db.fovRestore = nil end
    UpdateEvents()
end
function ns.SetFOV(value, permanent)
    local low, high = ns.FOVRange()
    local number = NumberInRange(value, low, high)
    if not number then return false end
    ns.db[permanent and "permanentFov" or "fov"] = number
    ns.UpdateFOV()
    return true
end
function ns.SetPermanentFOV(enabled) ns.db.permanentFOV = not not enabled; ns.UpdateFOV() end
function RetCinema_ToggleFOV(value)
    if operationDepth == 0 and RoleplayOwns("fov") then return end
    if not ns.IsEffectEnabled("fov") or not ns.IsAppliedToLens("fov") or not ns.FOVAvailable() then return end
    if operationDepth == 0 and ns.CancelRoleplay and not ns.IsRoleplayActive() then ns.CancelRoleplay() end
    exitingAll = false
    if operationDepth == 0 then ns.runtimeSettings.fov = nil end
    if value ~= nil then ns.fovActive, ns.fovLensValue = true, value
    else ns.fovActive, ns.fovLensValue = not ns.fovActive, nil end
    ns.UpdateFOV()
end
SetActionState = function(action, active, value, options)
    if active then exitingAll = false end
    if action.effect == "hideui" and active and uiHidden then ns.RestoreUI() end
    ns.runtimeSettings[action.effect] = options
    if action.effect == "letterbox" then
        local changed = letterboxShown ~= active or letterboxLensHeight ~= value
        letterboxShown, letterboxLensHeight = active, active and value or nil
        if changed or active then UpdateLetterboxVisibility() end
    elseif action.effect == "camerashift" then
        if not active then
            if cameraShiftActive then RestoreCamera() end
        elseif not cameraShiftActive then RetCinema_ToggleCameraShift(value)
        else cameraLensOffset = value; ApplyCamera() end
    elseif action.effect == "fov" then
        ns.fovActive, ns.fovLensValue = active, active and value or nil
        ns.UpdateFOV()
    elseif IsActionActive(action) ~= active then action.run() end
end
function ns.CaptureLensState()
    local state = {}
    state.combined = {}
    for index, entries in pairs(combinedStates) do
        state.combined[index] = {}
        for _, entry in ipairs(entries) do
            state.combined[index][#state.combined[index] + 1] = { action = entry.action, active = entry.active, value = entry.value, options = entry.options }
        end
    end
    for _, action in ipairs(ns.actions) do
        state[#state + 1] = { action = action, active = IsActionActive(action), options = ns.runtimeSettings[action.effect],
            value = action.effect == "letterbox" and letterboxLensHeight or action.effect == "camerashift" and cameraLensOffset or
                action.effect == "fov" and ns.fovLensValue or nil }
    end
    return state
end
function ns.RestoreLensState(state)
    operationDepth = operationDepth + 1
    if state and state.combined then
        combinedStates = {}
        for index, entries in pairs(state.combined) do
            combinedStates[index] = {}
            for _, entry in ipairs(entries) do combinedStates[index][#combinedStates[index] + 1] = {
                action = entry.action, active = entry.active, value = entry.value, options = entry.options } end
        end
    end
    for _, saved in ipairs(state or {}) do
        if ns.IsActionEnabled(saved.action) then SetActionState(saved.action, saved.active, saved.value, saved.options) end
    end
    operationDepth = operationDepth - 1
    UpdateEvents()
end
function ns.ActivateRoleplayTarget(target)
    operationDepth = operationDepth + 1
    -- Preserve the original numeric IDs used by existing Trigger profiles.
    if target <= 2 or target == 8 then
        local action = ns.actions[target == 8 and 4 or target + 1]
        if ns.IsActionEnabled(action) then SetActionState(action, true, ns.GetCombinedEffectValue(1, action.effect), ns.EffectSettings(action.effect)) end
    else
        local index = target - 2
        for _, action in ipairs(ns.actions) do
            if ns.IsActionEnabled(action) and ns.GetCombinedActions(index)[action.binding] then
                SetActionState(action, true, ns.GetCombinedEffectValue(index, action.effect), ns.EffectSettings(action.effect, false, index))
            end
        end
    end
    operationDepth = operationDepth - 1
    UpdateEvents()
end
function ns.SetAdvanced(id, enabled)
    if id == nil then ns.db.advancedCinematographer = enabled == true
    else
        local known
        for _, option in ipairs(ns.advancedOptions) do if option.id == id then known = true; break end end
        if not known then return false end
        ns.db.advanced[id] = enabled == true
        if enabled and (id == "hideInterface" or id == "hideNames") then ns.db[id] = false end
    end
    ns.RestoreAll()
    ns.runtimeSettings = {}
    UpdateCombinedBindingName()
    UpdateLetterboxVisibility()
    ns.RefreshCamera()
    ns.UpdateFOV()
    ns.UpdateTrigger()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
    return true
end
function ns.RestoreAll(preserveRoleplay)
    if preserveRoleplay and ns.IsRoleplayActive() then
        if restoringAll then return end
        restoringAll = true
        operationDepth = operationDepth + 1
        combinedStates = {}
        for _, action in ipairs(ns.actions) do if not RoleplayOwns(action.effect) then SetActionState(action, false) end end
        operationDepth = operationDepth - 1
        restoringAll = false
        UpdateEvents()
        return
    end
    if not ns.db or restoringAll or exitingAll then return end
    restoringAll, exitingAll = true, true
    operationDepth = operationDepth + 1
    combinedStates = {}
    if letterboxShown then
        letterboxShown, letterboxLensHeight = false, nil
        UpdateLetterboxVisibility()
    end
    ns.RestoreUI()
    if cameraShiftActive then RestoreCamera() end
    if ns.fovActive then ns.fovActive, ns.fovLensValue = false, nil; ns.UpdateFOV() end
    if ns.CancelRoleplay then ns.CancelRoleplay() end
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
        elseif id == "letterbox" and letterboxShown then letterboxShown, letterboxLensHeight = false, nil; UpdateLetterboxVisibility()
        elseif id == "camerashift" and cameraShiftActive then RestoreCamera()
        elseif id == "fov" then ns.fovActive, ns.fovLensValue = false, nil; ns.UpdateFOV() end
    end
    UpdateEvents()
    ns.UpdateTrigger()
    if ns.RefreshEffectSettings then ns.RefreshEffectSettings() end
end
function ns.SetEffectEnabled(id, enabled)
    if ns.db.effects[id] == nil then return end
    ns.db.effects[id] = not not enabled
    -- Checking CameraShift on the main page is the explicit experimental-camera consent.
    if id == "camerashift" and enabled then ns.SetCameraConsent(true) end
    if not enabled then
        ForgetCombinedEffect(id)
        if id == "hideui" then ns.RestoreUI()
        elseif id == "letterbox" then
            letterboxShown, letterboxLensHeight = false, nil
            UpdateLetterboxVisibility(true)
            if bars then bars:SetScript("OnSizeChanged", nil) end
        elseif id == "camerashift" then ReturnOriginalCamera(true)
        elseif id == "fov" then ns.ReturnOriginalFOV() end
    elseif id == "letterbox" then
        if bars then bars:SetScript("OnSizeChanged", UpdateBars); SyncScreen() end
        UpdateLetterboxVisibility()
    elseif id == "camerashift" and PermanentCameraActive() then ApplyCamera()
    elseif id == "fov" then ns.UpdateFOV() end
    UpdateEvents()
    ns.UpdateTrigger()
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
    ns.UpdateFOV(true)
    UpdateEvents()
end

function ns.ApplyProfilePreferences(settings)
    if ns.CloseCombinedSettings then ns.CloseCombinedSettings() end
    if ns.StopRoleplay then ns.StopRoleplay() end
    operationDepth = operationDepth + 1
    combinedStates = {}
    ns.RestoreUI()
    ReturnOriginalCamera(true)
    ns.ReturnOriginalFOV()
    ns.runtimeSettings = {}
    cameraLensRestore, cameraReturnValues = nil, nil
    letterboxShown, barHeight, animationTarget = false, 0, nil
    letterboxLensHeight, cameraLensOffset = nil, nil
    if bars then
        bars:SetScript("OnUpdate", nil)
        bars:SetScript("OnSizeChanged", nil)
        bars:Hide()
    end
    ns.db.roleplayDo, ns.db.roleplayStay = nil, nil
    for key, value in pairs(settings) do ns.db[key] = value end
    if not ns.db.cameraConsent then ns.db.effects.camerashift = false end
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
    ns.UpdateTrigger()
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
        ns.db.letterboxHeight = NumberInRange(ns.db.letterboxHeight, 0, 50) or 10
        ns.db.permanentLetterboxHeight = NumberInRange(ns.db.permanentLetterboxHeight, 0, 50) or 10
        ns.db.cameraOffset = NumberInRange(ns.db.cameraOffset, -15, 15) or 1.5
        ns.db.permanentCameraOffset = NumberInRange(ns.db.permanentCameraOffset, -15, 15) or 1.5
        ns.db.permanentLetterbox = ns.db.permanentLetterbox == true
        ns.db.permanentCameraShift = ns.db.permanentCameraShift == true
        ns.db.cameraConsent = ns.db.cameraConsent == true
        ns.db.enableAnimation = nil -- Letterbox transitions are always enabled.
        ns.db.advancedCinematographer = ns.db.advancedCinematographer == true
        if type(ns.db.advanced) ~= "table" then ns.db.advanced = {} end
        for _, option in ipairs(ns.advancedOptions) do ns.db.advanced[option.id] = ns.db.advanced[option.id] == true end
        local fovLow, fovHigh = ns.FOVRange()
        ns.db.fov = NumberInRange(ns.db.fov, fovLow, fovHigh) or ns.FOVDefault()
        ns.db.permanentFov = NumberInRange(ns.db.permanentFov, fovLow, fovHigh) or ns.FOVDefault()
        ns.db.permanentFOV = ns.db.permanentFOV == true
        ns.db.roleplayDo, ns.db.roleplayStay = nil, nil
        ns.db.roleplayLogoutTarget = tonumber(ns.db.roleplayLogoutTarget) or -1
        if ns.db.roleplayLogoutTarget % 1 ~= 0 or ns.db.roleplayLogoutTarget < -1 or ns.db.roleplayLogoutTarget > 8 then ns.db.roleplayLogoutTarget = -1 end
        ns.db.triggerEnabled = ns.db.triggerEnabled == true
        ns.db.triggerTarget = NumberInRange(ns.db.triggerTarget, 0, 8) or 0
        if ns.db.triggerTarget % 1 ~= 0 then ns.db.triggerTarget = 0 end
        for _, kind in ipairs({ "Sit", "Lay", "Lean" }) do
            local key = "roleplay" .. kind .. "Target"
            local value = NumberInRange(ns.db[key], 0, 8)
            ns.db[key] = value and value % 1 == 0 and value or ns.db.triggerTarget
        end
        for _, spec in ipairs(ns.roleplayNumbers) do ns.db[spec.key] = NumberInRange(ns.db[spec.key], spec.low, spec.high) or spec.default end
        local oldEffects = type(ns.db.modules) == "table" and ns.db.modules or {}
        if type(ns.db.effects) ~= "table" then ns.db.effects = {} end
        if oldEffects.camerashift == nil then oldEffects.camerashift = oldEffects.camera end
        for _, effect in ipairs(ns.effects) do
            if type(ns.db.effects[effect.id]) ~= "boolean" then
                ns.db.effects[effect.id] = oldEffects[effect.id] ~= false
            end
        end
        if not ns.db.cameraConsent then ns.db.effects.camerashift = false end
        ns.db.modules = nil
        if type(ns.db.lensEffects) ~= "table" then ns.db.lensEffects = {} end
        for _, action in ipairs(ns.actions) do
            if type(ns.db.lensEffects[action.effect]) ~= "boolean" then ns.db.lensEffects[action.effect] = action.effect ~= "fov" end
        end
        ns.db.lensEffects.smoothmotion = false -- No runtime action while this effect is in development.
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
            if ns.db.lensValuesVersion ~= 1 then
                if lens.customLetterbox ~= true then lens.letterboxHeight = ns.db.letterboxHeight end
                if lens.customCameraShift ~= true then lens.cameraOffset = ns.db.cameraOffset end
            end
            lens.letterboxHeight = NumberInRange(lens.letterboxHeight, 0, 50) or ns.db.letterboxHeight
            lens.cameraOffset = NumberInRange(lens.cameraOffset, -15, 15) or ns.db.cameraOffset
            lens.fov = NumberInRange(lens.fov, fovLow, fovHigh) or ns.db.fov
            lens.customLetterbox, lens.customCameraShift = nil, nil
            if type(lens.actions) ~= "table" then lens.actions = {} end
            for _, action in ipairs(ns.actions) do lens.actions[action.binding] = lens.actions[action.binding] == true end
        end
        ns.db.lensValuesVersion = 1
        local sources = { ns.db }
        for index = 2, 5 do sources[#sources + 1] = ns.db.extraCombinedLenses[index] end
        for _, source in ipairs(sources) do
            for _, spec in ipairs(ns.settingSpecs) do
                for _, prefix in ipairs(source == ns.db and spec.effect ~= "hideui" and { "", "permanent" } or { "" }) do
                    local key = prefix ~= "" and prefix .. spec.key:sub(1, 1):upper() .. spec.key:sub(2) or spec.key
                    local value = source[key]
                    if type(spec.default) == "boolean" then
                        if type(value) ~= "boolean" then value = spec.default end
                    elseif type(value) ~= "number" or value ~= value or value < spec.low or value > spec.high then value = spec.default end
                    source[key] = value
                end
            end
        end
        UpdateCombinedBindingName()
        ns.db.showSecondBinding = nil
        -- Recover the original camera before reapplying any saved permanent effect.
        RestoreNames()
        ReturnOriginalCamera(true)
        ns.ReturnOriginalFOV()
        ns.Profiles.Initialize()
        CreateMinimapButton()
        ns.RegisterSettings()
        ns.UpdateTrigger()
        if IsLoggedIn and IsLoggedIn() then StartPermanentEffects()
        else pendingStartup = true; UpdateEvents() end
    elseif event == "PLAYER_LOGOUT" then
        ns.Profiles.Save()
        RestoreNames()
        ReturnOriginalCamera(true)
        ns.ReturnOriginalFOV()
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
        ns.Print("Commands: /retcin, /retcin hideui, /retcin showletterbox, /retcin camerashift, /retcin fov, /retcin combinedlens (combinedlens1), combinedlens2 through combinedlens5")
    end
end
