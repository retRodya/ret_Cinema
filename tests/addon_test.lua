-- Run from the repository root with Lua 5.1: lua tests/addon_test.lua
-- WoW API stand-ins exercise behavior; rendering still needs an in-game check.
local frames, bindings, bindingOrder = {}, {}, {}
local combat, modifiers, saved = false, {}, 0
local focusedFrame
local Frame = {}
Frame.__index = Frame
local function noop() end
for _, method in ipairs({
    "SetJustifyH", "SetWordWrap", "SetColorTexture", "SetTexture", "SetTexCoord",
    "SetFrameStrata", "EnableMouse", "RegisterForClicks", "RegisterForDrag",
    "SetHighlightTexture", "SetNormalFontObject", "SetHighlightFontObject",
    "SetDisabledFontObject", "SetRotation",
    "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetFontObject",
    "SetMultiLine", "SetAutoFocus", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
    "SetOwner", "SetPropagateKeyboardInput", "LockHighlight", "UnlockHighlight", "SetMotionScriptsWhileDisabled", "SetMaxLetters",
}) do Frame[method] = noop end
function Frame:SetScript(event, callback) self.scripts[event] = callback end
function Frame:GetScript(event) return self.scripts[event] end
function Frame:HookScript(event, callback)
    local original = self.scripts[event]
    self.scripts[event] = function(...)
        if original then original(...) end
        callback(...)
    end
end
function Frame:SetPoint(point, ...) self.points[point] = { ... } end
function Frame:ClearAllPoints() self.points = {} end
function Frame:SetAllPoints(relative)
    relative = relative or self.parent
    self.width, self.height = relative:GetWidth(), relative:GetHeight()
end
function Frame:SetSize(w, h) self.width, self.height = w, h end
function Frame:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function Frame:SetWidth(w) self.width = w end
function Frame:SetHeight(h) self.height = h end
function Frame:SetJustifyH(justify) self.justifyH = justify end
function Frame:GetFont() return "TestFont", self.fontSize or 12, "" end
function Frame:SetFont(_, size) self.fontSize = size end
function Frame:SetTextColor(r, g, b) self.color = { r, g, b } end
function Frame:SetTexture(texture) self.texture = texture end
function Frame:SetAtlas(atlas) self.atlas = atlas end
function Frame:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
function Frame:GetStringWidth() return #self:GetText() * (self.fontSize or 12) / 2 end
function Frame:GetStringHeight() return self.fontSize or 12 end
function Frame:SetScrollChild(child) self.scrollChild = child end
function Frame:GetWidth() return self.width or 600 end
function Frame:GetHeight() return self.height or 1000 end
function Frame:SetScale(scale) self.scale = scale end
function Frame:SetAlpha(alpha) self.alpha = alpha end
function Frame:SetBackdropColor(r, g, b, alpha) self.backdropColor = { r, g, b, alpha } end
function Frame:GetScale() return self.scale or 1 end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:SetFrameLevel(level) self.level = level end
function Frame:SetID(id) self.id = id end
function Frame:GetID() return self.id end
function Frame:GetName() return self.name end
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent)
    if self.parent == parent then return end
    if self.parent then for i, child in ipairs(self.parent.children) do if child == self then table.remove(self.parent.children, i); break end end end
    self.parent = parent; if parent then parent.children[#parent.children + 1] = self end
end
function Frame:SetChecked(checked) self.checked = checked end
function Frame:GetChecked() return self.checked end
function Frame:SetEnabled(enabled) self.enabled = enabled end
function Frame:EnableKeyboard(enabled) self.keyboard = enabled end
function Frame:SetPropagateKeyboardInput(enabled) self.propagateKeyboard = enabled end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:UnregisterAllEvents() self.events = {} end
function Frame:IsShown() return self.shown end
function Frame:IsProtected() return false end
function Frame:SetShown(shown)
    if self.shown == shown then return end
    self.shown = shown
    local callback = self.scripts[shown and "OnShow" or "OnHide"]
    if callback then callback(self) end
end
function Frame:Hide() self:SetShown(false) end
function Frame:Show() self:SetShown(true) end
function Frame:SetText(text, r, g, b)
    self.text = text
    if r then self.tooltipColor = { r, g, b } end
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function Frame:GetText() return self.text or "" end
function Frame:GetFontString()
    if not self.fontString then self.fontString = self:CreateFontString() end
    return self.fontString
end
function Frame:SetValue(value)
    if self.value == value then return end
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function Frame:SetFocus()
    focusedFrame = self
    self.focused = true
    if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
end
function Frame:ClearFocus()
    local wasFocused = self.focused
    self.focused = false
    if focusedFrame == self then focusedFrame = nil end
    if wasFocused and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function GetCurrentKeyBoardFocus() return focusedFrame end
function Frame:HighlightText() self.highlighted = true end
function Frame:CreateTexture() return CreateFrame("Texture", nil, self) end
function Frame:CreateFontString(_, _, template)
    local string = CreateFrame("FontString", nil, self)
    string.fontTemplate = template
    return string
end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({ kind = kind, name = name, parent = parent,
        template = template, scripts = {}, points = {}, events = {}, shown = true, children = {} }, Frame)
    frames[#frames + 1] = frame
    if parent then parent.children[#parent.children + 1] = frame end
    if name then _G[name] = frame end
    if template == "OptionsSliderTemplate" then
        _G[name .. "Low"] = CreateFrame("FontString", nil, frame)
        _G[name .. "High"] = CreateFrame("FontString", nil, frame)
    end
    return frame
end
function CreateFont(name) return CreateFrame("Font", name) end
UIParent = CreateFrame("Frame", "UIParent")
UISpecialFrames = {}
-- Model the native UI-parent path that closes special windows before OnShow hooks.
UIParent:SetScript("OnShow", function()
    for _, name in ipairs(UISpecialFrames) do if _G[name] then _G[name]:Hide() end end
end)
Minimap = CreateFrame("Frame", "Minimap", UIParent)
GameTooltip = CreateFrame("Frame")
CLOSE, SlashCmdList, StaticPopupDialogs = "Close", {}, {}
local lastPopup
local lastPopupName
local now = 0
function GetTime() return now end
function StaticPopup_Show(name)
    lastPopup = CreateFrame("Frame")
    lastPopupName = name
    lastPopup.editBox = CreateFrame("EditBox", nil, lastPopup)
    if StaticPopupDialogs[name] and StaticPopupDialogs[name].OnShow then StaticPopupDialogs[name].OnShow(lastPopup) end
    return lastPopup
end
function StaticPopup_Hide(name) if name == lastPopupName then lastPopup:Hide() end end
local secureHookCalls = {}
local nativeWalkCalls = 0
local walkMode, playerSpeed, playerRunSpeed = false, 0, 7
local pendingTimers = {}
C_Timer = { After = function(_, callback) pendingTimers[#pendingTimers + 1] = callback end }
local function flushTimers()
    local pending = pendingTimers; pendingTimers = {}
    for _, callback in ipairs(pending) do callback() end
end
function GetUnitSpeed() return playerSpeed, playerRunSpeed end
function ToggleRun()
    nativeWalkCalls = nativeWalkCalls + 1
    walkMode = not walkMode
    if playerSpeed > 0 then playerSpeed = walkMode and 2.5 or playerRunSpeed end
end
C_ChatInfo = { PerformEmote = function() return false end }
function DoEmote(...) return C_ChatInfo.PerformEmote(...) end
function SitStandOrDescendStart() end
function hooksecurefunc(name, callback, tableCallback)
    local target = _G
    if type(name) == "table" then target, name, callback = name, callback, tableCallback end
    secureHookCalls[name] = (secureHookCalls[name] or 0) + 1
    local original = target[name]
    target[name] = function(...)
        local result = { original(...) }
        callback(...)
        return unpack(result)
    end
end
function SetUIVisibility(shown) UIParent:SetShown(shown) end
function InCombatLockdown() return combat end
function IsLoggedIn() return true end
function IsShiftKeyDown() return modifiers.shift end
function IsControlKeyDown() return modifiers.ctrl end
function IsAltKeyDown() return modifiers.alt end
function GetBindingAction(key) return bindings[key] or "" end
function GetBindingText(key) return key end
function GetBindingKey(action)
    local keys = {}
    for _, key in ipairs(bindingOrder) do
        if bindings[key] == action then keys[#keys + 1] = key end
    end
    return unpack(keys)
end
function SetBinding(key, action)
    local known = false
    for _, existing in ipairs(bindingOrder) do if existing == key then known = true end end
    if not known then bindingOrder[#bindingOrder + 1] = key end
    bindings[key] = action
    return true
end
function GetCurrentBindingSet() return 2 end
function SaveBindings(set) assert(set == 2); saved = saved + 1 end
function PanelTemplates_TabResize(tab, padding, width)
    assert(type(tab) == "table", "TabResize expects the tab first")
    tab.width = width
end
function PanelTemplates_SelectTab(tab) tab.selected = true end
function PanelTemplates_DeselectTab(tab) tab.selected = false end
local settingsCategories, nextCategoryId = {}, 123
local function RegisterCategory(parent, panel, name)
    local id = nextCategoryId
    nextCategoryId = id + 1
    local category = { parent = parent, panel = panel, name = name, subcategories = {}, GetID = function() return id end,
        GetSubcategories = function(self) return self.subcategories end, SetShouldSortAlphabetically = noop }
    if parent then parent.subcategories[#parent.subcategories + 1] = category end
    settingsCategories[id] = category
    return category
end
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name) return RegisterCategory(nil, panel, name) end,
    RegisterCanvasLayoutSubcategory = RegisterCategory,
    RegisterAddOnCategory = noop,
    OpenToCategory = function(id)
        assert(settingsCategories[id])
        for _, category in pairs(settingsCategories) do category.panel:Hide() end
        settingsCategories[id].panel:Show()
    end,
}

local cvars = {
    UnitNameOwn = "1", UnitNameNPC = "1", UnitNameHostleNPC = "0",
    UnitNameFriendlyPlayerName = "1", UnitNameEnemyPlayerName = "1",
    UnitNameFriendlyPetName = "1", UnitNameEnemyPetName = "0",
    UnitNamePlayerGuild = "1", UnitNameFocused = "1", SoftTargetIconInteract = "1",
    test_cameraOverShoulder = "-2", CameraKeepCharacterCentered = "1", CameraReduceUnexpectedMovement = "1",
    cameraFov = "85", test_cameraHeadMovementStrength = "0.4",
    test_cameraTargetFocusEnemyEnable = "0", test_cameraTargetFocusInteractEnable = "1", CameraFollowTargetCombat = "1",
}
local logoutCancelCalls = 0
function CancelLogout() logoutCancelCalls = logoutCancelCalls + 1 end
function GetCameraFOVDefaults() return 90, 60, 90 end
function GetCVar(name) return cvars[name] end
function SetCVar(name, value)
    assert(cvars[name] ~= nil, "Unknown CVar")
    local changed = cvars[name] ~= tostring(value)
    cvars[name] = tostring(value)
    if changed and name == "test_cameraOverShoulder" then StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING") end
    return true
end
local toc = assert(io.open("ret_Cinema/ret_Cinema.toc", "r"))
local tocText = toc:read("*a")
local notes = assert(tocText:match("## Notes: ([^\r\n]+)"))
local version = assert(tocText:match("## Version: ([^\r\n]+)"))
toc:close()
function GetAddOnMetadata(_, field) if field == "Notes" then return notes end; assert(field == "Version"); return version end
C_AddOns = { GetAddOnMetadata = GetAddOnMetadata }
local ns = {}
assert(loadfile("ret_Cinema/Core.lua"))("ret_Cinema", ns)
assert(loadfile("ret_Cinema/Roleplay.lua"))("ret_Cinema", ns)
assert(loadfile("ret_Cinema/Profiles.lua"))("ret_Cinema", ns)
assert(loadfile("ret_Cinema/Options.lua"))("ret_Cinema", ns)
local events = frames[4]
assert(events.events.ADDON_LOADED)
events.scripts.OnEvent(events, "ADDON_LOADED", "anotherAddon")
assert(not ns.db)
events.scripts.OnEvent(events, "ADDON_LOADED", "ret_Cinema")
local function finishCamera()
    local frame = RetCinemaCameraAnimator
    if frame and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 1) end
end
local function pressEscape()
    local frame = RetCinemaEscapeHandler
    if frame and frame:IsShown() then frame.scripts.OnKeyDown(frame, "ESCAPE") end
end
local function finishEffects()
    finishCamera()
    local fov = RetCinemaFOVAnimator
    if fov and fov.scripts.OnUpdate then fov.scripts.OnUpdate(fov, 1) end
    local frame = RetCinemaLetterbox
    if frame and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 1) end
end
assert(ns.icon == 136034 and not ns.db.enableAnimation and ns.db.letterboxHeight == 10)
assert(not ns.db.combinedAsEsc and not ns.db.showSecondBinding)
assert(not ns.db.triggerEnabled and not secureHookCalls.ToggleRun)
assert(not ns.db.advancedCinematographer and not ns.Advanced("secondButton") and ns.GetCombinedCount() == 1 and not RetCinemaRoleplayEvents)
assert(ns.GetDescription() == notes)
local metadataAPI = C_AddOns
C_AddOns = nil
assert(ns.GetDescription() == notes, "Legacy metadata fallback must also read the TOC")
C_AddOns = metadataAPI
assert(not ns.HasCombinedActions() and not RetCinemaLetterbox, "Bars must be created lazily")
assert(not events.events.UI_SCALE_CHANGED and not events.events.PLAYER_LOGOUT)
RetCinema_ToggleLetterbox()
local bars, top, bottom = RetCinemaLetterbox, RetCinemaLetterbox.children[1], RetCinemaLetterbox.children[2]
local function step(delta)
    assert(bars:IsShown(), "An animation must remain visible to receive updates")
    assert(bars.scripts.OnUpdate, "Expected an active animation")(bars, delta)
end
assert(bars:IsShown() and top.height < 1)
step(0.15)
assert(math.abs(top.height - 50) < 0.001 and top.height == bottom.height)
local halfway = top.height
RetCinema_ToggleLetterbox()
assert(top.height == halfway, "Reversing must not jump")
step(0.075)
assert(top.height > 0 and top.height < halfway)
step(0.2)
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
RetCinema_ToggleLetterbox()
step(1)
assert(top.height == 100 and not bars.scripts.OnUpdate)
ns.SetLetterboxHeight(17.6)
step(1); assert(ns.db.letterboxHeight == 17.6 and top.height == 176)
ns.SetLetterboxHeight(0)
step(1)
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
ns.SetLetterboxHeight(10)
step(1)
RetCinema_ToggleLetterbox()
step(0.1)
finishEffects()
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
RetCinema_ToggleLetterbox()
finishEffects()
assert(top.height == 100 and not bars.scripts.OnUpdate)
ns.SetEffectEnabled("letterbox", false)
assert(not bars:IsShown() and not bars.scripts.OnUpdate and not bars.scripts.OnSizeChanged)
assert(not events.events.UI_SCALE_CHANGED)
RetCinema_ToggleLetterbox()
assert(not bars:IsShown())
ns.SetEffectEnabled("letterbox", true)
assert(not bars.scripts.OnSizeChanged and not bars:IsShown() and not events.events.UI_SCALE_CHANGED)
print("PASS: animation regression, lazy bars, Effect shutdown, no idle updates")

local originalNames = {}
for name, value in pairs(cvars) do originalNames[name] = value end
RetCinema_ToggleUI()
assert(not UIParent:IsShown() and events.events.PLAYER_LOGOUT)
for name in pairs(ns.db.hiddenCVars) do assert(cvars[name] == "0", name .. " remains visible") end
assert(cvars.UnitNameNPC == "0" and cvars.UnitNameFriendlyPlayerName == "0" and cvars.UnitNameFocused == "0")
UIParent:Show() -- An unsolicited UI show (camera controls/combat) must not end a mode.
assert(not UIParent:IsShown() and ns.db.hiddenCVars and cvars.UnitNameNPC == "0")
pressEscape()
finishEffects()
assert(not ns.db.hiddenCVars and not events.events.PLAYER_LOGOUT)
for name, value in pairs(originalNames) do assert(cvars[name] == value, name .. " was not restored") end
RetCinema_ToggleUI()
ns.SetEffectEnabled("hideui", false)
assert(UIParent:IsShown() and cvars.UnitNameNPC == "1" and not ns.db.hiddenCVars)
RetCinema_ToggleUI()
assert(UIParent:IsShown())
ns.SetEffectEnabled("hideui", true)
print("PASS: player/NPC/pet/focused names hidden, exact restoration, unsolicited UI shows and Effect disable")
RetCinema_ToggleCameraShift()
assert(not ns.IsCameraShiftActive() and not RetCinemaCameraAnimator and cvars.test_cameraOverShoulder == "-2")
ns.SetEffectEnabled("camerashift", true)
assert(ns.db.cameraConsent and ns.IsEffectEnabled("camerashift"))

RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == "-2", "Starting a camera transition must not jump")
assert(RetCinemaCameraAnimator and RetCinemaCameraAnimator.scripts.OnUpdate)
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.175)
assert(math.abs(tonumber(cvars.test_cameraOverShoulder) + 0.25) < 0.001)
finishEffects()
assert(ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "1.5")
assert(cvars.CameraKeepCharacterCentered == "0" and cvars.CameraReduceUnexpectedMovement == "0")
ns.SetCameraOffset(-4.25)
finishEffects()
assert(ns.db.cameraOffset == -4.2 and cvars.test_cameraOverShoulder == "-4.2")
ns.SetCameraOffset(0)
finishEffects()
assert(cvars.test_cameraOverShoulder == "0" and cvars.CameraKeepCharacterCentered == "1")
ns.SetCameraOffset(3)
ns.SetEffectEnabled("camerashift", false)
assert(cvars.test_cameraOverShoulder == "-2" and cvars.CameraKeepCharacterCentered == "1")
assert(not ns.db.cameraRestore and not events.events.PLAYER_LOGOUT)
RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == "-2")
ns.SetEffectEnabled("camerashift", true)
assert(cvars.test_cameraOverShoulder == "-2" and not ns.IsCameraShiftActive())
cvars.test_cameraOverShoulder = "7"
RetCinema_ToggleCameraShift()
finishEffects()
assert(cvars.test_cameraOverShoulder == "3")
RetCinema_ToggleCameraShift()
finishEffects()
assert(not ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "7", "Each activation must remember the live nonzero offset")
cvars.test_cameraOverShoulder = "-2"
ns.SetCameraOffset(1.5)
print("PASS: shoulder offset, rounding, motion-sickness settings, disable/re-enable, original camera restored")

for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, true) end
assert(ns.HasCombinedActions() and ns.GetCombinedActions(1).RETCINEMA_CAMERA)
RetCinema_ToggleCombined()
finishEffects()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
RetCinema_ToggleCombined()
finishEffects()
assert(UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
ns.SetEffectEnabled("camerashift", false)
assert(ns.HasCombinedActions() and not ns.IsActionEnabled(ns.actions[3]))


RetCinema_ToggleCombined()
assert(not UIParent:IsShown() and bars:IsShown())
RetCinema_ToggleCombined()
assert(UIParent:IsShown() and not bars:IsShown())
SlashCmdList.RETCINEMA("hideui") -- Chat commands remain available independently of key capture.
assert(not UIParent:IsShown())
SlashCmdList.RETCINEMA("HIDEUI")
assert(UIParent:IsShown())

ns.SetEffectEnabled("camerashift", true)
SlashCmdList.RETCINEMA("camerashift")
assert(ns.IsCameraShiftActive())
SlashCmdList.RETCINEMA("camerashift")
assert(not ns.IsCameraShiftActive())
finishEffects()
print("PASS: combined actions, renamed command, disabled actions excluded, Apply selection filtering")

-- Regression: Escape must cancel all effects, even in the middle of a transition.
RetCinema_ToggleCombined()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.1)
pressEscape()
assert(UIParent:IsShown() and not ns.IsCameraShiftActive())
assert(RetCinemaCameraAnimator.scripts.OnUpdate, "Escape must animate the camera return")
finishEffects()
assert(UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
assert(cvars.test_cameraOverShoulder == "-2" and cvars.CameraKeepCharacterCentered == "1")
assert(cvars.UnitNameNPC == "1" and cvars.UnitNameFriendlyPlayerName == "1")
assert(not ns.db.cameraRestore and not ns.db.hiddenCVars)
assert(not RetCinemaEscapeHandler:IsShown() and not bars.scripts.OnUpdate and not RetCinemaCameraAnimator.scripts.OnUpdate)
-- The next combined press starts a new mode; it must not restore an obsolete snapshot.
RetCinema_ToggleCombined()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
RetCinema_ToggleCombined()
finishEffects()
assert(UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
RetCinema_ToggleCameraShift()
pressEscape() -- Camera-only mode still responds while UIParent is visible.
finishEffects()
assert(cvars.test_cameraOverShoulder == "-2" and not ns.IsCameraShiftActive())
RetCinema_ToggleLetterbox()
pressEscape()
finishEffects()
assert(not bars:IsShown())
UIParent:Hide() -- Preserve an interface that was already hidden before our action.
RetCinema_ToggleUI()
pressEscape()
assert(not UIParent:IsShown() and cvars.UnitNameNPC == "1")
UIParent:Show()
-- Combined restores the states captured at entry, rather than toggling the current selection.
RetCinema_ToggleLetterbox()
RetCinema_ToggleCombined()
assert(bars:IsShown())
ns.SetCombinedAction("RETCINEMA_CAMERA", false)
RetCinema_ToggleCombined()
finishEffects()
assert(UIParent:IsShown() and bars:IsShown() and not ns.IsCameraShiftActive())
pressEscape()
finishEffects()
assert(not bars:IsShown())
ns.SetCombinedAction("RETCINEMA_CAMERA", true)
-- Reversing unfinished camera transitions remains continuous and retains the original baseline.
RetCinema_ToggleCameraShift()
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.175)
local interruptedOffset = cvars.test_cameraOverShoulder
RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == interruptedOffset)
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.1)
interruptedOffset = cvars.test_cameraOverShoulder
RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == interruptedOffset)
finishEffects()
RetCinema_ToggleCameraShift()
finishEffects()
assert(cvars.test_cameraOverShoulder == "-2" and not RetCinemaCameraAnimator.scripts.OnUpdate)
print("PASS: Escape restores combined/individual effects, external hidden UI, original offsets, and unfinished transitions")

-- Only explicit input ends a mode; unrelated window closes and combat do not.
ns.SetCombinedAction("RETCINEMA_CAMERA", false)
RetCinema_ToggleCameraShift()
finishEffects()
RetCinema_ToggleCombined()
finishEffects()
RetCinema_ToggleCombined() -- Exit all off: the uncombined camera remains active.
finishEffects()
assert(ns.IsCameraShiftActive() and not bars:IsShown() and UIParent:IsShown())
ns.db.combinedAsEsc = true
RetCinema_ToggleCombined()
finishEffects()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
for _, name in ipairs(UISpecialFrames) do assert(name ~= "RetCinemaEscapeHandler") end
RetCinemaEscapeHandler.scripts.OnKeyDown(RetCinemaEscapeHandler, "F")
assert(RetCinemaEscapeHandler.propagateKeyboard and ns.IsCameraShiftActive())
for _, name in ipairs(UISpecialFrames) do if _G[name] then _G[name]:Hide() end end
assert(ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "1.5")
-- A native window close must not act as Escape, even if something hides this frame.
RetCinemaEscapeHandler:Hide()
assert(ns.IsCameraShiftActive() and bars:IsShown())
ns.UpdateEscapeHandler()
combat = true
for _, frame in ipairs(frames) do
    if frame.events.PLAYER_REGEN_DISABLED and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, "PLAYER_REGEN_DISABLED") end
end
UIParent:Show()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
assert(cvars.UnitNameNPC == "0" and cvars.test_cameraOverShoulder == "1.5")
RetCinema_ToggleCombined() -- Exit all on: all three modes exit, including the uncombined camera.
assert(not UIParent:IsShown() and bars:IsShown() and not ns.IsCameraShiftActive(), "First press removes unrelated effects")
RetCinema_ToggleCombined() -- Only this lens now remains: one press exits it.
assert(UIParent:IsShown() and bars:IsShown() and not ns.IsCameraShiftActive())
assert(cvars.test_cameraOverShoulder == "1.5" and RetCinemaCameraAnimator.scripts.OnUpdate)
local returning = RetCinemaCameraAnimator.scripts.OnUpdate
pressEscape()
assert(RetCinemaCameraAnimator.scripts.OnUpdate == returning, "Repeated Escape must not restart the return")
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.175)
assert(math.abs(tonumber(cvars.test_cameraOverShoulder) + 0.25) < 0.001)
finishEffects()
assert(not bars:IsShown() and cvars.test_cameraOverShoulder == "-2" and cvars.UnitNameNPC == "1")
assert(not RetCinemaEscapeHandler:IsShown() and not RetCinemaCameraAnimator.scripts.OnUpdate)
combat = false
ns.db.combinedAsEsc = false
ns.SetCombinedAction("RETCINEMA_CAMERA", true)
finishEffects()
print("PASS: zoom/window closes and combat keep modes active; All Lenses smoothly exits uncombined Effects")

local function click(frame, mouse)
    assert(frame.scripts.OnClick, "Missing click handler")(frame, mouse or "LeftButton")
end
local function find(predicate)
    for _, frame in ipairs(frames) do if predicate(frame) then return frame end end
    error("UI element not found")
end

-- Permanent effects form a baseline; Lens activation temporarily overrides it.
do
        assert(ns.SetLetterboxHeight(6.2, true))
    ns.SetPermanentLetterbox(true)
    local permanentBarsTransition = bars.scripts.OnUpdate
    RetCinema_ToggleUI()
    pressEscape()
    assert(bars.scripts.OnUpdate == permanentBarsTransition, "Exiting HideUI must not restart permanent bars")
    finishEffects()
    assert(top.height == 62 and bars:IsShown() and not RetCinemaEscapeHandler:IsShown())
    ns.SetLetterboxHeight(15)
    RetCinema_ToggleLetterbox()
    finishEffects()
    assert(top.height == 150)
    ns.SetLetterboxHeight(3, true)
    finishEffects()
    assert(top.height == 150, "Changing the permanent setting must not replace an active Lens")
    pressEscape()
    finishEffects()
    assert(top.height == 30 and bars:IsShown(), "Esc must restore the permanent height")
    ns.SetLetterboxHeight(20, true)
    ns.SetLetterboxHeight(5)
    finishEffects()
    assert(top.height == 200)
    RetCinema_ToggleLetterbox()
    finishEffects()
    assert(top.height == 50, "Lens may be smaller than the permanent bars")
    RetCinema_ToggleLetterbox()
    finishEffects()
    assert(top.height == 200)
    ns.SetLetterboxHeight(3, true)
    ns.SetLetterboxHeight(15)
    finishEffects()
    RetCinema_ToggleLetterbox()
    finishEffects()
    ns.SetApplyToLens("letterbox", false)
    finishEffects()
    assert(top.height == 30)
    RetCinema_RunBinding("RETCINEMA_LETTERBOX")
    SlashCmdList.RETCINEMA("showletterbox")
    assert(top.height == 30 and not RetCinemaEscapeHandler:IsShown())
    ns.SetEffectEnabled("letterbox", false)
    assert(not bars:IsShown() and not bars.scripts.OnUpdate and not bars.scripts.OnSizeChanged)
    ns.SetEffectEnabled("letterbox", true)
    finishEffects()
    assert(top.height == 30)
    ns.SetApplyToLens("letterbox", true)
    ns.SetPermanentLetterbox(false)
    finishEffects()
    assert(not bars:IsShown())

    ns.SetCameraOffset(3, true)
    ns.SetPermanentCameraShift(true)
    local permanentCameraTransition = RetCinemaCameraAnimator.scripts.OnUpdate
    RetCinema_ToggleUI()
    pressEscape()
    assert(RetCinemaCameraAnimator.scripts.OnUpdate == permanentCameraTransition,
        "Exiting HideUI must not restart permanent camera movement")
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "3" and ns.db.cameraRestore.test_cameraOverShoulder == "-2")
    assert(not ns.IsCameraShiftActive() and not RetCinemaEscapeHandler:IsShown())
    ns.SetCameraOffset(6)
    RetCinema_ToggleCameraShift()
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "6")
    ns.SetCameraOffset(7, true)
    assert(cvars.test_cameraOverShoulder == "6")
    pressEscape()
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "7" and ns.db.cameraRestore.test_cameraOverShoulder == "-2")
    RetCinema_ToggleCameraShift()
    finishEffects()
    ns.SetApplyToLens("camerashift", false)
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "7" and not ns.IsCameraShiftActive())
    ns.SetApplyToLens("camerashift", true)
    RetCinema_ToggleCameraShift()
    finishEffects()
    ns.SetPermanentCameraShift(false)
    RetCinema_ToggleCameraShift()
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "-2" and not ns.db.cameraRestore)
    ns.SetPermanentCameraShift(true)
    finishEffects()
    RetCinema_ToggleCameraShift()
    finishEffects()
    ns.SetEffectEnabled("camerashift", false)
    assert(cvars.test_cameraOverShoulder == "-2" and not ns.db.cameraRestore)
    ns.SetEffectEnabled("camerashift", true)
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "7")
    ns.SetCameraConsent(false)
    assert(cvars.test_cameraOverShoulder == "-2" and not ns.db.cameraRestore)
    RetCinema_ToggleCameraShift()
    assert(not ns.IsCameraShiftActive())
    ns.SetCameraConsent(true)
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "7")
    assert(lastPopupName == "EXPERIMENTAL_CVAR_WARNING" and not lastPopup:IsShown())
    StaticPopup_Show("AN_UNRELATED_WARNING")
    assert(lastPopup:IsShown(), "Never dismiss other kinds of warning")
    now = now + 1
    StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING")
    assert(lastPopup:IsShown(), "Warnings unrelated to our own CVar writes must remain visible")
    StaticPopup_Hide("EXPERIMENTAL_CVAR_WARNING")

    -- All Lenses exits temporary effects while preserving both permanent baselines.
    ns.SetPermanentLetterbox(true)
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true)
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", false)
    ns.SetCombinedAction("RETCINEMA_CAMERA", false)
    RetCinema_ToggleCameraShift()
    RetCinema_ToggleLetterbox()
    finishEffects()
    ns.db.combinedAsEsc = true
    SlashCmdList.RETCINEMA("combinedlens1")
    assert(not UIParent:IsShown())
    SlashCmdList.RETCINEMA("combinedlens1")
    finishEffects()
    assert(not UIParent:IsShown() and not ns.IsCameraShiftActive())
    SlashCmdList.RETCINEMA("combinedlens1")
    finishEffects()
    assert(UIParent:IsShown() and top.height == 30 and cvars.test_cameraOverShoulder == "7")
    assert(not ns.IsCameraShiftActive())
    ns.SetPermanentCameraShift(false)
    ns.SetPermanentLetterbox(false)
    finishEffects()
    assert(cvars.test_cameraOverShoulder == "-2" and not bars:IsShown())
    ns.SetLetterboxHeight(10)
    ns.SetCameraOffset(1.5)
    ns.db.combinedAsEsc = false
    for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, true) end
end
print("PASS: permanent baselines, Lens overrides, Apply gating, consent, scoped warning dismissal, all-Lens exit")

-- Separate native General / Effect / Lens categories build their content lazily.
SlashCmdList.RETCINEMA("")
assert(not RetCinemaSettingsTab1 and not RetCinemaGeneralPanel and RetCinemaSettingsPanel.content)
assert(find(function(f) return f.parent == RetCinemaSettingsPanel and f.text == ns.title end).fontTemplate == "GameFontHighlightHuge")
assert(ns.ColorRet(ns.title) == ns.title and BINDING_HEADER_RETCINEMA == ns.title)
assert(ns.title == "|cff9acd32ret_|r|cff40c7ebCinema|r" and ns.settingsCategories.main.name == ns.title)
assert(find(function(f) return f.parent == RetCinemaSettingsPanel and f.atlas == "Options_HorizontalDivider" end))
for index, name in ipairs({ "Effect", "|cff40c7ebLens|r", "Profiles", "Support" }) do
    assert(ns.settingsCategories.main.subcategories[index].name == name)
end
assert(not ns.settingsCategories.general)
local function page(id) return find(function(f) return f.pageId == id end) end
local function checkbox(content, text)
    if text == "Advanced Cinematographer" then return find(function(f) return f.parent == content and f.frameRole == "advancedMaster" end) end
    if text == "Apply Effect to Lens" then
        local names = { hideui = "HideUI", letterbox = "Letterbox", camerashift = "CameraShift", fov = "FOV", smoothmotion = "SmoothMotion" }
        text = "Apply " .. assert(names[content.parent.pageId]) .. " to Lens"
    end
    return find(function(f) return f.kind == "CheckButton" and f.parent == content and f.label:GetText() == text end)
end
local function ToV5(text)
    local newKeys = { fov = true, permanentFov = true, permanentFOV = true, RETCINEMA_FOV = true }
    for _, spec in ipairs(ns.settingSpecs) do
        newKeys[spec.key] = true
        newKeys["permanent" .. spec.key:sub(1, 1):upper() .. spec.key:sub(2)] = true
    end
    text = text:gsub("PROFILE:[6789]", "PROFILE:5")
    return (text:gsub(";([%w_.]+)=([^;]+)", function(key, value)
        if key == "effects.fov" then return ";" .. key .. "=" .. value end
        if key:match("^advanced%.") or key:match("^roleplay") or newKeys[key:match("([^.]+)$")] then return "" end
        return ";" .. key .. "=" .. value
    end))
end
local function effectTab(index)
    Settings.OpenToCategory(ns.settingsCategories.effect:GetID())
    local current = find(function(f) return f.frameRole == "currentEffect" end)
    click(current)
    click(find(function(f) return f.parent == current.menu and f.value == index end))
end
local general = page("main").content
local checks = {}
for index, effect in ipairs(ns.effects) do
    checks[effect.id] = find(function(f) return f.kind == "CheckButton" and f.label:GetText() == effect.name end)
    checks[effect.id].scripts.OnEnter(checks[effect.id])
    assert(GameTooltip:GetText():find(effect.description, 1, true) == 1)
    assert(checks[effect.id].points.TOPLEFT[2] == -8 - math.floor((index - 1) / 4) * 34)
end
assert(#ns.effects == 5 and ns.db.effects.lens == nil and ns.db.effects.keybindings == nil)
local description = find(function(f) return f.parent == RetCinemaSettingsPanel and f.text == notes end)
assert(description.fontSize == 18)
local oldNotes = notes
notes = "A new description from TOC"
RetCinemaSettingsPanel:Hide(); RetCinemaSettingsPanel:Show()
assert(description:GetText() == notes)
notes = oldNotes
RetCinemaSettingsPanel:Hide(); RetCinemaSettingsPanel:Show()
assert(find(function(f) return f.kind == "FontString" and f.text == ns.generalHint end))
assert(find(function(f) return f.kind == "FontString" and f.text == "Enable Effect:" end))
assert(find(function(f) return f.text == "Need a bug fix or a new feature? " end))
assert(not RetCinemaProfilesPanel.content and not RetCinemaSupportPanel.content, "Child pages build on first use")
assert(ns.settingsCategories.profiles.parent == ns.settingsCategories.main)
assert(ns.settingsCategories.support.parent == ns.settingsCategories.main)
do
    local lines = 0
    for _, f in ipairs(general.children) do
        if f.kind == "Texture" and f.points.BOTTOMLEFT and f.height == 1 then lines = lines + 1 end
    end
    assert(lines == 2)
    local creditIcon = find(function(f) return f.kind == "Texture" and f.parent == general and f.texture == 136034 end)
    local made = find(function(f) return f.text == "Made by " end)
    assert(creditIcon.width == 64 and made.points.BOTTOMLEFT[1] > creditIcon.points.BOTTOMLEFT[1])
    for _, word in ipairs({ "ret_", "Cinematic", "DynamicCam", "Ask for it!" }) do
        local link = find(function(f) return f.kind == "Button" and f.text == word end)
        local color = link:GetFontString().color
        assert(color[1] == (word == "ret_" and 154 / 255 or 0.25))
        assert(color[2] == (word == "ret_" and 205 / 255 or 0.78))
        click(link)
        assert(RetCinemaCopyDialog.editBox:GetText():find("https://github.com/", 1, true))
    end
    assert(RetCinemaCopyDialog.editBox:GetText() == "https://github.com/retRodya/ret_Cinema/issues/new")
    assert(RetCinemaCopyDialog.title.justifyH == "CENTER")
    local field = RetCinemaCopyDialog.editBox
    field:SetText("edited")
    assert(field:GetText() ~= "edited")
    modifiers = { ctrl = true }
    field.scripts.OnKeyDown(field, "C")
    assert(RetCinemaCopyDialog:IsShown())
    field.scripts.OnKeyUp(field, "C")
    modifiers = {}
    assert(not RetCinemaCopyDialog:IsShown())
end

do
    local advanced = checkbox(general, "Advanced Cinematographer")
    local button = find(function(f) return f.kind == "Button" and f.text == "Advanced Cinematographer" end)
    assert(button:IsShown() and not button.enabled and not RetCinemaAdvancedDialog)
    advanced.scripts.OnEnter(advanced)
    assert(GameTooltip:GetText() == "Allow access to additional and |cffff8000Experimental|r options.\nDefault: Unchecked")
    advanced:SetChecked(true); click(advanced)
    assert(ns.db.advancedCinematographer and button:IsShown() and not advanced.label:IsShown())
    click(button)
    local dialog = RetCinemaAdvancedDialog
    assert(dialog.groups.Effect.kind == "Button" and dialog.groups.Lens.kind == "Button" and dialog.groups.LiteRP.kind == "CheckButton" and not dialog.groups.HideUI)
    click(dialog.groups.Effect)
    assert(dialog.groups.HideUI and not dialog.checks.hideInterface, "Effect groups must disclose lazily")
    for _, name in ipairs({ "HideUI", "Letterbox", "CameraShift", "FOV", "Lens" }) do click(dialog.groups[name]) end
    local lite = dialog.groups.LiteRP
    assert(lite.label.color[2] == 0.5 and lite.label:GetText() == "[additional] LiteRP")
    lite:SetChecked(true); click(lite)
    assert(ns.Advanced("roleplay") and dialog.checks.roleplayDo and dialog.checks.roleplayStay)
    local doCheck = dialog.checks.roleplayDo; doCheck:SetChecked(true); click(doCheck)
    assert(dialog.checks.triggerEnabled and not ns.db.triggerEnabled)
    assert(dialog.groups.FOV:GetText() == "-" and dialog.groups.FOV.label.color[2] == 0.82)
    local count = 0
    for _, option in ipairs(ns.advancedOptions) do assert(dialog.checks[option.id]); count = count + 1 end
    assert(count == #ns.advancedOptions and dialog.checks.fovSpeed:IsShown())
    dialog.checks.hideInterface:SetChecked(true); click(dialog.checks.hideInterface)
    assert(not ns.EffectSettings("hideui").hideInterface, "Don't hide must activate an exception to the normal hide behavior")
    dialog.checks.hideInterface.scripts.OnEnter(dialog.checks.hideInterface)
    assert(GameTooltip:GetText():match("\nDefault: Unchecked$"))
    click(dialog.groups.Effect)
    assert(not dialog.checks.hideInterface:IsShown() and ns.Advanced("hideInterface"), "Collapsing must preserve enabled options")
    lite:SetChecked(false); click(lite)
    dialog.scripts.OnKeyDown(dialog, "ESCAPE")
    assert(not dialog:IsShown() and dialog.propagateKeyboard == false and general.parent:IsShown(), "Esc closes the modal without reaching settings")
    click(button)
    click(button); assert(not RetCinemaAdvancedDialog:IsShown())
    click(button); assert(RetCinemaAdvancedDialog:IsShown())
    advanced:SetChecked(false); click(advanced)
    assert(button:IsShown() and not button.enabled and not RetCinemaAdvancedDialog:IsShown())
    assert(checks.smoothmotion.label.color[1] == 0.5)
    assert(not checks.fov.label.color or checks.fov.label.color[1] == 1)
    ns.SetAdvanced(nil, true)
    ns.SetAdvanced("hideInterface", false)
    ns.SetRoleplayOption("roleplayDo", false)
    ns.SetAdvanced("secondButton", true)
    ns.SetAdvanced("moreCombined", true)
end

effectTab(1)
local hideContent = page("hideui").content
local hidePermanent = checkbox(hideContent, "Permanent Hide UI")
assert(not hidePermanent.enabled and not hidePermanent.scripts.OnClick)
hidePermanent.scripts.OnEnter(hidePermanent)
assert(GameTooltip:GetText() == "Not sure yet you really need this :)\nDefault: Unchecked")
local hideApply = checkbox(hideContent, "Apply Effect to Lens")
assert(hideApply:GetChecked())

effectTab(2)
local letterContent = page("letterbox").content
assert(RetCinemaBarHeightSlider and not RetCinemaPermanentBarHeightSlider)
local letterPermanent = checkbox(letterContent, "Permanent Letterbox")
local letterApply = checkbox(letterContent, "Apply Effect to Lens")
for _, child in ipairs(letterContent.children) do
    assert(not child.label or child.label:GetText() ~= "Enable animation")
end
assert(RetCinemaBarHeightSlider.parent:GetWidth() * 2 + 24 <= letterContent:GetWidth())
assert(find(function(f) return f.text == "Lens bar height" end))
letterPermanent:SetChecked(true)
click(letterPermanent)
assert(RetCinemaPermanentBarHeightSlider and ns.db.permanentLetterbox)
assert(find(function(f) return f.text == "Permanent bar height" end))
RetCinemaPermanentBarHeightInput:SetText("6,2%")
RetCinemaPermanentBarHeightInput.scripts.OnEnterPressed(RetCinemaPermanentBarHeightInput)
assert(ns.db.permanentLetterboxHeight == 6.2)
RetCinemaBarHeightInput:SetText("12,5%")
RetCinemaBarHeightInput.scripts.OnEditFocusLost(RetCinemaBarHeightInput)
assert(ns.db.letterboxHeight == 12.5)
RetCinemaBarHeightInput:SetText("bad")
RetCinemaBarHeightInput.scripts.OnEnterPressed(RetCinemaBarHeightInput)
assert(RetCinemaBarHeightInput:GetText() == "12.5%")
RetCinemaBarHeightInput:SetText("99")
RetCinemaBarHeightInput.scripts.OnEnterPressed(RetCinemaBarHeightInput)
assert(ns.db.letterboxHeight == 25)
RetCinemaBarHeightInput:SetText("3")
RetCinemaBarHeightInput.scripts.OnEscapePressed(RetCinemaBarHeightInput)
assert(ns.db.letterboxHeight == 25 and RetCinemaBarHeightInput:GetText() == "25%")
letterApply:SetChecked(false)
click(letterApply)
assert(not ns.IsAppliedToLens("letterbox") and not RetCinemaBarHeightSlider.parent:IsShown())
finishEffects()
assert(top.height == 62, "Turning off Apply must leave permanent bars intact")
letterApply:SetChecked(true)
click(letterApply)
letterPermanent:SetChecked(false)
click(letterPermanent)
finishEffects()
assert(not bars:IsShown() and not RetCinemaPermanentBarHeightSlider.parent:IsShown())

-- Enabling the main CameraShift checkbox grants consent; its Effect page needs no permission checkbox.
ns.SetCameraConsent(false)
ns.SetEffectEnabled("camerashift", false)
checks.camerashift:SetChecked(true)
click(checks.camerashift)
assert(ns.db.cameraConsent and ns.IsEffectEnabled("camerashift"))
effectTab(3)
local cameraContent = page("camerashift").content
local cameraPermanent = checkbox(cameraContent, "Permanent CameraShift")
local cameraApply = checkbox(cameraContent, "Apply Effect to Lens")
assert(cameraPermanent:IsShown() and cameraApply:IsShown())
for _, child in ipairs(cameraContent.children) do
    assert(not child.label or child.label:GetText() ~= "Allow Blizzard experimental camera feature")
    assert(not child.text or not child.text:find("CameraShift remembers", 1, true))
end
assert(RetCinemaCameraOffsetSlider.parent:GetWidth() * 2 + 24 <= cameraContent:GetWidth())
assert(RetCinemaBarHeightSlider.points.TOPLEFT[2] == RetCinemaCameraOffsetSlider.points.TOPLEFT[2])
assert(find(function(f) return f.text == "Lens shoulder camera offset" end))
cameraPermanent:SetChecked(true)
click(cameraPermanent)
assert(RetCinemaPermanentCameraOffsetSlider and ns.db.permanentCameraShift)
assert(find(function(f) return f.text == "Permanent shoulder camera offset" end))
RetCinemaPermanentCameraOffsetInput:SetText("-6,7")
RetCinemaPermanentCameraOffsetInput.scripts.OnEnterPressed(RetCinemaPermanentCameraOffsetInput)
finishEffects()
assert(ns.db.permanentCameraOffset == -6.7 and cvars.test_cameraOverShoulder == "-6.7")
RetCinemaCameraOffsetInput:SetText("4.5")
RetCinemaCameraOffsetInput.scripts.OnEnterPressed(RetCinemaCameraOffsetInput)
assert(ns.db.cameraOffset == 4.5 and cvars.test_cameraOverShoulder == "-6.7")
cameraPermanent:SetChecked(false)
click(cameraPermanent)
finishEffects()
assert(cvars.test_cameraOverShoulder == "-2")

effectTab(4)
assert(checkbox(page("fov").content, "Apply Effect to Lens").enabled)
assert(checkbox(page("fov").content, "Permanent FOV").enabled)
assert(not RetCinemaFOVSlider, "Inactive FOV controls are lazy")
effectTab(5)
local smoothContent = page("smoothmotion").content
assert(RetCinemaSmoothMotionSlider and not RetCinemaSmoothMotionSlider.enabled)
assert(not RetCinemaSmoothMotionSlider.scripts.OnValueChanged and not RetCinemaSmoothMotionSlider.scripts.OnUpdate)
assert(not checkbox(smoothContent, "Apply Effect to Lens").enabled)
checks.smoothmotion:SetChecked(false)
click(checks.smoothmotion)
assert(page("hideui"):IsShown())
checks.smoothmotion:SetChecked(true)
click(checks.smoothmotion)
print("PASS: colored title, Experimental tooltip, gray placeholders, Effect selector, compact sliders and TOC metadata")

-- Lens requires an enabled Effect with Apply selected.
effectTab(5)
local current = find(function(f) return f.frameRole == "currentEffect" end)
assert(current:GetText() == "SmoothMotion" and current:GetWidth() == 272 and current:GetHeight() == 30)
assert(current:GetFontString().color[2] == 0.5)
assert(find(function(f) return f.frameRole == "nextEffect" end):GetHeight() == 30)
assert(find(function(f) return f.frameRole == "previousEffect" end):GetHeight() == 30)
for _, frame in ipairs(frames) do assert(frame.frameRole ~= "effectRule") end
assert(current.menu and current.arrow and current:GetFontString().color[1] == 0.5)
click(current)
local letterChoice = find(function(f) return f.parent == current.menu and f.value == 2 end)
click(letterChoice)
assert(current.effectId == "letterbox" and page("letterbox"):IsShown() and current:GetFontString().color[2] == 0.82)
click(current)
local fovChoice = find(function(f) return f.parent == current.menu and f.value == 4 end)
assert(fovChoice:GetFontString().color[1] == 1)
click(fovChoice)
assert(current.effectId == "fov")
Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
local lensPage, lensContent = page("lens"), page("lens").content
local function binding(action, slot)
    return find(function(f) return f.action == action and f.slot == slot end)
end
local combined1, combined2 = binding("RETCINEMA_COMBINED", 1), binding("RETCINEMA_COMBINED", 2)
local hide1, hide2 = binding("RETCINEMA_HIDEUI", 1), binding("RETCINEMA_HIDEUI", 2)
local letter1, camera1 = binding("RETCINEMA_LETTERBOX", 1), binding("RETCINEMA_CAMERA", 1)
local combinedBox = combined1.parent.parent
assert(combined1.parent:GetHeight() == 114 and combined2:IsShown())
assert(not hide2:IsShown() and combined1:GetFontString().color[1] == 0.5)
assert(combinedBox.template == "BackdropTemplate")
assert(not RetCinemaCombinedSettingsDialog)
for _, button in ipairs({ hide1, letter1, camera1 }) do assert(button.parent.gear:IsShown() and not button.parent.extraContainer:IsShown()) end
assert(combinedBox.points.TOPLEFT[2] < camera1.parent.points.TOPLEFT[2] - camera1.parent:GetHeight())
local escape = combined1.parent.escape
assert(escape.label:GetText() == "Escape Button" and escape.points.TOPLEFT[2] < combined2.points.TOPLEFT[2] - combined2:GetHeight())
escape:SetChecked(true); click(escape)
assert(ns.db.combinedAsEsc and escape:GetChecked())
escape:SetChecked(false); click(escape)
assert(not ns.db.combinedAsEsc)
for _, action in ipairs(ns.actions) do
    local button = binding(action.binding, 1)
    local hover = find(function(f) return f.kind == "Frame" and f.parent == button.parent and f.scripts.OnEnter end)
    hover.scripts.OnEnter(hover)
    assert(GameTooltip:GetText() == "Can be enabled via\n/retcin " .. action.command)
end
find(function(f) return f.kind == "Frame" and f.parent == combined1.parent and f.scripts.OnEnter end).scripts.OnEnter(combined1.parent)
assert(GameTooltip:GetText() == "Can be enabled via\n/retcin combinedlens1")
for _, f in ipairs(frames) do
    if f.kind == "FontString" and (f.parent == lensContent or f.parent == combined1.parent) then
        assert(f.text ~= "Module" and f.text ~= "Exit all" and f.text ~= "Key")
        assert(f.text ~= "or use marcro commands below:")
    end
    assert(not (f.kind == "Button" and f.text == "Copy macro text"), "Lens must not build a macro-copy block")
end
local rule = find(function(f) return f.kind == "Texture" and f.parent == lensContent and f.points.TOPLEFT end)
assert(rule.points.TOPLEFT[2] > hide1.parent.points.TOPLEFT[2])
checks.letterbox:SetChecked(false)
click(checks.letterbox)
assert(not letter1.parent:IsShown() and not letter1.enabled and not ns.IsEffectEnabled("letterbox"))
assert(ns.HasLensEffects())
checks.letterbox:SetChecked(true)
click(checks.letterbox)
assert(letter1.enabled)
ns.SetApplyToLens("letterbox", false)
assert(not letter1.parent:IsShown())
ns.SetApplyToLens("letterbox", true)
assert(letter1.parent:IsShown())

SetBinding("ALT-CTRL-F", "RETCINEMA_HIDEUI")
click(combined1)
modifiers = { alt = true, ctrl = true }
combined1.scripts.OnKeyDown(combined1, "F")
modifiers = {}
assert(bindings["ALT-CTRL-F"] == "RETCINEMA_COMBINED" and saved == 1)
assert(combined1:GetFontString().color[1] == 1 and combined2:GetFontString().color[1] == 0.5)
local status = find(function(f) return f.text and f.text:find("reassigned from", 1, true) end)
assert(status.fontSize == 18)
click(combined2)
combined2.scripts.OnKeyDown(combined2, "G")
assert(bindings.G == "RETCINEMA_COMBINED")
click(combined1, "RightButton")
assert(combined1:GetText() == "G" and combined2:IsShown())
click(combined1, "RightButton")
assert(combined2:IsShown() and not bindings.G, "Combined always offers both slots")
click(combined1)
combined1.scripts.OnKeyDown(combined1, "G")
click(camera1)
camera1.scripts.OnKeyDown(camera1, "C")
assert(bindings.C == "RETCINEMA_CAMERA")
local combinedY = combinedBox.points.TOPLEFT[2]
click(hide1)
hide1.scripts.OnKeyDown(hide1, "H")
assert(hide2:IsShown() and combinedBox.points.TOPLEFT[2] < combinedY)
ns.SetApplyToLens("hideui", false)
assert(bindings.H == "RETCINEMA_HIDEUI" and not hide1.parent:IsShown())
RetCinema_RunBinding("RETCINEMA_HIDEUI")
assert(UIParent:IsShown())
ns.SetApplyToLens("hideui", true)
assert(hide1:GetText() == "H")
click(camera1)
combat = true
lensPage.scripts.OnEvent(lensPage, "PLAYER_REGEN_DISABLED")
assert(not camera1.keyboard and not camera1.enabled)
combat = false
lensPage.scripts.OnEvent(lensPage, "PLAYER_REGEN_ENABLED")
assert(camera1.enabled)
for _, button in ipairs({ hide1, letter1, camera1 }) do
    button.parent.checks[1]:SetChecked(false)
    click(button.parent.checks[1])
end
assert(combinedBox:IsShown() and bindings.G == "RETCINEMA_COMBINED")
for _, effect in ipairs(ns.effects) do ns.SetApplyToLens(effect.id, false) end
assert(not hide1.parent:IsShown() and not letter1.parent:IsShown() and not camera1.parent:IsShown())
assert(page("main"):IsShown() and not lensPage:IsShown())
for _, child in ipairs(ns.settingsCategories.main.subcategories) do assert(child ~= ns.settingsCategories.lens) end
-- An Apply flag on a disabled Effect must not expose Lens.
ns.SetEffectEnabled("hideui", false)
ns.SetApplyToLens("hideui", true)
assert(not ns.HasLensEffects())
for _, child in ipairs(ns.settingsCategories.main.subcategories) do assert(child ~= ns.settingsCategories.lens) end
ns.SetEffectEnabled("hideui", true)
assert(ns.settingsCategories.main.subcategories[2] == ns.settingsCategories.lens)
assert(not lensPage.events.UPDATE_BINDINGS)
print("PASS: Lens membership, gray unbound keys, Escape Button, commands, key conflicts and combat")

-- Up to five Combined Lenses have independent selections, bindings and exit policies.
do
    for _, action in ipairs(ns.actions) do ns.SetApplyToLens(action.effect, true) end
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
    local add = find(function(f) return f.kind == "Button" and f.parent == combinedBox and f.text == "+" end)
    assert(add:IsShown() and ns.GetCombinedCount() == 1)
    for count = 2, 5 do
        click(add)
        assert(ns.GetCombinedCount() == count)
        for _, frame in ipairs(frames) do assert(not (frame.action == ns.CombinedBinding(count) and frame.slot == 1), "Empty Combined Lens must remain unbuilt") end
        local member = binding("RETCINEMA_HIDEUI", 1).parent.checks[count]
        member:SetChecked(true); click(member)
        local firstRow = binding("RETCINEMA_COMBINED", 1).parent
        local row = binding(ns.CombinedBinding(count), 1).parent
        assert(row:IsShown())
        assert(firstRow.label:GetText() == "Combined Lens 1" and row.label:GetText() == "Combined Lens " .. count)
        assert(row.parent == combinedBox and binding(ns.CombinedBinding(count), 2):IsShown())
        assert(find(function(f) return f.parent == row and f.kind == "Texture" and f.points.TOPLEFT end))

        for _, action in ipairs(ns.actions) do
            local check = binding(action.binding, 1).parent.checks[count]
            assert(check and check:IsShown())
            check.scripts.OnEnter(check)
            assert(GameTooltip:GetText() == "Add " .. _G["BINDING_NAME_" .. action.binding] .. " to Combined Lens " .. count .. "\nDefault: Unchecked")
        end
    end
    assert(add:IsShown() and not add.enabled and not ns.AddCombinedLens())
    assert(find(function(f) return f.parent == lensContent and f.text == "Add to a specific Combined Lens" end))
    for _, action in ipairs(ns.actions) do
        local row = binding(action.binding, 1).parent
        for index = 1, 5 do
            local check = row.checks[index]
            assert(check.points.TOPLEFT[2] == -1 and check.parent == row.extraContainer)
            if index > 1 then assert(check.points.TOPLEFT[1] - row.checks[index - 1].points.TOPLEFT[1] == 28) end
        end
    end
    for _, action in ipairs(ns.actions) do
        local row = binding(action.binding, 1).parent
        for index = 1, 5 do
            local check = row.checks[index]
            check:SetChecked(true); click(check)
            assert(ns.GetCombinedActions(index)[action.binding] and check:GetChecked())
            check:SetChecked(false); click(check)
            assert(not ns.GetCombinedActions(index)[action.binding] and not check:GetChecked())
        end
    end

    assert(ns.GetCombinedCount() == 5 and not hide1.parent.extraContainer:IsShown(), "Empty persisted CL2-5 must not expose an empty container")
    click(add)
    assert(hide1.parent.extraContainer:IsShown() and hide1.parent.checks[2]:IsShown(), "Plus reveals a slot for assigning Effects")
    Settings.OpenToCategory(ns.settingsCategories.main:GetID())
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
    assert(not hide1.parent.extraContainer:IsShown() and hide1.parent.checks[1].parent == hide1.parent, "An unassigned pending slot disappears when leaving Lens")

    -- Per-Effect settings are built lazily and target additional lenses only.
    for _, button in ipairs({ hide1, letter1, camera1 }) do
        local row = button.parent
        assert(row.gear:IsShown() and not row.extraContainer:IsShown() and row.gear.points.TOPLEFT[1] == row.checks[1])
    end
    assert(not hide1.parent.gear.enabled, "Simple HideUI has no gear options")
    for _, index in ipairs({ 2, 3 }) do
        ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, index)
        ns.SetCombinedAction("RETCINEMA_CAMERA", true, index)
    end
    lensPage.refresh()
    click(letter1.parent.gear)
    local dialog = RetCinemaCombinedSettingsDialog
    assert(dialog:IsShown() and dialog.index == 2 and dialog.selector:GetText() == "Combined Lens 2")
    assert(dialog.controls.letterbox and not dialog.controls.camerashift)
    assert(not dialog.inherit and not dialog.member and not dialog.noOptions and RetCinemaCombinedBarHeightSlider.enabled)
    local function chooseLens(index)
        click(dialog.selector)
        for _, child in ipairs(dialog.selector.menu.children) do assert(child.value >= 1) end
        click(find(function(f) return f.parent == dialog.selector.menu and f.value == index end))
        assert(dialog.index == index)
    end
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 1); lensPage.refresh(); ns.RefreshCombinedSettings()
    chooseLens(1)
    local originalCL1Height = ns.db.letterboxHeight
    RetCinemaCombinedBarHeightInput:SetText("9.1"); RetCinemaCombinedBarHeightInput.scripts.OnEnterPressed(RetCinemaCombinedBarHeightInput)
    assert(ns.GetCombinedEffectValue(1, "letterbox") == 9.1 and ns.db.letterboxHeight == 9.1)
    assert(ns.SetCombinedEffectValue(1, "letterbox", originalCL1Height))
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", false, 1); lensPage.refresh(); ns.RefreshCombinedSettings()
    chooseLens(3); chooseLens(2)
    assert(RetCinemaCombinedBarHeightSlider.enabled)
    RetCinemaCombinedBarHeightInput:SetText("7,5%")
    RetCinemaCombinedBarHeightInput.scripts.OnEnterPressed(RetCinemaCombinedBarHeightInput)
    local height = ns.GetCombinedEffectValue(2, "letterbox")
    assert(height == 7.5 and ns.db.letterboxHeight == 25)
    RetCinemaCombinedBarHeightInput:SetFocus()
    RetCinemaCombinedBarHeightInput:SetText("8")
    chooseLens(3)
    assert(ns.GetCombinedEffectValue(2, "letterbox") == 8 and ns.GetCombinedEffectValue(3, "letterbox") == 10)
    chooseLens(2)
    RetCinemaCombinedBarHeightInput:SetText("7.5")
    RetCinemaCombinedBarHeightInput.scripts.OnEnterPressed(RetCinemaCombinedBarHeightInput)
    letter1.parent.checks[2]:SetChecked(true); click(letter1.parent.checks[2])
    assert(letter1.parent.checks[2]:GetChecked() and binding("RETCINEMA_COMBINED2", 1).parent.summary:GetText() == "Letterbox, CameraShift")
    click(camera1.parent.gear)
    RetCinemaCombinedCameraOffsetInput:SetText("3.4")
    RetCinemaCombinedCameraOffsetInput.scripts.OnEnterPressed(RetCinemaCombinedCameraOffsetInput)
    camera1.parent.checks[2]:SetChecked(true); click(camera1.parent.checks[2])
    assert(ns.GetCombinedEffectValue(2, "camerashift") == 3.4 and ns.db.cameraOffset == 4.5)
    chooseLens(3)
    RetCinemaCombinedCameraOffsetInput:SetText("-4")
    RetCinemaCombinedCameraOffsetInput.scripts.OnEnterPressed(RetCinemaCombinedCameraOffsetInput)
    camera1.parent.checks[3]:SetChecked(true); click(camera1.parent.checks[3])
    click(letter1.parent.gear)
    chooseLens(3)
    RetCinemaCombinedBarHeightInput:SetText("14")
    RetCinemaCombinedBarHeightInput.scripts.OnEnterPressed(RetCinemaCombinedBarHeightInput)
    letter1.parent.checks[3]:SetChecked(true); click(letter1.parent.checks[3])
    ns.SetAdvanced("hideInterface", true)
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true, 2)
    lensPage.refresh()
    click(hide1.parent.gear)
    assert(not dialog.noOptions and not dialog.member and not dialog.controls.letterbox:IsShown())
    assert(checkbox(dialog.extraGroups.hideui, "Don't hide interface elements"))
    assert(binding("RETCINEMA_COMBINED2", 1).parent.summary:GetText() == "HideUI, Letterbox, CameraShift")
    ns.SetCombinedAction("RETCINEMA_HIDEUI", false, 2); lensPage.refresh()
    ns.SetEffectSetting("hideInterface", true)
    assert(binding("RETCINEMA_COMBINED2", 1).parent.summary:GetText() == "Letterbox, CameraShift")
    ns.CloseCombinedSettings()
    click(letter1.parent.gear)
    chooseLens(2)
    RetCinemaCombinedBarHeightInput:SetFocus()
    RetCinemaCombinedBarHeightInput:SetText("13")
    ns.CloseCombinedSettings()
    assert(ns.GetCombinedEffectValue(2, "letterbox") == 7.5, "Closing must not commit a pending edit into another lens or profile")
    click(letter1.parent.gear)
    ns.SetEffectEnabled("letterbox", false)
    assert(not dialog:IsShown())
    ns.SetEffectEnabled("letterbox", true)
    ns.SetCombinedExitAll(2, false); ns.SetCombinedExitAll(3, false)
    RetCinema_ToggleCombined(2); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4")
    RetCinema_ToggleCombined(3); finishEffects()
    assert(top.height == 140 and cvars.test_cameraOverShoulder == "-4")
    RetCinema_ToggleCombined(3); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4", "Return must restore the previous lens's numeric settings")
    RetCinema_ToggleCombined(2); finishEffects()
    assert(not bars:IsShown() and cvars.test_cameraOverShoulder == "-2")
    RetCinema_ToggleLetterbox(); RetCinema_ToggleCameraShift(); finishEffects()
    assert(top.height == 250 and cvars.test_cameraOverShoulder == "4.5")
    RetCinema_ToggleCombined(2); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4")
    RetCinema_ToggleCombined(2); finishEffects()
    assert(top.height == 250 and cvars.test_cameraOverShoulder == "4.5")
    pressEscape(); finishEffects()
    ns.SetPermanentLetterbox(true); ns.SetLetterboxHeight(4, true)
    ns.SetPermanentCameraShift(true); ns.SetCameraOffset(2, true); finishEffects()
    RetCinema_ToggleCombined(2); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4")
    RetCinema_ToggleCombined(3); finishEffects()
    pressEscape(); finishEffects()
    assert(top.height == 40 and cvars.test_cameraOverShoulder == "2")
    ns.SetPermanentLetterbox(false); ns.SetPermanentCameraShift(false); finishEffects()
    assert(not bars:IsShown() and cvars.test_cameraOverShoulder == "-2")
    -- Escape Button requires consecutive presses; any intervening Lens breaks the sequence.
    ns.SetCombinedExitAll(2, true)
    RetCinema_ToggleCombined(2); finishEffects()
    RetCinema_ToggleUI()
    RetCinema_ToggleCombined(2); finishEffects()
    assert(UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive(), "First press replaces unrelated HideUI with this Lens")
    RetCinema_ToggleCombined(2); finishEffects()
    assert(UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
    RetCinema_ToggleCombined(2); RetCinema_ToggleCombined(3); finishEffects()
    RetCinema_ToggleCombined(2); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4", "An intervening Combined Lens must reset the Escape sequence")
    RetCinema_ToggleCombined(2); finishEffects()
    assert(not bars:IsShown() and cvars.test_cameraOverShoulder == "-2")
    RetCinema_ToggleCombined(3); finishEffects()
    assert(top.height == 140 and cvars.test_cameraOverShoulder == "-4", "Global exit discards every obsolete Combined snapshot")
    pressEscape(); finishEffects()
    ns.SetCombinedExitAll(2, false)
    for _, index in ipairs({ 2, 3 }) do
        ns.SetCombinedEffectValue(index, "letterbox", ns.db.letterboxHeight)
        ns.SetCombinedEffectValue(index, "camerashift", ns.db.cameraOffset)
    end
    assert(ns.GetCombinedEffectValue(2, "letterbox") == 25)
    assert(not ns.SetCombinedEffectCustom and ns.SetCombinedEffectValue(1, "letterbox", ns.db.letterboxHeight))
    print("PASS: direct per-lens sliders, overlap restoration, permanent baseline and consecutive Escape Button sequences")

    local secondButton = binding("RETCINEMA_COMBINED2", 1)
    click(secondButton); secondButton.scripts.OnKeyDown(secondButton, "K")
    assert(bindings.K == "RETCINEMA_COMBINED2")
    -- Each Escape Button controls only its own Combined Lens.
    for index = 1, 5 do
        local escape = binding(ns.CombinedBinding(index), 1).parent.escape
        escape:SetChecked(index % 2 == 0)
        click(escape)
        assert(ns.GetCombinedExitAll(index) == (index % 2 == 0))
    end
    for index = 1, 5 do
        for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, false, index) end
    end
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true, 1)
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 2)
    ns.SetCombinedAction("RETCINEMA_CAMERA", true, 2)
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true, 3)
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 3)
    ns.SetCombinedExitAll(2, false)
    SlashCmdList.RETCINEMA("combinedlens1")
    SlashCmdList.RETCINEMA("combinedlens2")
    finishEffects()
    assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
    SlashCmdList.RETCINEMA("combinedlens1")
    assert(UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
    RetCinema_ToggleCombined(2); finishEffects()
    assert(not bars:IsShown() and not ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "-2")
    -- Overlap captures the state at each activation, rather than sharing one snapshot.
    RetCinema_ToggleCombined(1)
    RetCinema_ToggleCombined(3)
    assert(UIParent:IsShown())
    RetCinema_ToggleCombined(3)
    assert(not UIParent:IsShown())
    RetCinema_ToggleCombined(1); finishEffects()
    assert(UIParent:IsShown() and not bars:IsShown())
    -- All Lenses clears every snapshot and smoothly exits effects outside this Combined Lens.
    ns.SetCombinedExitAll(2, true)
    RetCinema_ToggleCombined(1); RetCinema_ToggleCombined(2); finishEffects()
    RetCinema_ToggleCombined(2)
    assert(UIParent:IsShown() and ns.IsCameraShiftActive())
    RetCinema_ToggleCombined(2)
    assert(UIParent:IsShown() and not ns.IsCameraShiftActive() and RetCinemaCameraAnimator.scripts.OnUpdate)
    finishEffects()
    RetCinema_ToggleCombined(1)
    assert(not UIParent:IsShown(), "All Lenses must discard other Combined snapshots")
    RetCinema_ToggleCombined(2)
    pressEscape(); finishEffects()
    assert(UIParent:IsShown() and not bars:IsShown() and cvars.test_cameraOverShoulder == "-2")
    -- Removing an Effect invalidates it in every active snapshot.
    RetCinema_ToggleCombined(1); RetCinema_ToggleCombined(3)
    ns.SetEffectEnabled("hideui", false)
    RetCinema_ToggleCombined(3); finishEffects()
    assert(UIParent:IsShown() and not bars:IsShown())
    ns.SetEffectEnabled("hideui", true)
    RetCinema_ToggleCombined(1)
    assert(not UIParent:IsShown())
    pressEscape(); finishEffects()
    local remove = find(function(f) return f.kind == "Button" and f.parent == combinedBox and f.text == "-" end)
    assert(remove:IsShown() and remove.enabled and add.enabled, "Unused stored slots must not look like existing Lenses")
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 5); lensPage.refresh()
    assert(not add.enabled)
    local last = binding("RETCINEMA_COMBINED5", 1)
    click(last); last.scripts.OnKeyDown(last, "J")
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 5)
    ns.SetCombinedExitAll(5, true)
    RetCinema_ToggleUI()
    RetCinema_ToggleCombined(5); finishEffects()
    assert(not UIParent:IsShown() and bars:IsShown())
    combat = true
    lensPage.scripts.OnEvent(lensPage, "PLAYER_REGEN_DISABLED")
    assert(not remove.enabled and not ns.RemoveCombinedLens() and bindings.J == "RETCINEMA_COMBINED5")
    combat = false
    lensPage.scripts.OnEvent(lensPage, "PLAYER_REGEN_ENABLED")
    click(remove); finishEffects()
    assert(ns.GetCombinedCount() == 4 and bindings.J == "RETCINEMA_COMBINED5" and not bars:IsShown())
    assert(not UIParent:IsShown(), "Removing a lens restores only its own snapshot, even with Escape Button checked")
    assert(not last.parent:IsShown() and add.enabled)
    click(add); click(add)
    assert(ns.GetCombinedCount() == 5 and ns.HasCombinedActions(5) and ns.GetCombinedExitAll(5) and bindings.J == "RETCINEMA_COMBINED5")
    pressEscape(); finishEffects()
    SlashCmdList.RETCINEMA("combinedlens")
    assert(not UIParent:IsShown(), "The unnumbered command must activate the first lens")
    SlashCmdList.RETCINEMA("combinedlens1")
    assert(UIParent:IsShown(), "Both names must address the same first lens")
    -- Version 4 round-trips all five lens configurations and their custom values.
    ns.SetCombinedEffectValue(2, "letterbox", 7.5)
    ns.SetCombinedEffectValue(2, "camerashift", 3.4)
    local originalName = ns.Profiles.Current()
    ns.db.advancedCinematographer = true
    ns.SetAdvanced("roleplay", true)
    assert(ns.SetTrigger(true, 4))
    local export = ns.Profiles.Export()
    local ok, imported = ns.Profiles.Import(export)
    assert(ns.db.advancedCinematographer and not ns.db.enableAnimation and ns.db.triggerEnabled and ns.db.triggerTarget == 4)
    assert(ok and ns.GetCombinedCount() == 5 and ns.GetCombinedExitAll(2))
    local customHeight = ns.GetCombinedEffectValue(2, "letterbox")
    assert(customHeight == 7.5 and ns.GetCombinedEffectValue(2, "camerashift") == 3.4)
    assert(not ns.SetCombinedEffectValue(2, "letterbox", 0 / 0))
    assert(ns.GetCombinedActions(2).RETCINEMA_CAMERA and ns.GetCombinedActions(3).RETCINEMA_HIDEUI)
    ns.SetCombinedAction("RETCINEMA_CAMERA", false, 2)
    assert(ns.Profiles.Activate(originalName))
    assert(ns.GetCombinedActions(2).RETCINEMA_CAMERA and ns.Profiles.Delete(imported))
    assert(bindings.K == "RETCINEMA_COMBINED2")
    export = export:gsub("triggerEnabled=true", "triggerEnabled=false"):gsub("triggerTarget=4", "triggerTarget=0")
    assert(ns.SetTrigger(false, 0))
    local version2 = ToV5(export):gsub("PROFILE:5", "PROFILE:2"):gsub(";advancedCinematographer=true", "") .. ";enableAnimation=false"
    for _, field in ipairs({ "customLetterbox", "letterboxHeight", "customCameraShift", "cameraOffset" }) do
        version2 = version2:gsub(";extraCombinedLenses%.[2-5]%." .. field .. "=[^;]+", "")
    end
    version2 = version2:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    local legacyOK, legacyName = ns.Profiles.Import(version2)
    assert(legacyOK and ns.db.combinedLensCount == 5 and not ns.db.advancedCinematographer and not ns.db.enableAnimation)
    assert(ns.GetCombinedActions(2).RETCINEMA_CAMERA)
    assert(ns.GetCombinedEffectValue(2, "letterbox") == ns.db.letterboxHeight)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(legacyName))
    local version3 = ToV5(export):gsub("PROFILE:5", "PROFILE:3")
    for _, field in ipairs({ "customLetterbox", "letterboxHeight", "customCameraShift", "cameraOffset" }) do
        version3 = version3:gsub(";extraCombinedLenses%.[2-5]%." .. field .. "=[^;]+", "")
    end
    version3 = version3:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    local version3OK, version3Name = ns.Profiles.Import(version3)
    assert(version3OK and ns.db.advancedCinematographer)
    assert(ns.GetCombinedEffectValue(2, "camerashift") == ns.db.cameraOffset)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(version3Name))
    local version4 = ToV5(export):gsub("PROFILE:5", "PROFILE:4")
    version4 = version4:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    for index = 2, 5 do
        version4 = version4 .. ";extraCombinedLenses." .. index .. ".customLetterbox=" .. (index == 2 and "true" or "false")
        version4 = version4 .. ";extraCombinedLenses." .. index .. ".customCameraShift=" .. (index == 2 and "true" or "false")
    end
    local version4OK, version4Name = ns.Profiles.Import(version4)
    assert(version4OK and ns.GetCombinedEffectValue(2, "letterbox") == 7.5 and ns.GetCombinedEffectValue(2, "camerashift") == 3.4)
    assert(ns.GetCombinedEffectValue(3, "letterbox") == ns.db.letterboxHeight and ns.db.lensValuesVersion == 1)
    assert(not ns.db.extraCombinedLenses[2].customLetterbox and not ns.Profiles.Export():find("customLetterbox", 1, true))
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(version4Name))
    assert(ns.SetTrigger(false, 0))
    SlashCmdList.RETCINEMA("combined")
    assert(UIParent:IsShown(), "The removed alias must not activate an Effect")
    RetCinema_ToggleCombined(0); RetCinema_ToggleCombined(6)
    assert(UIParent:IsShown())
end
print("PASS: five Combined Lenses, working horizontal checks, Escape Buttons, add/remove, keys, overlap and numbered commands")

-- LiteRP Walk persists while stationary; Escape Button becomes an ordinary toggle.
do
    assert(not RetCinemaLiteRPPanel.content)
    SetBinding("NUMPADDIVIDE", "TOGGLERUN")
    local savedBefore = saved
    Settings.OpenToCategory(ns.settingsCategories["literp"]:GetID())
    local trigger = RetCinemaLiteRPPanel
    local enabled = checkbox(trigger.content, "Walk")
    assert(trigger.content and trigger.events.UPDATE_BINDINGS and not enabled:GetChecked())
    playerSpeed = 0
    enabled:SetChecked(true); click(enabled)
    local target = find(function(f) return f.frameRole == "triggerTarget" end)
    local function choose(value)
        click(target); click(find(function(f) return f.parent == target.menu and f.value == value end))
    end
    assert(ns.GetWalkingMode() == nil and UIParent:IsShown(), "Stationary startup must not guess walk mode")
    walkMode, playerSpeed = true, 2.5
    RetCinemaRoleplayEvents.scripts.OnEvent(RetCinemaRoleplayEvents, "PLAYER_STARTED_MOVING")
    flushTimers(); assert(ns.GetWalkingMode() and not UIParent:IsShown())
    playerSpeed = 0
    assert(not UIParent:IsShown(), "Stopping must retain a walk-mode Lens")
    ns.SetRoleplayOption("roleplayDo", false)
    assert(UIParent:IsShown() and ns.db.triggerEnabled and not ns.IsRoleplayActive(), "Disabling Do preserves Walk's selection but exits its scene")
    ns.SetRoleplayOption("roleplayDo", true)
    assert(not UIParent:IsShown() and ns.IsRoleplayActive(), "Re-enabling Do resumes a known walk-mode Lens")
    ToggleRun(); assert(not ns.GetWalkingMode() and UIParent:IsShown())
    ToggleRun(); assert(ns.GetWalkingMode() and not UIParent:IsShown(), "Walk mode activates even while stationary")
    assert(bindings.NUMPADDIVIDE == "TOGGLERUN" and saved == savedBefore)
    choose(1); finishEffects(); assert(UIParent:IsShown() and bars:IsShown())
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    ns.SetEffectEnabled("letterbox", false)
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    ns.SetEffectEnabled("letterbox", true); finishEffects(); assert(bars:IsShown())
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    ns.SetCombinedExitAll(2, true)
    choose(4)
    ToggleRun(); finishEffects()
    assert(ns.IsRoleplayActive() and top.height == 75 and cvars.test_cameraOverShoulder == "3.4")
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
    local escape = binding("RETCINEMA_COMBINED2", 1).parent.escape
    assert(not escape.enabled)
    local savedExit = ns.GetCombinedExitAll(1)
    local savedActions = {}
    for key, value in pairs(ns.GetCombinedActions(1)) do savedActions[key] = value end
    for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, action.effect == "hideui", 1) end
    ns.SetCombinedExitAll(1, true)
    RetCinema_ToggleCombined(1); finishEffects()
    assert(not UIParent:IsShown() and ns.IsRoleplayActive() and top.height == 75 and ns.IsCameraShiftActive(), "Escape-enabled button must still apply its own Effects during Walk")
    RetCinema_ToggleCombined(1); finishEffects()
    assert(UIParent:IsShown() and ns.IsRoleplayActive() and top.height == 75 and ns.IsCameraShiftActive(), "Second press restores only that button's snapshot, leaving Walk active")
    assert(ns.GetCombinedExitAll(1) and ns.GetCombinedExitAll(2), "LiteRP must preserve saved Escape Button preferences")
    for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, savedActions[action.binding] == true, 1) end
    ns.SetCombinedExitAll(1, savedExit)
    ToggleRun(); finishEffects()
    assert(not ns.IsRoleplayActive() and not bars:IsShown() and not ns.IsCameraShiftActive() and escape.enabled)
    RetCinema_ToggleCombined(2); finishEffects(); RetCinema_ToggleCombined(2); finishEffects()
    assert(not bars:IsShown() and not ns.IsCameraShiftActive(), "Escape Button returns after source cancellation")
    Settings.OpenToCategory(ns.settingsCategories["literp"]:GetID())
    choose(7)
    ToggleRun(); finishEffects(); assert(bars:IsShown())
    assert(ns.RemoveCombinedLens() and not ns.IsTriggerTargetAvailable())
    finishEffects(); assert(not bars:IsShown())
    assert(ns.AddCombinedLens() and ns.IsTriggerTargetAvailable() and bindings.J == "RETCINEMA_COMBINED5")
    finishEffects(); assert(bars:IsShown())
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    enabled:SetChecked(false); click(enabled)
    assert(ns.SetTrigger(true, 8) and ns.SetTrigger(false, 0) and not ns.SetTrigger(true, 9))
    assert(not ns.SetTrigger(true, 0.5) and secureHookCalls.ToggleRun == 1)
    Settings.OpenToCategory(ns.settingsCategories.main:GetID())
    assert(not trigger.events.UPDATE_BINDINGS and next(RetCinemaRoleplayEvents.events) == nil)
    assert(not RetCinemaRoleplayEvents.scripts.OnUpdate and not bars.scripts.OnUpdate)
    playerSpeed = 0
end
print("PASS: walk-mode synchronization and stationary retention, native bindings, LiteRP Escape protection, hidden targets and idle shutdown")
-- Profile preferences switch independently of runtime snapshots, consent and WoW bindings.
do
    assert(ns.Profiles.Current() == "Default" and #ns.Profiles.List() == 1)
    ns.SetApplyToLens("hideui", true)
    ns.SetApplyToLens("letterbox", true)
    ns.SetApplyToLens("camerashift", true)
    ns.SetLetterboxHeight(4, true)
    ns.SetCameraOffset(3, true)
    ns.SetPermanentLetterbox(true)
    ns.SetPermanentCameraShift(true)
    finishEffects()
    RetCinema_ToggleUI()
    RetCinema_ToggleCameraShift()
    finishEffects()
    assert(not UIParent:IsShown() and ns.IsCameraShiftActive())
    assert(ns.Profiles.Create(" Photo "))
    assert(ns.Profiles.Current() == "Photo" and UIParent:IsShown() and cvars.test_cameraOverShoulder == "-2")
    assert(not ns.db.cameraRestore and not ns.db.hiddenCVars and not bars:IsShown())
    assert(ns.db.effects.hideui and ns.db.lensEffects.hideui and ns.db.cameraConsent)
    assert(ns.db.profiles.Default.permanentLetterbox and ns.db.profiles.Default.permanentCameraShift)
    assert(ns.GetCombinedCount() == 1 and not ns.RemoveCombinedLens() and ns.db.profiles.Default.combinedLensCount == 5)
    assert(ns.db.profiles.Default.extraCombinedLenses[2].exitAll and ns.db.profiles.Default.extraCombinedLenses[2].actions.RETCINEMA_CAMERA)
    assert(not ns.db.profiles.Default.cameraRestore and not ns.db.profiles.Default.cameraConsent)
    assert(not ns.Profiles.Create("photo") and not ns.Profiles.Create("   ") and not ns.Profiles.Create("Bad|Name"))
    ns.SetLetterboxHeight(17.2)
    ns.SetMinimapButton(false)
    local exported = ns.Profiles.Export()
    assert(exported:find("RETCINEMA_PROFILE:9|Photo|", 1, true) == 1)
    assert(not exported:find("cameraConsent", 1, true) and not exported:find("cameraRestore", 1, true))
    assert(ns.Profiles.CopyFrom("Default"))
    assert(ns.Profiles.Current() == "Photo" and ns.db.permanentLetterbox and cvars.test_cameraOverShoulder == "3")
    assert(ns.GetCombinedCount() == 5 and ns.GetCombinedExitAll(2) and ns.GetCombinedActions(3).RETCINEMA_HIDEUI)
    ns.SetCombinedAction("RETCINEMA_CAMERA", false, 2)
    assert(ns.db.profiles.Default.extraCombinedLenses[2].actions.RETCINEMA_CAMERA, "Combined selections must be deep-copied")
    ns.SetCombinedEffectValue(2, "letterbox", 12)
    assert(ns.db.profiles.Default.extraCombinedLenses[2].letterboxHeight == 7.5, "Custom values must be deep-copied")
    ns.SetEffectEnabled("hideui", false)
    assert(ns.db.profiles.Default.effects.hideui, "Copying must not share mutable preference tables")
    assert(ns.Profiles.Activate("Default"))
    local legacy = ToV5(exported):gsub("PROFILE:5", "PROFILE:1")
    legacy = legacy:gsub(";advancedCinematographer=false", "") .. ";enableAnimation=false"
    legacy = legacy:gsub(";effects.fov=true", ""):gsub(";combinedLensCount=1", "")
    legacy = legacy:gsub(";extraCombinedLenses%.[^;]+", "")
    legacy = legacy:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    local ok, imported = ns.Profiles.Import(legacy)
    assert(ok and imported == "Photo (Imported)" and ns.Profiles.Current() == imported)
    assert(ns.db.letterboxHeight == 17.2 and not ns.db.showMinimapButton)
    assert(ns.GetCombinedCount() == 1 and not ns.GetCombinedActions(2).RETCINEMA_CAMERA and bindings.K == "RETCINEMA_COMBINED2")
    assert(ns.db.cameraConsent and cvars.test_cameraOverShoulder == "-2" and not bars:IsShown())
    assert(bindings.G == "RETCINEMA_COMBINED" and bindings.H == "RETCINEMA_HIDEUI")
    assert(not ns.Profiles.Delete(imported))
    assert(ns.Profiles.Delete("Photo") and not ns.db.profiles.Photo)
    local count = #ns.Profiles.List()
    for _, bad in ipairs({
        "return _G", exported:gsub("PROFILE:9", "PROFILE:10"),
        exported .. ";cameraConsent=true", exported .. ";letterboxHeight=5",
        exported:gsub("letterboxHeight=17.199999999999999", "letterboxHeight=1e999"),
        exported:gsub("showMinimapButton=false;", ""), exported .. ";;",
        exported:gsub("combinedLensCount=1", "combinedLensCount=1.5"), string.rep("x", 16385),
    }) do
        assert(not ns.Profiles.Import(bad), "Malformed exports must be rejected: " .. bad:sub(1, 60))
        assert(ns.Profiles.Current() == imported and #ns.Profiles.List() == count)
    end
    combat = true
    assert(not ns.Profiles.Create("Combat") and not ns.Profiles.Activate("Default"))
    assert(not ns.Profiles.CopyFrom("Default") and not ns.Profiles.Import(exported) and not ns.Profiles.Delete("Default"))
    assert(type(ns.Profiles.Export()) == "string")
    combat = false
    assert(ns.Profiles.Current() == imported and ns.db.cameraConsent)
end
print("PASS: profile creation/switch/copy/import/export/delete, snapshot isolation, validation, combat and binding preservation")

-- Native child categories expose working profile controls and support links.
do
    Settings.OpenToCategory(ns.settingsCategories.profiles:GetID())
    local profilesPanel = RetCinemaProfilesPanel
    local content = profilesPanel.content
    assert(content and not RetCinemaSettingsPanel:IsShown())
    local activeSelector = find(function(f) return f.profileRole == "active" end)
    local createButton = find(function(f) return f.parent == content and f.text == "Create New" end)
    assert(activeSelector.arrow and activeSelector:GetFontString().justifyH == "LEFT")
    assert(createButton.points.TOPLEFT[1] + createButton:GetWidth() == activeSelector.points.TOPLEFT[1] + activeSelector:GetWidth())
    assert(find(function(f) return f.parent == profilesPanel and f.text == "Profiles" end).fontTemplate == "GameFontHighlightHuge")
    assert(find(function(f) return f.parent == profilesPanel and f.atlas == "Options_HorizontalDivider" end))
    local function childButton(text)
        return find(function(f) return f.kind == "Button" and f.parent == content and f.text == text end)
    end
    local function selector(role) return find(function(f) return f.profileRole == role end) end
    local function selectProfile(dropdown, name)
        click(dropdown)
        local option = find(function(f)
            return f.kind == "Button" and f.text == name and f.parent and f.parent.parent and
                f.parent.parent.parent == dropdown.menu
        end)
        click(option)
    end
    click(childButton("Create New"))
    RetCinemaProfileDialog.editBox:SetText("UI Profile")
    click(RetCinemaProfileDialog.submitButton)
    assert(ns.Profiles.Current() == "UI Profile" and not RetCinemaProfileDialog:IsShown())
    assert(selector("active"):GetText() == "UI Profile")
    ns.SetLetterboxHeight(13.4)
    click(childButton("Export"))
    local exportString = RetCinemaCopyDialog.editBox:GetText()
    assert(exportString:find("RETCINEMA_PROFILE:9|UI Profile|", 1, true) == 1)
    RetCinemaCopyDialog:Hide()
    click(childButton("Import"))
    RetCinemaProfileDialog.editBox:SetText("invalid")
    click(RetCinemaProfileDialog.submitButton)
    assert(RetCinemaProfileDialog:IsShown() and RetCinemaProfileDialog.error:GetText() ~= "")
    RetCinemaProfileDialog.editBox:SetText(exportString)
    click(RetCinemaProfileDialog.submitButton)
    assert(ns.Profiles.Current() == "UI Profile (Imported)" and not RetCinemaProfileDialog:IsShown())
    selectProfile(selector("copy"), "Default")
    click(childButton("Copy"))
    assert(ns.Profiles.Current() == "UI Profile (Imported)" and ns.db.permanentLetterbox and cvars.test_cameraOverShoulder == "3")
    click(childButton("Create New"))
    RetCinemaProfileDialog.editBox:SetText("Spare")
    RetCinemaProfileDialog.editBox.scripts.OnEnterPressed(RetCinemaProfileDialog.editBox)
    assert(ns.Profiles.Current() == "Spare" and cvars.test_cameraOverShoulder == "-2")
    selectProfile(selector("delete"), "UI Profile (Imported)")
    click(childButton("Delete"))
    assert(RetCinemaProfileDialog.mode == "delete" and ns.db.profiles["UI Profile (Imported)"])
    click(RetCinemaProfileDialog.submitButton)
    assert(not ns.db.profiles["UI Profile (Imported)"] and ns.Profiles.Current() == "Spare")
    selectProfile(selector("active"), "UI Profile")
    assert(ns.Profiles.Current() == "UI Profile" and ns.db.letterboxHeight == 13.4)
    combat = true
    profilesPanel.scripts.OnEvent(profilesPanel, "PLAYER_REGEN_DISABLED")
    assert(not childButton("Create New").enabled and not selector("active").enabled)
    combat = false
    profilesPanel.scripts.OnEvent(profilesPanel, "PLAYER_REGEN_ENABLED")
    assert(childButton("Create New").enabled and selector("active").enabled)
    Settings.OpenToCategory(ns.settingsCategories.support:GetID())
    assert(not profilesPanel.events.PLAYER_REGEN_DISABLED)
    local support = RetCinemaSupportPanel
    assert(support.content)
    local versionLabel = find(function(f) return f.parent == support.content and f.text == "Version " .. version end)
    assert(versionLabel.fontTemplate == "GameFontHighlightSmall" and versionLabel.color[1] == 0.5)
    local characterLabel = find(function(f) return f.parent == support.content and f.text == "Хардрес-РевущийФьорд" end)
    assert(characterLabel.color[1] == 0.96 and characterLabel.color[2] == 0.55 and characterLabel.color[3] == 0.73)
    assert(find(function(f) return f.parent == support and f.text == "Support" end).fontTemplate == "GameFontHighlightHuge")
    local pendingLink = find(function(f) return f.parent == support.content and f.kind == "Button" and f.text == "Copy link" and not f.enabled end)
    pendingLink.scripts.OnEnter(pendingLink)
    assert(GameTooltip:GetText() == "Coming soon")
    local boosty = find(function(f) return f.parent == support.content and f.kind == "Button" and f.text == "Copy link" and f.enabled ~= false end)
    click(boosty)
    assert(RetCinemaCopyDialog.editBox:GetText() == "https://boosty.to/ret_ro")
    RetCinemaCopyDialog:Hide()
    click(find(function(f) return f.parent == support.content and f.kind == "Button" and f.text == "Copy character name" end))
    assert(RetCinemaCopyDialog.editBox:GetText() == "Хардрес-РевущийФьорд")
    RetCinemaCopyDialog:Hide()
    assert(not RetCinemaWishBoard)
    local wish = find(function(f) return f.parent == support.content and f.text == "Wish Board" end)
    assert(wish.points.TOPLEFT[2] == -60 and wish:GetWidth() == 110)
    click(wish)
    assert(RetCinemaWishBoard:IsShown())
    local feature = find(function(f) return f.parent == RetCinemaWishBoard and f.kind == "Button" and f.text == "LiteRP: Walk" end)
    click(feature)
    assert(find(function(f) return f.parent == RetCinemaWishBoard and f.text == "Walk applies a Lens while walk mode is enabled. LiteRP is available through Advanced Cinematographer." end))
    RetCinemaWishBoard:Hide()
    RetCinema_OpenSettings()
    assert(RetCinemaSettingsPanel:IsShown() and not support:IsShown())
    for _, effect in ipairs(ns.effects) do ns.SetApplyToLens(effect.id, false) end
    ns.SetPermanentCameraShift(false)
    ns.SetPermanentLetterbox(false)
    finishEffects()
end
print("PASS: Profiles and Support child pages, profile dialogs/dropdowns, confirmed deletion and correct copy links")

-- Functional Advanced settings, FOV, exact camera options and filtered gear pages.
do
    local function clone(value)
        if type(value) ~= "table" then return value end
        local result = {}; for key, entry in pairs(value) do result[key] = clone(entry) end; return result
    end
    ns.Profiles.Save()
    local preferences = clone(ns.db.profiles[ns.Profiles.Current()])
    local function settle() for _ = 1, 8 do finishEffects() end end
    ns.SetAdvanced(nil, true)
    for _, option in ipairs(ns.advancedOptions) do ns.SetAdvanced(option.id, true) end
    ns.SetEffectSetting("hideInterface", true); ns.SetEffectSetting("hideNames", true)
    while ns.GetCombinedCount() < 5 do assert(ns.AddCombinedLens()) end
    for _, id in ipairs({ "hideui", "letterbox", "camerashift", "fov" }) do ns.SetEffectEnabled(id, true); ns.SetApplyToLens(id, true) end
    ns.RestoreAll(); settle()

    -- Escape Button detects the remaining scene after other lenses were toggled off.
    for index = 1, 3 do for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, false, index) end end
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true, 1)
    ns.SetCombinedAction("RETCINEMA_LETTERBOX", true, 2)
    ns.SetCombinedAction("RETCINEMA_CAMERA", true, 3)
    ns.SetCombinedExitAll(1, true); ns.SetCombinedExitAll(2, false); ns.SetCombinedExitAll(3, false)
    RetCinema_ToggleCombined(1); RetCinema_ToggleCombined(2); RetCinema_ToggleCombined(3); settle()
    RetCinema_ToggleCombined(3); RetCinema_ToggleCombined(2); settle()
    assert(not UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
    RetCinema_ToggleCombined(1); settle(); assert(UIParent:IsShown(), "The last remaining CL1 exits in one press")
    RetCinema_ToggleCombined(1); RetCinema_ToggleCombined(2); RetCinema_ToggleCombined(3); settle()
    RetCinema_ToggleCombined(2); RetCinema_ToggleCombined(1); settle()
    assert(not UIParent:IsShown() and not ns.IsCameraShiftActive(), "First CL1 press removes the remaining CL3 camera")
    RetCinema_ToggleCombined(1); settle(); assert(UIParent:IsShown())

    -- FOV uses the game's bounds; permanent and temporary values are independent.
    assert(cvars.cameraFov == "85" and ns.SetFOV(70) and ns.SetFOV(80, true))
    ns.SetPermanentFOV(true)
    assert(cvars.cameraFov == "85" and RetCinemaFOVAnimator.scripts.OnUpdate)
    RetCinemaFOVAnimator.scripts.OnUpdate(RetCinemaFOVAnimator, 0.175)
    assert(math.abs(tonumber(cvars.cameraFov) - 82.5) < 0.001)
    settle(); assert(cvars.cameraFov == "80" and ns.db.fovRestore == "85")
    RetCinema_RunBinding("RETCINEMA_FOV"); settle(); assert(cvars.cameraFov == "70" and ns.fovActive)
    pressEscape(); settle(); assert(cvars.cameraFov == "80" and not ns.fovActive)
    ns.SetPermanentFOV(false); settle(); assert(cvars.cameraFov == "85" and not ns.db.fovRestore)
    assert(ns.SetFOV(120) and ns.db.fov == 90 and not ns.SetFOV(0 / 0))
    ns.SetFOV(68); SlashCmdList.RETCINEMA("fov"); settle(); assert(cvars.cameraFov == "68")
    ns.SetEffectEnabled("fov", false); assert(cvars.cameraFov == "85" and not ns.fovActive)
    ns.SetEffectEnabled("fov", true)
    ns.SetPermanentFOV(true)
    events.scripts.OnEvent(events, "PLAYER_LOGOUT")
    assert(cvars.cameraFov == "85" and not ns.db.fovRestore)
    ns.SetPermanentFOV(false)
    effectTab(4)
    local fovApply = checkbox(page("fov").content, "Apply Effect to Lens")
    assert(RetCinemaFOVSlider.enabled and fovApply:GetChecked())
    RetCinemaFOVInput:SetText("74.5"); RetCinemaFOVInput.scripts.OnEnterPressed(RetCinemaFOVInput)
    assert(ns.db.fov == 74.5)
    cvars.cameraFov = nil; page("fov").refresh(); assert(not RetCinemaFOVSlider.enabled and not fovApply.enabled)
    RetCinema_ToggleFOV(); assert(not ns.fovActive)
    cvars.cameraFov = "85"; page("fov").refresh()

    -- FOV duration is an Advanced option, with a separate disclosure on Effect.
    local fovPage = page("fov")
    local durationCheck = find(function(f) return f.parent == fovPage.content and f.durationKey == "fovDuration" and not f.permanentMode end)
    assert(durationCheck:IsShown() and not durationCheck:GetChecked() and not RetCinemaLensFOVfovDurationInput)
    durationCheck:SetChecked(true); click(durationCheck)
    local fovDurationInput = RetCinemaLensFOVfovDurationInput
    assert(fovDurationInput and fovDurationInput:IsShown() and fovDurationInput:GetText() == "0.35")
    fovDurationInput.scripts.OnEnter(fovDurationInput); assert(GameTooltip:GetText() == "Enter an exact value.\nDefault: 0.35")
    fovDurationInput:SetText("2"); fovDurationInput.scripts.OnEnterPressed(fovDurationInput)
    ns.SetFOV(65); RetCinema_ToggleFOV()
    RetCinemaFOVAnimator.scripts.OnUpdate(RetCinemaFOVAnimator, 1)
    assert(math.abs(tonumber(cvars.cameraFov) - 75) < 0.001, "FOV must use the configured two-second transition")
    settle(); assert(cvars.cameraFov == "65")
    pressEscape(); RetCinemaFOVAnimator.scripts.OnUpdate(RetCinemaFOVAnimator, 1)
    assert(math.abs(tonumber(cvars.cameraFov) - 75) < 0.001, "FOV return must use the configured duration")
    settle(); assert(cvars.cameraFov == "85")
    durationCheck:SetChecked(false); click(durationCheck)
    assert(not fovDurationInput.parent:IsShown() and ns.db.fovDuration == 2, "Disclosure only changes visibility")
    assert(ns.SetEffectSetting("fovDuration", 1, true) and ns.SetEffectSetting("fovDuration", 3, false, 3))
    assert(ns.db.permanentFovDuration == 1 and ns.db.extraCombinedLenses[3].fovDuration == 3)
    ns.SetFOV(75, true); ns.SetPermanentFOV(true)
    RetCinemaFOVAnimator.scripts.OnUpdate(RetCinemaFOVAnimator, 0.5)
    assert(math.abs(tonumber(cvars.cameraFov) - 80) < 0.001)
    settle(); ns.SetPermanentFOV(false); settle()
    ns.SetAdvanced("fovSpeed", false); assert(not durationCheck:IsShown())
    assert(not ns.SetEffectSetting("fovDuration", 3) and ns.EffectSettings("fov").duration == 0.35)
    RetCinema_ToggleFOV(); RetCinemaFOVAnimator.scripts.OnUpdate(RetCinemaFOVAnimator, 0.35)
    assert(cvars.cameraFov == "65" and not RetCinemaFOVAnimator.scripts.OnUpdate)
    pressEscape(); settle()
    ns.SetAdvanced("fovSpeed", true)

    -- Full-height bars, opacity and duration are gated without erasing preferences.
    ns.SetLetterboxHeight(50)
    ns.SetLetterboxHeight(12, true)
    ns.SetEffectSetting("letterboxOpacity", 0.6, true)
    ns.SetEffectSetting("letterboxOpacity", 0.4)
    ns.SetEffectSetting("letterboxDuration", 2)
    ns.SetPermanentLetterbox(true); settle()
    assert(top.height == 120 and bars.alpha == 0.6)
    RetCinema_ToggleLetterbox()
    assert(bars.scripts.OnUpdate and bars.alpha == 0.4)
    bars.scripts.OnUpdate(bars, 0.2)
    assert(top.height > 120 and top.height < 500)
    settle(); assert(top.height == 500)
    pressEscape(); settle(); assert(top.height == 120 and bars.alpha == 0.6)
    ns.SetLetterboxHeight(50, true); settle()
    ns.SetAdvanced(nil, false); settle()
    assert(top.height == 250 and bars.alpha == 1 and ns.db.permanentLetterboxHeight == 50)
    assert(ns.GetCombinedCount() == 3 and ns.db.combinedLensCount == 5 and not ns.AddCombinedLens())
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
    assert(not binding("RETCINEMA_COMBINED", 2):IsShown() and not binding("RETCINEMA_COMBINED4", 1).parent:IsShown())
    assert(bindings.K == "RETCINEMA_COMBINED2" and bindings.J == "RETCINEMA_COMBINED5")
    assert(not ns.SetEffectSetting("letterboxOpacity", 0.2))
    ns.SetAdvanced(nil, true); settle()
    assert(top.height == 500 and ns.GetCombinedCount() == 5 and binding("RETCINEMA_COMBINED", 2):IsShown())
    ns.SetPermanentLetterbox(false); settle()
    effectTab(2)
    assert(RetCinemaBarHeightSlider.maximum == 50)
    ns.SetAdvanced("letterboxFull", false); settle()
    assert(RetCinemaBarHeightSlider.maximum == 25 and ns.db.letterboxHeight == 50 and RetCinemaBarHeightInput:GetText() == "25%")
    ns.SetAdvanced("letterboxFull", true)

    -- HideUI can hide either part independently, including per-lens preferences.
    ns.SetEffectSetting("hideInterface", false); ns.SetEffectSetting("hideNames", true)
    effectTab(1)
    local hideInterface = checkbox(page("hideui").content, "Don't hide interface elements")
    hideInterface:SetChecked(false); click(hideInterface); assert(ns.db.hideInterface)
    hideInterface:SetChecked(true); click(hideInterface); assert(not ns.db.hideInterface)
    RetCinema_ToggleUI(); assert(UIParent:IsShown() and cvars.UnitNameNPC == "0")
    pressEscape(); assert(UIParent:IsShown() and cvars.UnitNameNPC == "1")
    ns.SetEffectSetting("hideInterface", true); ns.SetEffectSetting("hideNames", false)
    RetCinema_ToggleUI(); assert(not UIParent:IsShown() and cvars.UnitNameNPC == "1")
    pressEscape(); assert(UIParent:IsShown())
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID()); lensPage.refresh()
    local hideGear = binding("RETCINEMA_HIDEUI", 1).parent.gear
    click(hideGear)
    assert(RetCinemaCombinedSettingsDialog.index == 1, "HideUI gear must include CL1")
    local cl1Exception = checkbox(RetCinemaCombinedSettingsDialog.extraGroups.hideui, "Don't hide interface elements")
    assert(not cl1Exception:GetChecked())
    cl1Exception:SetChecked(true); click(cl1Exception)
    assert(not ns.db.hideInterface and not ns.EffectSettings("hideui", false, 1).hideInterface)
    ns.CloseCombinedSettings(); ns.SetEffectSetting("hideInterface", true)
    ns.SetCombinedAction("RETCINEMA_HIDEUI", true, 3)
    ns.SetEffectSetting("hideInterface", false, false, 3); ns.SetEffectSetting("hideNames", true, false, 3)
    ns.SetCombinedExitAll(3, false)
    RetCinema_ToggleCombined(3); assert(UIParent:IsShown() and cvars.UnitNameNPC == "0")
    pressEscape(); settle(); assert(cvars.UnitNameNPC == "1")

    -- Camera options and animation duration return exactly to the player's values.
    local baseline = { head = cvars.test_cameraHeadMovementStrength, enemy = cvars.test_cameraTargetFocusEnemyEnable, interact = cvars.test_cameraTargetFocusInteractEnable, combat = cvars.CameraFollowTargetCombat }
    ns.SetCameraOffset(4); ns.SetEffectSetting("cameraDuration", 2)
    ns.SetEffectSetting("cameraHeadMovement", true); ns.SetEffectSetting("cameraTargetFocus", true)
    effectTab(3)
    local lensHead = find(function(f) return f.parent == page("camerashift").content and f.settingKey == "cameraHeadMovement" and not f.permanentMode end)
    assert(lensHead:IsShown() and lensHead:GetChecked())
    lensHead:SetChecked(false); click(lensHead); assert(not ns.db.cameraHeadMovement)
    lensHead:SetChecked(true); click(lensHead); assert(ns.db.cameraHeadMovement)
    RetCinema_ToggleCameraShift()
    assert(cvars.test_cameraHeadMovementStrength == "1" and cvars.test_cameraTargetFocusEnemyEnable == "1" and cvars.CameraFollowTargetCombat == "0")
    RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.5)
    assert(tonumber(cvars.test_cameraOverShoulder) > -2 and tonumber(cvars.test_cameraOverShoulder) < 4)
    settle(); assert(cvars.test_cameraOverShoulder == "4")
    pressEscape()
    RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.5)
    assert(tonumber(cvars.test_cameraOverShoulder) > -2, "Escape must retain the chosen return duration")
    settle()
    assert(cvars.test_cameraHeadMovementStrength == baseline.head and cvars.test_cameraTargetFocusEnemyEnable == baseline.enemy and cvars.test_cameraTargetFocusInteractEnable == baseline.interact and cvars.CameraFollowTargetCombat == baseline.combat)
    ns.SetCameraOffset(0)
    RetCinema_ToggleCameraShift(); settle()
    assert(cvars.CameraKeepCharacterCentered == "0" and cvars.test_cameraHeadMovementStrength == "1", "Head bob and target focus must work with zero shoulder offset")
    pressEscape(); settle()
    ns.SetCameraOffset(1, true); ns.SetEffectSetting("cameraTargetFocus", false, true)
    ns.SetPermanentCameraShift(true); settle()
    RetCinema_ToggleCameraShift(); settle(); pressEscape(); settle()
    assert(cvars.test_cameraOverShoulder == "1" and cvars.test_cameraTargetFocusEnemyEnable == "0" and cvars.CameraFollowTargetCombat == baseline.combat)
    ns.SetPermanentCameraShift(false); settle()
    assert(cvars.test_cameraHeadMovementStrength == baseline.head and cvars.test_cameraTargetFocusInteractEnable == baseline.interact and cvars.CameraFollowTargetCombat == baseline.combat)

    -- Only checked additional lenses are exposed by the gear, with page counts.
    for index = 2, 5 do ns.SetCombinedAction("RETCINEMA_FOV", index == 3, index) end
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID()); lensPage.refresh()
    local fovRow = binding("RETCINEMA_FOV", 1).parent
    click(fovRow.gear)
    local dialog = RetCinemaCombinedSettingsDialog
    assert(dialog:IsShown() and dialog.index == 3 and dialog.counter:GetText() == "1 / 1")
    click(dialog.selector)
    for _, entry in ipairs(dialog.selector.menu.children) do if entry:IsShown() then assert(entry.value == 3) end end
    click(dialog.selector.menu.children[1])
    RetCinemaCombinedFOVInput:SetText("65"); RetCinemaCombinedFOVInput.scripts.OnEnterPressed(RetCinemaCombinedFOVInput)
    assert(ns.GetCombinedEffectValue(3, "fov") == 65)
    click(fovRow.gear); assert(not dialog:IsShown())
    click(fovRow.gear)
    local special = {}; for _, name in ipairs(UISpecialFrames) do special[name] = true end
    assert(special.RetCinemaCombinedSettingsDialog and special.RetCinemaAdvancedDialog)
    ns.CloseCombinedSettings()
    ns.SetCombinedExitAll(3, false); RetCinema_ToggleCombined(3); settle(); assert(cvars.cameraFov == "65")
    pressEscape(); settle(); assert(cvars.cameraFov == "85")
    effectTab(4)
    assert(find(function(f) return f.parent == RetCinemaEffectPanel and f.text == "4 / 5" end))

    -- Postures are stationary-only and canceled by movement; logout has no idle work.
    ns.SetTrigger(false, 1)
    for _, kind in ipairs({ "Sit", "Lay", "Lean" }) do ns.SetRoleplayTarget(kind, 1) end
    for _, key in ipairs({ "roleplaySit", "roleplayLay", "roleplayLean", "roleplayLogout" }) do ns.SetRoleplayOption(key, true) end
    playerSpeed = 7; DoEmote("SIT"); settle(); assert(not bars:IsShown())
    assert(secureHookCalls.PerformEmote == 1 and not secureHookCalls.DoEmote, "Use Blizzard's current emote API without double hooks")
    local function CheckOrdinaryCombinedDuringLiteRP()
        local savedExit, savedActions = ns.GetCombinedExitAll(1), {}
        for key, value in pairs(ns.GetCombinedActions(1)) do savedActions[key] = value end
        for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, action.effect == "hideui", 1) end
        ns.SetCombinedExitAll(1, true)
        RetCinema_ToggleCombined(1); settle()
        assert(ns.IsRoleplayActive() and not UIParent:IsShown() and bars:IsShown(), "LiteRP must permit an Escape-enabled Combined Lens to activate")
        RetCinema_ToggleCombined(1); settle()
        assert(ns.IsRoleplayActive() and UIParent:IsShown() and bars:IsShown(), "LiteRP must use ordinary restoration instead of exit-all")
        assert(ns.GetCombinedExitAll(1), "Saved Escape Button policy must remain checked")
        for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, savedActions[action.binding] == true, 1) end
        ns.SetCombinedExitAll(1, savedExit)
    end
    playerSpeed = 0; DoEmote("SIT"); settle(); assert(bars:IsShown())
    ns.SetRoleplayOption("roleplayStay", false); settle()
    assert(not bars:IsShown() and ns.db.roleplaySit and not ns.IsRoleplayActive(), "Disabling Stay ends its action without erasing Sit")
    ns.SetRoleplayOption("roleplayStay", true)
    DoEmote("SIT"); settle(); assert(bars:IsShown())
    CheckOrdinaryCombinedDuringLiteRP()
    DoEmote("STAND"); settle(); assert(not bars:IsShown())
    for _, token in ipairs({ "LAYDOWN", "SLEEP", "LEAN" }) do
        DoEmote(token); settle(); assert(bars:IsShown())
        playerSpeed = 7; RetCinemaRoleplayEvents.scripts.OnEvent(RetCinemaRoleplayEvents, "PLAYER_STARTED_MOVING")
        flushTimers(); settle(); assert(not bars:IsShown()); playerSpeed = 0
    end
    ns.SetLetterboxHeight(8, true); ns.SetPermanentLetterbox(true); settle()
    local rp = RetCinemaRoleplayEvents
    rp.scripts.OnEvent(rp, "PLAYER_CAMPING"); assert(rp.scripts.OnUpdate and ns.logoutBarHeight == 8)
    rp.scripts.OnUpdate(rp, 10); assert(top.height == 280 and bars.alpha == 1)
    rp.scripts.OnUpdate(rp, 6); assert(top.height == 460)
    rp.scripts.OnUpdate(rp, 3); assert(top.height == 500)
    rp.scripts.OnUpdate(rp, 1); assert(not rp.scripts.OnUpdate)
    rp.scripts.OnEvent(rp, "LOGOUT_CANCEL"); settle(); assert(top.height == 80 and not ns.logoutBarHeight)
    ns.SetEffectSetting("letterboxDuration", 5, true)
    rp.scripts.OnEvent(rp, "PLAYER_CAMPING"); rp.scripts.OnUpdate(rp, 8)
    assert(logoutCancelCalls == 0 and rp.scripts.OnUpdate and top.height > 80, "The addon must never cancel native logout itself")
    CancelLogout()
    assert(logoutCancelCalls == 1 and secureHookCalls.CancelLogout == 1 and not rp.scripts.OnUpdate and ns.logoutBarHeight == nil)
    assert(bars.scripts.OnUpdate, "Canceled logout must animate back quickly")
    bars.scripts.OnUpdate(bars, 0.15)
    assert(top.height == 80 and not bars.scripts.OnUpdate and ns.db.permanentLetterboxDuration == 5, "Cancel return is 0.15 seconds, independent of saved five-second duration")
    rp.scripts.OnEvent(rp, "LOGOUT_CANCEL"); assert(not bars.scripts.OnUpdate)
    ns.SetEffectSetting("letterboxDuration", 0.3, true)
    rp.scripts.OnEvent(rp, "PLAYER_CAMPING")
    ns.SetEffectEnabled("letterbox", false)
    assert(not rp.scripts.OnUpdate and not ns.logoutBarHeight and not bars.scripts.OnUpdate)
    ns.SetEffectEnabled("letterbox", true)
    ns.SetPermanentLetterbox(false); settle()
    -- Each Stay action chooses its own Lens in the UI and backend.
    ns.SetRoleplayTarget("Sit", 0); ns.SetRoleplayTarget("Lay", 2); ns.SetRoleplayTarget("Lean", 1)
    Settings.OpenToCategory(ns.settingsCategories["literp"]:GetID())
    local staySelectors = {}
    for _, item in ipairs(frames) do if item.frameRole == "stayTarget" then staySelectors[item.poseKind] = item end end
    assert(staySelectors.Sit:GetText() == "HideUI" and staySelectors.Lay:GetText() == "CameraShift" and staySelectors.Lean:GetText() == "Letterbox")
    playerSpeed = 0; DoEmote("SIT"); settle()
    assert(not UIParent:IsShown() and not ns.IsCameraShiftActive())
    DoEmote("LAYDOWN"); settle()
    assert(UIParent:IsShown() and ns.IsCameraShiftActive() and not bars:IsShown())
    DoEmote("LEAN"); settle()
    assert(not ns.IsCameraShiftActive() and bars:IsShown())
    DoEmote("STAND"); settle(); assert(not bars:IsShown())

    -- GoOffline values are editable and every precise control has a default reset.
    assert(not RetCinemaGoOfflineDialog, "GoOffline settings must stay lazy until opened")
    local goOfflineButton = find(function(f) return f.parent == RetCinemaLiteRPPanel.content and f.kind == "Button" and f:GetText() == "GoOffline" end)
    assert(goOfflineButton.enabled)
    click(goOfflineButton)
    local durationInput = RetCinemaroleplayLogoutDuration1Input
    assert(durationInput and durationInput:IsShown() and RetCinemaGoOfflineDialog:IsShown())
    durationInput:SetText("4,2 s"); durationInput.scripts.OnEnterPressed(durationInput)
    assert(ns.db.roleplayLogoutDuration1 == 4.2)
    durationInput.scripts.OnEnter(durationInput)
    assert(GameTooltip:GetText() == "Enter an exact value.\nDefault: 10 s")
    click(durationInput.parent.reset); assert(ns.db.roleplayLogoutDuration1 == 10)
    ns.SetRoleplayNumber("roleplayLogoutStart", 10)
    ns.SetRoleplayNumber("roleplayLogoutMax", 35)
    ns.SetRoleplayNumber("roleplayLogoutRate1", 5)
    rp.scripts.OnEvent(rp, "PLAYER_CAMPING"); assert(top.height == 100 and ns.IsRoleplayActive())
    CheckOrdinaryCombinedDuringLiteRP()
    rp.scripts.OnUpdate(rp, 3); assert(top.height == 250)
    rp.scripts.OnUpdate(rp, 3); assert(top.height == 350)
    rp.scripts.OnEvent(rp, "LOGOUT_CANCEL"); settle(); assert(not ns.IsRoleplayActive() and not bars:IsShown())

    -- A modal consumes only Escape and leaves the native settings category open.
    local rpPage = RetCinemaLiteRPPanel
    if not RetCinemaGoOfflineDialog:IsShown() then click(goOfflineButton) end
    RetCinemaGoOfflineDialog.scripts.OnKeyDown(RetCinemaGoOfflineDialog, "A")
    assert(RetCinemaGoOfflineDialog.propagateKeyboard and RetCinemaGoOfflineDialog:IsShown())
    combat = true
    RetCinemaGoOfflineDialog.scripts.OnKeyDown(RetCinemaGoOfflineDialog, "ESCAPE")
    combat = false
    assert(not RetCinemaGoOfflineDialog:IsShown() and not RetCinemaGoOfflineDialog.propagateKeyboard and rpPage:IsShown())
    local walkCheck = checkbox(rpPage.content, "Walk")
    walkCheck.scripts.OnEnter(walkCheck)
    assert(GameTooltip:GetText():find("|cffff8000Warning!|r", 1, true) == 1)
    for _, kind in ipairs({ "Sit", "Lay", "Lean" }) do
        local check = checkbox(rpPage.content, kind)
        assert(staySelectors[kind].points.TOPLEFT[1] == 20 and staySelectors[kind].points.TOPLEFT[2] < check.points.TOPLEFT[2])
    end

    -- Main and gear numeric defaults, active FOV styling and restored arrows.
    effectTab(2)
    local showDuration = find(function(f) return f.parent == page("letterbox").content and f.durationKey == "letterboxDuration" and not f.permanentMode end)
    showDuration:SetChecked(true); click(showDuration)
    local letterDuration = find(function(f) return f.parent == page("letterbox").content and f.settingKey == "letterboxDuration" and not f.permanentMode end)
    letterDuration.input.scripts.OnEnter(letterDuration.input)
    assert(GameTooltip:GetText() == "Enter an exact value.\nDefault: 0.3")
    click(letterDuration.reset); assert(ns.db.letterboxDuration == 0.3)
    ns.SetEffectSetting("letterboxDuration", 5, true)
    ns.SetLetterboxHeight(10, true); ns.SetPermanentLetterbox(true); settle()
    ns.SetPermanentLetterbox(false)
    bars.scripts.OnUpdate(bars, 0.3)
    assert(not bars:IsShown() and not bars.scripts.OnUpdate, "Disabled Permanent must return using the default duration")
    assert(checkbox(page("hideui").content, "Apply HideUI to Lens").points.TOPLEFT[2] == checkbox(page("letterbox").content, "Apply Letterbox to Lens").points.TOPLEFT[2])
    local nextEffect = find(function(f) return f.frameRole == "nextEffect" end)
    click(nextEffect); assert(current.effectId == "camerashift")
    ns.SetAdvanced("cameraHeadMovement", false)
    assert(not lensHead:IsShown() and not ns.SetEffectSetting("cameraHeadMovement", true))
    ns.SetAdvanced("cameraHeadMovement", true); assert(lensHead:IsShown())
    effectTab(4); assert(current:GetFontString().color[2] == 0.82)
    for _, name in ipairs({ "RetCinemaAdvancedDialog", "RetCinemaCombinedSettingsDialog", "RetCinemaProfileDialog", "RetCinemaCopyDialog", "RetCinemaWishBoard" }) do
        assert(_G[name].backdropColor[4] == 0.8, name .. " must have an 80% opaque background")
    end
    Settings.OpenToCategory(ns.settingsCategories.lens:GetID())
    local r = binding("RETCINEMA_LETTERBOX", 1).parent
    local center = 12 + r.extraContainer.points.TOPLEFT[1] + r.extraContainer:GetWidth() / 2
    assert(center == 342 + 190 / 2, "The complete membership container must be centered under the third column")
    local summary = binding("RETCINEMA_COMBINED", 1).parent.summary
    assert(summary.justifyH == "CENTER" and 12 + summary.points.TOPLEFT[1] + summary:GetWidth() / 2 == center)
    assert(general:GetHeight() == 432)

    ns.SetAdvanced("roleplay", false)
    assert(next(rp.events) == nil and not rp.scripts.OnUpdate)
    for _, child in ipairs(ns.settingsCategories.main.subcategories) do assert(child ~= ns.settingsCategories["literp"]) end

    -- New preferences are included in profile exports, including the 50% range.
    local originalName = ns.Profiles.Current()
    local export = ns.Profiles.Export()
    assert(export:find("RETCINEMA_PROFILE:9|", 1, true) == 1 and export:find("letterboxHeight=50", 1, true))
    local ok, imported = ns.Profiles.Import(export)
    assert(ok and ns.db.advanced.letterboxFull and ns.db.letterboxHeight == 50 and ns.db.extraCombinedLenses[3].fov == 65)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(imported))
    local legacy8 = export:gsub("PROFILE:9", "PROFILE:8"):gsub(";roleplayDo=[^;]+", ""):gsub(";roleplayStay=[^;]+", "")
    local ok8, name8 = ns.Profiles.Import(legacy8)
    assert(ok8 and ns.db.roleplayDo == ns.db.triggerEnabled and ns.db.roleplayStay == (ns.db.roleplaySit or ns.db.roleplayLay or ns.db.roleplayLean or ns.db.roleplayLogout))
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(name8))
    local legacy7 = export:gsub("PROFILE:9", "PROFILE:7"):gsub(";roleplayDo=[^;]+", ""):gsub(";roleplayStay=[^;]+", ""):gsub(";advanced%.fovSpeed=[^;]+", ""):gsub(";[%w_.]*[Ff]ovDuration=[^;]+", "")
    local imported7, name7 = ns.Profiles.Import(legacy7)
    assert(imported7 and ns.db.fovDuration == 0.35 and not ns.Advanced("fovSpeed"), "Version 7 must migrate new FOV defaults safely")
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(name7))
    local legacy6 = export:gsub("PROFILE:9", "PROFILE:6"):gsub(";roleplayDo=[^;]+", ""):gsub(";roleplayStay=[^;]+", "")
    legacy6 = legacy6:gsub(";advanced%.fovSpeed=[^;]+", ""):gsub(";[%w_.]*[Ff]ovDuration=[^;]+", "")
    legacy6 = legacy6:gsub(";advanced%.cameraHeadMovement=[^;]+", ""):gsub(";advanced%.cameraTargetFocus=[^;]+", "")
    legacy6 = legacy6:gsub(";roleplay%a+Target=[^;]+", ""):gsub(";roleplayLogout%a+%d*=[^;]+", "")
    local migrated, legacyName = ns.Profiles.Import(legacy6)
    assert(migrated and ns.db.roleplaySitTarget == ns.db.triggerTarget and ns.db.roleplayLogoutRate1 == 2)
    assert(not ns.db.advanced.cameraHeadMovement)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(legacyName))
    ns.ApplyProfilePreferences(preferences); ns.Profiles.Save(); settle()
end
print("PASS: FOV permanent/Lens/logout, working Advanced options, 50% bars, exact head/target restoration, filtered gear pages, postures and 20-second logout phases")

-- Disabled effects stay idle; old profiles and interrupted camera snapshots migrate safely.
for _, effect in ipairs(ns.effects) do ns.SetEffectEnabled(effect.id, false) end
assert(next(events.events) == nil and not bars.scripts.OnUpdate and not RetCinemaCameraAnimator.scripts.OnUpdate)
Settings.OpenToCategory(ns.settingsCategories.effect:GetID())
assert(not current:IsShown() and not ns.HasLensEffects())
local frameCount = #frames
RetCinema_ToggleLetterbox()
RetCinema_RunBinding("RETCINEMA_CAMERA")
RetCinema_ToggleCombined()
assert(#frames == frameCount)
local savedProfileDatabase = ret_CinemaDB
do
    ret_CinemaDB = {
        modules = { hideui = false, letterbox = false, camera = false, fov = false, smoothmotion = false, keybindings = true },
        cameraRestore = { test_cameraOverShoulder = "-2", CameraKeepCharacterCentered = "1", CameraReduceUnexpectedMovement = "1" },
        hiddenCVars = { UnitNameNPC = "1", UnitNameEnemyPlayerName = "1" },
        cameraEnabled = true, showSecondBinding = true, combinedAsEsc = true,
    }
    cvars.test_cameraOverShoulder, cvars.CameraKeepCharacterCentered = "7", "0"
    cvars.UnitNameNPC, cvars.UnitNameEnemyPlayerName = "0", "0"
    local reloaded = {}
    assert(loadfile("ret_Cinema/Core.lua"))("ret_CinemaReload", reloaded)
    assert(loadfile("ret_Cinema/Roleplay.lua"))("ret_CinemaReload", reloaded)
    assert(loadfile("ret_Cinema/Profiles.lua"))("ret_CinemaReload", reloaded)
    local reloadEvents = frames[#frames]
    assert(loadfile("ret_Cinema/Options.lua"))("ret_CinemaReload", reloaded)
    reloadEvents.scripts.OnEvent(reloadEvents, "ADDON_LOADED", "ret_CinemaReload")
    assert(cvars.test_cameraOverShoulder == "-2" and cvars.CameraKeepCharacterCentered == "1")
    assert(cvars.UnitNameNPC == "1" and cvars.UnitNameEnemyPlayerName == "1")
    assert(not reloaded.db.cameraRestore and not reloaded.db.hiddenCVars and not reloaded.db.modules)
    assert(not reloaded.db.cameraEnabled and not reloaded.db.showSecondBinding and reloaded.db.combinedAsEsc)
    for _, effect in ipairs(reloaded.effects) do assert(not reloaded.IsEffectEnabled(effect.id)) end
    assert(next(reloadEvents.events) == nil)
    assert(bindings.G == "RETCINEMA_COMBINED" and bindings.H == "RETCINEMA_HIDEUI")
end
do
    ret_CinemaDB = {
        effects = { hideui = false, letterbox = true, camerashift = true, smoothmotion = false },
        cameraConsent = true, permanentCameraShift = true, permanentCameraOffset = 3,
        permanentLetterbox = true, permanentLetterboxHeight = 4,
        cameraRestore = { test_cameraOverShoulder = "-2", CameraKeepCharacterCentered = "1", CameraReduceUnexpectedMovement = "1" },
    }
    cvars.test_cameraOverShoulder, cvars.CameraKeepCharacterCentered = "8", "0"
    local startup = {}
    assert(loadfile("ret_Cinema/Core.lua"))("ret_CinemaStartup", startup)
    assert(loadfile("ret_Cinema/Roleplay.lua"))("ret_CinemaStartup", startup)
    assert(loadfile("ret_Cinema/Profiles.lua"))("ret_CinemaStartup", startup)
    local startupEvents = frames[#frames]
    assert(loadfile("ret_Cinema/Options.lua"))("ret_CinemaStartup", startup)
    function IsLoggedIn() return false end
    startupEvents.scripts.OnEvent(startupEvents, "ADDON_LOADED", "ret_CinemaStartup")
    assert(cvars.test_cameraOverShoulder == "-2" and startupEvents.events.PLAYER_LOGIN)
    startupEvents.scripts.OnEvent(startupEvents, "PLAYER_LOGIN")
    assert(cvars.test_cameraOverShoulder == "3" and startup.db.cameraRestore.test_cameraOverShoulder == "-2")
    assert(RetCinemaLetterbox:IsShown() and RetCinemaLetterbox.children[1].height == 40)
    startupEvents.scripts.OnEvent(startupEvents, "PLAYER_LOGOUT")
    assert(cvars.test_cameraOverShoulder == "-2" and not startup.db.cameraRestore)
    assert(startup.db.permanentCameraShift and startup.db.permanentLetterbox)
end
print("PASS: disabled Effects idle, old-profile migration, binding preservation, permanent login, exact logout recovery")

do
    ret_CinemaDB = savedProfileDatabase
    local persisted = {}
    assert(loadfile("ret_Cinema/Core.lua"))("ret_CinemaPersisted", persisted)
    assert(loadfile("ret_Cinema/Roleplay.lua"))("ret_CinemaPersisted", persisted)
    assert(loadfile("ret_Cinema/Profiles.lua"))("ret_CinemaPersisted", persisted)
    local persistedEvents = frames[#frames]
    assert(loadfile("ret_Cinema/Options.lua"))("ret_CinemaPersisted", persisted)
    function IsLoggedIn() return true end
    persistedEvents.scripts.OnEvent(persistedEvents, "ADDON_LOADED", "ret_CinemaPersisted")
    assert(persisted.Profiles.Current() == "UI Profile" and #persisted.Profiles.List() == 4)
    assert(persisted.db.letterboxHeight == 13.4 and persisted.db.cameraConsent)
    assert(persisted.db.profiles.Default.permanentCameraShift and not persisted.IsEffectEnabled("hideui"))
    assert(not persisted.db.profiles["UI Profile"].effects.hideui, "Reload saves the latest active preferences")
    assert(bindings.G == "RETCINEMA_COMBINED" and bindings.H == "RETCINEMA_HIDEUI")
end
print("PASS: active profile, profile history and latest preferences survive addon reload")
