local _, ns = ...
local panel, category
local effectPanel, lensPanel, roleplayPanel
local pages, bindingButtons = {}, {}
local listening, bindingStatus, bindingLayout
local selectedTab = 1
local builders = {}
local copyDialog
local linkFonts = {}
local presetChecks = {}
local DESCRIPTION_FONT_SCALE = 1.5
local BINDING_BUTTON_WIDTH = 122
local LENS_KEY_X, MEMBERSHIP_CENTER, MEMBERSHIP_STRIDE = 120, 384, 52
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
    label:SetText(ns.FormatText(text))
    return label
end

local function Button(parent, text, width, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(ns.FormatText(text))
    button:SetScript("OnClick", onClick)
    return button
end
local function GearButton(parent, x, y, onClick)
    local button = Button(parent, "", 26, x, y, onClick)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\ret_Cinema\\Assets\\Settings")
    icon:SetPoint("CENTER"); icon:SetSize(18, 18)
    return button
end
local dialogOrder = {}
function ns.IsAddonDialogShown()
    if not UIParent:IsShown() or UIParent:GetAlpha() == 0 then return false end
    for _, dialog in ipairs(dialogOrder) do if dialog:IsShown() then return true end end
    return false
end
local function DialogBackdrop(frame)
    -- Consume Escape at the topmost addon dialog before Blizzard handles it.
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    local function Activate(self)
        for index = #dialogOrder, 1, -1 do if dialogOrder[index] == self then table.remove(dialogOrder, index) end end
        dialogOrder[#dialogOrder + 1] = self
        self:SetFrameLevel(200 + #dialogOrder * 10)
        self:SetPropagateKeyboardInput(true)
    end
    frame:HookScript("OnShow", Activate)
    Activate(frame)
    frame:SetScript("OnKeyDown", function(self, key)
        local top
        for index = #dialogOrder, 1, -1 do if dialogOrder[index]:IsShown() then top = dialogOrder[index]; break end end
        if top ~= self then return end
        if self:IsProtected() and InCombatLockdown() then return end
        local escape = key == "ESCAPE"
        self:SetPropagateKeyboardInput(not escape)
        if escape then self:Hide(); self:SetPropagateKeyboardInput(false) end
    end)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
        edgeSize = 32, insets = { left = 10, right = 10, top = 10, bottom = 10 } })
    frame:SetBackdropColor(0.025, 0.025, 0.025, 0.9)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(28, 28); close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() frame:Hide() end)
    frame.closeButton = close
end

local function ResetIcon(button)
    -- Draw an undo arrow from solid segments: no font glyph or external asset.
    local function Segment(x1, y1, x2, y2)
        local texture = button:CreateTexture(nil, "ARTWORK")
        local dx, dy = x2 - x1, y2 - y1
        texture:SetColorTexture(1, 0.82, 0, 1)
        texture:SetSize(math.sqrt(dx * dx + dy * dy), 1.6)
        texture:SetPoint("CENTER", (x1 + x2) / 2, (y1 + y2) / 2)
        texture:SetRotation(math.atan2(dy, dx))
    end
    for index = 0, 17 do
        local a, b = math.rad(-135 + index * 15), math.rad(-120 + index * 15)
        Segment(6 * math.cos(a), 6 * math.sin(a), 6 * math.cos(b), 6 * math.sin(b))
    end
    Segment(-4.25, 4.25, 0, 4.25)
    Segment(-4.25, 4.25, -4.25, 8)
end

local function Tooltip(frame, text, orange)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local hint = type(text) == "function" and text() or text
        local default = type(self.defaultHint) == "function" and self.defaultHint() or self.defaultHint
        if self.defaultValue then
            local value = self.defaultValue()
            if value ~= nil then default = value and "Checked" or "Unchecked" end
        end
        if default then hint = hint .. "\n\n" .. ns.GetPresetName() .. ": " .. default end
        GameTooltip:SetText(ns.FormatText(hint), 1, orange and 0.5 or 0.82, 0, 1, true)
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
        DialogBackdrop(copyDialog)
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
    end
    copyDialog.title:SetText(ns.FormatText(title))
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
    local r, g, b = author and 154 / 255 or 0.25, author and 205 / 255 or 0.78, author and 50 / 255 or 0.92
    local fontName = "RetCinemaLinkFont" .. (large and "Large" or "Normal") .. (author and "Author" or "Blue")
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
        button:SetShown(button.slot == 1 or (ns.Advanced("secondButton") and
            (button.action:match("^RETCINEMA_COMBINED") ~= nil or GetBindingKey(button.action) ~= nil)))
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
    checkbox.defaultHint = "Unchecked"
    local function Default()
        local hint = type(checkbox.defaultHint) == "function" and checkbox.defaultHint() or checkbox.defaultHint
        if hint ~= "Checked" and hint ~= "Unchecked" then return end
        local key = type(checkbox.defaultKey) == "function" and checkbox.defaultKey() or checkbox.defaultKey
        return ns.PresetDefault(key, hint == "Checked")
    end
    checkbox.defaultValue = Default
    local function RefreshReset()
        local value = Default()
        local needed = onClick and value ~= nil and (not not checkbox:GetChecked()) ~= value
        local reset = checkbox.reset
        if needed and not reset then
            reset = Button(checkbox, "", 18, 0, 0, function()
                checkbox:SetChecked(Default())
                checkbox:GetScript("OnClick")(checkbox)
            end)
            reset:SetSize(18, 18); ResetIcon(reset)
            Tooltip(reset, "Restore the preset value.")
            reset.defaultHint = function() return Default() and "Checked" or "Unchecked" end
            checkbox.reset = reset
        end
        if reset then
            reset:ClearAllPoints()
            if checkbox.membershipGear then reset:SetPoint("TOP", checkbox.membershipGear, "BOTTOM", 0, -2)
            else reset:SetPoint("LEFT", checkbox.resetAnchor or checkbox.label, "RIGHT", 4, 0) end
            reset:SetShown(not not needed)
            reset:SetEnabled(not checkbox.IsEnabled or checkbox:IsEnabled())
        end
    end
    checkbox.refreshReset = RefreshReset
    if onClick then
        checkbox:SetScript("OnClick", function(self, ...) onClick(self, ...); RefreshReset() end)
        hooksecurefunc(checkbox, "SetChecked", RefreshReset)
        hooksecurefunc(checkbox, "SetEnabled", RefreshReset)
        checkbox:HookScript("OnShow", RefreshReset)
        presetChecks[#presetChecks + 1] = checkbox
    end
    Tooltip(checkbox, text)
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

local function Selector(parent, width, x, y, choices, choose)
    local selector = Button(parent, "", width, x, y)
    selector.arrow = Label(selector, "v", "GameFontNormal", 0, 0)
    selector.arrow:ClearAllPoints()
    selector.arrow:SetPoint("RIGHT", -8, 0)
    selector:GetFontString():ClearAllPoints()
    selector:GetFontString():SetPoint("LEFT", 12, 0)
    selector:GetFontString():SetPoint("RIGHT", -28, 0)
    selector:GetFontString():SetJustifyH("LEFT")
    local menu = FramedBox(selector, -32, 40)
    selector.menu = menu
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(selector:GetFrameLevel() + 20)
    menu:Hide()
    local buttons = {}
    selector:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide(); return end
        local options = choices()
        for _, button in ipairs(buttons) do button:Hide() end
        for index, option in ipairs(options) do
            local button = buttons[index]
            if not button then button = Button(menu, "", width - 12, 6, -6 - (index - 1) * 28); buttons[index] = button end
            button.value = option.value
            button:SetText(option.text)
            local font = option.planned and "GameFontDisable" or "GameFontHighlight"
            button:SetNormalFontObject(font)
            button:SetHighlightFontObject(font)
            button:GetFontString():SetTextColor(option.planned and 0.5 or 1, option.planned and 0.5 or 1, option.planned and 0.5 or 1)
            button:SetScript("OnClick", function() menu:Hide(); choose(option.value) end)
            button:Show()
        end
        menu:SetHeight(#options * 28 + 12)
        menu:SetShown(#options > 0)
    end)
    selector:HookScript("OnHide", function() menu:Hide() end)
    return selector
end

local function NumericControl(parent, name, title, minimum, maximum, suffix, getValue, setValue, defaultValue, defaultKey)
    local control = CreateFrame("Frame", nil, parent)
    control:SetPoint("TOPLEFT")
    control:SetHeight(94)
    local label = Label(control, title, "GameFontNormal", 0, 0)
    label:SetWordWrap(true)
    local slider = CreateFrame("Slider", name .. "Slider", control, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 4, -40)
    slider:SetSize(170, 18)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(title:lower():find("duration", 1, true) and 0.01 or 0.1)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "SliderLow"]:SetText(minimum .. suffix)
    _G[name .. "SliderHigh"]:SetText(maximum .. suffix)
    local value = CreateFrame("EditBox", name .. "Input", control, "InputBoxTemplate")
    value:SetPoint("TOPRIGHT", -30, -36)
    value:SetSize(70, 24)
    value:SetAutoFocus(false)
    value:SetMaxLetters(12)
    local function Layout()
        local width = math.max(180, (parent:GetWidth() - 24) / 2)
        control:SetWidth(width)
        label:SetWidth(width)
        slider:SetWidth(width - 118)
    end
    parent:HookScript("OnSizeChanged", Layout)
    Layout()
    local function Default()
        local value = type(defaultValue) == "function" and defaultValue() or defaultValue or minimum
        return ns.PresetDefault(type(defaultKey) == "function" and defaultKey() or defaultKey, value)
    end
    local reset
    local function ShowValue()
        value:SetText(string.format("%g", math.max(minimum, math.min(maximum, getValue()))) .. suffix)
        if reset then reset:SetShown(math.abs(getValue() - Default()) > 0.000001) end
    end
    Tooltip(value, "Enter an exact value.")
    value.defaultHint = function() return string.format("%g", Default()) .. suffix end
    reset = Button(control, "", 24, 0, 0, function()
        value:ClearFocus()
        if setValue(Default()) then control.refresh() end
    end)
    reset:ClearAllPoints(); reset:SetPoint("LEFT", value, "RIGHT", 4, 0)
    ResetIcon(reset)
    Tooltip(reset, "Restore the preset value.")
    reset.defaultHint = value.defaultHint
    control.input, control.slider, control.reset = value, slider, reset
    value:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    local function Commit(self)
        local number = tonumber((self:GetText():gsub("%%", ""):gsub(",", "."):gsub("%s*[sS]%s*$", "")))
        if setValue(number) then
            control.refreshing = true
            slider:SetValue(getValue())
            control.refreshing = false
        end
        ShowValue()
    end
    value:SetScript("OnEnterPressed", function(self) Commit(self); self:ClearFocus() end)
    value:SetScript("OnEditFocusLost", Commit)
    value:SetScript("OnEscapePressed", function(self) ShowValue(); self:ClearFocus() end)
    slider:SetScript("OnValueChanged", function(_, number) if not control.refreshing then setValue(number) end; ShowValue() end)
    control.setRange = function(low, high)
        minimum, maximum = low, high
        slider:SetMinMaxValues(low, high)
        _G[name .. "SliderLow"]:SetText(low .. suffix)
        _G[name .. "SliderHigh"]:SetText(high .. suffix)
    end
    control.refresh = function(enabled)
        control.refreshing = true
        slider:SetEnabled(enabled ~= false)
        value:SetEnabled(enabled ~= false)
        reset:SetEnabled(enabled ~= false)
        slider:SetValue(math.max(minimum, math.min(maximum, getValue())))
        ShowValue()
        control.refreshing = false
    end
    return control
end

local advancedDialog
local function OpenAdvanced()
    if advancedDialog and advancedDialog:IsShown() then advancedDialog:Hide(); return end
    if not advancedDialog then
        local dialog = CreateFrame("Frame", "RetCinemaAdvancedDialog", UIParent, "BackdropTemplate")
        advancedDialog = dialog
        dialog:SetSize(470, 570); dialog:SetPoint("CENTER"); dialog:SetFrameStrata("DIALOG"); dialog:EnableMouse(true)
        DialogBackdrop(dialog)
        dialog.title = SettingsHeading(dialog, "Advanced Cinematographer")
        dialog.title:SetTextColor(1, 0.82, 0)
        table.insert(UISpecialFrames, "RetCinemaAdvancedDialog")
        local scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 24, -58); scroll:SetSize(400, 450)
        local body = CreateFrame("Frame", nil, scroll); body:SetSize(392, 450); scroll:SetScrollChild(body)
        dialog.body, dialog.checks, dialog.groups = body, {}, {}
        local lite = { name = "LiteRP", id = "roleplay", experimental = true, children = {
            { name = "Move", children = { { name = "Walk", id = "rpWalk" } } },
            { name = "Stay", children = {
                { name = "Sit", id = "rpSit" }, { name = "Lay", id = "rpLay" },
                { name = "Lean", id = "rpLean" }, { name = "GoOffline", id = "rpLogout" },
            } },
        } }
        local roots = { { name = "Effect", children = {} }, { name = "Lens", children = {} }, lite }
        for _, name in ipairs({ "HideUI", "Letterbox", "CameraShift", "FOV" }) do
            roots[1].children[#roots[1].children + 1] = { name = name, children = {} }
        end
        for _, option in ipairs(ns.advancedOptions) do
            if option.group ~= "LiteRP" then
                local destination = option.group == "Lens" and roots[2]
                if not destination then for _, node in ipairs(roots[1].children) do if node.name == option.group then destination = node end end end
                destination.children[#destination.children + 1] = { name = option.name, id = option.id, experimental = option.experimental }
            end
        end
        local function Value(node)
            if node.id then return ns.db.advanced[node.id] end
            return node.expanded
        end
        local function AnyEnabled(node)
            if node.id then return Value(node) end
            for _, child in ipairs(node.children) do if AnyEnabled(child) then return true end end
            return false
        end
        local function Layout(nodes, depth, y, shown)
            for _, node in ipairs(nodes) do
                local option = node.id
                if shown and not node.control then
                    if option then
                        node.control = Checkbox(body, (node.experimental and ns.ChatText("RAID_LEADER", "[Experimental]") .. " " or "") .. (node.name == "LiteRP" and ns.ChatText("EMOTE", "LiteRP") or node.name), 0, 0, function(self)
                            ns.SetAdvanced(node.id, self:GetChecked())
                            dialog.refresh()
                        end)
                        if node.children and not node.experimental then node.control.label:SetTextColor(1, 0.82, 0) end
                        Tooltip(node.control, node.id == "letterboxFull" and "Show the option to allow each bar to cover up to half the screen." or "Show " .. node.name .. " settings. This does not enable the action or change its settings.")
                        dialog.checks[node.id] = node.control
                        node.control.defaultKey = "advanced." .. node.id
                    else
                        node.expanded = AnyEnabled(node)
                        node.control = Button(body, "+", 24, 0, 0, function() node.expanded = not node.expanded; dialog.refresh() end)
                        node.control.label = Label(node.control, node.name, "GameFontNormal", 30, -6)
                        node.control.label:SetTextColor(1, 0.82, 0)
                        Tooltip(node.control, "Expand or collapse this group. Enabled features are preserved.")
                    end
                    if node.children then dialog.groups[node.name] = node.control end
                end
                if node.control then
                    node.control:SetShown(shown)
                    if option then node.control:SetChecked(Value(node)) else node.control:SetText(node.expanded and "-" or "+") end
                    if shown then node.control:SetPoint("TOPLEFT", depth * 24 - 4, y); y = y - 30 end
                end
                if node.children then y = Layout(node.children, depth + 1, y, shown and Value(node)) end
            end
            return y
        end
        dialog.refresh = function() body:SetHeight(math.max(450, -Layout(roots, 0, 0, true) + 12)) end
    end
    advancedDialog.refresh()
    advancedDialog:Show()
end

builders.general = function(page, content)
    local minimap = Checkbox(content, "Show minimap icon", -4, 0,
        function(self) ns.SetMinimapButton(self:GetChecked()) end)
    minimap.defaultHint = "Checked"
    minimap.defaultKey = "showMinimapButton"
    local advanced = Checkbox(content, "", 240, 0, function(self)
        ns.SetAdvanced(nil, self:GetChecked())
        page.refresh()
    end)
    local advancedButton = Button(content, "Advanced Cinematographer", 236, 270, 0, OpenAdvanced)
    advancedButton:SetDisabledFontObject("GameFontDisable")
    advanced.frameRole = "advancedMaster"
    advanced.defaultKey, advanced.resetAnchor = "advancedCinematographer", advancedButton
    advancedButton:SetMotionScriptsWhileDisabled(true)
    Tooltip(advanced, "Allow access to hidden, additional and " .. ns.ChatText("RAID_LEADER", "Experimental") .. " options.")
    Tooltip(advancedButton, ns.ChatText("SYSTEM", "Warning!") .. " Options that are not enabled by default may worsen your user experience.")
    Label(content, "Global Preset:", "GameFontNormal", 0, -46)
    local preset = Selector(content, 180, 120, -40, function()
        local choices = {}
        for _, entry in ipairs(ns.presets) do choices[#choices + 1] = { value = entry.name, text = ns.FormatText(entry.name) } end
        return choices
    end, ns.SetGlobalPreset)
    preset.frameRole = "globalPreset"
    Tooltip(preset, "Choose the reference values used by preset hints and reset buttons. Existing settings are preserved.")
    Label(content, "Enable Effect:", "GameFontNormal", 0, -94)
    local box = FramedBox(content, -120, 50)
    local checks = {}
    for _, effect in ipairs(ns.effects) do
        local checkbox = Checkbox(box, effect.name, 8, -8,
            function(self) ns.SetEffectEnabled(effect.id, self:GetChecked()) end)
        if effect.underConsideration then checkbox.label:SetTextColor(0.5, 0.5, 0.5) end
        local hint = effect.description
        if effect.id == "camerashift" then
            hint = hint .. "\nEnabling CameraShift also allows Blizzard's experimental camera features. Camera changes may cause visual discomfort."
        end
        checkbox.defaultHint = effect.id == "camerashift" and "Unchecked" or "Checked"
        checkbox.defaultKey = "effects." .. effect.id
        Tooltip(checkbox, hint)
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
    content:SetHeight(480)
    page.refresh = function()
        minimap:SetChecked(ns.db.showMinimapButton)
        advanced:SetChecked(ns.db.advancedCinematographer)
        advanced.label:Hide()
        advancedButton:SetEnabled(ns.db.advancedCinematographer)
        preset:SetText(ns.FormatText(ns.GetPresetName()))
        if not ns.db.advancedCinematographer and advancedDialog then advancedDialog:Hide() end
        page.layoutEffects()
    end
    page:HookScript("OnHide", function() preset.menu:Hide() end)
end

local function ExtraOptions(parent, effect, permanent, indexGetter, namePrefix)
    local controls, durationChecks = {}, {}
    local refresh
    local function Source() local index = indexGetter and indexGetter(); return index and index > 1 and ns.db.extraCombinedLenses[index] or ns.db end
    local function Key(spec) return permanent and "permanent" .. spec.key:sub(1, 1):upper() .. spec.key:sub(2) or spec.key end
    local function Path(key)
        local index = indexGetter and indexGetter()
        return index and index > 1 and "extraCombinedLenses." .. index .. "." .. key or key
    end
    refresh = function(y, shown)
        for _, spec in ipairs(ns.settingSpecs) do
            if spec.effect == effect and not spec.duration then
                local visible = shown ~= false and (not spec.advanced or ns.Advanced(spec.advanced))
                local control = controls[spec.key]
                if spec.key:match("Duration$") then
                    local custom
                    for _, candidate in ipairs(ns.settingSpecs) do if candidate.duration == spec.key then custom = candidate; break end end
                    local check = durationChecks[spec.key]
                    if visible and not check then
                        local key = spec.key
                        check = Checkbox(parent, custom.label, -4, y, function(self)
                            ns.SetEffectSetting(custom.key, self:GetChecked(), permanent, indexGetter and indexGetter())
                            ns.RefreshEffectSettings()
                        end)
                        check.durationKey, check.permanentMode = key, permanent
                        check.defaultKey = function() return Path(Key(custom)) end
                        durationChecks[key] = check
                    end
                    if check then
                        check:SetShown(visible); check:SetChecked(Source()[Key(custom)] == true)
                        if visible then check:SetPoint("TOPLEFT", -4, y); y = y - 32 end
                    end
                    visible = visible and Source()[Key(custom)] == true
                end
                if visible then
                    if not control then
                        local setting = spec
                        local function Set(value)
                            if parent.closing then return false end
                            return ns.SetEffectSetting(setting.key, value, permanent, indexGetter and indexGetter())
                        end
                        if type(spec.default) == "boolean" then
                            control = Checkbox(parent, spec.label, -4, y, function(self)
                                local checked = self:GetChecked()
                                Set(checked)
                            end)
                            control.defaultHint = spec.default and "Checked" or "Unchecked"
                            control.defaultKey = function() return Path(Key(setting)) end
                            control.refresh = function()
                                local checked = Source()[Key(setting)]
                                control:SetChecked(checked)
                                control:SetEnabled(not setting.cvar or ns.GetCVar(setting.cvar) ~= nil)
                            end
                        else
                            local opacity = spec.key == "letterboxOpacity"
                            control = NumericControl(parent, namePrefix .. spec.key, spec.label,
                                spec.low, opacity and 100 or spec.high, opacity and "%" or "",
                                function() return Source()[Key(setting)] * (opacity and 100 or 1) end,
                                function(value) if not value then return false end; return Set(value / (opacity and 100 or 1)) end,
                                function() return ns.PresetDefault(Path(Key(setting)), spec.default) * (opacity and 100 or 1) end)
                        end
                        if spec.tooltip then Tooltip(control, spec.tooltip) end
                        control.settingKey, control.permanentMode = spec.key, permanent
                        controls[spec.key] = control
                    end
                    control:ClearAllPoints()
                    control:SetPoint("TOPLEFT", type(spec.default) == "boolean" and -4 or 0, y)
                    control:Show()
                    control.refresh()
                    y = y - (type(spec.default) == "boolean" and 32 or 94)
                elseif control then control:Hide() end
            end
        end
        return y
    end
    return refresh
end

builders.hideui = function(page, content)
    PlannedPermanent(content, "Permanent HideUI", 0)
    local apply = Checkbox(content, "Apply HideUI to Lens", -4, -36, function(self)
        ns.SetApplyToLens("hideui", self:GetChecked())
    end)
    apply.defaultHint = "Checked"
    apply.defaultKey = "lensEffects.hideui"
    local extras = ExtraOptions(content, "hideui", false, nil, "RetCinemaHideUI")
    page.refresh = function()
        apply:SetChecked(ns.IsAppliedToLens("hideui"))
        local y = extras(-80, ns.IsAppliedToLens("hideui"))
        content:SetHeight(math.max(140, -y + 32))
    end
    content:SetHeight(140)
end

local function BuildLayeredEffect(page, content, camera)
    local id = camera and "camerashift" or "letterbox"
    local permanentField = camera and "permanentCameraShift" or "permanentLetterbox"
    local permanentValue = camera and "permanentCameraOffset" or "permanentLetterboxHeight"
    local lensValue = camera and "cameraOffset" or "letterboxHeight"
    local setPermanent = camera and ns.SetPermanentCameraShift or ns.SetPermanentLetterbox
    local setValue = camera and ns.SetCameraOffset or ns.SetLetterboxHeight
    local permanentControl, lensControl
    local permanentExtras = ExtraOptions(content, id, true, nil, "RetCinemaPermanent")
    local lensExtras = ExtraOptions(content, id, false, nil, "RetCinemaLens")
    local permanent = Checkbox(content, camera and "Permanent CameraShift" or "Permanent Letterbox", -4, 0,
        function(self) setPermanent(self:GetChecked()); page.refresh() end)
    permanent.defaultKey = permanentField
    local apply = Checkbox(content, camera and "Apply CameraShift to Lens" or "Apply Letterbox to Lens", -4, 0,
        function(self) ns.SetApplyToLens(id, self:GetChecked()) end)
    apply.defaultHint = "Checked"
    apply.defaultKey = "lensEffects." .. id
    local unsupported
    if camera then unsupported = Label(content, "CameraShift is not supported by this client.", "GameFontNormal", 0, 0) end
    local function MakeControl(permanentMode)
        local name = camera and (permanentMode and "RetCinemaPermanentCameraOffset" or "RetCinemaCameraOffset") or
            (permanentMode and "RetCinemaPermanentBarHeight" or "RetCinemaBarHeight")
        local field = permanentMode and permanentValue or lensValue
        local title
        if camera then title = permanentMode and "Permanent shoulder camera offset" or "Lens shoulder camera offset"
        else title = permanentMode and "Permanent bar height" or "Lens bar height" end
        return NumericControl(content, name, title,
            camera and -15 or 0, camera and 15 or 25, camera and "" or "%",
            function() return ns.db[field] end, function(value) return setValue(value, permanentMode) end,
            camera and (permanentMode and 1.5 or ns.defaults.cameraOffset) or (permanentMode and 10 or ns.defaults.letterboxHeight), field)
    end
    page.refresh = function()
        local usable = not camera or (ns.CameraAvailable() and ns.db.cameraConsent)
        permanent:SetChecked(ns.db[permanentField])
        permanent:SetEnabled(usable)
        apply:SetEnabled(usable)
        permanent:SetPoint("TOPLEFT", -4, 0)
        local y = -36
        if ns.db[permanentField] then
            if not permanentControl then permanentControl = MakeControl(true) end
            permanentControl:SetPoint("TOPLEFT", 0, y)
            permanentControl:Show()
            if not camera then permanentControl.setRange(0, ns.LetterboxMaximum()) end
            permanentControl.refresh(usable)
            y = y - 106
            y = permanentExtras(y)
        else
            if permanentControl then permanentControl:Hide() end
            permanentExtras(0, false)
        end
        apply:SetPoint("TOPLEFT", -4, y)
        apply:SetChecked(ns.IsAppliedToLens(id))
        y = y - 36
        if ns.IsAppliedToLens(id) then
            if not lensControl then lensControl = MakeControl(false) end
            lensControl:SetPoint("TOPLEFT", 0, y)
            lensControl:Show()
            if not camera then lensControl.setRange(0, ns.LetterboxMaximum()) end
            lensControl.refresh(usable)
            y = y - 96
            y = lensExtras(y)
        else
            if lensControl then lensControl:Hide() end
            lensExtras(0, false)
        end
        if unsupported then
            unsupported:SetPoint("TOPLEFT", 0, y)
            unsupported:SetShown(not ns.CameraAvailable())
        end
        content:SetHeight(math.max(200, -y + 40))
    end
end
builders.letterbox = function(page, content) BuildLayeredEffect(page, content, false) end
builders.camerashift = function(page, content) BuildLayeredEffect(page, content, true) end

local function BuildPlannedEffect(page, content)
    local permanent = PlannedPermanent(content, "Permanent SmoothMotion", 0)
    Tooltip(permanent, "Under consideration. This Effect is not available yet.")
    local apply = Checkbox(content, "Apply SmoothMotion to Lens", -4, -40)
    apply:SetEnabled(false)
    apply:SetChecked(false)
    apply.label:SetTextColor(0.5, 0.5, 0.5)
    apply:SetMotionScriptsWhileDisabled(true)
    Tooltip(apply, "Under consideration. This Effect is not available yet.")
    local box = FramedBox(content, -88, 124)
    Label(box, "Smoothing amount", "GameFontDisable", 12, -14)
    local slider = CreateFrame("Slider", "RetCinemaSmoothMotionSlider", box, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -50)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(0, 100)
    slider:SetValue(50)
    slider:SetEnabled(false)
    _G[slider:GetName() .. "Low"]:SetText("Low")
    _G[slider:GetName() .. "High"]:SetText("High")
    content:SetHeight(400)
end
builders.fov = function(page, content)
    local permanentControl, lensControl
    local permanentExtras = ExtraOptions(content, "fov", true, nil, "RetCinemaPermanentFOV")
    local lensExtras = ExtraOptions(content, "fov", false, nil, "RetCinemaLensFOV")
    local permanent = Checkbox(content, "Permanent FOV", -4, 0, function(self) ns.SetPermanentFOV(self:GetChecked()); page.refresh() end)
    local apply = Checkbox(content, "Apply FOV to Lens", -4, -36, function(self) ns.SetApplyToLens("fov", self:GetChecked()) end)
    permanent.defaultKey, apply.defaultKey = "permanentFOV", "lensEffects.fov"
    local unsupported = Label(content, "FOV is not supported by this client.", "GameFontNormal", 0, -80)
    local function Control(permanentMode)
        local low, high = ns.FOVRange()
        return NumericControl(content, permanentMode and "RetCinemaPermanentFOV" or "RetCinemaFOV",
            permanentMode and "Permanent field of view" or "Lens field of view", low, high, "",
            function() return ns.db[permanentMode and "permanentFov" or "fov"] end,
            function(value) return ns.SetFOV(value, permanentMode) end, ns.FOVDefault, permanentMode and "permanentFov" or "fov")
    end
    page.refresh = function()
        local usable, y = ns.FOVAvailable(), -36
        permanent:SetChecked(ns.db.permanentFOV); permanent:SetEnabled(usable)
        apply:SetChecked(ns.IsAppliedToLens("fov")); apply:SetEnabled(usable)
        if ns.db.permanentFOV then
            permanentControl = permanentControl or Control(true)
            permanentControl:SetPoint("TOPLEFT", 0, y); permanentControl:Show(); permanentControl.refresh(usable)
            y = permanentExtras(y - 106)
        else
            if permanentControl then permanentControl:Hide() end
            permanentExtras(0, false)
        end
        apply:SetPoint("TOPLEFT", -4, y); y = y - 36
        if ns.IsAppliedToLens("fov") then
            lensControl = lensControl or Control(false)
            lensControl:SetPoint("TOPLEFT", 0, y); lensControl:Show(); lensControl.refresh(usable)
            y = lensExtras(y - 106)
        else
            if lensControl then lensControl:Hide() end
            lensExtras(0, false)
        end
        unsupported:SetPoint("TOPLEFT", 0, y); unsupported:SetShown(not usable)
        content:SetHeight(math.max(200, -y + 40))
    end
end
builders.smoothmotion = BuildPlannedEffect

local combinedDialog
local function CombinedSettingsChoices(action)
    local choices = {}
    for index = 1, ns.GetCombinedCount() do
        if ns.GetCombinedActions(index)[action.binding] then choices[#choices + 1] = { value = index, text = "Combined Lens " .. index } end
    end
    return choices
end
local function HasCombinedSettings(action)
    return (action.effect ~= "hideui" or ns.Advanced("hideInterface") or ns.Advanced("hideNames")) and #CombinedSettingsChoices(action) > 0
end
local function ClearDialogFocus()
    local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focus then focus:ClearFocus() end
end
function ns.CloseCombinedSettings()
    if combinedDialog then combinedDialog:Hide() end
end
function ns.RefreshCombinedSettings()
    local dialog = combinedDialog
    if not dialog or not dialog:IsShown() then return end
    if not HasCombinedSettings(dialog.action) or
        not ns.IsEffectEnabled(dialog.action.effect) or not ns.IsAppliedToLens(dialog.action.effect) then
        dialog:Hide()
    else
        if not ns.GetCombinedActions(dialog.index) or not ns.GetCombinedActions(dialog.index)[dialog.action.binding] or dialog.index > ns.GetCombinedCount() then
            dialog.index = CombinedSettingsChoices(dialog.action)[1].value
        end
        dialog.refresh()
    end
end
local function OpenCombinedSettings(action, requestedIndex)
    if combinedDialog and combinedDialog:IsShown() and combinedDialog.action == action and combinedDialog.index == requestedIndex then combinedDialog:Hide(); return end
    if not HasCombinedSettings(action) then return end
    if not ns.GetCombinedActions(requestedIndex)[action.binding] then return end
    if not combinedDialog then
        local dialog = CreateFrame("Frame", "RetCinemaCombinedSettingsDialog", UIParent, "BackdropTemplate")
        combinedDialog = dialog
        dialog:SetSize(620, 664)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)
        table.insert(UISpecialFrames, "RetCinemaCombinedSettingsDialog")
        DialogBackdrop(dialog)
        dialog.title = SettingsHeading(dialog, "")
        dialog.effectSelector = Selector(dialog, 272, 0, 0, function()
            local choices = {}
            for index, item in ipairs(ns.actions) do
                if ns.IsActionEnabled(item) and HasCombinedSettings(item) then choices[#choices + 1] = { value = index, text = _G["BINDING_NAME_" .. item.binding] } end
            end
            return choices
        end, function(index)
            ClearDialogFocus()
            dialog.action = ns.actions[index]
            if not ns.GetCombinedActions(dialog.index)[dialog.action.binding] then dialog.index = CombinedSettingsChoices(dialog.action)[1].value end
            dialog.refresh()
        end)
        dialog.effectSelector:ClearAllPoints(); dialog.effectSelector:SetPoint("TOP", dialog, "TOP", 0, -76)
        dialog.effectSelector:SetHeight(30)
        dialog.selector = Selector(dialog, 272, 0, 0, function()
            return CombinedSettingsChoices(dialog.action)
        end, function(index)
            ClearDialogFocus()
            dialog.index = index
            dialog.refresh()
        end)
        dialog.selector:ClearAllPoints()
        dialog.selector:SetPoint("TOP", dialog, "TOP", 0, -120)
        dialog.selector:SetHeight(30)
        local function Cycle(direction)
            local choices = CombinedSettingsChoices(dialog.action)
            local position = 1
            for index, choice in ipairs(choices) do if choice.value == dialog.index then position = index; break end end
            if #choices == 0 then return end
            ClearDialogFocus()
            dialog.index = choices[(position - 1 + direction) % #choices + 1].value
            dialog.refresh()
        end
        dialog.previous = Button(dialog, "<", 30, 0, 0, function() Cycle(-1) end)
        dialog.next = Button(dialog, ">", 30, 0, 0, function() Cycle(1) end)
        dialog.previous:ClearAllPoints(); dialog.next:ClearAllPoints()
        dialog.previous:SetPoint("RIGHT", dialog.selector, "LEFT", -8, 0); dialog.next:SetPoint("LEFT", dialog.selector, "RIGHT", 8, 0)
        dialog.previous:SetHeight(30); dialog.next:SetHeight(30)
        dialog.counter = Label(dialog, "", "GameFontHighlightSmall", 0, 0)
        dialog.counter:ClearAllPoints()
        dialog.counter:SetPoint("LEFT", dialog.next, "RIGHT", 12, 0)
        dialog.description = PageDescription(dialog, "")
        dialog.description:ClearAllPoints()
        dialog.description:SetPoint("TOPLEFT", 20, -168)
        dialog.description:SetPoint("TOPRIGHT", -20, -168)
        dialog.hint = Label(dialog, "Settings apply the next time this Combined Lens is enabled.", "GameFontNormal", 0, 0)
        dialog.hint:ClearAllPoints()
        dialog.hint:SetPoint("TOPLEFT", dialog.description, "BOTTOMLEFT", 0, -10)
        dialog.hint:SetPoint("TOPRIGHT", dialog.description, "BOTTOMRIGHT", 0, -10)
        dialog.hint:SetWordWrap(true)
        local body = CreateFrame("Frame", nil, dialog)
        body:SetPoint("TOPLEFT", dialog.hint, "BOTTOMLEFT", 0, -28)
        body:SetWidth(580)
        body:SetHeight(250)
        dialog.body, dialog.controls = body, {}
        dialog.extraGroups = {}
        dialog.refresh = function()
            local effect = dialog.action.effect
            dialog.title:SetText(_G["BINDING_NAME_" .. dialog.action.binding])
            dialog.effectSelector:SetText(_G["BINDING_NAME_" .. dialog.action.binding])
            for _, item in ipairs(ns.effects) do if item.id == effect then dialog.description:SetText(item.description) end end
            dialog.selector:SetText("Combined Lens " .. dialog.index)
            local choices = CombinedSettingsChoices(dialog.action)
            dialog.previous:SetEnabled(#choices > 1); dialog.next:SetEnabled(#choices > 1)
            for position, choice in ipairs(choices) do
                if choice.value == dialog.index then dialog.counter:SetText(position .. " / " .. #choices) end
            end
            local numeric = effect ~= "hideui"
            for _, control in pairs(dialog.controls) do control:Hide() end
            for _, group in pairs(dialog.extraGroups) do group:Hide() end
            local y = 0
            if numeric then
                local control = dialog.controls[effect]
                if not control then
                    local selectedEffect = effect
                    local low, high = 0, 25
                    if effect == "camerashift" then low, high = -15, 15 elseif effect == "fov" then low, high = ns.FOVRange() end
                    control = NumericControl(body, "RetCinemaCombined" .. (effect == "letterbox" and "BarHeight" or effect == "fov" and "FOV" or "CameraOffset"),
                        effect == "letterbox" and "Lens bar height" or effect == "fov" and "Lens field of view" or "Lens shoulder camera offset",
                        low, high, effect == "letterbox" and "%" or "",
                        function() return ns.GetCombinedEffectValue(dialog.index, selectedEffect) end,
                        function(value)
                            if dialog.closing then return false end
                            return ns.SetCombinedEffectValue(dialog.index, selectedEffect, value)
                        end, effect == "letterbox" and ns.defaults.letterboxHeight or effect == "fov" and ns.FOVDefault() or ns.defaults.cameraOffset,
                        function()
                            local field = selectedEffect == "letterbox" and "letterboxHeight" or selectedEffect == "fov" and "fov" or "cameraOffset"
                            return dialog.index > 1 and "extraCombinedLenses." .. dialog.index .. "." .. field or field
                        end)
                    control:SetPoint("TOPLEFT", 0, 0)
                    dialog.controls[effect] = control
                end
                control:Show()
                if effect == "letterbox" then control.setRange(0, ns.LetterboxMaximum()) end
                control.refresh(true)
                y = -100
            end
            local group = dialog.extraGroups[effect]
            if not group then
                group = CreateFrame("Frame", nil, body)
                group:SetWidth(580); group:SetHeight(300)
                group.layout = ExtraOptions(group, effect, false, function() return dialog.index end, "RetCinemaCombinedExtra" .. effect)
                dialog.extraGroups[effect] = group
            end
            group:SetPoint("TOPLEFT", 0, y)
            group:Show(); group.layout(0)
        end
        dialog:SetScript("OnHide", function()
            dialog.closing = true
            for _, group in pairs(dialog.extraGroups) do group.closing = true end
            ClearDialogFocus()
            dialog.selector.menu:Hide()
            dialog.effectSelector.menu:Hide()
            dialog.closing = false
            for _, group in pairs(dialog.extraGroups) do group.closing = false end
        end)
    end
    ClearDialogFocus()
    local dialog = combinedDialog
    dialog.action = action
    dialog.index = requestedIndex
    for _, effect in ipairs(ns.effects) do if effect.id == action.effect then dialog.description:SetText(effect.description) end end
    dialog:Show()
    dialog.refresh()
end

builders.lens = function(page, content)
    local listedCount, pendingCount = 1, 1
    Label(content, "Effect", "GameFontNormal", 12, 0)
    local keyHeader = Label(content, "Lens button", "GameFontNormal", LENS_KEY_X + 12, 0)
    keyHeader:SetWidth(BINDING_BUTTON_WIDTH)
    keyHeader:SetJustifyH("CENTER")
    local addHeader = Label(content, "", "GameFontNormal", MEMBERSHIP_CENTER + 12 - 120, 0)
    addHeader:SetWidth(240)
    addHeader:SetWordWrap(true)
    addHeader:SetJustifyH("CENTER")
    Divider(content, "TOP", -38)
    local rows, combinedRows = {}, {}
    local function BindingRow(parent, binding, effect, command, combinedIndex)
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(518, 26)
        row.binding, row.effect, row.combinedIndex = binding, effect, combinedIndex
        row.label = Label(row, _G["BINDING_NAME_" .. binding], "GameFontHighlight", 0, -6)
        CreateBindingButton(row, binding, 1, LENS_KEY_X, 0)
        row.orLabel = Label(row, "or", "GameFontHighlightSmall", LENS_KEY_X, -29)
        row.orLabel:SetWidth(BINDING_BUTTON_WIDTH)
        row.orLabel:SetJustifyH("CENTER")
        CreateBindingButton(row, binding, 2, LENS_KEY_X, -48)
        local hover = CreateFrame("Frame", nil, row)
        hover:SetPoint("TOPLEFT")
        hover:SetSize(LENS_KEY_X - 4, 26)
        Tooltip(hover, "Can be enabled via\n/retcin " .. command)
        return row
    end
    local function PlaceRow(row, y, minimum)
        local second = ns.Advanced("secondButton") and (row.combinedIndex ~= nil or GetBindingKey(row.binding) ~= nil)
        row.orLabel:SetShown(second)
        row:SetHeight(math.max(row.combinedIndex and (second and 114 or 66) or second and 74 or 26, minimum or 0))
        if row.escape then row.escape:SetPoint("TOPLEFT", LENS_KEY_X - 4, second and -84 or -36) end
        row:SetPoint("TOPLEFT", 12, y)
        row:SetPoint("TOPRIGHT", -12, y)
        return y - row:GetHeight()
    end
    local combinedBox = FramedBox(content, 0, 110)
    local function BuildCombined(index)
        local row = BindingRow(combinedBox, ns.CombinedBinding(index), nil, "combinedlens" .. index, index)
        local font, size, flags = row.label:GetFont()
        row.label:SetFont(font, size + 2, flags)
        row.escape = Checkbox(row, "Escape Button", LENS_KEY_X - 4, -84, function(self)
            local checked = self:GetChecked()
            StopListening()
            ns.SetCombinedExitAll(index, checked)
            self:SetChecked(checked)
        end)
        row.escape:SetMotionScriptsWhileDisabled(true)
        row.escape.defaultKey = index == 1 and "combinedAsEsc" or "extraCombinedLenses." .. index .. ".exitAll"
        row.summary = Label(row, "", "GameFontHighlightSmall", MEMBERSHIP_CENTER - 120, -6)
        row.summary:SetWidth(240)
        row.summary:SetJustifyH("CENTER")
        row.summary:SetWordWrap(true)
        Tooltip(row.escape, function()
            return ns.IsRoleplayActive() and "Effects controlled by an RP action ignore Lens buttons until that action ends. Unrelated Effects can still toggle; Escape Button behavior resumes afterward." or
                (not ns.HasCombinedActions(index) and "Exit all active Lenses with this button. Permanent Effects are preserved." or
                "Press again to exit all Lenses when only this Combined Lens's Effects remain. Otherwise, replace the remaining Effects with this Lens first. Permanent Effects are preserved.")
        end)
        if index > 1 then Divider(row, "TOP", 16) end
        combinedRows[index] = row
        return row
    end
    local add = Button(combinedBox, "+", 28, 12, 0, function()
        StopListening()
        local target = listedCount + 1
        if target > ns.GetCombinedCount() then ns.AddCombinedLens() end
        pendingCount = target
        RefreshBindings()
    end)
    local remove = Button(combinedBox, "-", 28, 46, 0, function()
        StopListening()
        local target = listedCount
        pendingCount = 1
        while ns.GetCombinedCount() >= target and ns.GetCombinedCount() > 1 do if not ns.RemoveCombinedLens() then break end end
        RefreshBindings()
    end)
    Tooltip(add, "Add another Combined Lens (up to five).")
    Tooltip(remove, "Hide the last Combined Lens. Its settings and keybindings are kept.")
    bindingStatus = LargeYellow(Label(content, "", "GameFontHighlight", 0, 0), 1.5)
    local function RefreshLens()
        local count = math.min(pendingCount, ns.GetCombinedCount())
        for index = 2, ns.GetCombinedCount() do if ns.HasCombinedActions(index) or ns.GetCombinedExitAll(index) then count = math.max(count, index) end end
        count = math.max(1, count)
        listedCount = count
        addHeader:SetText(count == 1 and "Add to Combined Lens" or "Add to a specific Combined Lens")
        local y, visible = -52, 0
        for _, row in ipairs(rows) do
            local listed = ns.IsEffectEnabled(row.effect) and ns.IsAppliedToLens(row.effect)
            row:SetShown(listed)
            for index = 1, count do
                if not row.checks[index] then
                    local lensIndex = index
                    local check = Checkbox(count > 1 and row.extraContainer or row, "", 0, -1, function(self)
                        -- Refreshing key buttons also refreshes checks: capture the new value first.
                        local checked = self:GetChecked()
                        StopListening()
                        ns.SetCombinedAction(row.binding, checked, lensIndex)
                        pendingCount = 1
                        self:SetChecked(checked)
                        RefreshBindings()
                        ns.RefreshCombinedSettings()
                    end)
                    Tooltip(check, function()
                        return "Add " .. _G["BINDING_NAME_" .. row.binding] .. " to Combined Lens " .. lensIndex
                    end)
                    row.checks[index] = check
                    local gear = GearButton(row.extraContainer, 0, 0, function() StopListening(); OpenCombinedSettings(ns.actions[row.actionIndex], lensIndex) end)
                    gear:SetSize(18, 24)
                    gear.frameRole, gear.lensIndex = "combinedEffectSettings", lensIndex
                    Tooltip(gear, "Configure " .. _G["BINDING_NAME_" .. row.binding] .. " for Combined Lens " .. lensIndex .. ".")
                    row.gears[index] = gear
                    check.membershipGear = gear
                    check.defaultKey = lensIndex == 1 and "combinedActions." .. row.binding or "extraCombinedLenses." .. lensIndex .. ".actions." .. row.binding
                    if index > 1 then
                        local rule = row.extraContainer:CreateTexture(nil, "ARTWORK")
                        rule:SetColorTexture(0.6, 0.6, 0.6, 0.3); rule:SetSize(1, 32)
                        row.membershipRules[index] = rule
                    end
                end
            end
            for index, check in ipairs(row.checks) do
                check:SetParent(count > 1 and row.extraContainer or row)
                check:SetShown(index <= count)
                check:SetChecked(ns.GetCombinedActions(index)[row.binding])
                check:ClearAllPoints()
                check:SetSize(22, 24)
                check:SetPoint("TOPLEFT", count == 1 and MEMBERSHIP_CENTER - 21 or 4 + (index - 1) * MEMBERSHIP_STRIDE, -1)
                check.label:SetText(count > 1 and tostring(index) or "")
                check.label:ClearAllPoints()
                check.label:SetPoint("TOP", check, "BOTTOM", 0, 0)
                local gear = row.gears[index]
                gear:SetParent(count > 1 and row.extraContainer or row)
                gear:SetShown(index <= count)
                gear:SetEnabled(ns.GetCombinedActions(index)[row.binding] == true and HasCombinedSettings(ns.actions[row.actionIndex]))
                gear:ClearAllPoints(); gear:SetPoint("TOPLEFT", check, "TOPRIGHT", 2, 0)
                local rule = row.membershipRules[index]
                if rule then
                    rule:SetShown(index <= count); rule:SetPoint("TOPLEFT", (index - 1) * MEMBERSHIP_STRIDE, 0)
                end
            end
            row.extraContainer:SetShown(count >= 2)
            row.extraContainer:SetSize(count * MEMBERSHIP_STRIDE + 8, 50)
            row.extraContainer:SetPoint("TOPLEFT", MEMBERSHIP_CENTER - (count * MEMBERSHIP_STRIDE + 8) / 2, 0)
            if listed then y = PlaceRow(row, y, 42) - 28; visible = visible + 1 end
        end
        combinedBox:SetShown(visible > 0)
        local combinedY = -18
        local escapeLens = ns.GetEscapeLens()
        for index = 1, count do
            local listed = ns.HasCombinedActions(index) or ns.GetCombinedExitAll(index) or (index > 1 and index <= pendingCount)
            local row = combinedRows[index] or (listed and BuildCombined(index))
            if row then
                row:SetShown(listed)
                row.label:SetText(count > 1 and "Combined Lens " .. index or "Combined Lens")
                row.escape:SetChecked(ns.GetCombinedExitAll(index))
                row.escape:SetShown(not escapeLens or escapeLens == index)
                row.escape:SetEnabled(not (ns.GetCombinedExitAll(index) and ns.IsRoleplayActive()))
                local names = {}
                for _, action in ipairs(ns.actions) do
                    if ns.IsActionEnabled(action) and ns.GetCombinedActions(index)[action.binding] then
                        names[#names + 1] = _G["BINDING_NAME_" .. action.binding]
                    end
                end
                row.summary:SetText(table.concat(names, ", "))
                if listed then combinedY = PlaceRow(row, combinedY) - 34 end
            end
        end
        for index, row in pairs(combinedRows) do
            if index > count then row:Hide() end
        end
        add:SetEnabled(count < ns.CombinedLimit())
        add:Show()
        remove:Show()
        remove:SetEnabled(count > 1 and not InCombatLockdown())
        add:ClearAllPoints()
        remove:ClearAllPoints()
        add:SetPoint("TOPLEFT", 12, combinedY + 10)
        remove:SetPoint("TOPLEFT", 46, combinedY + 10)
        combinedBox:SetHeight(-combinedY + 36)
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
        row.checks, row.gears, row.membershipRules = {}, {}, {}
        row.actionIndex = index
        row.extraContainer = FramedBox(row, 0, 50)
        row.extraContainer:ClearAllPoints()
        row.extraContainer:SetPoint("TOPLEFT", 407, 0)
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
    ns.RefreshLensRuntime = function() if page:IsShown() then RefreshBindings() end end
    page:HookScript("OnHide", function(self)
        pendingCount = 1
        StopListening()
        ns.CloseCombinedSettings()
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
    page:SetPoint("TOPLEFT", headerHint, "BOTTOMLEFT", 0, -28)
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
local effectTab, effectCounter, effectPrevious, effectNext
LayoutTabs = function()
    if not effectTab then return end
    local width = math.min(272, math.max(180, effectPanel:GetWidth() - 150))
    effectTab:SetSize(width, 30)
end
SelectTab = function(index)
    StopListening()
    effectTab.menu:Hide()
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
    effectTab:SetShown(index ~= nil)
    effectCounter:SetShown(index ~= nil)
    effectPrevious:SetShown(index ~= nil); effectNext:SetShown(index ~= nil)
    if index then
        local position, total = 0, 0
        for candidate, spec in ipairs(tabSpecs) do
            if ns.IsEffectEnabled(spec.id) then total = total + 1; if candidate == index then position = total end end
        end
        effectCounter:SetText(position .. " / " .. total)
        effectPrevious:SetEnabled(total > 1); effectNext:SetEnabled(total > 1)
        local page = pages[index] or BuildEffectPage(index)
        local info = tabSpecs[index]
        effectTab.effectId = info.id
        effectTab:SetText(info.name)
        local gray = info.underConsideration
        local font = gray and "GameFontDisable" or "GameFontNormal"
        effectTab:SetNormalFontObject(font)
        effectTab:SetHighlightFontObject(font)
        effectTab:SetDisabledFontObject(font)
        effectTab:GetFontString():SetTextColor(gray and 0.5 or 1, gray and 0.5 or 0.82, gray and 0.5 or 0)
        headerDescription:SetText(ns.FormatText(info.description))
        headerHint:SetText(ns.FormatText(info.hint or ""))
        page:Show()
        if page.refresh then page.refresh() end
    end
    LayoutTabs()
end
local function BuildEffects()
    if not headerHint then
        SettingsHeading(effectPanel, "Effect")
        effectTab = Selector(effectPanel, 272, 0, 0, function()
            local choices = {}
            for index, effect in ipairs(tabSpecs) do
                if ns.IsEffectEnabled(effect.id) then choices[#choices + 1] = { value = index, text = effect.name, planned = effect.underConsideration } end
            end
            return choices
        end, function(index) SelectTab(index) end)
        effectTab:ClearAllPoints()
        effectTab:SetPoint("TOP", effectPanel, "TOP", 0, -76)
        effectTab.frameRole = "currentEffect"
        local function Cycle(direction)
            local index = selectedTab or 1
            for _ = 1, #tabSpecs do
                index = (index - 1 + direction) % #tabSpecs + 1
                if ns.IsEffectEnabled(tabSpecs[index].id) then SelectTab(index); return end
            end
        end
        effectPrevious = Button(effectPanel, "<", 30, 0, 0, function() Cycle(-1) end)
        effectNext = Button(effectPanel, ">", 30, 0, 0, function() Cycle(1) end)
        effectPrevious:ClearAllPoints(); effectNext:ClearAllPoints()
        effectPrevious:SetPoint("RIGHT", effectTab, "LEFT", -8, 0); effectNext:SetPoint("LEFT", effectTab, "RIGHT", 8, 0)
        effectPrevious:SetHeight(30); effectNext:SetHeight(30)
        effectPrevious.frameRole, effectNext.frameRole = "previousEffect", "nextEffect"
        effectCounter = Label(effectPanel, "", "GameFontHighlightSmall", 0, 0)
        effectCounter:ClearAllPoints()
        effectCounter:SetPoint("LEFT", effectNext, "RIGHT", 12, 0)
        headerDescription = PageDescription(effectPanel, "")
        headerDescription:ClearAllPoints()
        headerDescription:SetPoint("TOPLEFT", 20, -130)
        headerDescription:SetPoint("TOPRIGHT", -38, -130)
        headerHint = Label(effectPanel, "", "GameFontNormal", 0, 0)
        headerHint:ClearAllPoints()
        headerHint:SetPoint("TOPLEFT", headerDescription, "BOTTOMLEFT", 0, -10)
        headerHint:SetPoint("TOPRIGHT", headerDescription, "BOTTOMRIGHT", 0, -10)
        headerHint:SetWordWrap(true)
        effectEmpty = Label(effectPanel, "Enable an Effect on the ret_Cinema page to configure it here.", "GameFontNormal", 20, -130)
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
        DialogBackdrop(dialog)
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
            if ok then dialog:Hide() else dialog.error:SetText(ns.FormatText(errorText or "Could not update the profile.")) end
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
    dialog.title:SetText(ns.FormatText(title))
    dialog.instructions:SetText(ns.FormatText(text))
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
    local arrow = Label(selector, "v", "GameFontNormal", 0, 0)
    arrow:ClearAllPoints()
    arrow:SetPoint("RIGHT", -8, 0)
    selector.arrow = arrow
    selector:GetFontString():ClearAllPoints()
    selector:GetFontString():SetPoint("LEFT", 10, 0)
    selector:GetFontString():SetPoint("RIGHT", -28, 0)
    selector:GetFontString():SetJustifyH("LEFT")
    Tooltip(selector, "Select a profile.")
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
            button:SetText(ns.FormatText(name))
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
            status:SetText(ns.FormatText(ok and "Active profile: " .. message or message))
        end)
    local create = Button(content, "Create New", 150, 308, -46, function()
        ProfileDialog("create", "Create a new profile", "Enter a name for the new profile:", function(name)
            local ok, result = ns.Profiles.Create(name)
            if ok then status:SetText(ns.FormatText("Created profile: " .. result)) end
            return ok, result
        end)
    end)
    SectionHeading(content, "Import / Export / Copy", -106)
    Button(content, "Export", 106, 238, -144,
        function() CopyText("Export: " .. ns.Profiles.Current(), ns.Profiles.Export()) end)
    local import = Button(content, "Import", 106, 352, -144, function()
        ProfileDialog("import", "Import a profile", "Paste a ret_Cinema profile export, then click Import.", function(text)
            local ok, result = ns.Profiles.Import(text)
            if ok then status:SetText(ns.FormatText("Imported profile: " .. result)) end
            return ok, result
        end)
    end)
    Label(content, "Copy from profile:", "GameFontNormal", 0, -200)
    local source
    local copySelector
    copySelector = ProfileSelector(content, "copy", -194, function() return ns.Profiles.List(true) end,
        function(name) source = name; copySelector:SetText(ns.FormatText(name)) end)
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
        function(name) deletion = name; deleteSelector:SetText(ns.FormatText(name)) end)
    local delete = Button(content, "Delete", 106, 352, -372, function()
        if not deletion then status:SetText("Select a profile to delete."); return end
        local target = deletion
        ProfileDialog("delete", "Delete profile", "Delete '" .. target .. "'? This cannot be undone.", function()
            local ok, message = ns.Profiles.Delete(target)
            if ok then status:SetText(ns.FormatText("Deleted profile: " .. message)) end
            return ok, message
        end)
    end)
    page.refresh = function()
        if page:IsShown() then
            page:RegisterEvent("PLAYER_REGEN_DISABLED")
            page:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        active:SetText(ns.FormatText(ns.Profiles.Current()))
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

local goOfflineDialog
local function OpenGoOffline()
    if not ns.Advanced("roleplay") or not ns.db.roleplayLogout then return end
    if goOfflineDialog and goOfflineDialog:IsShown() then goOfflineDialog:Hide(); return end
    if not goOfflineDialog then
        local dialog = CreateFrame("Frame", "RetCinemaGoOfflineDialog", UIParent, "BackdropTemplate")
        goOfflineDialog = dialog
        dialog:SetSize(620, 550); dialog:SetPoint("CENTER"); dialog:SetFrameStrata("DIALOG"); dialog:EnableMouse(true)
        DialogBackdrop(dialog); SettingsHeading(dialog, "GoOffline")
        table.insert(UISpecialFrames, "RetCinemaGoOfflineDialog")
        local hint = Label(dialog, "The game countdown lasts 20 seconds. Longer stage plans are cut short by logout.", "GameFontNormal", 24, -70)
        hint:SetWidth(560); hint:SetWordWrap(true)
        local body = CreateFrame("Frame", nil, dialog); body:SetSize(560, 380); body:SetPoint("TOPLEFT", 24, -116)
        dialog.controls = {}
        for index, spec in ipairs(ns.roleplayNumbers) do
            local setting = spec
            local control = NumericControl(body, "RetCinema" .. spec.key, spec.label, spec.low, spec.high, spec.suffix,
                function() return ns.db[setting.key] end, function(value) return ns.SetRoleplayNumber(setting.key, value) end, spec.default, spec.key)
            control:SetPoint("TOPLEFT", (index - 1) % 2 * 286, -math.floor((index - 1) / 2) * 94)
            dialog.controls[#dialog.controls + 1] = control
        end
        dialog.refresh = function() for _, control in ipairs(dialog.controls) do control.refresh(ns.IsEffectEnabled("letterbox")) end end
    end
    goOfflineDialog.refresh(); goOfflineDialog:Show()
end
local function BuildTrigger(page, content)
    local selectors = {}
    local box = FramedBox(content, 0, 350)
    local moveColumn = CreateFrame("Frame", nil, box)
    local stayColumn = CreateFrame("Frame", nil, box)
    page.moveColumn, page.stayColumn, page.roleplayBox = moveColumn, stayColumn, box
    local separator = box:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.6, 0.6, 0.6, 0.3); separator:SetWidth(1)
    separator:SetPoint("TOP", box, "TOP", 0, -10); separator:SetPoint("BOTTOM", box, "BOTTOM", 0, 10)
    SectionHeading(moveColumn, "Move", 0):SetTextColor(1, 0.82, 0)
    SectionHeading(stayColumn, "Stay", 0):SetTextColor(1, 0.82, 0)
    local function Choices(logout)
        local choices = logout and { { value = -1, text = "No Lens" } } or {}
        for index, action in ipairs(ns.actions) do
            if ns.IsActionEnabled(action) then choices[#choices + 1] = { value = index == 4 and 8 or index - 1, text = _G["BINDING_NAME_" .. action.binding] } end
        end
        for index = 1, ns.GetCombinedCount() do
            if ns.HasCombinedActions(index) then choices[#choices + 1] = { value = index + 2, text = "Combined Lens " .. index } end
        end
        return choices
    end
    local walking, synchronize, status, logout, logoutButton
    local poseChecks, actionRules = {}, {}
    local function EnsureWalk()
        if walking then return end
        walking = Checkbox(moveColumn, "Walk", -4, -36, function(self) ns.SetTrigger(self:GetChecked()) end)
        walking.defaultKey = "triggerEnabled"
        Tooltip(walking, ns.ChatText("SYSTEM", "Warning!") .. " Apply the selected Lens in walk mode, including while stationary. Its Lens buttons cannot change the RP action. Switch Run/Walk to end it.")
        synchronize = Checkbox(moveColumn, "Walking mode is currently enabled", -4, 0, function(self) ns.SyncWalkingMode(self:GetChecked()) end)
        local font, size, flags = synchronize.label:GetFont(); synchronize.label:SetFont(font, size * 0.85, flags)
        synchronize.label:SetTextColor(0.5, 0.5, 0.5); synchronize.label:SetWordWrap(true)
        synchronize.defaultHint = "Automatic detection"
        Tooltip(synchronize, ns.ChatText("SYSTEM", "Warning!") .. " Synchronize LiteRP with your current game movement mode. This does not switch the character's mode. Move once to detect it automatically, or match walk/run while stationary.")
        status = Label(moveColumn, "", "GameFontHighlightSmall", 0, 0)
        status:SetTextColor(0.5, 0.5, 0.5); status:SetWordWrap(true)
    end
    local function EnsurePose(kind)
        if poseChecks[kind] then return end
        poseChecks[kind] = Checkbox(stayColumn, kind, -4, 0, function(self) ns.SetRoleplayOption("roleplay" .. kind, self:GetChecked()) end)
        poseChecks[kind].defaultKey = "roleplay" .. kind
        Tooltip(poseChecks[kind], "Apply this action's Lens while stationary. Lens buttons cannot change its Effects. Moving or standing up ends the action.")
    end
    local function EnsureLogout()
        if logout then return end
        logout = Checkbox(stayColumn, "GoOffline", -4, 0, function(self)
            ns.SetRoleplayOption("roleplayLogout", self:GetChecked())
            local color = self:GetChecked() and 1 or 0.5
            self.label:SetTextColor(color, color, color)
        end)
        logout.defaultKey = "roleplayLogout"
        logout.frameRole = "goOfflineEnabled"
        logoutButton = GearButton(stayColumn, 0, 0, OpenGoOffline)
        logoutButton.frameRole = "goOfflineSettings"
        logoutButton:ClearAllPoints(); logoutButton:SetPoint("LEFT", logout.label, "RIGHT", 8, 0)
        Tooltip(logout, "Apply a Lens during the logout countdown. GoOffline's Letterbox animation takes priority over that Lens's animation. Cancel logout to end the action.")
        Tooltip(logoutButton, "Configure GoOffline's bar heights and animation stages.")
    end
    local function ActionRule(kind, y, shown)
        local rule = actionRules[kind]
        if shown and not rule then
            rule = stayColumn:CreateTexture(nil, "ARTWORK")
            rule:SetColorTexture(0.6, 0.6, 0.6, 0.3); rule:SetHeight(1)
            actionRules[kind] = rule
        end
        if rule then
            rule:SetShown(shown)
            rule:SetPoint("TOPLEFT", 0, y + 9); rule:SetPoint("TOPRIGHT", -8, y + 9)
        end
    end
    page.actionRules = actionRules
    local function TargetSelector(kind)
        if selectors[kind] then return selectors[kind] end
        local column = kind == "Walk" and moveColumn or stayColumn
        local selector = Selector(column, 240, 12, 0, function() return Choices(kind == "Logout") end, function(value)
            if kind == "Walk" then ns.SetTrigger(ns.db.triggerEnabled, value) else ns.SetRoleplayTarget(kind, value) end
        end)
        selector.frameRole = kind == "Walk" and "triggerTarget" or kind == "Logout" and "logoutTarget" or "stayTarget"
        selector.poseKind = kind; selectors[kind] = selector
        return selector
    end
    page.refresh = function()
        if not page:IsShown() then return end
        page:RegisterEvent("UPDATE_BINDINGS")
        local width = math.max(180, (content:GetWidth() - 40) / 2)
        box:SetWidth(content:GetWidth())
        moveColumn:SetPoint("TOPLEFT", 12, -12); moveColumn:SetWidth(width)
        stayColumn:SetPoint("TOPLEFT", width + 28, -12); stayColumn:SetWidth(width)
        local walkVisible = ns.RoleplayActionVisible("Walk")
        if walkVisible then EnsureWalk() end
        if walking then
            walking:SetShown(walkVisible)
            walking:SetChecked(ns.db.triggerEnabled); walking:SetEnabled(ns.TriggerAvailable() or ns.db.triggerEnabled)
            synchronize.label:SetWidth(width - 30); status:SetWidth(width - 12)
        end
        local moveY = walkVisible and -74 or -36
        if walkVisible and ns.db.triggerEnabled then
            local selector = TargetSelector("Walk"); selector:SetWidth(width - 16); selector:SetPoint("TOPLEFT", 12, moveY)
            selector:SetText(ns.GetTriggerTargetName(ns.db.triggerTarget)); selector:Show(); moveY = moveY - 38
            synchronize:SetPoint("TOPLEFT", -4, moveY); synchronize:SetChecked(ns.GetWalkingMode() == true); synchronize:Show()
            moveY = moveY - math.max(36, synchronize.label:GetStringHeight() + 14)
            local mode = ns.GetWalkingMode()
            status:SetText(mode == nil and "Movement mode is unknown. Move once to synchronize, or match your current mode above." or
                mode and "Walk mode: the Lens stays active when you stop moving." or "Run mode: the walking Lens is inactive.")
            status:SetPoint("TOPLEFT", 0, moveY); status:Show(); moveY = moveY - math.max(50, status:GetStringHeight() + 18)
        else
            if selectors.Walk then selectors.Walk:Hide() end
            if synchronize then synchronize:Hide(); status:Hide() end
        end
        local stayY, previous = -36, false
        for _, kind in ipairs({ "Sit", "Lay", "Lean", "Logout" }) do
            local visible = ns.RoleplayActionVisible(kind)
            if visible then
                if kind == "Logout" then EnsureLogout() else EnsurePose(kind) end
            end
            local check = kind == "Logout" and logout or poseChecks[kind]
            if check then check:SetShown(visible) end
            ActionRule(kind, stayY, visible and previous)
            if visible then
                local enabled = ns.RoleplayActionEnabled(kind)
                check:SetPoint("TOPLEFT", -4, stayY); check:SetChecked(enabled)
                check:SetEnabled(kind == "Logout" and ns.IsEffectEnabled("letterbox") or kind ~= "Logout" and ns.PostureAvailable())
                stayY = stayY - 36
                if enabled then
                    local selector = TargetSelector(kind); selector:SetWidth(width - 16); selector:SetPoint("TOPLEFT", 12, stayY)
                    selector:SetText(ns.GetTriggerTargetName(ns.db["roleplay" .. kind .. "Target"])); selector:Show(); stayY = stayY - 38
                elseif selectors[kind] then selectors[kind]:Hide() end
                stayY, previous = stayY - 18, true
            elseif selectors[kind] then selectors[kind]:Hide() end
            if kind == "Logout" and logout then
                local active = visible and ns.db.roleplayLogout
                logout.label:SetTextColor(active and 1 or 0.5, active and 1 or 0.5, active and 1 or 0.5)
                logoutButton:SetShown(active); logoutButton:SetEnabled(ns.IsEffectEnabled("letterbox"))
            end
        end
        local height = math.max(180, -moveY, -stayY)
        moveColumn:SetHeight(height); stayColumn:SetHeight(height); box:SetHeight(height + 24); content:SetHeight(height + 44)
    end
    ns.RefreshTriggerSettings = function()
        if page:IsShown() then page.refresh() end
        if goOfflineDialog and goOfflineDialog:IsShown() then
            if not ns.RoleplayActionEnabled("Logout") then goOfflineDialog:Hide() else goOfflineDialog.refresh() end
        end
    end
    content:HookScript("OnSizeChanged", function() if page:IsShown() then page.refresh() end end)
    page:HookScript("OnEvent", page.refresh)
    page:HookScript("OnHide", function() for _, selector in pairs(selectors) do selector.menu:Hide() end; page:UnregisterAllEvents() end)
end

local wishDialog
local function OpenWishBoard()
    if not wishDialog then
        local dialog = CreateFrame("Frame", "RetCinemaWishBoard", UIParent, "BackdropTemplate")
        wishDialog = dialog
        dialog:SetSize(580, 534)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)
        DialogBackdrop(dialog)
        SettingsHeading(dialog, "Too-Doo")
        Label(dialog, "Ideas being explored and developed.", "GameFontNormal", 24, -76)
        local ideas = {
            { "FOV", "Available", "Choose permanent, individual Lens and per-Combined Lens field-of-view settings." },
            { "SmoothMotion", "Under consideration", "Explore smoother camera movement.", true },
            { "Custom Letterbox transparency", "Available", "Enable this option in Advanced Cinematographer to adjust bar opacity." },
            { "Custom Letterbox animation duration", "Available", "Enable this option in Advanced Cinematographer to choose transition duration." },
            { "Custom CameraShift animation duration", "Available", "Enable this option in Advanced Cinematographer to choose shoulder-offset transition duration." },
            { "LiteRP: Walk", "Experimental", "Walk applies a Lens while walk mode is enabled. LiteRP is available through Advanced Cinematographer." },
            { "LiteRP: poses and logout", "Experimental", "Stationary actions and logout can apply a Lens. RP actions protect their Effects from Lens buttons." },
            { "Improve descriptions and tooltips", "Planned", "Make Effect descriptions and option tooltips more precise." },
            { "Add a 'Like ret_' profile", "Planned", "Provide a profile containing the author's preferred settings." },
            { "Update ret_like preset defaults", "Planned", "Adjust the ret_like preset reference values to the author's preferred defaults." },
        }
        Label(dialog, "Feature", "GameFontNormal", 24, -112)
        Label(dialog, "Status", "GameFontNormal", 340, -112)
        local details = Label(dialog, "Select a feature to learn more.", "GameFontHighlightSmall", 24, -138 - #ideas * 28 - 16)
        details:SetWidth(532)
        details:SetWordWrap(true)
        local ideaFont = CreateFont("RetCinemaWishIdeaFont")
        ideaFont:SetFontObject("GameFontHighlight")
        ideaFont:SetTextColor(1, 0.5, 0)
        for index, idea in ipairs(ideas) do
            local row = Button(dialog, idea[1], 290, 20, -138 - (index - 1) * 28, function() details:SetText(ns.FormatText(idea[3])) end)
            local font = idea[4] and "GameFontDisable" or idea[2] == "Available" and "GameFontNormal" or ideaFont
            row:SetNormalFontObject(font)
            row:SetHighlightFontObject(font)
            row:GetFontString():SetTextColor(idea[4] and 0.5 or 1, idea[4] and 0.5 or idea[2] == "Available" and 0.82 or 0.5, idea[4] and 0.5 or 0)
            local status = Label(dialog, idea[2], "GameFontHighlightSmall", 340, -144 - (index - 1) * 28)
            if idea[2] == "Experimental" then status:SetTextColor(ns.ChatColor("RAID_LEADER"))
            else status:SetTextColor(idea[2] == "Available" and 0.6 or 1, idea[2] == "Available" and 1 or 0.5, 0) end
        end
    end
    wishDialog:Show()
end

local function BuildSupport(page, content)
    Label(content, "CurseForge", "GameFontNormal", 0, -10)
    local curseForge = Button(content, "Copy link", 150, 238, -4)
    curseForge:SetEnabled(false)
    curseForge:SetMotionScriptsWhileDisabled(true)
    Tooltip(curseForge, "Coming soon")
    Label(content, "Coming soon", "GameFontDisable", 238, -36)
    local version = Label(content, "Version " .. ns.GetVersion(), "GameFontHighlightSmall", 0, -34)
    version:SetTextColor(0.5, 0.5, 0.5)
    SectionHeading(content, "Support Development", -122)
    local intro = Label(content, "If you enjoy ret_Cinema, you can support its continued development.", "GameFontHighlightSmall", 0, -158)
    intro:SetPoint("TOPRIGHT", 0, -158)
    intro:SetWordWrap(true)
    Label(content, "boosty.to", "GameFontNormal", 0, -202)
    Button(content, "Copy link", 150, 238, -196, function() CopyText("boosty.to", "https://boosty.to/ret_ro") end)
    local gold = Label(content, "You also may support development with in-game gold.", "GameFontHighlightSmall", 0, -262)
    gold:SetPoint("TOPRIGHT", 0, -262)
    gold:SetWordWrap(true)
    Label(content, "Retail", "GameFontNormal", 0, -300)
    local horde = Label(content, "Horde", "GameFontNormal", 0, -328)
    horde:SetTextColor(1, 0.3, 0.3)
    local character = Label(content, "Хардрес-РевущийФьорд", "GameFontHighlight", 0, -364)
    local paladin = RAID_CLASS_COLORS and RAID_CLASS_COLORS.PALADIN
    character:SetTextColor(paladin and paladin.r or 0.96, paladin and paladin.g or 0.55, paladin and paladin.b or 0.73)
    Button(content, "Copy character name", 180, 238, -358,
        function() CopyText("Retail — Horde", "Хардрес-РевущийФьорд") end)
    Button(content, "Too-Doo", 110, 0, -60, OpenWishBoard)
    content:SetHeight(484)
end

local function ChildPanel(name, builder, info, main)
    local child = CreateFrame("Frame", main and "RetCinemaSettingsPanel" or "RetCinema" .. name:gsub("%W", "") .. "Panel", UIParent)
    child.name = main and ns.title or name == "Lens" and "|cff40c7ebLens|r" or name == "LiteRP" and ns.ChatText("EMOTE", "LiteRP") or name
    child.pageId = main and "main" or name:lower()
    child:Hide()
    local initialized, description, hint
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
                hint = Label(child, (info().hint or ""):gsub("%s+$", ""), "GameFontNormal", 0, 0)
                hint:ClearAllPoints()
                hint:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -10)
                hint:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT", 0, -10)
                hint:SetWordWrap(true)
                local _, lineHeight = hint:GetFont()
                scroll:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, name == "LiteRP" and -lineHeight or -28)
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
            child.hint, child.scroll = hint, scroll
            builder(child, content)
        end
        if description then description:SetText(ns.FormatText(info().description)) end
        if hint then hint:SetText(ns.FormatText((info().hint or ""):gsub("%s+$", ""))) end
        if child.refresh then child.refresh() end
    end)
    return child
end

local function OpenChild(id)
    local target = ns.settingsCategories[id]
    if target and Settings and Settings.OpenToCategory then Settings.OpenToCategory(target:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(id == "main" and panel or id == "effect" and effectPanel or lensPanel)
    end
end
local function UpdateRoleplayCategory()
    local shown, child = ns.Advanced("roleplay"), ns.settingsCategories["literp"]
    if category and child then
        local children = category.GetSubcategories and category:GetSubcategories() or category.subcategories
        local found
        for index, entry in ipairs(children or {}) do if entry == child then found = index; break end end
        if found and not shown then table.remove(children, found)
        elseif not found and shown then table.insert(children, math.min(ns.HasLensEffects() and 3 or 2, #children + 1), child) end
        if (found ~= nil) ~= not not shown and SettingsPanel and SettingsPanel.CategoryList then SettingsPanel.CategoryList:CreateCategories() end
    elseif INTERFACEOPTIONS_ADDONCATEGORIES then
        local found
        for index, entry in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do if entry == roleplayPanel then found = index; break end end
        if found and not shown then table.remove(INTERFACEOPTIONS_ADDONCATEGORIES, found)
        elseif not found and shown then table.insert(INTERFACEOPTIONS_ADDONCATEGORIES, roleplayPanel) end
        if InterfaceAddOnsList_Update then InterfaceAddOnsList_Update() end
    end
    if not shown and roleplayPanel:IsShown() then roleplayPanel:Hide(); OpenChild("main") end
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
            elseif not found and shown then table.insert(children, math.min(2, #children + 1), lensCategory) end
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
    if not shown and lensPanel:IsShown() then
        StopListening()
        lensPanel:Hide()
        OpenChild("main")
    end
end
local function ColorRoleplayNavigation()
    local list = SettingsPanel and SettingsPanel.CategoryList
    local scroll = list and list.ScrollBox
    if not scroll or not ScrollUtil or not ScrollUtil.AddInitializedFrameCallback then return end
    local function Paint(frame, initializer)
        initializer = initializer or (frame.GetElementData and frame:GetElementData())
        if not frame.Label or not initializer or not initializer.data or initializer.data.category ~= ns.settingsCategories.literp then return end
        frame.Label:SetText(ns.ChatText("EMOTE", "LiteRP"))
        frame.Label:SetTextColor(ns.ChatColor("EMOTE"))
        -- Blizzard reapplies font objects on hover/selection. Repaint this
        -- registered category after those changes, including recycled rows.
        if not frame.retCinemaColorHook and frame.UpdateStateInternal and hooksecurefunc then
            frame.retCinemaColorHook = true
            hooksecurefunc(frame, "UpdateStateInternal", function(self) Paint(self) end)
        end
    end
    ScrollUtil.AddInitializedFrameCallback(scroll, function(_, frame, initializer) Paint(frame, initializer) end, panel)
    if scroll.ForEachFrame then scroll:ForEachFrame(Paint) end
end
function ns.RegisterSettings()
    panel = ChildPanel("ret_Cinema", builders.general, function()
        return { description = ns.GetDescription(), hint = ns.generalHint }
    end, true)
    effectPanel = CreateFrame("Frame", "RetCinemaEffectPanel", UIParent)
    effectPanel.name = "Effect"
    effectPanel:Hide()
    effectPanel:SetScript("OnShow", BuildEffects)
    effectPanel:SetScript("OnHide", function()
        for _, page in pairs(pages) do page:Hide() end
        if effectTab then effectTab.menu:Hide() end
    end)
    lensPanel = ChildPanel("Lens", builders.lens, function() return ns.lens end)
    roleplayPanel = ChildPanel("LiteRP", BuildTrigger, function()
        return { description = "Bring your Lens into RP Actions", hint = "Keep a Lens in walk mode, choose a different Lens for each Stay action, or customize GoOffline. Lens buttons cannot change Effects controlled by an active RP action." }
    end)
    local profiles = ChildPanel("Profiles", BuildProfiles)
    local support = ChildPanel("Support", BuildSupport)
    local children = { effectPanel, lensPanel, roleplayPanel, profiles, support }
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
        UpdateRoleplayCategory()
        if panel.content and panel.refresh then panel.refresh() end
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
        ns.RefreshCombinedSettings()
        if ns.RefreshTriggerSettings then ns.RefreshTriggerSettings() end
        for _, check in ipairs(presetChecks) do check.refreshReset() end
    end
    ColorRoleplayNavigation()
    UpdateLensCategory()
    UpdateRoleplayCategory()
end

function RetCinema_OpenSettings()
    if not panel then return end
    ns.RestoreUI()
    if category then Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel) end
end
