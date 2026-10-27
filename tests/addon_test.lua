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
function StaticPopup_Show(name)
    lastPopup = CreateFrame("Frame")
    lastPopup.editBox = CreateFrame("EditBox", nil, lastPopup)
    StaticPopupDialogs[name].OnShow(lastPopup)
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
function SetCVar(name, value) assert(cvars[name] ~= nil, "Unknown CVar"); cvars[name] = tostring(value); return true end
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
assert(ns.db.letterboxHeight == 17.6 and top.height == 176)
ns.SetLetterboxHeight(0)
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
ns.SetLetterboxHeight(10)
step(1)
RetCinema_ToggleLetterbox()
step(0.1)
ns.SetLetterboxAnimation(false)
assert(not bars:IsShown() and not bars.scripts.OnUpdate)
RetCinema_ToggleLetterbox()
assert(top.height == 100 and not bars.scripts.OnUpdate)
ns.SetModuleEnabled("letterbox", false)
assert(not bars:IsShown() and not bars.scripts.OnUpdate and not bars.scripts.OnSizeChanged)
assert(not events.events.UI_SCALE_CHANGED)
RetCinema_ToggleLetterbox()
assert(not bars:IsShown())
ns.SetModuleEnabled("letterbox", true)
assert(bars.scripts.OnSizeChanged and not bars:IsShown())
print("PASS: animation regression, lazy bars, module shutdown, no idle updates")

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
ns.SetModuleEnabled("hideui", false)
assert(UIParent:IsShown() and cvars.UnitNameNPC == "1" and not ns.db.hiddenCVars)
RetCinema_ToggleUI()
assert(UIParent:IsShown())
ns.SetModuleEnabled("hideui", true)
print("PASS: player/NPC/pet/focused names hidden, exact restoration, unsolicited UI shows and module disable")

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
ns.SetModuleEnabled("camerashift", false)
assert(cvars.test_cameraOverShoulder == "-2" and cvars.CameraKeepCharacterCentered == "1")
assert(not ns.db.cameraRestore and not events.events.PLAYER_LOGOUT)
RetCinema_ToggleCameraShift()
assert(cvars.test_cameraOverShoulder == "-2")
ns.SetModuleEnabled("camerashift", true)
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
ns.SetModuleEnabled("camerashift", false)
assert(ns.GetCombinedCommands() == "/retcin hideui\n/retcin showletterbox")
ns.SetModuleEnabled("keybindings", false)
assert(ns.IsModuleEnabled("keybindings"), "Keybindings must remain enabled while an action module is enabled")
RetCinema_ToggleCombined()
assert(not UIParent:IsShown() and bars:IsShown())
RetCinema_ToggleCombined()
assert(UIParent:IsShown() and not bars:IsShown())
SlashCmdList.RETCINEMA("hideui") -- Chat commands remain available independently of key capture.
assert(not UIParent:IsShown())
SlashCmdList.RETCINEMA("HIDEUI")
assert(UIParent:IsShown())
ns.SetModuleEnabled("keybindings", true)
ns.SetModuleEnabled("camerashift", true)
SlashCmdList.RETCINEMA("camerashift")
assert(ns.IsCameraShiftActive())
SlashCmdList.RETCINEMA("camerashift")
assert(not ns.IsCameraShiftActive())
finishCamera()
print("PASS: combined actions, renamed command, disabled actions excluded, automatic keybindings dependency")

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
print("PASS: zoom/window closes and combat keep modes active; Exit all smoothly exits uncombined effects")

local function click(frame, mouse)
    assert(frame.scripts.OnClick, "Missing click handler")(frame, mouse or "LeftButton")
end
local function find(predicate)
    for _, frame in ipairs(frames) do if predicate(frame) then return frame end end
    error("UI element not found")
end
SlashCmdList.RETCINEMA("")
assert(RetCinemaSettingsTab1.selected and RetCinemaSettingsTab6:GetText() == "Keybindings")
assert(not RetCinemaBarHeightSlider and not RetCinemaCameraOffsetSlider and not RetCinemaSmoothMotionSlider,
    "Unopened pages must not allocate controls")
assert(RetCinemaSettingsTab5:GetText() == "Smooth Motion")
assert(RetCinemaSettingsTab6.points.TOPLEFT[1] + RetCinemaSettingsTab6:GetWidth() <= RetCinemaSettingsPanel:GetWidth() - 16)
local description = find(function(f) return f.text == ns.GetDescription() end)
assert(description.fontSize == 18 and description.color[1] == 1)
local savedNotes = notes
notes = "Description changed in TOC metadata"
RetCinemaSettingsPanel:Hide()
RetCinemaSettingsPanel:Show()
assert(description:GetText() == notes)
notes = savedNotes
RetCinemaSettingsPanel:Hide()
RetCinemaSettingsPanel:Show()
assert(description:GetText() == savedNotes)
local general = description.parent
local creditLines = 0
for _, child in ipairs(general.children) do
    if child.kind == "Texture" and child.points.BOTTOMLEFT then creditLines = creditLines + 1 end
end
assert(creditLines == 2, "Credits must have two separator lines")
local made = find(function(f) return f.text == "Made by " end)
assert(made.fontSize == 24)
local feedback = find(function(f) return f.text == "Need bug fix or new feature? " end)
assert(feedback.points.BOTTOMLEFT[2] > 105)
click(find(function(f) return f.kind == "Button" and f.text == "Ask for it!" end))
assert(RetCinemaCopyDialog.editBox:GetText() == "https://github.com/retRodya/ret_Cinema/issues/new")
for _, word in ipairs({ "ret_", "Cinematic", "DynamicCam" }) do
    local link = find(function(f) return f.kind == "Button" and f.text == word end)
    click(link)
    assert(RetCinemaCopyDialog.editBox.focused and RetCinemaCopyDialog.editBox.highlighted)
    assert(RetCinemaCopyDialog.editBox:GetText():find("https://github.com/", 1, true))
end
RetCinemaCopyDialog:Hide()
local moduleCheckboxes = {}
for index, module in ipairs(ns.modules) do
    local label = find(function(f)
        return f.text == module.name and f.parent.kind == "CheckButton"
    end)
    local checkbox = label.parent
    moduleCheckboxes[module.id] = checkbox
    assert(checkbox.points.TOPLEFT[2] == -8 - math.floor((index - 1) / 4) * 34,
        "Module checkboxes wrap after four entries")
    if index % 4 == 1 then assert(checkbox.points.TOPLEFT[1] == 8) end
    checkbox.scripts.OnEnter(checkbox)
    assert(GameTooltip:GetText() == module.description)
end
assert(moduleCheckboxes.keybindings:GetChecked() and not moduleCheckboxes.keybindings.enabled)
assert(math.abs(moduleCheckboxes.letterbox.points.TOPLEFT[1] - moduleCheckboxes.hideui.points.TOPLEFT[1] - (general:GetWidth() - 16) / 4) < 0.001)
moduleCheckboxes.letterbox:SetChecked(false)
click(moduleCheckboxes.letterbox)
assert(not RetCinemaSettingsTab3:IsShown() and not ns.db.modules.letterbox)
moduleCheckboxes.letterbox:SetChecked(true)
click(moduleCheckboxes.letterbox)
assert(RetCinemaSettingsTab3:IsShown())
click(RetCinemaSettingsTab2)
assert(find(function(f) return f.text == ns.modules[1].description end).fontSize == 18)
assert(find(function(f) return f.text == "Assign a key in the Keybindings tab." end):GetFont())
click(RetCinemaSettingsTab3)
assert(RetCinemaBarHeightSlider)
local heightInput = RetCinemaBarHeightInput
heightInput:SetText("12,5%")
heightInput.scripts.OnEnterPressed(heightInput)
assert(ns.db.letterboxHeight == 12.5 and RetCinemaBarHeightSlider.value == 12.5)
heightInput:SetText("invalid")
heightInput.scripts.OnEnterPressed(heightInput)
assert(heightInput:GetText() == "12.5%" and ns.db.letterboxHeight == 12.5)
heightInput:SetText("99")
heightInput.scripts.OnEditFocusLost(heightInput)
assert(ns.db.letterboxHeight == 25)
heightInput:SetText("3")
heightInput.scripts.OnEscapePressed(heightInput)
assert(ns.db.letterboxHeight == 25 and heightInput:GetText() == "25%")
assert(not ns.SetLetterboxHeight(math.huge) and not ns.SetLetterboxHeight(0/0))
assert(find(function(f) return f.text == "Frame your view with cinematic letterboxes." end).fontSize == 18)
assert(find(function(f) return f.text == "Letterboxes - black bars at the top and bottom of the screen." end).fontSize == nil)
local animation = find(function(f) return f.text == "Enable animation" end).parent
local letterAlways = find(function(f)
    return f.text == "Always On" and f.parent.parent == animation.parent
end).parent
assert(not letterAlways.enabled and not letterAlways:GetChecked() and not letterAlways.scripts.OnClick)
letterAlways.scripts.OnEnter(letterAlways)
assert(GameTooltip:GetText():find("Under consideration", 1, true))
animation:SetChecked(true)
click(animation)
assert(ns.db.enableAnimation)
click(RetCinemaSettingsTab4)
local cameraControls = RetCinemaCameraOffsetSlider.parent
assert(cameraControls.points.TOPLEFT[2] + RetCinemaCameraOffsetSlider.points.TOPLEFT[2] == RetCinemaBarHeightSlider.points.TOPLEFT[2])
assert(RetCinemaSettingsTab4:GetText() == "Camera Shift" and cameraControls:IsShown())
local cameraAlways = find(function(f)
    return f.text == "Always On" and f.parent.parent == cameraControls.parent
end).parent
assert(not cameraAlways.enabled and not cameraAlways:GetChecked() and not cameraAlways.scripts.OnClick)
assert(not ns.IsCameraShiftActive())
RetCinemaCameraOffsetSlider:SetValue(4.5)
assert(cvars.test_cameraOverShoulder == "-2", "An inactive slider configures the next activation")
RetCinema_ToggleCameraShift()
finishCamera()
assert(cvars.test_cameraOverShoulder == "4.5")
RetCinema_ToggleCameraShift()
finishCamera()
assert(cvars.test_cameraOverShoulder == "-2" and cameraControls:IsShown())
local offsetInput = RetCinemaCameraOffsetInput
assert(offsetInput.kind == "EditBox" and offsetInput:GetText() == "4.5")
offsetInput:SetText("-6,7")
offsetInput.scripts.OnEnterPressed(offsetInput)
assert(ns.db.cameraOffset == -6.7 and RetCinemaCameraOffsetSlider.value == -6.7)
offsetInput:SetText("bad input")
offsetInput.scripts.OnEnterPressed(offsetInput)
assert(ns.db.cameraOffset == -6.7 and offsetInput:GetText() == "-6.7")
offsetInput:SetText("99")
offsetInput.scripts.OnEditFocusLost(offsetInput)
assert(ns.db.cameraOffset == 15 and offsetInput:GetText() == "15.0")
offsetInput:SetText("-99")
offsetInput.scripts.OnEditFocusLost(offsetInput)
assert(ns.db.cameraOffset == -15)
offsetInput:SetText("3")
offsetInput.scripts.OnEscapePressed(offsetInput)
assert(ns.db.cameraOffset == -15 and offsetInput:GetText() == "-15.0")
assert(not ns.SetCameraOffset(0/0) and not ns.SetCameraOffset(math.huge))
ns.SetCameraOffset(1.5)
click(RetCinemaSettingsTab5)
assert(RetCinemaSmoothMotionSlider and not RetCinemaSmoothMotionSlider.enabled)
assert(not RetCinemaSmoothMotionSlider.scripts.OnValueChanged and not RetCinemaSmoothMotionSlider.scripts.OnUpdate)
local smoothPage = RetCinemaSmoothMotionSlider.parent.parent.parent
assert(smoothPage.kind == "ScrollFrame" and next(smoothPage.events) == nil)
assert(find(function(f) return f.text == "Under development." and f.kind == "FontString" end))
local smoothEnable = find(function(f) return f.text == "Enable Smooth Motion" end).parent
assert(not smoothEnable.enabled and not smoothEnable:GetChecked() and not smoothEnable.scripts.OnClick)
moduleCheckboxes.smoothmotion:SetChecked(false)
click(moduleCheckboxes.smoothmotion)
assert(not RetCinemaSettingsTab5:IsShown() and RetCinemaSettingsTab1.selected)
moduleCheckboxes.smoothmotion:SetChecked(true)
click(moduleCheckboxes.smoothmotion)
assert(RetCinemaSettingsTab5:IsShown())
print("PASS: six tabs, lazy settings, module tooltips, linked feedback/credits, inert planned controls")

click(RetCinemaSettingsTab6)
assert(find(function(f) return f.kind == "FontString" and f.text == "Assign keys to Modules." end).fontSize == 18)
assert(find(function(f) return f.text == ns.modules[5].hint end))
local combined1 = find(function(f) return f.action == "RETCINEMA_COMBINED" and f.slot == 1 end)
local combined2 = find(function(f) return f.action == "RETCINEMA_COMBINED" and f.slot == 2 end)
local hide1 = find(function(f) return f.action == "RETCINEMA_HIDEUI" and f.slot == 1 end)
local letter1 = find(function(f) return f.action == "RETCINEMA_LETTERBOX" and f.slot == 1 end)
local camera1 = find(function(f) return f.action == "RETCINEMA_CAMERA" and f.slot == 1 end)
local macroLabel = find(function(f) return f.kind == "FontString" and f.text == ns.GetCombinedCommands() end)
assert(combined1.parent:IsShown() and macroLabel.kind == "FontString")
local combinedContainer = combined1.parent.parent
assert(combinedContainer.template == "BackdropTemplate")
assert(combinedContainer.points.TOPLEFT[2] < camera1.parent.points.TOPLEFT[2] - camera1.parent:GetHeight())
assert(combined1:GetWidth() == 156 and hide1:GetWidth() == 156)
local tooltipArea = find(function(f) return f.parent == combined1.parent and f.scripts.OnEnter and f.kind == "Frame" end)
tooltipArea.scripts.OnEnter(tooltipArea)
assert(GameTooltip:GetText() == "One Key for all Combined modules above")
local topDivider = find(function(f)
    return f.kind == "Texture" and f.parent == hide1.parent.parent and f.points.TOPLEFT
end)
assert(topDivider.points.TOPLEFT[2] > hide1.parent.points.TOPLEFT[2])
assert(find(function(f) return f.text == "or use marcro commands below:" end))
assert(find(function(f) return f.text == "Module" and f.kind == "FontString" end))
assert(find(function(f) return f.text == "Combined Key" and f.kind == "FontString" end).fontSize == 14)
assert(not combined2:IsShown())
assert(not combined1.parent.orLabel:IsShown() and combined1.parent:GetHeight() == 26)
assert(not RetCinemaSecondBindingCheckbox and not RetCinemaCombinedAsEscCheckbox)
local moduleHeadings, keyHeadings = 0, 0
for _, frame in ipairs(frames) do
    if frame.kind == "FontString" then
        if frame.text == "Module" then moduleHeadings = moduleHeadings + 1 end
        if frame.text == "Key" then keyHeadings = keyHeadings + 1 end
        assert(frame.text ~= "Key 1" and frame.text ~= "Key 2" and frame.text ~= "As Esc")
    end
end
assert(moduleHeadings == 2 and keyHeadings == 2)
local exitHeader = find(function(f) return f.kind == "FontString" and f.text == "Exit all" end)
local moduleHeader = find(function(f) return f.kind == "FontString" and f.text == "Combined" end)
assert(exitHeader.parent ~= moduleHeader.parent and exitHeader.parent:IsShown())
assert(find(function(f) return f.kind == "FontString" and f.text == "Show Letterbox" end))
for _, button in ipairs({ hide1, letter1, camera1 }) do
    assert(find(function(f) return f.kind == "Texture" and f.parent == button.parent and f.points.BOTTOMLEFT end))
end
local macroDivider = find(function(f)
    return f.kind == "Texture" and f.parent == combined1.parent.parent and f.points.TOPLEFT
end)
assert(macroDivider.points.TOPLEFT[2] < macroLabel.parent.points.TOPLEFT[2] - macroLabel.parent:GetHeight())
local macroTop = macroLabel.parent.points.TOPLEFT[2]
RetCinemaExitAllCheckbox:SetChecked(true)
click(RetCinemaExitAllCheckbox)
assert(ns.db.combinedAsEsc)
RetCinemaExitAllCheckbox.scripts.OnEnter(RetCinemaExitAllCheckbox)
assert(GameTooltip:GetText():find("even those not included in Combined Key", 1, true))
click(find(function(f) return f.kind == "Button" and f.text == "Copy macro text" end))
assert(RetCinemaCopyDialog.editBox:GetText() == ns.GetCombinedCommands())
RetCinemaCopyDialog.editBox:SetText("edited")
assert(RetCinemaCopyDialog.editBox:GetText() == ns.GetCombinedCommands())
assert(RetCinemaCopyDialog.title.justifyH == "CENTER")
assert(find(function(f) return f.text == "Press Ctrl+C to copy and close." end))
local copyField = RetCinemaCopyDialog.editBox
copyField.scripts.OnKeyDown(copyField, "C")
copyField.scripts.OnKeyUp(copyField, "C")
assert(RetCinemaCopyDialog:IsShown(), "C without Control must not close the dialog")
modifiers = { ctrl = true }
copyField.scripts.OnKeyDown(copyField, "C")
assert(RetCinemaCopyDialog:IsShown(), "Keep the field focused until native clipboard handling finishes")
modifiers = {}
copyField.scripts.OnKeyUp(copyField, "C")
assert(not RetCinemaCopyDialog:IsShown() and not copyField.focused)
SetBinding("ALT-CTRL-F", "RETCINEMA_HIDEUI")
click(combined1)
modifiers = { alt = true, ctrl = true }
combined1.scripts.OnKeyDown(combined1, "F")
modifiers = {}
assert(bindings["ALT-CTRL-F"] == "RETCINEMA_COMBINED" and saved == 1)
assert(combined2:IsShown() and combined1.parent.orLabel:IsShown())
assert(combined2.points.TOPLEFT[1] == combined1.points.TOPLEFT[1])
assert(combined2.points.TOPLEFT[2] < combined1.points.TOPLEFT[2])
assert(combined1.parent.orLabel.justifyH == "CENTER")
assert(macroLabel.parent.points.TOPLEFT[2] == macroTop - 48, "Macro must move below the second binding")
local status = find(function(f) return f.text and f.text:find("reassigned from", 1, true) end)
assert(status.fontSize == 18 and status.color[1] == 1)
click(combined2)
combined2.scripts.OnKeyDown(combined2, "G")
assert(bindings.G == "RETCINEMA_COMBINED")
click(combined1, "RightButton")
assert(not bindings["ALT-CTRL-F"] and bindings.G == "RETCINEMA_COMBINED")
assert(combined1:GetText() == "G" and combined2:IsShown(), "Remaining key becomes primary")
click(combined1, "RightButton")
assert(not combined2:IsShown() and not combined1.parent.orLabel:IsShown())
assert(macroLabel.parent.points.TOPLEFT[2] == macroTop)
click(combined1)
combined1.scripts.OnKeyDown(combined1, "G")
assert(combined2:IsShown())
local letterTop = letter1.parent.points.TOPLEFT[2]
click(camera1)
camera1.scripts.OnKeyDown(camera1, "C")
assert(bindings.C == "RETCINEMA_CAMERA")
assert(camera1.parent.orLabel:IsShown() and letter1.parent.points.TOPLEFT[2] == letterTop)
assert(combinedContainer.points.TOPLEFT[2] < camera1.parent.points.TOPLEFT[2] - camera1.parent:GetHeight())
click(combined1)
combined1.scripts.OnKeyDown(combined1, "ESCAPE")
assert(not combined1.keyboard)
click(combined1)
combat = true
local keyPage = hide1.parent.parent.parent
assert(keyPage.kind == "ScrollFrame")
keyPage.scripts.OnEvent(keyPage, "PLAYER_REGEN_DISABLED")
assert(not combined1.keyboard and not combined1.enabled)
combat = false
keyPage.scripts.OnEvent(keyPage, "PLAYER_REGEN_ENABLED")
assert(combined1.enabled)
for _, rowButton in ipairs({ hide1, letter1, camera1 }) do
    rowButton.parent.checkbox:SetChecked(false)
    click(rowButton.parent.checkbox)
end
assert(not combined1.parent:IsShown() and not macroLabel.parent:IsShown())
assert(not combinedContainer:IsShown())
assert(not exitHeader.parent:IsShown() and not macroDivider:IsShown())
assert(moduleHeader.parent.points.TOPLEFT[2] == -84)
assert(bindings.G == "RETCINEMA_COMBINED")
click(combined2)
ns.SetModuleEnabled("keybindings", false)
assert(ns.IsModuleEnabled("keybindings"))
ns.SetModuleEnabled("hideui", false)
ns.SetModuleEnabled("letterbox", false)
ns.SetModuleEnabled("camerashift", false)
assert(not combined2.keyboard and not keyPage.events.UPDATE_BINDINGS)
assert(RetCinemaSettingsTab1.selected and not RetCinemaSettingsTab6:IsShown())
assert(not moduleCheckboxes.keybindings:IsShown() and not moduleCheckboxes.keybindings:GetChecked())
moduleCheckboxes.hideui:SetChecked(true)
click(moduleCheckboxes.hideui)
assert(moduleCheckboxes.keybindings:IsShown() and moduleCheckboxes.keybindings:GetChecked() and not moduleCheckboxes.keybindings.enabled)
moduleCheckboxes.hideui:SetChecked(false)
click(moduleCheckboxes.hideui)
assert(not moduleCheckboxes.keybindings:IsShown())
print("PASS: static macro preview/copy button, camera binding, larger status, conflicts, combat, disabled-page cleanup")

-- Disabling every module leaves no module events or animation callbacks.
for _, module in ipairs(ns.modules) do ns.SetModuleEnabled(module.id, false) end
assert(next(events.events) == nil and not bars.scripts.OnUpdate)
local frameCount = #frames
RetCinema_RunBinding("RETCINEMA_CAMERA")
RetCinema_ToggleCombined()
RetCinema_ToggleLetterbox()
assert(#frames == frameCount)
-- Simulate reload with an interrupted screenshot and camera override.
ns.db.hiddenCVars = { UnitNameNPC = "1", UnitNameEnemyPlayerName = "1" }
cvars.UnitNameNPC, cvars.UnitNameEnemyPlayerName = "0", "0"
ns.db.cameraRestore = { test_cameraOverShoulder = "-2", CameraKeepCharacterCentered = "1" }
cvars.test_cameraOverShoulder, cvars.CameraKeepCharacterCentered = "7", "0"
-- A pre-rename profile must keep its disabled Camera choice and derive Keybindings.
ns.db.modules.camerashift, ns.db.modules.camera = nil, false
ns.db.modules.keybindings = true
ns.db.cameraEnabled = true
ns.db.showSecondBinding = true -- Obsolete global preference is migrated away.
local reloaded = {}
assert(loadfile("ret_Cinema/Core.lua"))("ret_CinemaReload", reloaded)
local reloadEvents = frames[#frames]
assert(loadfile("ret_Cinema/Options.lua"))("ret_CinemaReload", reloaded)
reloadEvents.scripts.OnEvent(reloadEvents, "ADDON_LOADED", "ret_CinemaReload")
assert(cvars.UnitNameNPC == "1" and cvars.UnitNameEnemyPlayerName == "1")
assert(cvars.test_cameraOverShoulder == "-2" and cvars.CameraKeepCharacterCentered == "1")
assert(not reloaded.db.hiddenCVars and not reloaded.db.cameraRestore)
assert(reloaded.db.modules.camera == nil and reloaded.db.cameraEnabled == nil)
assert(not reloaded.IsCameraShiftActive())
assert(reloaded.db.combinedAsEsc and reloaded.db.showSecondBinding == nil)
for _, module in ipairs(reloaded.modules) do assert(not reloaded.db.modules[module.id]) end
assert(next(reloadEvents.events) == nil)
print("PASS: disabled modules idle, preferences survive reload, interrupted name/camera overrides recovered")
