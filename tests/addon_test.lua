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
    "SetDisabledFontObject",
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
function Frame:GetScale() return self.scale or 1 end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:SetFrameLevel(level) self.level = level end
function Frame:SetID(id) self.id = id end
function Frame:GetID() return self.id end
function Frame:GetName() return self.name end
function Frame:GetParent() return self.parent end
function Frame:SetChecked(checked) self.checked = checked end
function Frame:GetChecked() return self.checked end
function Frame:SetEnabled(enabled) self.enabled = enabled end
function Frame:EnableKeyboard(enabled) self.keyboard = enabled end
function Frame:SetPropagateKeyboardInput(enabled) self.propagateKeyboard = enabled end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:UnregisterAllEvents() self.events = {} end
function Frame:IsShown() return self.shown end
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
function ToggleRun() nativeWalkCalls = nativeWalkCalls + 1 end
function hooksecurefunc(name, callback)
    secureHookCalls[name] = (secureHookCalls[name] or 0) + 1
    local original = _G[name]
    _G[name] = function(...)
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
}
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
    local frame = RetCinemaLetterbox
    if frame and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 1) end
end
assert(ns.icon == 136034 and not ns.db.enableAnimation and ns.db.letterboxHeight == 10)
assert(not ns.db.combinedAsEsc and not ns.db.showSecondBinding)
assert(not ns.db.triggerEnabled and not secureHookCalls.ToggleRun)
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
for index, name in ipairs({ "Effect", "|cff40c7ebLens|r", "Trigger", "Profiles", "Support" }) do
    assert(ns.settingsCategories.main.subcategories[index].name == name)
end
assert(not ns.settingsCategories.general)
local function page(id) return find(function(f) return f.pageId == id end) end
local function checkbox(content, text)
    return find(function(f) return f.kind == "CheckButton" and f.parent == content and f.label:GetText() == text end)
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
    assert(not button:IsShown() and not RetCinemaAdvancedDialog)
    advanced.scripts.OnEnter(advanced)
    assert(GameTooltip:GetText() == "|cffff8000Experimental|r. Allow access to additional options.")
    advanced:SetChecked(true); click(advanced)
    assert(ns.db.advancedCinematographer and button:IsShown() and not advanced.label:IsShown())
    click(button)
    local count = 0
    for _, child in ipairs(RetCinemaAdvancedDialog.children) do
        if child.kind == "CheckButton" then
            count = count + 1
            assert(not child.enabled and not child.scripts.OnClick and child.label.color[1] == 0.5 and child.label.color[2] == 0.5)
            child.scripts.OnEnter(child)
            assert(GameTooltip:GetText() == "Under consideration" and GameTooltip.tooltipColor[2] == 0.5)
        end
    end
    assert(count == 5)
    advanced:SetChecked(false); click(advanced)
    assert(not button:IsShown() and not RetCinemaAdvancedDialog:IsShown())
    for _, id in ipairs({ "fov", "smoothmotion" }) do assert(checks[id].label.color[1] == 0.5 and checks[id].label.color[2] == 0.5) end
end

effectTab(1)
local hideContent = page("hideui").content
local hidePermanent = checkbox(hideContent, "Permanent Hide UI")
assert(not hidePermanent.enabled and not hidePermanent.scripts.OnClick)
hidePermanent.scripts.OnEnter(hidePermanent)
assert(GameTooltip:GetText() == "Not sure yet you really need this :)")
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
assert(RetCinemaFOVSlider and not RetCinemaFOVSlider.enabled and not RetCinemaFOVSlider.scripts.OnValueChanged)
assert(not checkbox(page("fov").content, "Apply FOV to Lens").enabled)
assert(not checkbox(page("fov").content, "Permanent FOV").enabled)
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
for _, frame in ipairs(frames) do assert(frame.frameRole ~= "nextEffect" and frame.frameRole ~= "previousEffect") end
for _, frame in ipairs(frames) do assert(frame.frameRole ~= "effectRule") end
assert(current.menu and current.arrow and current:GetFontString().color[1] == 0.5)
click(current)
local letterChoice = find(function(f) return f.parent == current.menu and f.value == 2 end)
click(letterChoice)
assert(current.effectId == "letterbox" and page("letterbox"):IsShown() and current:GetFontString().color[2] == 0.82)
click(current)
local fovChoice = find(function(f) return f.parent == current.menu and f.value == 4 end)
assert(fovChoice:GetFontString().color[1] == 0.5)
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
for _, button in ipairs({ hide1, letter1, camera1 }) do assert(not button.parent.gear:IsShown()) end
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
    assert(GameTooltip:GetText() == "Can be enabled via /retcin " .. action.command)
end
find(function(f) return f.kind == "Frame" and f.parent == combined1.parent and f.scripts.OnEnter end).scripts.OnEnter(combined1.parent)
assert(GameTooltip:GetText() == "Can be enabled via /retcin combinedlens1")
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
    local add = find(function(f) return f.kind == "Button" and f.text == "+" end)
    assert(add:IsShown() and ns.GetCombinedCount() == 1)
    for count = 2, 5 do
        click(add)
        assert(ns.GetCombinedCount() == count)
        local firstRow = binding("RETCINEMA_COMBINED", 1).parent
        local row = binding(ns.CombinedBinding(count), 1).parent
        assert(firstRow.label:GetText() == "Combined Lens 1" and row.label:GetText() == "Combined Lens " .. count)
        assert(row.parent == combinedBox and binding(ns.CombinedBinding(count), 2):IsShown())
        assert(find(function(f) return f.parent == row and f.kind == "Texture" and f.points.TOPLEFT end))
        for _, action in ipairs(ns.actions) do
            local check = binding(action.binding, 1).parent.checks[count]
            assert(check and check:IsShown())
            check.scripts.OnEnter(check)
            assert(GameTooltip:GetText() == "Add " .. _G["BINDING_NAME_" .. action.binding] .. " to Combined Lens " .. count)
        end
    end
    assert(add:IsShown() and not add.enabled and not ns.AddCombinedLens())
    assert(find(function(f) return f.parent == lensContent and f.text == "Add to a specific Combined Lens" end))
    for _, action in ipairs(ns.actions) do
        local row = binding(action.binding, 1).parent
        for index = 1, 5 do
            local check = row.checks[index]
            assert(check.points.TOPLEFT[2] == -1)
            if index > 1 then assert(check.points.TOPLEFT[1] > row.checks[index - 1].points.TOPLEFT[1]) end
            if index == 2 then assert(check.points.TOPLEFT[1] - row.checks[1].points.TOPLEFT[1] == 46) end
            check:SetChecked(true); click(check)
            assert(ns.GetCombinedActions(index)[action.binding] and check:GetChecked())
            check:SetChecked(false); click(check)
            assert(not ns.GetCombinedActions(index)[action.binding] and not check:GetChecked())
        end
    end

    -- Per-Effect settings are built lazily and target additional lenses only.
    for _, button in ipairs({ hide1, letter1, camera1 }) do
        local row = button.parent
        assert(row.gear:IsShown() and row.gear.points.TOPLEFT[1] == row.checks[5])
    end
    click(letter1.parent.gear)
    local dialog = RetCinemaCombinedSettingsDialog
    assert(dialog:IsShown() and dialog.index == 2 and dialog.selector:GetText() == "Combined Lens 2")
    assert(dialog.controls.letterbox and not dialog.controls.camerashift)
    assert(not dialog.inherit and not dialog.member:IsShown() and RetCinemaCombinedBarHeightSlider.enabled)
    local function chooseLens(index)
        click(dialog.selector)
        for _, child in ipairs(dialog.selector.menu.children) do assert(child.value ~= 1) end
        click(find(function(f) return f.parent == dialog.selector.menu and f.value == index end))
        assert(dialog.index == index)
    end
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
    assert(letter1.parent.checks[2]:GetChecked() and binding("RETCINEMA_COMBINED2", 1).parent.summary:GetText() == "Letterbox")
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
    RetCinemaCombinedBarHeightInput:SetText("14")
    RetCinemaCombinedBarHeightInput.scripts.OnEnterPressed(RetCinemaCombinedBarHeightInput)
    letter1.parent.checks[3]:SetChecked(true); click(letter1.parent.checks[3])
    click(hide1.parent.gear)
    assert(dialog.noOptions:IsShown() and not dialog.inherit and not dialog.controls.letterbox:IsShown())
    chooseLens(2)
    dialog.member:SetChecked(true); click(dialog.member)
    assert(binding("RETCINEMA_COMBINED2", 1).parent.summary:GetText() == "HideUI, Letterbox, CameraShift")
    dialog.member:SetChecked(false); click(dialog.member)
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
    assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive(), "An intervening individual Lens makes this a first press again")
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
    assert(not ns.SetCombinedEffectCustom and not ns.SetCombinedEffectValue(1, "letterbox", 7))
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
    assert(remove:IsShown() and remove.enabled and not add.enabled)
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
    click(add)
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
    local version2 = export:gsub("PROFILE:5", "PROFILE:2"):gsub(";advancedCinematographer=true", "") .. ";enableAnimation=false"
    for _, field in ipairs({ "customLetterbox", "letterboxHeight", "customCameraShift", "cameraOffset" }) do
        version2 = version2:gsub(";extraCombinedLenses%.[2-5]%." .. field .. "=[^;]+", "")
    end
    version2 = version2:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    local legacyOK, legacyName = ns.Profiles.Import(version2)
    assert(legacyOK and ns.GetCombinedCount() == 5 and not ns.db.advancedCinematographer and not ns.db.enableAnimation)
    assert(ns.GetCombinedActions(2).RETCINEMA_CAMERA)
    assert(ns.GetCombinedEffectValue(2, "letterbox") == ns.db.letterboxHeight)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(legacyName))
    local version3 = export:gsub("PROFILE:5", "PROFILE:3")
    for _, field in ipairs({ "customLetterbox", "letterboxHeight", "customCameraShift", "cameraOffset" }) do
        version3 = version3:gsub(";extraCombinedLenses%.[2-5]%." .. field .. "=[^;]+", "")
    end
    version3 = version3:gsub(";triggerEnabled=false", ""):gsub(";triggerTarget=0", ""):gsub(";lensValuesVersion=1", "")
    local version3OK, version3Name = ns.Profiles.Import(version3)
    assert(version3OK and ns.db.advancedCinematographer)
    assert(ns.GetCombinedEffectValue(2, "camerashift") == ns.db.cameraOffset)
    assert(ns.Profiles.Activate(originalName) and ns.Profiles.Delete(version3Name))
    local version4 = export:gsub("PROFILE:5", "PROFILE:4")
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

-- Run/Walk Trigger reuses the native game action and never touches its bindings.
do
    assert(not RetCinemaTriggerPanel.content)
    SetBinding("NUMPADDIVIDE", "TOGGLERUN")
    local savedBefore = saved
    ToggleRun()
    assert(UIParent:IsShown() and not bars:IsShown())
    Settings.OpenToCategory(ns.settingsCategories.trigger:GetID())
    local trigger = RetCinemaTriggerPanel
    local enabled = checkbox(trigger.content, "Enable Trigger")
    local target = find(function(f) return f.frameRole == "triggerTarget" end)
    assert(trigger.content and trigger.events.UPDATE_BINDINGS and not enabled:GetChecked())
    local function choose(value)
        click(target)
        click(find(function(f) return f.parent == target.menu and f.value == value end))
    end
    enabled:SetChecked(true); click(enabled)
    assert(ns.db.triggerEnabled and secureHookCalls.ToggleRun == 1)
    ToggleRun(); assert(not UIParent:IsShown())
    ToggleRun(); assert(UIParent:IsShown())
    assert(bindings.NUMPADDIVIDE == "TOGGLERUN" and saved == savedBefore)
    choose(1)
    ToggleRun(); finishEffects(); assert(bars:IsShown())
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    ns.SetEffectEnabled("letterbox", false)
    local frameCount = #frames
    local walkBefore = nativeWalkCalls
    ToggleRun()
    assert(nativeWalkCalls == walkBefore + 1 and #frames == frameCount and not bars:IsShown())
    ns.SetEffectEnabled("letterbox", true)
    choose(4) -- Combined Lens 2
    ToggleRun(); finishEffects()
    assert(top.height == 75 and cvars.test_cameraOverShoulder == "3.4")
    ToggleRun(); finishEffects()
    assert(not bars:IsShown() and not ns.IsCameraShiftActive())
    choose(7) -- Combined Lens 5
    assert(ns.RemoveCombinedLens() and not ns.IsTriggerTargetAvailable())
    ToggleRun(); finishEffects(); assert(not bars:IsShown())
    assert(ns.AddCombinedLens() and ns.IsTriggerTargetAvailable() and bindings.J == "RETCINEMA_COMBINED5")
    ToggleRun(); finishEffects(); assert(bars:IsShown())
    pressEscape(); finishEffects()
    enabled:SetChecked(false); click(enabled)
    ToggleRun(); assert(not bars:IsShown() and UIParent:IsShown())
    assert(ns.SetTrigger(true, 0) and secureHookCalls.ToggleRun == 1)
    assert(ns.SetTrigger(false, 0) and not ns.SetTrigger(true, 8) and not ns.SetTrigger(true, 0.5))
    assert(bindings.NUMPADDIVIDE == "TOGGLERUN" and saved == savedBefore)
    Settings.OpenToCategory(ns.settingsCategories.main:GetID())
    assert(not trigger.events.UPDATE_BINDINGS and not trigger.scripts.OnUpdate)
    assert(next(events.events) == nil and not bars.scripts.OnUpdate and not bars.scripts.OnSizeChanged)
end
print("PASS: Run/Walk Trigger preserves native actions/bindings, gates hidden/disabled targets, installs once and performs no polling")

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
    assert(exported:find("RETCINEMA_PROFILE:5|Photo|", 1, true) == 1)
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
    local legacy = exported:gsub("PROFILE:5", "PROFILE:1")
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
        "return _G", exported:gsub("PROFILE:5", "PROFILE:9"),
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
    assert(exportString:find("RETCINEMA_PROFILE:5|UI Profile|", 1, true) == 1)
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
    assert(wish.points.TOPLEFT[2] < characterLabel.points.TOPLEFT[2] - 24)
    click(wish)
    assert(RetCinemaWishBoard:IsShown())
    local feature = find(function(f) return f.parent == RetCinemaWishBoard and f.kind == "Button" and f.text == "Trigger: Run/Walk" end)
    click(feature)
    assert(find(function(f) return f.parent == RetCinemaWishBoard and f.text == "Experimental Run/Walk integration is available in Trigger." end))
    RetCinemaWishBoard:Hide()
    RetCinema_OpenSettings()
    assert(RetCinemaSettingsPanel:IsShown() and not support:IsShown())
    for _, effect in ipairs(ns.effects) do ns.SetApplyToLens(effect.id, false) end
    ns.SetPermanentCameraShift(false)
    ns.SetPermanentLetterbox(false)
    finishEffects()
end
print("PASS: Profiles and Support child pages, profile dialogs/dropdowns, confirmed deletion and correct copy links")
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
