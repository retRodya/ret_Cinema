local _, ns = ...
local panel, category, built
local pages, tabs, bindingButtons = {}, {}, {}
local listening, bindingStatus

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

local function RefreshBindings()
    for _, button in ipairs(bindingButtons) do
        local key = select(button.slot, GetBindingKey(button.action))
        button:SetText(button == listening and "Press a key..." or
            (key and GetBindingText(key) or "Not bound"))
        button:SetEnabled(not InCombatLockdown())
    end
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
    local button = Button(parent, "Not bound", 150, x, y, function(self, mouseButton)
        if InCombatLockdown() then return end
        if mouseButton == "RightButton" then
            AssignKey(self, nil)
        elseif listening == self then
            StopListening()
        else
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

local function SelectTab(index)
    StopListening()
    for i, page in ipairs(pages) do
        page:SetShown(i == index)
        tabs[i]:SetEnabled(i ~= index)
    end
end

local function Build()
    if built then return end
    built = true
    Label(panel, "ret_Cinema", "GameFontNormalLarge", 16, -16)
    for index, name in ipairs({ "General", "Letterbox", "Keybindings" }) do
        tabs[index] = Button(panel, name, 130, 16 + (index - 1) * 138, -52,
            function() SelectTab(index) end)
        local page = CreateFrame("Frame", nil, panel)
        page:SetPoint("TOPLEFT", 20, -100)
        page:SetPoint("BOTTOMRIGHT", -20, 20)
        page:Hide()
        pages[index] = page
    end

    local checkbox = CreateFrame("CheckButton", nil, pages[1], "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", -4, 0)
    checkbox:SetSize(28, 28)
    Label(checkbox, "Show minimap icon", "GameFontHighlight", 30, -6)
    checkbox:SetScript("OnClick", function(self) ns.SetMinimapButton(self:GetChecked()) end)
    pages[1]:SetScript("OnShow", function() checkbox:SetChecked(ns.db.showMinimapButton) end)

    Label(pages[2], "Bar height", "GameFontNormal", 0, 0)
    local slider = CreateFrame("Slider", "RetCinemaBarHeightSlider", pages[2], "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 4, -40)
    slider:SetSize(330, 18)
    slider:SetMinMaxValues(0, 25)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText("0%")
    _G[slider:GetName() .. "High"]:SetText("25%")
    local valueLabel = Label(pages[2], "", "GameFontHighlight", 355, -42)
    Label(pages[2], "Height of each bar as a percentage of the screen.", "GameFontHighlight", 0, -88)
    slider:SetScript("OnValueChanged", function(_, value)
        ns.SetLetterboxHeight(value)
        valueLabel:SetText(ns.db.letterboxHeight .. "%")
    end)
    pages[2]:SetScript("OnShow", function()
        slider:SetValue(ns.db.letterboxHeight)
        valueLabel:SetText(ns.db.letterboxHeight .. "%")
    end)

    local help = Label(pages[3], "Click a binding, then press a key. Right-click to clear. Escape cancels.",
        "GameFontHighlight", 0, 0)
    help:SetWidth(500)
    help:SetWordWrap(true)
    Label(pages[3], "Key 1", "GameFontNormal", 178, -50)
    Label(pages[3], "Key 2", "GameFontNormal", 336, -50)
    for index, action in ipairs({ "RETCINEMA_HIDEUI", "RETCINEMA_LETTERBOX" }) do
        local y = -78 - (index - 1) * 42
        Label(pages[3], _G["BINDING_NAME_" .. action], "GameFontHighlight", 0, y - 6)
        CreateBindingButton(pages[3], action, 1, 170, y)
        CreateBindingButton(pages[3], action, 2, 328, y)
    end
    Label(pages[3], "Press the same binding again to toggle back.", "GameFontHighlight", 0, -176)
    bindingStatus = Label(pages[3], "", "GameFontHighlight", 0, -210)
    bindingStatus:SetWidth(500)
    bindingStatus:SetWordWrap(true)
    pages[3]:SetScript("OnShow", function(self)
        self:RegisterEvent("UPDATE_BINDINGS")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        RefreshBindings()
    end)
    pages[3]:SetScript("OnHide", function(self)
        StopListening()
        self:UnregisterAllEvents()
    end)
    pages[3]:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            StopListening()
            bindingStatus:SetText("Keybindings cannot be changed in combat.")
        else
            RefreshBindings()
        end
    end)
    SelectTab(1)
end

function ns.RegisterSettings()
    panel = CreateFrame("Frame", "RetCinemaSettingsPanel", UIParent)
    panel.name = "ret_Cinema"
    panel:Hide()
    panel:SetScript("OnShow", Build)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, "ret_Cinema")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function RetCinema_OpenSettings()
    if not panel then return end
    if category then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end
