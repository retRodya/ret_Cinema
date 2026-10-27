local _, ns = ...
local panel, category, built
local pages, tabs, bindingButtons = {}, {}, {}
local listening, bindingStatus, bindingLayout
local selectedTab = 1
local builders = {}
local copyDialog
local linkFonts = {}
local DESCRIPTION_FONT_SCALE = 1.5
local BINDING_BUTTON_WIDTH = 156
local tabSpecs = { { id = "general", name = "General" }, { id = "lens", name = "Lens" } }
for _, effect in ipairs(ns.effects) do tabSpecs[#tabSpecs + 1] = effect end

local function LargeYellow(label, scale)
    local font, size, flags = label:GetFont()
    label:SetFont(font, size * (scale or 2), flags)
    label:SetTextColor(1, 0.82, 0)
    label:SetWordWrap(true)
    return label
end

local function Label(parent, text, font, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x or 0, y or 0)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Button(parent, text, width, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function Tooltip(frame, text)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text, 1, 0.82, 0, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Divider(parent, point, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.6, 0.6, 0.6, 0.3)
    line:SetHeight(1)
    line:SetPoint(point .. "LEFT", 0, y)
    line:SetPoint(point .. "RIGHT", 0, y)
    return line
end

local function MakeReadOnly(editBox)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= self.readOnlyText then
            self:SetText(self.readOnlyText or "")
        end
    end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
end

local function CopyText(title, text)
    if not copyDialog then
        copyDialog = CreateFrame("Frame", "RetCinemaCopyDialog", UIParent, "BackdropTemplate")
        copyDialog:SetSize(480, 210)
        copyDialog:SetPoint("CENTER")
        copyDialog:SetFrameStrata("DIALOG")
        copyDialog:EnableMouse(true)
        copyDialog:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
            edgeSize = 32, insets = { left = 10, right = 10, top = 10, bottom = 10 } })
        copyDialog.title = Label(copyDialog, "", "GameFontNormalLarge", 24, -22)
        copyDialog.title:SetPoint("TOPRIGHT", -24, -22)
        copyDialog.title:SetJustifyH("CENTER")
        Label(copyDialog, "Press Ctrl+C to copy and close.", "GameFontNormal", 24, -50)
        local editBox = CreateFrame("EditBox", nil, copyDialog)
        copyDialog.editBox = editBox
        editBox:SetMultiLine(true)
        editBox:SetFontObject("GameFontHighlight")
        editBox:SetPoint("TOPLEFT", 24, -80)
        editBox:SetSize(430, 76)
        MakeReadOnly(editBox)
        editBox:SetScript("OnEscapePressed", function() copyDialog:Hide() end)
        editBox:SetScript("OnKeyDown", function(self, key)
            if key == "C" and IsControlKeyDown() then self.copyPending = true end
        end)
        -- Native clipboard handling runs on key-down. Close on key-up, after the copy.
        editBox:SetScript("OnKeyUp", function(self, key)
            if key == "C" and self.copyPending then copyDialog:Hide() end
        end)
        copyDialog:SetScript("OnHide", function()
            editBox.copyPending = nil
            editBox:ClearFocus()
        end)
        Button(copyDialog, CLOSE, 100, 190, -168, function() copyDialog:Hide() end)
    end
    copyDialog.title:SetText(title)
    copyDialog.editBox.copyPending = nil
    copyDialog.editBox.readOnlyText = text
    copyDialog.editBox:SetText(text)
    copyDialog:Show()
    copyDialog.editBox:SetFocus()
    copyDialog.editBox:HighlightText()
end

local function WordLink(parent, word, url, large)
    local button = CreateFrame("Button", nil, parent)
    local fontName = large and "RetCinemaLargeLinkFont" or "RetCinemaLinkFont"
    if not linkFonts[fontName] then
        local font = CreateFont(fontName)
        font:SetFontObject("GameFontHighlight")
        local path, size, flags = font:GetFont()
        font:SetFont(path, size * (large and 2 or 1), flags)
        font:SetTextColor(0.25, 0.78, 0.92)
        linkFonts[fontName] = font
    end
    button:SetNormalFontObject(linkFonts[fontName])
    button:SetHighlightFontObject(linkFonts[fontName])
    button:SetText(word)
    local text = button:GetFontString()
    text:SetTextColor(0.25, 0.78, 0.92)
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT")
    button:SetSize(text:GetStringWidth(), text:GetStringHeight() + 3)
    local underline = button:CreateTexture(nil, "ARTWORK")
    underline:SetColorTexture(0.25, 0.78, 0.92, 1)
    underline:SetHeight(1)
    underline:SetPoint("BOTTOMLEFT")
    underline:SetPoint("BOTTOMRIGHT")
    button:SetScript("OnClick", function() CopyText(word, url) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(url, 0.25, 0.78, 0.92)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function RefreshBindings()
    for _, button in ipairs(bindingButtons) do
        local key = select(button.slot, GetBindingKey(button.action))
        button:SetText(button == listening and "Press a key..." or
            (key and GetBindingText(key) or "Not bound"))
        local unbound = not key and button ~= listening
        button:SetNormalFontObject(unbound and "GameFontDisable" or "GameFontNormal")
        button:SetHighlightFontObject(unbound and "GameFontDisable" or "GameFontHighlight")
        button:GetFontString():SetTextColor(unbound and 0.5 or 1, unbound and 0.5 or 0.82, unbound and 0.5 or 0)
        button:SetEnabled(not InCombatLockdown() and (not button.effect or
            (ns.IsEffectEnabled(button.effect) and ns.IsAppliedToLens(button.effect))))
        button:SetShown(button.slot == 1 or button.action == "RETCINEMA_COMBINED" or GetBindingKey(button.action) ~= nil)
    end
    if bindingLayout then bindingLayout() end
end

local function StopListening()
    if listening then
        listening:EnableKeyboard(false)
        listening:UnlockHighlight()
        listening = nil
    end
    RefreshBindings()
end

local function AssignKey(button, key)
    StopListening()
    if InCombatLockdown() then
        bindingStatus:SetText("Lens buttons cannot be changed in combat.")
        return
    end
    local keys = { GetBindingKey(button.action) }
    local previous = key and GetBindingAction(key) or ""
    local restore, wanted = {}, {}
    for _, old in ipairs(keys) do restore[old] = button.action end
    if key then restore[key] = previous end
    for i = 1, math.max(#keys, button.slot) do
        local value = keys[i]
        if i == button.slot then value = key end
        if value and (i == button.slot or value ~= key) then
            wanted[#wanted + 1] = value
        end
    end
    local ok = true
    for _, old in ipairs(keys) do
        if not SetBinding(old) then ok = false; break end
    end
    if ok then
        for _, value in ipairs(wanted) do
            if not SetBinding(value, button.action) then ok = false; break end
        end
    end
    if not ok then
        for value, action in pairs(restore) do
            SetBinding(value, action ~= "" and action or nil)
        end
        bindingStatus:SetText("Could not assign this key. Try another key.")
    else
        SaveBindings(GetCurrentBindingSet())
        if previous ~= "" and previous ~= button.action then
            local name = _G["BINDING_NAME_" .. previous] or previous
            bindingStatus:SetText(GetBindingText(key) .. " reassigned from " .. name .. ".")
        else
            bindingStatus:SetText(key and "Lens button saved." or "Lens button cleared.")
        end
    end
    RefreshBindings()
end

local ignoredKeys = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true, UNKNOWN = true,
}

local function CreateBindingButton(parent, action, slot, x, y)
    local button = Button(parent, "Not bound", BINDING_BUTTON_WIDTH, x, y, function(self, mouseButton)
        if InCombatLockdown() then return end
        if mouseButton == "RightButton" then
            AssignKey(self, nil)
        elseif listening == self then
            StopListening()
        else
            local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
            if focus then focus:ClearFocus() end
            StopListening()
            listening = self
            self:EnableKeyboard(true)
            self:SetPropagateKeyboardInput(false)
            self:LockHighlight()
            RefreshBindings()
        end
    end)
    button.action, button.slot = action, slot
    button.effect = parent.effect
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnKeyDown", function(self, key)
        if self ~= listening then return end
        if key == "ESCAPE" then
            StopListening()
        elseif not ignoredKeys[key] then
            if IsShiftKeyDown() then key = "SHIFT-" .. key end
            if IsControlKeyDown() then key = "CTRL-" .. key end
            if IsAltKeyDown() then key = "ALT-" .. key end
            AssignKey(self, key)
        end
    end)
    button:EnableKeyboard(false)
    bindingButtons[#bindingButtons + 1] = button
end

local function PageDescription(content, text)
    local label = LargeYellow(Label(content, text, "GameFontHighlight", 0, 0), DESCRIPTION_FONT_SCALE)
    label:SetPoint("TOPRIGHT")
    return label
end

local function EffectDescription(content, effect)
    local description = PageDescription(content, effect.description)
    if effect.hint then
        local hint = Label(content, effect.hint, "GameFontNormal", 0, 0)
        hint:ClearAllPoints()
        hint:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16)
        hint:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT", 0, -16)
        hint:SetWordWrap(true)
    end
    return description
end

local function Checkbox(parent, text, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetSize(28, 28)
    checkbox.label = Label(checkbox, text, "GameFontHighlight", 30, -6)
    checkbox:SetScript("OnClick", onClick)
    return checkbox
end

local function PlannedPermanent(parent, text, y)
    local checkbox = Checkbox(parent, text, -4, y)
    checkbox:SetChecked(false)
    checkbox:SetEnabled(false)
    checkbox.label:SetTextColor(0.5, 0.5, 0.5)
    checkbox:SetMotionScriptsWhileDisabled(true)
    Tooltip(checkbox, "Not sure yet you really need this :)")
    return checkbox
end

local function FramedBox(parent, y, height)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 0, y)
    box:SetPoint("TOPRIGHT", 0, y)
    box:SetHeight(height)
    box:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16,
        edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    box:SetBackdropColor(0, 0, 0, 0.35)
    box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    return box
end

local function NumericControl(parent, name, title, minimum, maximum, suffix, getValue, setValue)
    local control = CreateFrame("Frame", nil, parent)
    control:SetPoint("TOPLEFT")
    control:SetPoint("TOPRIGHT")
    control:SetHeight(94)
    Label(control, title, "GameFontNormal", 0, 0)
    local slider = CreateFrame("Slider", name .. "Slider", control, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 4, -40)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(0.1)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "SliderLow"]:SetText(minimum .. suffix)
    _G[name .. "SliderHigh"]:SetText(maximum .. suffix)
    local value = CreateFrame("EditBox", name .. "Input", control, "InputBoxTemplate")
    value:SetPoint("TOPLEFT", 355, -36)
    value:SetSize(70, 24)
    value:SetAutoFocus(false)
    value:SetMaxLetters(12)
    local function ShowValue() value:SetText(string.format("%g", getValue()) .. suffix) end
    value:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    local function Commit(self)
        local number = tonumber((self:GetText():gsub("%%", ""):gsub(",", ".")))
        if setValue(number) then slider:SetValue(getValue()) end
        ShowValue()
    end
    value:SetScript("OnEnterPressed", function(self) Commit(self); self:ClearFocus() end)
    value:SetScript("OnEditFocusLost", Commit)
    value:SetScript("OnEscapePressed", function(self) ShowValue(); self:ClearFocus() end)
    slider:SetScript("OnValueChanged", function(_, number) setValue(number); ShowValue() end)
    control.refresh = function(enabled)
        slider:SetEnabled(enabled ~= false)
        value:SetEnabled(enabled ~= false)
        slider:SetValue(getValue())
        ShowValue()
    end
    return control
end

builders.general = function(page, content)
    local description = EffectDescription(content, { description = ns.GetDescription(), hint = ns.generalHint })
    local minimap = Checkbox(content, "Show minimap icon", -4, -104,
        function(self) ns.SetMinimapButton(self:GetChecked()) end)
    Label(content, "Enable Effect modules:", "GameFontNormal", 0, -150)
    local box = FramedBox(content, -176, 50)
    local checks = {}
    for _, effect in ipairs(ns.effects) do
        local checkbox = Checkbox(box, effect.name, 8, -8,
            function(self) ns.SetEffectEnabled(effect.id, self:GetChecked()) end)
        Tooltip(checkbox, effect.description)
        checks[effect.id] = checkbox
    end
    page.layoutEffects = function()
        local cellWidth = math.max(1, (content:GetWidth() - 16) / 4)
        for index, effect in ipairs(ns.effects) do
            local checkbox = checks[effect.id]
            checkbox:SetChecked(ns.IsEffectEnabled(effect.id))
            checkbox:ClearAllPoints()
            checkbox:SetPoint("TOPLEFT", 8 + (index - 1) % 4 * cellWidth, -8 - math.floor((index - 1) / 4) * 34)
        end
        box:SetHeight(16 + math.max(1, math.ceil(#ns.effects / 4)) * 34)
    end
    local feedback = Label(content, "Need bug fix or new feature? ", "GameFontNormal", 0, 0)
    feedback:ClearAllPoints()
    feedback:SetPoint("BOTTOMLEFT", 0, 132)
    local ask = WordLink(content, "Ask for it!", "https://github.com/retRodya/ret_Cinema/issues/new")
    ask:SetPoint("TOPLEFT", feedback, "TOPRIGHT", 0, 0)
    Divider(content, "BOTTOM", 100)
    Divider(content, "BOTTOM", 105)
    local icon = content:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.icon)
    icon:SetSize(64, 64)
    icon:SetPoint("BOTTOMLEFT", 0, 24)
    local made = LargeYellow(Label(content, "Made by ", "GameFontHighlight", 0, 0))
    made:ClearAllPoints()
    made:SetPoint("BOTTOMLEFT", 84, 62)
    local author = WordLink(content, "ret_", "https://github.com/retRodya/ret_Cinema", true)
    author:SetPoint("TOPLEFT", made, "TOPRIGHT", 0, 0)
    local inspired = Label(content, "Inspired by ", "GameFontNormal", 0, 0)
    inspired:ClearAllPoints()
    inspired:SetPoint("BOTTOMLEFT", 84, 28)
    local cinematic = WordLink(content, "Cinematic", "https://github.com/andrewcasals/Cinematic")
    cinematic:SetPoint("TOPLEFT", inspired, "TOPRIGHT", 0, 0)
    local andText = Label(content, " and ", "GameFontNormal", 0, 0)
    andText:ClearAllPoints()
    andText:SetPoint("TOPLEFT", cinematic, "TOPRIGHT", 0, 0)
    local dynamicCam = WordLink(content, "DynamicCam", "https://github.com/Mpstark/DynamicCam")
    dynamicCam:SetPoint("TOPLEFT", andText, "TOPRIGHT", 0, 0)
    content:SetHeight(480)
    page.refresh = function()
        description:SetText(ns.GetDescription())
        minimap:SetChecked(ns.db.showMinimapButton)
        page.layoutEffects()
    end
end

builders.hideui = function(page, content)
    EffectDescription(content, ns.effects[1])
    PlannedPermanent(content, "Permanent Hide UI", -96)
    local apply = Checkbox(content, "Apply Effect to Lens", -4, -148, function(self)
        ns.SetApplyToLens("hideui", self:GetChecked())
    end)
    page.refresh = function() apply:SetChecked(ns.IsAppliedToLens("hideui")) end
    content:SetHeight(230)
end

local function BuildLayeredEffect(page, content, camera)
    local id = camera and "camerashift" or "letterbox"
    EffectDescription(content, ns.effects[camera and 3 or 2])
    local permanentField = camera and "permanentCameraShift" or "permanentLetterbox"
    local permanentValue = camera and "permanentCameraOffset" or "permanentLetterboxHeight"
    local lensValue = camera and "cameraOffset" or "letterboxHeight"
    local setPermanent = camera and ns.SetPermanentCameraShift or ns.SetPermanentLetterbox
    local setValue = camera and ns.SetCameraOffset or ns.SetLetterboxHeight
    local permanentControl, lensControl, animation
    local permanent = Checkbox(content, camera and "Permanent CameraShift" or "Permanent Letterbox", -4, -96,
        function(self) setPermanent(self:GetChecked()); page.refresh() end)
    local apply = Checkbox(content, "Apply Effect to Lens", -4, 0,
        function(self) ns.SetApplyToLens(id, self:GetChecked()) end)
    local consent, warning, explanation, unsupported
    if camera then
        consent = Checkbox(content, "Allow Blizzard experimental camera features", -4, 0, function(self)
            ns.SetCameraConsent(self:GetChecked()); page.refresh()
        end)
        Tooltip(consent, "I agree to temporarily disable Keep Character Centered and Reduce Unexpected Camera Movement for CameraShift. Experimental camera changes may cause visual discomfort. This choice is saved.")
        warning = Label(content, "Warning!", "GameFontNormal", 0, 0)
        explanation = Label(content, "CameraShift remembers your current offset. A Lens button temporarily applies its chosen offset; a second press or Esc returns to Permanent CameraShift, if enabled, or your previous camera settings. Allow experimental camera features above before using this Effect.", "GameFontHighlight", 0, 0)
        explanation:SetWordWrap(true)
        unsupported = Label(content, "CameraShift is not supported by this client.", "GameFontNormal", 0, 0)
    end
    local function MakeControl(permanentMode)
        local name = camera and (permanentMode and "RetCinemaPermanentCameraOffset" or "RetCinemaCameraOffset") or
            (permanentMode and "RetCinemaPermanentBarHeight" or "RetCinemaBarHeight")
        local field = permanentMode and permanentValue or lensValue
        return NumericControl(content, name, camera and "Camera shoulder offset" or "Bar height",
            camera and -15 or 0, camera and 15 or 25, camera and "" or "%",
            function() return ns.db[field] end, function(value) return setValue(value, permanentMode) end)
    end
    page.refresh = function()
        local usable = not camera or (ns.CameraAvailable() and ns.db.cameraConsent)
        permanent:SetChecked(ns.db[permanentField])
        permanent:SetEnabled(usable)
        permanent:SetMotionScriptsWhileDisabled(true)
        if camera then Tooltip(permanent, "Allow experimental camera features below to use Permanent CameraShift.") end
        local y = -132
        if ns.db[permanentField] then
            if not permanentControl then permanentControl = MakeControl(true) end
            permanentControl:SetPoint("TOPLEFT", 0, y)
            permanentControl:SetPoint("TOPRIGHT", 0, y)
            permanentControl:Show()
            permanentControl.refresh(usable)
            y = y - 112
        elseif permanentControl then permanentControl:Hide() end
        apply:SetPoint("TOPLEFT", -4, y)
        apply:SetChecked(ns.IsAppliedToLens(id))
        y = y - 36
        if ns.IsAppliedToLens(id) then
            if not lensControl then lensControl = MakeControl(false) end
            lensControl:SetPoint("TOPLEFT", 0, y)
            lensControl:SetPoint("TOPRIGHT", 0, y)
            lensControl:Show()
            lensControl.refresh(usable)
            y = y - 96
            if not camera then
                if not animation then
                    animation = Checkbox(content, "Enable animation", -4, 0,
                        function(self) ns.SetLetterboxAnimation(self:GetChecked()) end)
                end
                animation:SetPoint("TOPLEFT", -4, y)
                animation:SetChecked(ns.db.enableAnimation)
                animation:Show()
                y = y - 36
            end
        else
            if lensControl then lensControl:Hide() end
            if animation then animation:Hide() end
        end
        if camera then
            consent:SetPoint("TOPLEFT", -4, y - 12)
            consent:SetChecked(ns.db.cameraConsent)
            consent:SetEnabled(ns.CameraAvailable())
            warning:SetPoint("TOPLEFT", 0, y - 60)
            explanation:SetPoint("TOPLEFT", 0, y - 84)
            explanation:SetPoint("TOPRIGHT", 0, y - 84)
            unsupported:SetPoint("TOPLEFT", 0, y - 184)
            unsupported:SetShown(not ns.CameraAvailable())
            y = y - 214
        end
        content:SetHeight(math.max(320, -y + 30))
    end
end
builders.letterbox = function(page, content) BuildLayeredEffect(page, content, false) end
builders.camerashift = function(page, content) BuildLayeredEffect(page, content, true) end

builders.smoothmotion = function(page, content)
    EffectDescription(content, ns.effects[4])
    local permanent = PlannedPermanent(content, "Permanent SmoothMotion", -96)
    Tooltip(permanent, "Under development. This Effect is not available yet.")
    local apply = Checkbox(content, "Apply Effect to Lens", -4, -148)
    apply:SetEnabled(false)
    apply:SetChecked(false)
    apply.label:SetTextColor(0.5, 0.5, 0.5)
    apply:SetMotionScriptsWhileDisabled(true)
    Tooltip(apply, "Under development. This Effect is not available yet.")
    local box = FramedBox(content, -200, 160)
    Label(box, "Coming soon", "GameFontNormal", 12, -14)
    Label(box, "Smoothing amount", "GameFontDisable", 12, -54)
    local slider = CreateFrame("Slider", "RetCinemaSmoothMotionSlider", box, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -90)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(0, 100)
    slider:SetValue(50)
    slider:SetEnabled(false)
    _G[slider:GetName() .. "Low"]:SetText("Low")
    _G[slider:GetName() .. "High"]:SetText("High")
    content:SetHeight(400)
end

builders.lens = function(page, content)
    EffectDescription(content, ns.lens)
    Label(content, "Effect", "GameFontNormal", 12, -84)
    local keyHeader = Label(content, "Lens button", "GameFontNormal", 172, -84)
    keyHeader:SetWidth(BINDING_BUTTON_WIDTH)
    keyHeader:SetJustifyH("CENTER")
    local addHeader = Label(content, "Add to Combined Lens", "GameFontNormal", 342, -84)
    addHeader:SetWidth(190)
    addHeader:SetWordWrap(true)
    addHeader:SetJustifyH("CENTER")
    Divider(content, "TOP", -122)
    local empty = Label(content, "Apply an Effect to Lens in its Effects tab to add a Lens button.", "GameFontNormal", 12, -144)
    empty:SetPoint("TOPRIGHT", -12, -144)
    empty:SetWordWrap(true)
    local function BindingRow(parent, binding, effect, command)
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(518, 26)
        row.binding, row.effect = binding, effect
        row.label = Label(row, _G["BINDING_NAME_" .. binding], "GameFontHighlight", 0, -6)
        CreateBindingButton(row, binding, 1, 160, 0)
        row.orLabel = Label(row, "or", "GameFontHighlightSmall", 160, -29)
        row.orLabel:SetWidth(BINDING_BUTTON_WIDTH)
        row.orLabel:SetJustifyH("CENTER")
        CreateBindingButton(row, binding, 2, 160, -48)
        local hover = CreateFrame("Frame", nil, row)
        hover:SetPoint("TOPLEFT")
        hover:SetSize(150, 26)
        Tooltip(hover, "Can be enabled via /retcin " .. command)
        return row
    end
    local function PlaceRow(row, y)
        local second = row.binding == "RETCINEMA_COMBINED" or GetBindingKey(row.binding) ~= nil
        row.orLabel:SetShown(second)
        row:SetHeight(second and 74 or 26)
        row:SetPoint("TOPLEFT", 12, y)
        row:SetPoint("TOPRIGHT", -12, y)
        return y - row:GetHeight()
    end
    local combinedBox = FramedBox(content, 0, 110)
    local combinedRow = BindingRow(combinedBox, "RETCINEMA_COMBINED", nil, "combinedlens")
    local font, size, flags = combinedRow.label:GetFont()
    combinedRow.label:SetFont(font, size + 2, flags)
    Label(combinedRow, "Second Button press exit:", "GameFontNormal", 330, -6)
    local selector = Button(combinedRow, "", 180, 330, -48)
    local arrow = Label(selector, "v", "GameFontNormal", 0, 0)
    arrow:ClearAllPoints()
    arrow:SetPoint("RIGHT", -6, 0)
    local menu = FramedBox(selector, -28, 68)
    menu:SetFrameStrata("DIALOG")
    menu:Hide()
    for index, choice in ipairs({ "All Lenses", "Only added Lenses" }) do
        Button(menu, choice, 168, 6, -6 - (index - 1) * 28, function()
            ns.db.combinedAsEsc = index == 1
            selector:SetText(choice)
            menu:Hide()
        end)
    end
    selector:SetScript("OnClick", function() StopListening(); menu:SetShown(not menu:IsShown()) end)
    bindingStatus = LargeYellow(Label(content, "", "GameFontHighlight", 0, 0), 1.5)
    local rows = {}
    local function RefreshLens()
        local y, visible = -136, 0
        for _, row in ipairs(rows) do
            local listed = ns.IsAppliedToLens(row.effect)
            row:SetShown(listed)
            if listed then y = PlaceRow(row, y) - 28; visible = visible + 1 end
            row.checkbox:SetChecked(ns.db.combinedActions[row.binding])
            row.label:SetTextColor(ns.IsEffectEnabled(row.effect) and 1 or 0.5,
                ns.IsEffectEnabled(row.effect) and 1 or 0.5, ns.IsEffectEnabled(row.effect) and 1 or 0.5)
        end
        empty:SetShown(visible == 0)
        local shown = ns.HasCombinedActions()
        combinedBox:SetShown(shown)
        combinedRow:SetShown(shown)
        selector:SetText(ns.db.combinedAsEsc and "All Lenses" or "Only added Lenses")
        if shown then
            combinedBox:SetPoint("TOPLEFT", 0, y)
            combinedBox:SetPoint("TOPRIGHT", 0, y)
            PlaceRow(combinedRow, -18)
            y = y - combinedBox:GetHeight() - 12
        else menu:Hide() end
        bindingStatus:ClearAllPoints()
        bindingStatus:SetPoint("TOPLEFT", 0, y - 8)
        bindingStatus:SetPoint("TOPRIGHT", 0, y - 8)
        content:SetHeight(math.max(320, -y + 100))
    end
    for index, action in ipairs(ns.actions) do
        local row = BindingRow(content, action.binding, action.effect, action.command)
        row.checkbox = Checkbox(row, "", 411, -1, function(self)
            local checked = self:GetChecked()
            StopListening()
            ns.SetCombinedAction(action.binding, checked)
            RefreshLens()
        end)
        Divider(row, "BOTTOM", -12)
        rows[index] = row
    end
    bindingLayout = RefreshLens
    page.refresh = function()
        page:RegisterEvent("UPDATE_BINDINGS")
        page:RegisterEvent("PLAYER_REGEN_DISABLED")
        page:RegisterEvent("PLAYER_REGEN_ENABLED")
        RefreshBindings()
    end
    page:HookScript("OnHide", function(self)
        StopListening(); menu:Hide(); self:UnregisterAllEvents()
    end)
    page:HookScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            StopListening()
            bindingStatus:SetText("Lens buttons cannot be changed in combat.")
        else RefreshBindings() end
    end)
end
local function BuildPage(index)
    local id = tabSpecs[index].id
    local page = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    page.pageId = id
    page:SetPoint("TOPLEFT", 20, -156)
    page:SetPoint("BOTTOMRIGHT", -38, 20)
    page:Hide()
    local content = CreateFrame("Frame", nil, page)
    page.content = content
    content:SetWidth(math.max(1, panel:GetWidth() - 58))
    content:SetHeight(480)
    page:SetScrollChild(content)
    page:HookScript("OnSizeChanged", function(self, width)
        content:SetWidth(math.max(1, width))
        if self.layoutEffects then self.layoutEffects() end
    end)
    builders[id](page, content)
    page:HookScript("OnShow", function(self) if self.refresh then self.refresh() end end)
    pages[index] = page
    return page
end

local function SelectTab(index)
    StopListening()
    if index > 2 and not ns.IsEffectEnabled(tabSpecs[index].id) then index = 1 end
    selectedTab = index
    if not pages[index] then BuildPage(index) end
    for i, page in pairs(pages) do page:SetShown(i == index) end
    for i, tab in ipairs(tabs) do
        if i == index then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
    end
    if pages[index].refresh then pages[index].refresh() end
end

local effectsHeader
local function LayoutTabs()
    local count = 0
    for _, effect in ipairs(ns.effects) do
        if ns.IsEffectEnabled(effect.id) then count = count + 1 end
    end
    if effectsHeader then effectsHeader:SetShown(count > 0) end
    local effectWidth = math.min(100, math.max(1, (panel:GetWidth() - 32) / math.max(1, count) - 6))
    local visible = 0
    for index, tab in ipairs(tabs) do
        if index <= 2 then
            tab.layoutWidth = 100
            tab:SetPoint("TOPLEFT", 16 + (index - 1) * 106, -48)
            PanelTemplates_TabResize(tab, 4, 100)
        elseif ns.IsEffectEnabled(tabSpecs[index].id) then
            tab.layoutWidth = effectWidth
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", 16 + visible * (effectWidth + 6), -108)
            PanelTemplates_TabResize(tab, 4, effectWidth)
            visible = visible + 1
        end
    end
end

local function Build()
    if built then SelectTab(selectedTab); return end
    built = true
    Label(panel, "ret_Cinema", "GameFontNormalLarge", 16, -16)
    effectsHeader = Label(panel, "Effects", "GameFontNormal", 16, -86)
    for index, spec in ipairs(tabSpecs) do
        local tab = CreateFrame("Button", "RetCinemaSettingsTab" .. index, panel, "PanelTopTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(spec.name)
        PanelTemplates_TabResize(tab, 4, 100)
        tab:HookScript("OnShow", function(self)
            self:RegisterEvent("DISPLAY_SIZE_CHANGED")
            PanelTemplates_TabResize(self, 4, self.layoutWidth or 100)
        end)
        tab:HookScript("OnHide", function(self) self:UnregisterEvent("DISPLAY_SIZE_CHANGED") end)
        tab:HookScript("OnEvent", function(self) if self:IsShown() then LayoutTabs() end end)
        tab:SetScript("OnClick", function() SelectTab(index) end)
        tabs[index] = tab
    end
    panel:HookScript("OnSizeChanged", LayoutTabs)
    ns.RefreshEffectSettings = function()
        StopListening()
        for index, tab in ipairs(tabs) do
            tab:SetShown(index <= 2 or ns.IsEffectEnabled(tabSpecs[index].id))
        end
        LayoutTabs()
        for index, page in pairs(pages) do
            if index > 2 and not ns.IsEffectEnabled(tabSpecs[index].id) then page:Hide() end
        end
        SelectTab(selectedTab)
        if pages[1] and pages[1].refresh then pages[1].refresh() end
    end
    ns.RefreshEffectSettings()
end
function ns.RegisterSettings()
    panel = CreateFrame("Frame", "RetCinemaSettingsPanel", UIParent)
    panel.name = "ret_Cinema"
    panel:Hide()
    panel:SetScript("OnShow", Build)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, "ret_Cinema")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel) end
end

function RetCinema_OpenSettings()
    if not panel then return end
    ns.RestoreUI()
    if category then Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel) end
end
