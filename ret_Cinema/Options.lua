local _, ns = ...
local panel, category
local generalPanel, effectPanel, lensPanel
local pages, tabs, bindingButtons = {}, {}, {}
local listening, bindingStatus, bindingLayout
local selectedTab = 1
local builders = {}
local copyDialog
local linkFonts = {}
local DESCRIPTION_FONT_SCALE = 1.5
local BINDING_BUTTON_WIDTH = 156
local tabSpecs = {}
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
    label:SetText(ns.ColorRet(text))
    return label
end

local function Button(parent, text, width, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(ns.ColorRet(text))
    button:SetScript("OnClick", onClick)
    return button
end

local function Tooltip(frame, text)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(ns.ColorRet(type(text) == "function" and text() or text), 1, 0.82, 0, 1, true)
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

local function SettingsHeading(parent, text)
    local title = Label(parent, text, "GameFontHighlightHuge", 7, -22)
    title:SetTextColor(1, 1, 1)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetAtlas("Options_HorizontalDivider", true)
    line:SetPoint("TOPLEFT", 0, -50)
    line:SetPoint("TOPRIGHT", 0, -50)
    return title
end

local function SectionHeading(parent, text, y)
    local title = Label(parent, text, "GameFontHighlightLarge", 0, y)
    title:SetTextColor(1, 1, 1)
    return title
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
        local scroll = CreateFrame("ScrollFrame", nil, copyDialog, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 24, -80)
        scroll:SetSize(416, 76)
        local editBox = CreateFrame("EditBox", nil, scroll)
        copyDialog.editBox = editBox
        editBox:SetMultiLine(true)
        editBox:SetFontObject("GameFontHighlight")
        editBox:SetPoint("TOPLEFT")
        editBox:SetSize(408, 76)
        scroll:SetScrollChild(editBox)
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
    copyDialog.title:SetText(ns.ColorRet(title))
    copyDialog.editBox.copyPending = nil
    copyDialog.editBox.readOnlyText = text
    copyDialog.editBox:SetText(text)
    copyDialog:Show()
    copyDialog.editBox:SetFocus()
    copyDialog.editBox:HighlightText()
end

local function WordLink(parent, word, url, large)
    local button = CreateFrame("Button", nil, parent)
    local author = word == "ret_"
    local r, g, b = author and 154 / 255 or 1, author and 205 / 255 or 1, author and 50 / 255 or 1
    local fontName = "RetCinemaLinkFont" .. (large and "Large" or "Normal") .. (author and "Author" or "White")
    if not linkFonts[fontName] then
        local font = CreateFont(fontName)
        font:SetFontObject("GameFontHighlight")
        local path, size, flags = font:GetFont()
        font:SetFont(path, size * (large and 2 or 1), flags)
        font:SetTextColor(r, g, b)
        linkFonts[fontName] = font
    end
    button:SetNormalFontObject(linkFonts[fontName])
    button:SetHighlightFontObject(linkFonts[fontName])
    button:SetText(word)
    local text = button:GetFontString()
    text:SetTextColor(r, g, b)
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT")
    button:SetSize(text:GetStringWidth(), text:GetStringHeight() + 3)
    local underline = button:CreateTexture(nil, "ARTWORK")
    underline:SetColorTexture(r, g, b, 1)
    underline:SetHeight(1)
    underline:SetPoint("BOTTOMLEFT")
    underline:SetPoint("BOTTOMRIGHT")
    button:SetScript("OnClick", function() CopyText(word, url) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(url, r, g, b)
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
        button:SetShown(button.slot == 1 or button.action:match("^RETCINEMA_COMBINED") ~= nil or GetBindingKey(button.action) ~= nil)
    end
    if bindingLayout and lensPanel and lensPanel:IsShown() then bindingLayout() end
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
    local minimap = Checkbox(content, "Show minimap icon", -4, 0,
        function(self) ns.SetMinimapButton(self:GetChecked()) end)
    Label(content, "Enable Effect modules:", "GameFontNormal", 0, -46)
    local box = FramedBox(content, -72, 50)
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
    local feedback = Label(content, "Need a bug fix or a new feature? ", "GameFontNormal", 0, 0)
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
    content:SetHeight(376)
    page.refresh = function()
        minimap:SetChecked(ns.db.showMinimapButton)
        page.layoutEffects()
    end
end

builders.hideui = function(page, content)
    PlannedPermanent(content, "Permanent Hide UI", 0)
    local apply = Checkbox(content, "Apply Effect to Lens", -4, -40, function(self)
        ns.SetApplyToLens("hideui", self:GetChecked())
    end)
    page.refresh = function() apply:SetChecked(ns.IsAppliedToLens("hideui")) end
    content:SetHeight(140)
end

local function BuildLayeredEffect(page, content, camera)
    local id = camera and "camerashift" or "letterbox"
    local permanentField = camera and "permanentCameraShift" or "permanentLetterbox"
    local permanentValue = camera and "permanentCameraOffset" or "permanentLetterboxHeight"
    local lensValue = camera and "cameraOffset" or "letterboxHeight"
    local setPermanent = camera and ns.SetPermanentCameraShift or ns.SetPermanentLetterbox
    local setValue = camera and ns.SetCameraOffset or ns.SetLetterboxHeight
    local permanentControl, lensControl, animation
    local permanent = Checkbox(content, camera and "Permanent CameraShift" or "Permanent Letterbox", -4, 0,
        function(self) setPermanent(self:GetChecked()); page.refresh() end)
    local apply = Checkbox(content, "Apply Effect to Lens", -4, 0,
        function(self) ns.SetApplyToLens(id, self:GetChecked()) end)
    local consent, explanation, unsupported
    if camera then
        consent = Checkbox(content, "Allow Blizzard experimental camera feature", -4, 0, function(self)
            ns.SetCameraConsent(self:GetChecked()); page.refresh()
        end)
        Tooltip(consent, "I agree to temporarily disable Keep Character Centered and Reduce Unexpected Camera Movement for CameraShift. Experimental camera changes may cause visual discomfort. This choice is saved.")
        explanation = Label(content, "CameraShift remembers your current shoulder camera offset. A Lens button temporarily applies its chosen offset; a second press or Esc returns to Permanent CameraShift, if enabled, or your previous camera settings.", "GameFontNormal", 0, 0)
        explanation:SetWordWrap(true)
        unsupported = Label(content, "CameraShift is not supported by this client.", "GameFontNormal", 0, 0)
    else
        animation = Checkbox(content, "Enable animation", 240, 0,
            function(self) ns.SetLetterboxAnimation(self:GetChecked()) end)
    end
    local function MakeControl(permanentMode)
        local name = camera and (permanentMode and "RetCinemaPermanentCameraOffset" or "RetCinemaCameraOffset") or
            (permanentMode and "RetCinemaPermanentBarHeight" or "RetCinemaBarHeight")
        local field = permanentMode and permanentValue or lensValue
        local title
        if camera then title = permanentMode and "Permanent shoulder camera offset" or "Lens shoulder camera offset"
        else title = permanentMode and "Permanent bar height" or "Lens bar height" end
        return NumericControl(content, name, title,
            camera and -15 or 0, camera and 15 or 25, camera and "" or "%",
            function() return ns.db[field] end, function(value) return setValue(value, permanentMode) end)
    end
    page.refresh = function()
        local allowed = not camera or ns.db.cameraConsent
        local usable = not camera or (ns.CameraAvailable() and allowed)
        permanent:SetShown(allowed)
        apply:SetShown(allowed)
        permanent:SetChecked(ns.db[permanentField])
        permanent:SetEnabled(usable)
        local y = 0
        if allowed then
            permanent:SetPoint("TOPLEFT", -4, y)
            y = y - 36
            if ns.db[permanentField] then
                if not permanentControl then permanentControl = MakeControl(true) end
                permanentControl:SetPoint("TOPLEFT", 0, y)
                permanentControl:SetPoint("TOPRIGHT", 0, y)
                permanentControl:Show()
                permanentControl.refresh(usable)
                y = y - 106
            elseif permanentControl then permanentControl:Hide() end
            apply:SetPoint("TOPLEFT", -4, y)
            apply:SetChecked(ns.IsAppliedToLens(id))
            if animation then
                animation:SetPoint("TOPLEFT", 240, y)
                animation:SetChecked(ns.db.enableAnimation)
                animation:SetShown(ns.IsAppliedToLens(id))
            end
            y = y - 36
            if ns.IsAppliedToLens(id) then
                if not lensControl then lensControl = MakeControl(false) end
                lensControl:SetPoint("TOPLEFT", 0, y)
                lensControl:SetPoint("TOPRIGHT", 0, y)
                lensControl:Show()
                lensControl.refresh(usable)
                y = y - 96
            elseif lensControl then lensControl:Hide() end
        else
            if permanentControl then permanentControl:Hide() end
            if lensControl then lensControl:Hide() end
        end
        if camera then
            -- Reserve both expanded control areas, including before consent.
            -- The permission checkbox must never move when either area collapses.
            y = -274
            consent:SetPoint("TOPLEFT", -4, y)
            consent:SetChecked(ns.db.cameraConsent)
            consent:SetEnabled(ns.CameraAvailable())
            explanation:SetPoint("TOPLEFT", 0, y - 40)
            explanation:SetPoint("TOPRIGHT", 0, y - 40)
            explanation:SetShown(allowed)
            unsupported:SetPoint("TOPLEFT", 0, allowed and y - 140 or y - 40)
            unsupported:SetShown(not ns.CameraAvailable())
            y = y - (allowed and 170 or 80)
        end
        content:SetHeight(math.max(200, -y + 20))
    end
end
builders.letterbox = function(page, content) BuildLayeredEffect(page, content, false) end
builders.camerashift = function(page, content) BuildLayeredEffect(page, content, true) end

local function BuildPlannedEffect(page, content, fov)
    local permanent = PlannedPermanent(content, fov and "Permanent FOV" or "Permanent SmoothMotion", 0)
    Tooltip(permanent, "Under consideration. This Effect is not available yet.")
    local apply = Checkbox(content, fov and "Apply FOV to Lens" or "Apply Effect to Lens", -4, -40)
    apply:SetEnabled(false)
    apply:SetChecked(false)
    apply.label:SetTextColor(0.5, 0.5, 0.5)
    apply:SetMotionScriptsWhileDisabled(true)
    Tooltip(apply, "Under consideration. This Effect is not available yet.")
    local box = FramedBox(content, -88, 124)
    Label(box, fov and "Field of view" or "Smoothing amount", "GameFontDisable", 12, -14)
    local slider = CreateFrame("Slider", fov and "RetCinemaFOVSlider" or "RetCinemaSmoothMotionSlider", box, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -50)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(fov and 60 or 0, fov and 120 or 100)
    slider:SetValue(fov and 90 or 50)
    slider:SetEnabled(false)
    _G[slider:GetName() .. "Low"]:SetText(fov and "60" or "Low")
    _G[slider:GetName() .. "High"]:SetText(fov and "120" or "High")
    content:SetHeight(400)
end
builders.fov = function(page, content) BuildPlannedEffect(page, content, true) end
builders.smoothmotion = function(page, content) BuildPlannedEffect(page, content, false) end

builders.lens = function(page, content)
    Label(content, "Effect", "GameFontNormal", 12, 0)
    local keyHeader = Label(content, "Lens button", "GameFontNormal", 172, 0)
    keyHeader:SetWidth(BINDING_BUTTON_WIDTH)
    keyHeader:SetJustifyH("CENTER")
    local addHeader = Label(content, "", "GameFontNormal", 342, 0)
    addHeader:SetWidth(190)
    addHeader:SetWordWrap(true)
    addHeader:SetJustifyH("CENTER")
    Divider(content, "TOP", -38)
    local rows, combinedRows, menus = {}, {}, {}
    local function BindingRow(parent, binding, effect, command, combinedIndex)
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(518, 26)
        row.binding, row.effect, row.combinedIndex = binding, effect, combinedIndex
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
    local function PlaceRow(row, y, minimum)
        local second = row.combinedIndex ~= nil or GetBindingKey(row.binding) ~= nil
        row.orLabel:SetShown(second)
        row:SetHeight(math.max(second and 74 or 26, minimum or 0))
        row:SetPoint("TOPLEFT", 12, y)
        row:SetPoint("TOPRIGHT", -12, y)
        return y - row:GetHeight()
    end
    local combinedBox = FramedBox(content, 0, 110)
    local function BuildCombined(index)
        local row = BindingRow(combinedBox, ns.CombinedBinding(index), nil,
            index == 1 and "combinedlens" or "combinedlens" .. index, index)
        local font, size, flags = row.label:GetFont()
        row.label:SetFont(font, size + 2, flags)
        Label(row, "Second Button press exit:", "GameFontNormal", 330, -6)
        local selector = Button(row, "", 180, 330, -48)
        local arrow = Label(selector, "v", "GameFontNormal", 0, 0)
        arrow:ClearAllPoints()
        arrow:SetPoint("RIGHT", -6, 0)
        local menu = FramedBox(selector, -28, 68)
        menu:SetFrameStrata("DIALOG")
        menu:Hide()
        menus[index] = menu
        for choiceIndex, choice in ipairs({ "All Lenses", "Only added Lenses" }) do
            Button(menu, choice, 168, 6, -6 - (choiceIndex - 1) * 28, function()
                ns.SetCombinedExitAll(index, choiceIndex == 1)
                selector:SetText(choice)
                menu:Hide()
            end)
        end
        selector:SetScript("OnClick", function()
            StopListening()
            local opening = not menu:IsShown()
            for _, other in pairs(menus) do other:Hide() end
            menu:SetShown(opening)
        end)
        row.selector = selector
        if index > 1 then Divider(row, "TOP", 16) end
        combinedRows[index] = row
        return row
    end
    local add = Button(combinedBox, "Add another Combined Lens", 228, 12, 0, function()
        StopListening()
        ns.AddCombinedLens()
    end)
    bindingStatus = LargeYellow(Label(content, "", "GameFontHighlight", 0, 0), 1.5)
    local function RefreshLens()
        local count = ns.GetCombinedCount()
        addHeader:SetText(count == 1 and "Add to Combined Lens" or "Add to a specific Combined Lens")
        local y, visible = -52, 0
        for _, row in ipairs(rows) do
            local listed = ns.IsEffectEnabled(row.effect) and ns.IsAppliedToLens(row.effect)
            row:SetShown(listed)
            for index = 1, count do
                if not row.checks[index] then
                    local lensIndex = index
                    local check = Checkbox(row, "", 411, -(index - 1) * 28 - 1, function(self)
                        StopListening()
                        ns.SetCombinedAction(row.binding, self:GetChecked(), lensIndex)
                    end)
                    Tooltip(check, function()
                        return "Add " .. _G["BINDING_NAME_" .. row.binding] .. " to Combined Lens " .. lensIndex
                    end)
                    row.checks[index] = check
                end
            end
            for index, check in ipairs(row.checks) do
                check:SetShown(index <= count)
                check:SetChecked(ns.GetCombinedActions(index)[row.binding])
                check.label:SetText(count > 1 and tostring(index) or "")
            end
            if listed then y = PlaceRow(row, y, count * 28) - 28; visible = visible + 1 end
        end
        combinedBox:SetShown(visible > 0)
        local combinedY = -18
        for index = 1, count do
            local row = combinedRows[index] or BuildCombined(index)
            row:Show()
            row.label:SetText(count > 1 and "Combined Lens " .. index or "Combined Lens")
            row.selector:SetText(ns.GetCombinedExitAll(index) and "All Lenses" or "Only added Lenses")
            combinedY = PlaceRow(row, combinedY) - 34
        end
        for index, row in pairs(combinedRows) do
            if index > count then row:Hide(); menus[index]:Hide() end
        end
        add:SetShown(count < 5)
        add:ClearAllPoints()
        add:SetPoint("TOPLEFT", 12, combinedY + 10)
        combinedBox:SetHeight(-combinedY + (count < 5 and 36 or -12))
        combinedBox:SetPoint("TOPLEFT", 0, y)
        combinedBox:SetPoint("TOPRIGHT", 0, y)
        if visible > 0 then y = y - combinedBox:GetHeight() - 12 end
        bindingStatus:ClearAllPoints()
        bindingStatus:SetPoint("TOPLEFT", 0, y - 8)
        bindingStatus:SetPoint("TOPRIGHT", 0, y - 8)
        content:SetHeight(math.max(320, -y + 100))
    end
    for index, action in ipairs(ns.actions) do
        local row = BindingRow(content, action.binding, action.effect, action.command)
        row.checks = {}
        Divider(row, "BOTTOM", -12)
        rows[index] = row
    end
    bindingLayout = RefreshLens
    page.refresh = function()
        page:RegisterEvent("UPDATE_BINDINGS")
        page:RegisterEvent("PLAYER_REGEN_DISABLED")
        page:RegisterEvent("PLAYER_REGEN_ENABLED")
        -- Create newly requested rows before refreshing their binding buttons.
        RefreshLens()
        RefreshBindings()
    end
    page:HookScript("OnHide", function(self)
        StopListening()
        for _, menu in pairs(menus) do menu:Hide() end
        self:UnregisterAllEvents()
    end)
    page:HookScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            StopListening()
            RefreshBindings()
            bindingStatus:SetText("Lens buttons cannot be changed in combat.")
        else RefreshBindings() end
    end)
end

local headerDescription, headerHint, effectEmpty
local SelectTab, LayoutTabs
local function BuildEffectPage(index)
    local id = tabSpecs[index].id
    local page = CreateFrame("ScrollFrame", nil, effectPanel, "UIPanelScrollFrameTemplate")
    page.pageId = id
    page:SetPoint("TOPLEFT", headerHint, "BOTTOMLEFT", 0, -12)
    page:SetPoint("BOTTOMRIGHT", -38, 20)
    page:Hide()
    local content = CreateFrame("Frame", nil, page)
    page.content = content
    content:SetWidth(math.max(1, effectPanel:GetWidth() - 58))
    content:SetHeight(200)
    page:SetScrollChild(content)
    page:HookScript("OnSizeChanged", function(_, width) content:SetWidth(math.max(1, width)) end)
    builders[id](page, content)
    page:HookScript("OnShow", function(self) if self.refresh then self.refresh() end end)
    pages[index] = page
    return page
end
local function StyleEffectTab(tab, spec)
    if spec.underConsideration then
        tab:SetNormalFontObject("RetCinemaPlannedTabFont")
        tab:SetHighlightFontObject("RetCinemaPlannedTabFont")
        tab:SetDisabledFontObject("RetCinemaPlannedTabFont")
        tab:GetFontString():SetTextColor(1, 0.5, 0)
    end
end
LayoutTabs = function()
    if not headerHint then return end
    local widthAvailable = math.max(1, effectPanel:GetWidth() - 58)
    local perRow = math.min(4, math.max(1, math.floor((widthAvailable + 6) / 126)))
    local width = math.min(136, (widthAvailable - (perRow - 1) * 6) / perRow)
    local position = 0
    for index, tab in ipairs(tabs) do
        local shown = ns.IsEffectEnabled(tabSpecs[index].id)
        tab:SetShown(shown)
        if shown then
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", 20 + position % perRow * (width + 6), -76 - math.floor(position / perRow) * 34)
            PanelTemplates_TabResize(tab, 4, width)
            StyleEffectTab(tab, tabSpecs[index])
            position = position + 1
        end
    end
    local rows = math.max(1, math.ceil(position / perRow))
    headerDescription:SetPoint("TOPLEFT", 20, -86 - rows * 34)
    headerDescription:SetPoint("TOPRIGHT", -38, -86 - rows * 34)
end
SelectTab = function(index)
    StopListening()
    if not index or not ns.IsEffectEnabled(tabSpecs[index].id) then
        index = nil
        for candidate, spec in ipairs(tabSpecs) do
            if ns.IsEffectEnabled(spec.id) then index = candidate; break end
        end
    end
    selectedTab = index
    for i, page in pairs(pages) do page:SetShown(i == index) end
    effectEmpty:SetShown(index == nil)
    headerDescription:SetShown(index ~= nil)
    headerHint:SetShown(index ~= nil)
    if index then
        local page = pages[index] or BuildEffectPage(index)
        local info = tabSpecs[index]
        headerDescription:SetText(ns.ColorRet(info.description))
        headerHint:SetText(ns.ColorRet(info.hint or ""))
        page:Show()
        if page.refresh then page.refresh() end
    end
    for i, tab in ipairs(tabs) do
        if i == index then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
        StyleEffectTab(tab, tabSpecs[i])
    end
    LayoutTabs()
end
local function BuildEffects()
    if not headerHint then
        SettingsHeading(effectPanel, "Effect")
        headerDescription = PageDescription(effectPanel, "")
        headerDescription:ClearAllPoints()
        headerHint = Label(effectPanel, "", "GameFontNormal", 0, 0)
        headerHint:ClearAllPoints()
        headerHint:SetPoint("TOPLEFT", headerDescription, "BOTTOMLEFT", 0, -10)
        headerHint:SetPoint("TOPRIGHT", headerDescription, "BOTTOMRIGHT", 0, -10)
        headerHint:SetWordWrap(true)
        effectEmpty = Label(effectPanel, "Enable an Effect in General to configure it here.", "GameFontNormal", 20, -120)
        local plannedFont = CreateFont("RetCinemaPlannedTabFont")
        plannedFont:SetFontObject("GameFontHighlight")
        plannedFont:SetTextColor(1, 0.5, 0)
        for index, spec in ipairs(tabSpecs) do
            local tab = CreateFrame("Button", "RetCinemaSettingsTab" .. index, effectPanel, "PanelTopTabButtonTemplate")
            tab:SetID(index)
            tab:SetText(spec.name)
            tab:SetScript("OnClick", function() SelectTab(index) end)
            if spec.underConsideration then Tooltip(tab, spec.hint) end
            tabs[index] = tab
        end
        effectPanel:HookScript("OnSizeChanged", LayoutTabs)
    end
    SelectTab(selectedTab)
end
local profileDialog
local function ProfileDialog(mode, title, text, submit)
    if not profileDialog then
        local dialog = CreateFrame("Frame", "RetCinemaProfileDialog", UIParent, "BackdropTemplate")
        profileDialog = dialog
        dialog:SetSize(500, 270)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)
        dialog:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
            edgeSize = 32, insets = { left = 10, right = 10, top = 10, bottom = 10 } })
        dialog.title = Label(dialog, "", "GameFontHighlightLarge", 24, -24)
        dialog.instructions = Label(dialog, "", "GameFontNormal", 24, -54)
        dialog.instructions:SetPoint("TOPRIGHT", -24, -54)
        dialog.instructions:SetWordWrap(true)
        dialog.inputScroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.inputScroll:SetPoint("TOPLEFT", 28, -100)
        dialog.inputScroll:SetSize(418, 82)
        dialog.editBox = CreateFrame("EditBox", nil, dialog.inputScroll, "InputBoxTemplate")
        dialog.editBox:SetPoint("TOPLEFT")
        dialog.editBox:SetSize(410, 82)
        dialog.inputScroll:SetScrollChild(dialog.editBox)
        dialog.editBox:SetFontObject("GameFontHighlight")
        dialog.editBox:SetAutoFocus(false)
        dialog.error = Label(dialog, "", "GameFontNormal", 24, -186)
        dialog.error:SetPoint("TOPRIGHT", -24, -186)
        dialog.error:SetTextColor(1, 0.3, 0.3)
        dialog.error:SetWordWrap(true)
        dialog.submitButton = Button(dialog, "", 120, 120, -226, function()
            local ok, errorText = dialog.submit(dialog.editBox:GetText())
            if ok then dialog:Hide() else dialog.error:SetText(ns.ColorRet(errorText or "Could not update the profile.")) end
        end)
        Button(dialog, "Cancel", 120, 258, -226, function() dialog:Hide() end)
        dialog.editBox:SetScript("OnEnterPressed", function()
            if dialog.mode ~= "import" or IsControlKeyDown() then dialog.submitButton:Click() end
        end)
        dialog.editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
        dialog:SetScript("OnHide", function() dialog.editBox:ClearFocus(); dialog.submit = nil end)
    end
    local dialog = profileDialog
    dialog.mode, dialog.submit = mode, submit
    dialog.title:SetText(ns.ColorRet(title))
    dialog.instructions:SetText(ns.ColorRet(text))
    dialog.editBox:SetText("")
    dialog.editBox:SetMultiLine(mode == "import")
    dialog.editBox:SetHeight(mode == "import" and 82 or 26)
    dialog.editBox:SetMaxLetters(mode == "import" and 16384 or 32)
    dialog.editBox:SetShown(mode ~= "delete")
    dialog.inputScroll:SetShown(mode ~= "delete")
    dialog.error:SetText("")
    dialog.submitButton:SetText(mode == "create" and "Create" or mode == "import" and "Import" or "Delete")
    dialog:Show()
    if mode ~= "delete" then dialog.editBox:SetFocus() end
end

local function ProfileSelector(parent, role, y, choices, choose)
    local selector = Button(parent, "", 220, 238, y)
    selector.profileRole = role
    local menu = FramedBox(selector, -28, 40)
    menu:SetFrameStrata("DIALOG")
    local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -28, 4)
    local list = CreateFrame("Frame", nil, scroll)
    list:SetSize(186, 28)
    scroll:SetScrollChild(list)
    local buttons = {}
    menu:Hide()
    selector.menu = menu
    selector:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide(); return end
        local names = choices()
        for _, button in ipairs(buttons) do button:Hide() end
        for index, name in ipairs(names) do
            local button = buttons[index]
            if not button then button = Button(list, "", 182, 0, -(index - 1) * 28); buttons[index] = button end
            button:SetText(ns.ColorRet(name))
            button:SetScript("OnClick", function() menu:Hide(); choose(name) end)
            button:Show()
        end
        list:SetHeight(math.max(28, #names * 28))
        menu:SetHeight(math.min(204, #names * 28 + 8))
        menu:SetShown(#names > 0)
    end)
    return selector
end

local function BuildProfiles(page, content)
    local status = Label(content, "", "GameFontNormal", 0, -440)
    status:SetPoint("TOPRIGHT", 0, -440)
    status:SetWordWrap(true)
    Label(content, "Active profile", "GameFontNormal", 0, -10)
    local active = ProfileSelector(content, "active", -4, function() return ns.Profiles.List() end,
        function(name)
            local ok, message = ns.Profiles.Activate(name)
            status:SetText(ns.ColorRet(ok and "Active profile: " .. message or message))
        end)
    local create = Button(content, "Create New", 150, 238, -46, function()
        ProfileDialog("create", "Create a new profile", "Enter a name for the new profile:", function(name)
            local ok, result = ns.Profiles.Create(name)
            if ok then status:SetText(ns.ColorRet("Created profile: " .. result)) end
            return ok, result
        end)
    end)
    SectionHeading(content, "Import / Export / Copy", -106)
    Button(content, "Export", 106, 238, -144,
        function() CopyText("Export: " .. ns.Profiles.Current(), ns.Profiles.Export()) end)
    local import = Button(content, "Import", 106, 352, -144, function()
        ProfileDialog("import", "Import a profile", "Paste a ret_Cinema profile export, then click Import.", function(text)
            local ok, result = ns.Profiles.Import(text)
            if ok then status:SetText(ns.ColorRet("Imported profile: " .. result)) end
            return ok, result
        end)
    end)
    Label(content, "Copy from profile:", "GameFontNormal", 0, -200)
    local source
    local copySelector
    copySelector = ProfileSelector(content, "copy", -194, function() return ns.Profiles.List(true) end,
        function(name) source = name; copySelector:SetText(ns.ColorRet(name)) end)
    local copy = Button(content, "Copy", 106, 352, -232, function()
        if not source then status:SetText("Select a profile to copy."); return end
        local ok, message = ns.Profiles.CopyFrom(source)
        status:SetText(ok and "Copied settings to the active profile." or message)
    end)
    SectionHeading(content, "Delete Profile", -292)
    Label(content, "Select a profile to delete", "GameFontNormal", 0, -340)
    local deletion
    local deleteSelector
    deleteSelector = ProfileSelector(content, "delete", -334, function() return ns.Profiles.List(true) end,
        function(name) deletion = name; deleteSelector:SetText(ns.ColorRet(name)) end)
    local delete = Button(content, "Delete", 106, 352, -372, function()
        if not deletion then status:SetText("Select a profile to delete."); return end
        local target = deletion
        ProfileDialog("delete", "Delete profile", "Delete '" .. target .. "'? This cannot be undone.", function()
            local ok, message = ns.Profiles.Delete(target)
            if ok then status:SetText(ns.ColorRet("Deleted profile: " .. message)) end
            return ok, message
        end)
    end)
    page.refresh = function()
        if page:IsShown() then
            page:RegisterEvent("PLAYER_REGEN_DISABLED")
            page:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        active:SetText(ns.ColorRet(ns.Profiles.Current()))
        active.menu:Hide(); copySelector.menu:Hide(); deleteSelector.menu:Hide()
        source, deletion = nil, nil
        copySelector:SetText("Select a profile...")
        deleteSelector:SetText("Select a profile...")
        local editable = not InCombatLockdown()
        local others = #ns.Profiles.List(true) > 0
        for _, button in ipairs({ active, create, import }) do button:SetEnabled(editable) end
        for _, button in ipairs({ copySelector, deleteSelector, copy, delete }) do button:SetEnabled(editable and others) end
    end
    ns.RefreshProfileSettings = page.refresh
    page:HookScript("OnHide", function()
        active.menu:Hide(); copySelector.menu:Hide(); deleteSelector.menu:Hide()
        page:UnregisterAllEvents()
    end)
    page:HookScript("OnShow", function()
        page:RegisterEvent("PLAYER_REGEN_DISABLED")
        page:RegisterEvent("PLAYER_REGEN_ENABLED")
    end)
    page:HookScript("OnEvent", function() page.refresh() end)
    content:SetHeight(500)
end

local function BuildSupport(page, content)
    Label(content, "CurseForge", "GameFontNormal", 0, -10)
    local curseForge = Button(content, "Copy link", 150, 238, -4)
    curseForge:SetEnabled(false)
    curseForge:SetMotionScriptsWhileDisabled(true)
    Tooltip(curseForge, "Coming soon")
    Label(content, "Coming soon", "GameFontDisable", 238, -36)
    SectionHeading(content, "Support Development", -104)
    local intro = Label(content, "If you enjoy ret_Cinema, you can support its continued development.", "GameFontHighlightSmall", 0, -140)
    intro:SetPoint("TOPRIGHT", 0, -140)
    intro:SetWordWrap(true)
    Label(content, "boosty.to", "GameFontNormal", 0, -184)
    Button(content, "Copy link", 150, 238, -178, function() CopyText("boosty.to", "https://boosty.to/ret_ro") end)
    local gold = Label(content, "You also may support development with in-game gold.", "GameFontHighlightSmall", 0, -244)
    gold:SetPoint("TOPRIGHT", 0, -244)
    gold:SetWordWrap(true)
    Label(content, "Retail", "GameFontNormal", 0, -282)
    local horde = Label(content, "Horde", "GameFontNormal", 0, -310)
    horde:SetTextColor(1, 0.3, 0.3)
    Label(content, "Хардрес-РевущийФьорд", "GameFontHighlight", 0, -346)
    Button(content, "Copy character name", 180, 238, -340,
        function() CopyText("Retail — Horde", "Хардрес-РевущийФьорд") end)
    content:SetHeight(420)
end

local function ChildPanel(name, builder, info)
    local child = CreateFrame("Frame", "RetCinema" .. name .. "Panel", UIParent)
    child.name = name == "Lens" and "|cff40c7ebLens|r" or name
    child.pageId = name:lower()
    child:Hide()
    local initialized, description
    child:SetScript("OnShow", function()
        if name == "Lens" and not ns.HasLensEffects() then child:Hide(); return end
        if not initialized then
            initialized = true
            SettingsHeading(child, child.name)
            local scroll = CreateFrame("ScrollFrame", nil, child, "UIPanelScrollFrameTemplate")
            if info then
                description = PageDescription(child, "")
                description:ClearAllPoints()
                description:SetPoint("TOPLEFT", 20, -76)
                description:SetPoint("TOPRIGHT", -38, -76)
                local hint = Label(child, info().hint, "GameFontNormal", 0, 0)
                hint:ClearAllPoints()
                hint:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -10)
                hint:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT", 0, -10)
                hint:SetWordWrap(true)
                scroll:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
            else scroll:SetPoint("TOPLEFT", 20, -76) end
            scroll:SetPoint("BOTTOMRIGHT", -38, 20)
            local content = CreateFrame("Frame", nil, scroll)
            content:SetWidth(math.max(1, child:GetWidth() - 58))
            scroll:SetScrollChild(content)
            scroll:SetScript("OnSizeChanged", function(_, width)
                content:SetWidth(math.max(1, width))
                if child.layoutEffects then child.layoutEffects() end
            end)
            child.content = content
            builder(child, content)
        end
        if description then description:SetText(ns.ColorRet(info().description)) end
        if child.refresh then child.refresh() end
    end)
    return child
end

local function OpenChild(id)
    local target = ns.settingsCategories[id]
    if target and Settings and Settings.OpenToCategory then Settings.OpenToCategory(target:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(id == "general" and generalPanel or id == "effect" and effectPanel or lensPanel)
    end
end
local function UpdateLensCategory()
    local shown = ns.HasLensEffects()
    local lensCategory = ns.settingsCategories.lens
    if category and lensCategory then
        -- Blizzard exposes the parent's subcategory array. Keep one registered
        -- category and insert/remove its entry, preserving its layout and ID.
        local children = category.GetSubcategories and category:GetSubcategories() or category.subcategories
        if children then
            local found
            for index, child in ipairs(children) do if child == lensCategory then found = index; break end end
            local changed = (found ~= nil) ~= shown
            if found and not shown then table.remove(children, found)
            elseif not found and shown then table.insert(children, math.min(3, #children + 1), lensCategory) end
            if changed and SettingsPanel and SettingsPanel.CategoryList and SettingsPanel.CategoryList.CreateCategories then
                SettingsPanel.CategoryList:CreateCategories()
            end
        end
    elseif InterfaceOptions_AddCategory and INTERFACEOPTIONS_ADDONCATEGORIES then
        local found
        for index, entry in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do if entry == lensPanel then found = index; break end end
        if found and not shown then table.remove(INTERFACEOPTIONS_ADDONCATEGORIES, found)
        elseif not found and shown then
            local position = #INTERFACEOPTIONS_ADDONCATEGORIES + 1
            for index, entry in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
                if entry == effectPanel then position = index + 1; break end
            end
            table.insert(INTERFACEOPTIONS_ADDONCATEGORIES, position, lensPanel)
        end
        if InterfaceAddOnsList_Update then InterfaceAddOnsList_Update() end
    end
    if panel.lensButton then panel.lensButton:SetShown(shown) end
    if not shown and lensPanel:IsShown() then
        StopListening()
        lensPanel:Hide()
        OpenChild("general")
    end
end
function ns.RegisterSettings()
    panel = CreateFrame("Frame", "RetCinemaSettingsPanel", UIParent)
    panel.name = ns.title
    panel:Hide()
    local rootDescription
    panel:SetScript("OnShow", function()
        if not rootDescription then
            SettingsHeading(panel, ns.title)
            rootDescription = PageDescription(panel, "")
            rootDescription:ClearAllPoints()
            rootDescription:SetPoint("TOPLEFT", 20, -76)
            rootDescription:SetPoint("TOPRIGHT", -38, -76)
            Label(panel, "Choose a settings page below or in the category list.", "GameFontNormal", 20, -144)
            Button(panel, "General", 160, 20, -184, function() OpenChild("general") end)
            Button(panel, "Effect", 160, 20, -222, function() OpenChild("effect") end)
            panel.lensButton = Button(panel, "|cff40c7ebLens|r", 160, 20, -260, function() OpenChild("lens") end)
        end
        rootDescription:SetText(ns.ColorRet(ns.GetDescription()))
        panel.lensButton:SetShown(ns.HasLensEffects())
    end)
    generalPanel = ChildPanel("General", builders.general, function()
        return { description = ns.GetDescription(), hint = ns.generalHint }
    end)
    effectPanel = CreateFrame("Frame", "RetCinemaEffectPanel", UIParent)
    effectPanel.name = "Effect"
    effectPanel:Hide()
    effectPanel:SetScript("OnShow", BuildEffects)
    effectPanel:SetScript("OnHide", function() for _, page in pairs(pages) do page:Hide() end end)
    lensPanel = ChildPanel("Lens", builders.lens, function() return ns.lens end)
    local profiles = ChildPanel("Profiles", BuildProfiles)
    local support = ChildPanel("Support", BuildSupport)
    local children = { generalPanel, effectPanel, lensPanel, profiles, support }
    ns.settingsCategories = {}
    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, ns.title)
        if category.SetShouldSortAlphabetically then category:SetShouldSortAlphabetically(false) end
        Settings.RegisterAddOnCategory(category)
        ns.settingsCategories.main = category
        if Settings.RegisterCanvasLayoutSubcategory then
            for _, child in ipairs(children) do
                ns.settingsCategories[child.pageId or child.name:lower()] = Settings.RegisterCanvasLayoutSubcategory(category, child, child.name)
            end
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        for _, child in ipairs(children) do child.parent = ns.title; InterfaceOptions_AddCategory(child) end
    end
    ns.RefreshEffectSettings = function()
        StopListening()
        UpdateLensCategory()
        if generalPanel.content and generalPanel.refresh then generalPanel.refresh() end
        if headerHint then
            if effectPanel:IsShown() then SelectTab(selectedTab)
            else
                for index, page in pairs(pages) do
                    if not ns.IsEffectEnabled(tabSpecs[index].id) then page:Hide() end
                end
                LayoutTabs()
            end
        end
        if lensPanel.content and lensPanel:IsShown() then lensPanel.refresh() end
    end
    UpdateLensCategory()
end

function RetCinema_OpenSettings()
    if not panel then return end
    ns.RestoreUI()
    if category then Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel) end
end
