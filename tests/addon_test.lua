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
function Frame:SetText(text)
    self.text = text
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
    self.focused = false
    if focusedFrame == self then focusedFrame = nil end
end
function GetCurrentKeyBoardFocus() return focusedFrame end
function Frame:HighlightText() self.highlighted = true end
function Frame:CreateTexture() return CreateFrame("Texture", nil, self) end
function Frame:CreateFontString() return CreateFrame("FontString", nil, self) end
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
function hooksecurefunc(name, callback)
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
Settings = {
    RegisterCanvasLayoutCategory = function(panel)
        return { GetID = function() return 123 end }
    end,
    RegisterAddOnCategory = noop,
    OpenToCategory = function(id) assert(id == 123); RetCinemaSettingsPanel:Show() end,
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
local notes = assert(toc:read("*a"):match("## Notes: ([^\r\n]+)"))
toc:close()
function GetAddOnMetadata(_, field) assert(field == "Notes"); return notes end
C_AddOns = { GetAddOnMetadata = GetAddOnMetadata }
local ns = {}
assert(loadfile("ret_Cinema/Core.lua"))("ret_Cinema", ns)
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
assert(ns.icon == 136034 and ns.db.enableAnimation and ns.db.letterboxHeight == 10)
assert(not ns.db.combinedAsEsc and not ns.db.showSecondBinding)
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
ns.SetLetterboxAnimation(false)
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
RetCinema_ToggleLetterbox()
assert(top.height == 100 and not bars.scripts.OnUpdate)
ns.SetEffectEnabled("letterbox", false)
assert(not bars:IsShown() and not bars.scripts.OnUpdate and not bars.scripts.OnSizeChanged)
assert(not events.events.UI_SCALE_CHANGED)
RetCinema_ToggleLetterbox()
assert(not bars:IsShown())
ns.SetEffectEnabled("letterbox", true)
assert(bars.scripts.OnSizeChanged and not bars:IsShown())
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
ns.SetCameraConsent(true)

RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == "-2", "Starting a camera transition must not jump")
assert(RetCinemaCameraAnimator and RetCinemaCameraAnimator.scripts.OnUpdate)
RetCinemaCameraAnimator.scripts.OnUpdate(RetCinemaCameraAnimator, 0.175)
assert(math.abs(tonumber(cvars.test_cameraOverShoulder) + 0.25) < 0.001)
finishCamera()
assert(ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "1.5")
assert(cvars.CameraKeepCharacterCentered == "0" and cvars.CameraReduceUnexpectedMovement == "0")
ns.SetCameraOffset(-4.25)
finishCamera()
assert(ns.db.cameraOffset == -4.2 and cvars.test_cameraOverShoulder == "-4.2")
ns.SetCameraOffset(0)
finishCamera()
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
finishCamera()
assert(cvars.test_cameraOverShoulder == "3")
RetCinema_ToggleCameraShift()
finishCamera()
assert(not ns.IsCameraShiftActive() and cvars.test_cameraOverShoulder == "7", "Each activation must remember the live nonzero offset")
cvars.test_cameraOverShoulder = "-2"
ns.SetCameraOffset(1.5)
print("PASS: shoulder offset, rounding, motion-sickness settings, disable/re-enable, original camera restored")

for _, action in ipairs(ns.actions) do ns.SetCombinedAction(action.binding, true) end
assert(ns.GetCombinedCommands() == "/retcin hideui\n/retcin showletterbox\n/retcin camerashift")
RetCinema_ToggleCombined()
finishCamera()
assert(not UIParent:IsShown() and bars:IsShown() and ns.IsCameraShiftActive())
RetCinema_ToggleCombined()
finishCamera()
assert(UIParent:IsShown() and not bars:IsShown() and not ns.IsCameraShiftActive())
ns.SetEffectEnabled("camerashift", false)
assert(ns.GetCombinedCommands() == "/retcin hideui\n/retcin showletterbox")


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
finishCamera()
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
finishCamera()
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
assert(not bars:IsShown())
ns.SetCombinedAction("RETCINEMA_CAMERA", false)
RetCinema_ToggleCombined()
finishCamera()
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
finishCamera()
RetCinema_ToggleCameraShift()
finishCamera()
assert(cvars.test_cameraOverShoulder == "-2" and not RetCinemaCameraAnimator.scripts.OnUpdate)
print("PASS: Escape restores combined/individual effects, external hidden UI, original offsets, and unfinished transitions")

-- Only explicit input ends a mode; unrelated window closes and combat do not.
ns.SetLetterboxAnimation(true)
ns.SetCombinedAction("RETCINEMA_CAMERA", false)
RetCinema_ToggleCameraShift()
finishCamera()
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
ns.SetLetterboxAnimation(false)
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
    ns.SetLetterboxAnimation(true)
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
    SlashCmdList.RETCINEMA("combinedlens")
    assert(not UIParent:IsShown())
    SlashCmdList.RETCINEMA("combinedlens")
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

-- Settings pages are built lazily, in separate main and Effects tab groups.
SlashCmdList.RETCINEMA("")
assert(RetCinemaSettingsTab1:GetText() == "General" and RetCinemaSettingsTab2:GetText() == "Lens")
assert(RetCinemaSettingsTab1.points.TOPLEFT[2] == RetCinemaSettingsTab2.points.TOPLEFT[2])
assert(not RetCinemaBarHeightSlider and not RetCinemaCameraOffsetSlider and not RetCinemaSmoothMotionSlider)
for index, name in ipairs({ "HideUI", "Letterbox", "CameraShift", "SmoothMotion" }) do
    local tab = _G["RetCinemaSettingsTab" .. (index + 2)]
    assert(tab:GetText() == name and tab.points.TOPLEFT[2] < RetCinemaSettingsTab2.points.TOPLEFT[2])
end
local function page(id) return find(function(f) return f.pageId == id end) end
local function checkbox(content, text)
    return find(function(f) return f.kind == "CheckButton" and f.parent == content and f.label:GetText() == text end)
end
local function effectTab(index) click(_G["RetCinemaSettingsTab" .. (index + 2)]) end
local general = page("general").content
local checks = {}
for _, effect in ipairs(ns.effects) do
    checks[effect.id] = find(function(f) return f.kind == "CheckButton" and f.label:GetText() == effect.name end)
    checks[effect.id].scripts.OnEnter(checks[effect.id])
    assert(GameTooltip:GetText() == effect.description)
    assert(checks[effect.id].points.TOPLEFT[2] == -8)
end
assert(#ns.effects == 4 and ns.db.effects.lens == nil and ns.db.effects.keybindings == nil)
local description = find(function(f) return f.parent == general and f.text == notes end)
assert(description.fontSize == 18)
local oldNotes = notes
notes = "A new description from TOC"
page("general").refresh()
assert(description:GetText() == notes)
notes = oldNotes
page("general").refresh()
assert(find(function(f) return f.kind == "FontString" and f.text == ns.generalHint end))
assert(find(function(f) return f.kind == "FontString" and f.text == "Enable Effect modules:" end))
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
        click(find(function(f) return f.kind == "Button" and f.text == word end))
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
letterPermanent:SetChecked(true)
click(letterPermanent)
assert(RetCinemaPermanentBarHeightSlider and ns.db.permanentLetterbox)
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

-- Camera controls use the same layout and require explicit experimental-feature consent.
effectTab(3)
local cameraContent = page("camerashift").content
local cameraPermanent = checkbox(cameraContent, "Permanent CameraShift")
local cameraApply = checkbox(cameraContent, "Apply Effect to Lens")
local cameraConsent = checkbox(cameraContent, "Allow experimental camera features")
assert(cameraConsent:GetChecked() and cameraPermanent.enabled)
assert(RetCinemaBarHeightSlider.points.TOPLEFT[2] == RetCinemaCameraOffsetSlider.points.TOPLEFT[2])
cameraConsent:SetChecked(false)
click(cameraConsent)
assert(not ns.db.cameraConsent and not cameraPermanent.enabled and not RetCinemaCameraOffsetSlider.enabled)
cameraConsent:SetChecked(true)
click(cameraConsent)
cameraPermanent:SetChecked(true)
click(cameraPermanent)
assert(RetCinemaPermanentCameraOffsetSlider and ns.db.permanentCameraShift)
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
local smoothContent = page("smoothmotion").content
assert(RetCinemaSmoothMotionSlider and not RetCinemaSmoothMotionSlider.enabled)
assert(not RetCinemaSmoothMotionSlider.scripts.OnValueChanged and not RetCinemaSmoothMotionSlider.scripts.OnUpdate)
assert(not checkbox(smoothContent, "Apply Effect to Lens").enabled)
checks.smoothmotion:SetChecked(false)
click(checks.smoothmotion)
assert(not RetCinemaSettingsTab6:IsShown() and RetCinemaSettingsTab1.selected)
checks.smoothmotion:SetChecked(true)
click(checks.smoothmotion)
print("PASS: grouped Effects tabs, lazy permanent controls, editable values, TOC metadata, credits icon, planned Effects")

-- Lens lists Apply selections independently of the General runtime switches.
click(RetCinemaSettingsTab2)
local lensPage, lensContent = page("lens"), page("lens").content
local function binding(action, slot)
    return find(function(f) return f.action == action and f.slot == slot end)
end
local combined1, combined2 = binding("RETCINEMA_COMBINED", 1), binding("RETCINEMA_COMBINED", 2)
local hide1, hide2 = binding("RETCINEMA_HIDEUI", 1), binding("RETCINEMA_HIDEUI", 2)
local letter1, camera1 = binding("RETCINEMA_LETTERBOX", 1), binding("RETCINEMA_CAMERA", 1)
local combinedBox = combined1.parent.parent
assert(combined1.parent:GetHeight() == 74 and combined2:IsShown())
assert(not hide2:IsShown() and combined1:GetFontString().color[1] == 0.5)
assert(combinedBox.template == "BackdropTemplate")
assert(combinedBox.points.TOPLEFT[2] < camera1.parent.points.TOPLEFT[2] - camera1.parent:GetHeight())
local selector = find(function(f) return f.kind == "Button" and f.parent == combined1.parent and f.text == "Only added Lenses" end)
assert(selector.points.TOPLEFT[2] == combined2.points.TOPLEFT[2])
click(selector)
local all = find(function(f) return f.kind == "Button" and f.text == "All Lenses" and f.parent.parent == selector end)
click(all)
assert(ns.db.combinedAsEsc and selector:GetText() == "All Lenses")
click(selector)
local only = find(function(f) return f.kind == "Button" and f.text == "Only added Lenses" and f.parent.parent == selector end)
click(only)
assert(not ns.db.combinedAsEsc)
for _, action in ipairs(ns.actions) do
    local button = binding(action.binding, 1)
    local hover = find(function(f) return f.kind == "Frame" and f.parent == button.parent and f.scripts.OnEnter end)
    hover.scripts.OnEnter(hover)
    assert(GameTooltip:GetText() == "Can be enabled via /retcin " .. action.command)
end
find(function(f) return f.kind == "Frame" and f.parent == combined1.parent and f.scripts.OnEnter end).scripts.OnEnter(combined1.parent)
assert(GameTooltip:GetText() == "Can be enabled via /retcin combinedlens")
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
assert(letter1.parent:IsShown() and not letter1.enabled and not ns.IsEffectEnabled("letterbox"))
assert(RetCinemaSettingsTab2:IsShown(), "Lens is always available")
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
    button.parent.checkbox:SetChecked(false)
    click(button.parent.checkbox)
end
assert(not combinedBox:IsShown() and bindings.G == "RETCINEMA_COMBINED")
for _, effect in ipairs(ns.effects) do ns.SetApplyToLens(effect.id, false) end
assert(not hide1.parent:IsShown() and not letter1.parent:IsShown() and not camera1.parent:IsShown())
assert(find(function(f) return f.kind == "FontString" and f.parent == lensContent and f.text:find("Apply an Effect", 1, true) end):IsShown())
click(RetCinemaSettingsTab1)
assert(not lensPage.events.UPDATE_BINDINGS)
print("PASS: Lens membership, disabled Effect rows, two Combined slots, gray unbound keys, dropdown, commands, conflicts, combat")

-- Disabled effects stay idle; old profiles and interrupted camera snapshots migrate safely.
for _, effect in ipairs(ns.effects) do ns.SetEffectEnabled(effect.id, false) end
assert(next(events.events) == nil and not bars.scripts.OnUpdate and not RetCinemaCameraAnimator.scripts.OnUpdate)
assert(RetCinemaSettingsTab1:IsShown() and RetCinemaSettingsTab2:IsShown())
local frameCount = #frames
RetCinema_ToggleLetterbox()
RetCinema_RunBinding("RETCINEMA_CAMERA")
RetCinema_ToggleCombined()
assert(#frames == frameCount)
do
    ret_CinemaDB = {
        modules = { hideui = false, letterbox = false, camera = false, smoothmotion = false, keybindings = true },
        cameraRestore = { test_cameraOverShoulder = "-2", CameraKeepCharacterCentered = "1", CameraReduceUnexpectedMovement = "1" },
        hiddenCVars = { UnitNameNPC = "1", UnitNameEnemyPlayerName = "1" },
        cameraEnabled = true, showSecondBinding = true, combinedAsEsc = true,
    }
    cvars.test_cameraOverShoulder, cvars.CameraKeepCharacterCentered = "7", "0"
    cvars.UnitNameNPC, cvars.UnitNameEnemyPlayerName = "0", "0"
    local reloaded = {}
    assert(loadfile("ret_Cinema/Core.lua"))("ret_CinemaReload", reloaded)
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
