local _, ns = ...
local panel, category, built
local pages, tabs, bindingButtons = {}, {}, {}
local listening, bindingStatus, bindingLayout
local selectedTab = 1
local builders = {}
local copyDialog
local linkFonts = {}
local DESCRIPTION_FONT_SCALE = 1.5

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
        button:SetEnabled(not InCombatLockdown())
        button:SetShown(button.slot == 1 or GetBindingKey(button.action) ~= nil)
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
        bindingStatus:SetText("Keybindings cannot be changed in combat.")
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
            bindingStatus:SetText(key and "Keybinding saved." or "Keybinding cleared.")
        end
    end
    RefreshBindings()
end

local ignoredKeys = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true, UNKNOWN = true,
}

local function CreateBindingButton(parent, action, slot, x, y)
    local button = Button(parent, "Not bound", 180, x, y, function(self, mouseButton)
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

local function ModuleDescription(content, module)
    local description = PageDescription(content, module.description)
    if module.hint then
        local hint = Label(content, module.hint, "GameFontNormal", 0, 0)
        hint:ClearAllPoints()
        hint:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16)
        hint:SetPoint("TOPRIGHT", description, "BOTTOMRIGHT", 0, -16)
        hint:SetWordWrap(true)
    end
end

local function Checkbox(parent, text, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetSize(28, 28)
    Label(checkbox, text, "GameFontHighlight", 30, -6)
    checkbox:SetScript("OnClick", onClick)
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

builders.general = function(page, content)
    local description = PageDescription(content, ns.GetDescription())
    local minimap = Checkbox(content, "Show minimap icon", -4, -104,
        function(self) ns.SetMinimapButton(self:GetChecked()) end)
    Label(content, "Enable modules:", "GameFontNormal", 0, -150)
    local box = FramedBox(content, -176, 50)
    local moduleChecks = {}
    for index, module in ipairs(ns.modules) do
        local checkbox = Checkbox(box, module.name, 8, -8,
            function(self) ns.SetModuleEnabled(module.id, self:GetChecked()) end)
        checkbox:SetMotionScriptsWhileDisabled(true)
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(module.description, 1, 0.82, 0, 1, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
        moduleChecks[module.id] = checkbox
    end
    page.layoutModules = function()
        local visible = 0
        local cellWidth = math.max(1, (content:GetWidth() - 16) / 4)
        for _, module in ipairs(ns.modules) do
            local checkbox = moduleChecks[module.id]
            local shown = module.id ~= "keybindings" or ns.HasEnabledActionModules()
            checkbox:SetShown(shown)
            checkbox:SetEnabled(module.id ~= "keybindings")
            checkbox:SetChecked(ns.IsModuleEnabled(module.id))
            if shown then
                checkbox:ClearAllPoints()
                checkbox:SetPoint("TOPLEFT", 8 + visible % 4 * cellWidth, -8 - math.floor(visible / 4) * 34)
                visible = visible + 1
            end
        end
        box:SetHeight(16 + math.max(1, math.ceil(visible / 4)) * 34)
    end
    Divider(content, "BOTTOM", 100)
    Divider(content, "BOTTOM", 105)
    local made = LargeYellow(Label(content, "Made by ", "GameFontHighlight", 0, 0))
    made:ClearAllPoints()
    made:SetPoint("BOTTOMLEFT", 0, 62)
    local author = WordLink(content, "ret_", "https://github.com/retRodya/ret_Cinema", true)
    author:SetPoint("TOPLEFT", made, "TOPRIGHT", 0, 0)
    local inspired = Label(content, "Inspired by ", "GameFontNormal", 0, 0)
    inspired:ClearAllPoints()
    inspired:SetPoint("BOTTOMLEFT", 0, 28)
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
        page.layoutModules()
    end
end

builders.hideui = function(page, content)
    ModuleDescription(content, ns.modules[1])
    content:SetHeight(200)
end

builders.letterbox = function(page, content)
    ModuleDescription(content, ns.modules[2])
    Label(content, "Bar height", "GameFontNormal", 0, -118)
    local slider = CreateFrame("Slider", "RetCinemaBarHeightSlider", content, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 4, -158)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(0, 25)
    slider:SetValueStep(0.1)
    slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText("0%")
    _G[slider:GetName() .. "High"]:SetText("25%")
    local value = CreateFrame("EditBox", "RetCinemaBarHeightInput", content, "InputBoxTemplate")
    value:SetPoint("TOPLEFT", 355, -154)
    value:SetSize(70, 24)
    value:SetAutoFocus(false)
    value:SetMaxLetters(12)
    value:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    local function ShowHeight() value:SetText(string.format("%g%%", ns.db.letterboxHeight)) end
    local function CommitHeight(self)
        local number = tonumber((self:GetText():gsub("%%", ""):gsub(",", ".")))
        if ns.SetLetterboxHeight(number) then slider:SetValue(ns.db.letterboxHeight) end
        ShowHeight()
    end
    value:SetScript("OnEnterPressed", function(self) CommitHeight(self); self:ClearFocus() end)
    value:SetScript("OnEditFocusLost", CommitHeight)
    value:SetScript("OnEscapePressed", function(self) ShowHeight(); self:ClearFocus() end)
    local animation = Checkbox(content, "Enable animation", -4, -204,
        function(self) ns.SetLetterboxAnimation(self:GetChecked()) end)
    slider:SetScript("OnValueChanged", function(_, height)
        ns.SetLetterboxHeight(height)
        ShowHeight()
    end)
    page.refresh = function()
        slider:SetValue(ns.db.letterboxHeight)
        ShowHeight()
        animation:SetChecked(ns.db.enableAnimation)
    end
    content:SetHeight(280)
end

builders.camerashift = function(page, content)
    ModuleDescription(content, ns.modules[3])
    local controls = CreateFrame("Frame", nil, content)
    controls:SetPoint("TOPLEFT", 0, -120)
    controls:SetPoint("TOPRIGHT", 0, -120)
    controls:SetHeight(85)
    Label(controls, "Camera shoulder offset", "GameFontNormal", 0, 0)
    local slider = CreateFrame("Slider", "RetCinemaCameraOffsetSlider", controls, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 4, -38)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(-15, 15)
    slider:SetValueStep(0.1)
    slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText("-15")
    _G[slider:GetName() .. "High"]:SetText("15")
    local value = CreateFrame("EditBox", "RetCinemaCameraOffsetInput", controls, "InputBoxTemplate")
    value:SetPoint("TOPLEFT", 355, -34)
    value:SetSize(70, 24)
    value:SetAutoFocus(false)
    value:SetMaxLetters(12)
    value:SetText(string.format("%.1f", ns.db.cameraOffset))
    value:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    local function CommitOffset(self)
        local offset = tonumber((self:GetText():gsub(",", ".")))
        if not ns.SetCameraOffset(offset) then
            self:SetText(string.format("%.1f", ns.db.cameraOffset))
        else
            slider:SetValue(ns.db.cameraOffset)
            self:SetText(string.format("%.1f", ns.db.cameraOffset))
        end
    end
    value:SetScript("OnEnterPressed", function(self) CommitOffset(self); self:ClearFocus() end)
    value:SetScript("OnEditFocusLost", CommitOffset)
    value:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.1f", ns.db.cameraOffset))
        self:ClearFocus()
    end)
    Label(content, "Warning!", "GameFontNormal", 0, -232)
    local explanation = Label(content,
        "Camera Shift remembers your current offset. Press the key once to shift smoothly to the chosen value, and press key again or Esc to return.",
        "GameFontHighlight", 0, -256)
    explanation:SetPoint("TOPRIGHT", 0, -256)
    explanation:SetWordWrap(true)
    local warning = Label(content, "Camera Shift is not supported by this client.", "GameFontNormal", 0, -340)
    slider:SetScript("OnValueChanged", function(_, offset)
        ns.SetCameraOffset(offset)
        value:SetText(string.format("%.1f", ns.db.cameraOffset))
    end)
    page.refresh = function()
        slider:SetEnabled(ns.CameraAvailable())
        value:SetEnabled(ns.CameraAvailable())
        warning:SetShown(not ns.CameraAvailable())
        slider:SetValue(ns.db.cameraOffset)
        value:SetText(string.format("%.1f", ns.db.cameraOffset))
    end
    content:SetHeight(390)
end

builders.keybindings = function(page, content)
    ModuleDescription(content, ns.modules[4])
    local function Headers(option)
        local header = CreateFrame("Frame", nil, content)
        header:SetSize(540, 16)
        Label(header, "Module", "GameFontNormal", 0, 0)
        local key = Label(header, "Key", "GameFontNormal", 180, 0)
        key:SetWidth(180)
        key:SetJustifyH("CENTER")
        local choice = Label(header, option, "GameFontNormal", 414, 0)
        choice:SetWidth(126)
        choice:SetJustifyH("CENTER")
        return header
    end
    local function BindingRow(binding)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(540, 26)
        row.binding = binding
        row.label = Label(row, _G["BINDING_NAME_" .. binding], "GameFontHighlight", 0, -6)
        CreateBindingButton(row, binding, 1, 180, 0)
        row.orLabel = Label(row, "or", "GameFontHighlightSmall", 180, -29)
        row.orLabel:SetWidth(180)
        row.orLabel:SetJustifyH("CENTER")
        CreateBindingButton(row, binding, 2, 180, -48)
        return row
    end
    local function PlaceRow(row, y)
        local second = GetBindingKey(row.binding) ~= nil
        row.orLabel:SetShown(second)
        row:SetHeight(second and 74 or 26)
        row:SetPoint("TOPLEFT", 0, y)
        return y - row:GetHeight()
    end
    local combinedHeader = Headers("Exit all")
    local moduleHeader = Headers("Combined")
    local combinedRow = BindingRow("RETCINEMA_COMBINED")
    local font, size, flags = combinedRow.label:GetFont()
    combinedRow.label:SetFont(font, size + 2, flags)
    local exitAll = CreateFrame("CheckButton", "RetCinemaExitAllCheckbox", combinedRow, "UICheckButtonTemplate")
    exitAll:SetPoint("TOPLEFT", 463, -1)
    exitAll:SetSize(28, 28)
    exitAll:SetScript("OnClick", function(self) ns.db.combinedAsEsc = not not self:GetChecked() end)
    exitAll:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("A second press exits all active modules, even those not included in Combined Key. Exit animations still play.",
            1, 0.82, 0, 1, true)
        GameTooltip:Show()
    end)
    exitAll:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local subtitle = Label(content, "or use marcro commands below:", "GameFontHighlightSmall", 0, 0)
    local commandsBox = FramedBox(content, 0, 108)
    local commands = Label(commandsBox, "", "GameFontHighlightSmall", 12, -10)
    commands:SetPoint("TOPRIGHT", -12, -10)
    commands:SetWordWrap(true)
    Button(commandsBox, "Copy macro text", 156, 10, -72,
        function() CopyText("Copy macro text", ns.GetCombinedCommands()) end)
    local combinedDivider = Divider(content, "TOP", 0)
    bindingStatus = LargeYellow(Label(content, "", "GameFontHighlight", 0, 0), 1.5)
    local rows = {}
    local function RefreshCombined()
        local shown = ns.HasCombinedActions()
        combinedHeader:SetShown(shown)
        combinedRow:SetShown(shown)
        exitAll:SetChecked(ns.db.combinedAsEsc)
        subtitle:SetShown(shown)
        commandsBox:SetShown(shown)
        combinedDivider:SetShown(shown)
        commands:SetText(ns.GetCombinedCommands())
        local y = -84
        if shown then
            combinedHeader:SetPoint("TOPLEFT", 0, y)
            y = PlaceRow(combinedRow, y - 26) - 10
            subtitle:SetPoint("TOPLEFT", 0, y)
            y = y - 20
            commandsBox:SetPoint("TOPLEFT", 0, y)
            commandsBox:SetPoint("TOPRIGHT", 0, y)
            y = y - commandsBox:GetHeight() - 14
            combinedDivider:SetPoint("TOPLEFT", 0, y)
            combinedDivider:SetPoint("TOPRIGHT", 0, y)
            y = y - 20
        end
        moduleHeader:SetPoint("TOPLEFT", 0, y)
        y = y - 26
        for _, row in ipairs(rows) do
            local enabled = ns.IsModuleEnabled(row.module)
            row:SetShown(enabled)
            if enabled then y = PlaceRow(row, y) - 28 end
            row.checkbox:SetChecked(ns.db.combinedActions[row.binding])
        end
        bindingStatus:ClearAllPoints()
        bindingStatus:SetPoint("TOPLEFT", 0, y - 8)
        bindingStatus:SetPoint("TOPRIGHT", 0, y - 8)
        content:SetHeight(math.max(320, -y + 110))
    end
    for index, action in ipairs(ns.actions) do
        local row = BindingRow(action.binding)
        row.module = action.module
        row.checkbox = Checkbox(row, "", 463, -1, function(self)
            local checked = self:GetChecked()
            StopListening()
            ns.SetCombinedAction(action.binding, checked)
            RefreshCombined()
        end)
        Divider(row, "BOTTOM", -12)
        rows[index] = row
    end
    bindingLayout = RefreshCombined
    page.refresh = function()
        page:RegisterEvent("UPDATE_BINDINGS")
        page:RegisterEvent("PLAYER_REGEN_DISABLED")
        page:RegisterEvent("PLAYER_REGEN_ENABLED")
        RefreshBindings()
    end
    page:HookScript("OnHide", function(self) StopListening(); self:UnregisterAllEvents() end)
    page:HookScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            StopListening()
            bindingStatus:SetText("Keybindings cannot be changed in combat.")
        else RefreshBindings() end
    end)
end
local function BuildPage(index)
    local id = index == 1 and "general" or ns.modules[index - 1].id
    local page = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    page:SetPoint("TOPLEFT", 20, -100)
    page:SetPoint("BOTTOMRIGHT", -38, 20)
    page:Hide()
    local content = CreateFrame("Frame", nil, page)
    page.content = content
    content:SetWidth(math.max(1, panel:GetWidth() - 58))
    content:SetHeight(480)
    page:SetScrollChild(content)
    page:HookScript("OnSizeChanged", function(self, width)
        content:SetWidth(math.max(1, width))
        if self.layoutModules then self.layoutModules() end
    end)
    builders[id](page, content)
    page:HookScript("OnShow", function(self) if self.refresh then self.refresh() end end)
    pages[index] = page
    return page
end

local function SelectTab(index)
    StopListening()
    if index > 1 and not ns.IsModuleEnabled(ns.modules[index - 1].id) then index = 1 end
    selectedTab = index
    if not pages[index] then BuildPage(index) end
    for i, page in pairs(pages) do page:SetShown(i == index) end
    for i, tab in ipairs(tabs) do
        if i == index then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
    end
    if pages[index].refresh then pages[index].refresh() end
end

local function Build()
    if built then
        SelectTab(selectedTab)
        return
    end
    built = true
    Label(panel, "ret_Cinema", "GameFontNormalLarge", 16, -16)
    local names = { "General" }
    for _, module in ipairs(ns.modules) do names[#names + 1] = module.name end
    for index, name in ipairs(names) do
        local tab = CreateFrame("Button", "RetCinemaSettingsTab" .. index, panel, "PanelTopTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(name)
        tab:SetPoint("TOPLEFT", 16 + (index - 1) * 106, -48)
        PanelTemplates_TabResize(tab, 4, 100)
        tab:HookScript("OnShow", function(self)
            self:RegisterEvent("DISPLAY_SIZE_CHANGED")
            PanelTemplates_TabResize(self, 4, 100)
        end)
        tab:HookScript("OnHide", function(self) self:UnregisterEvent("DISPLAY_SIZE_CHANGED") end)
        tab:HookScript("OnEvent", function(self)
            if self:IsShown() then PanelTemplates_TabResize(self, 4, 100) end
        end)
        tab:SetScript("OnClick", function() SelectTab(index) end)
        tabs[index] = tab
    end
    ns.RefreshModuleSettings = function()
        StopListening()
        local visible = 0
        for index, tab in ipairs(tabs) do
            local enabled = index == 1 or ns.IsModuleEnabled(ns.modules[index - 1].id)
            tab:SetShown(enabled)
            if enabled then
                tab:ClearAllPoints()
                tab:SetPoint("TOPLEFT", 16 + visible * 106, -48)
                visible = visible + 1
            end
        end
        for index, page in pairs(pages) do
            if index > 1 and not ns.IsModuleEnabled(ns.modules[index - 1].id) then page:Hide() end
        end
        SelectTab(selectedTab)
        if pages[1] and pages[1].refresh then pages[1].refresh() end
    end
    ns.RefreshModuleSettings()
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
