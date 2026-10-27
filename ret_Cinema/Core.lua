local addonName, ns = ...

BINDING_HEADER_RETCINEMA = "ret_Cinema"
BINDING_NAME_RETCINEMA_HIDEUI = "Hide UI"
BINDING_NAME_RETCINEMA_LETTERBOX = "Show letterbox"

ns.icon = "Interface\\Icons\\INV_Misc_Spyglass_03"

local bars, topBar, bottomBar, minimapButton
local letterboxShown = false

function ns.Print(message)
    print("|cffffd100ret_Cinema:|r " .. message)
end

local function UpdateBars()
    if not bars then return end
    local height = math.max(0.01, bars:GetHeight() * ns.db.letterboxHeight / 100)
    topBar:SetHeight(height)
    bottomBar:SetHeight(height)
    bars:SetShown(letterboxShown and ns.db.letterboxHeight > 0)
end

local function SyncScreen()
    -- An independent parent keeps the bars visible when screenshot mode hides UIParent.
    bars:SetScale(UIParent:GetScale())
    bars:ClearAllPoints()
    bars:SetAllPoints(UIParent)
    UpdateBars()
end

function ns.SetLetterboxHeight(value)
    ns.db.letterboxHeight = math.max(0, math.min(25, math.floor(value + 0.5)))
    UpdateBars()
end

function RetCinema_ToggleLetterbox()
    if not ns.db then return end
    letterboxShown = not letterboxShown
    UpdateBars()
end

function RetCinema_ToggleUI()
    if not ns.db then return end
    if SetUIVisibility then
        -- The game's screenshot toggle also hides world names and nameplates.
        -- Reading the real state keeps this in sync with Alt+Z and other UI toggles.
        SetUIVisibility(not UIParent:IsShown())
    else
        ns.Print("Screenshot mode is not supported by this client.")
    end
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
        GameTooltip:SetText("ret_Cinema")
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

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        ret_CinemaDB = type(ret_CinemaDB) == "table" and ret_CinemaDB or {}
        ns.db = ret_CinemaDB
        if type(ns.db.showMinimapButton) ~= "boolean" then ns.db.showMinimapButton = true end
        ns.db.minimapAngle = tonumber(ns.db.minimapAngle) or 220
        ns.db.letterboxHeight = tonumber(ns.db.letterboxHeight) or 10

        bars = CreateFrame("Frame", "RetCinemaLetterbox")
        bars:Hide()
        bars:SetFrameStrata("BACKGROUND")
        bars:SetFrameLevel(0)
        bars:EnableMouse(false)
        topBar = bars:CreateTexture(nil, "BACKGROUND")
        bottomBar = bars:CreateTexture(nil, "BACKGROUND")
        for _, texture in ipairs({ topBar, bottomBar }) do
            texture:SetColorTexture(0, 0, 0, 1)
        end
        topBar:SetPoint("TOPLEFT")
        topBar:SetPoint("TOPRIGHT")
        bottomBar:SetPoint("BOTTOMLEFT")
        bottomBar:SetPoint("BOTTOMRIGHT")
        ns.SetLetterboxHeight(ns.db.letterboxHeight)
        SyncScreen()
        bars:SetScript("OnSizeChanged", UpdateBars)
        self:RegisterEvent("UI_SCALE_CHANGED")
        self:RegisterEvent("DISPLAY_SIZE_CHANGED")
        CreateMinimapButton()
        ns.RegisterSettings()
    else
        SyncScreen()
        PositionMinimapButton()
    end
end)

SLASH_RETCINEMA1 = "/retcinema"
SLASH_RETCINEMA2 = "/retcin"
SlashCmdList.RETCINEMA = function() RetCinema_OpenSettings() end
