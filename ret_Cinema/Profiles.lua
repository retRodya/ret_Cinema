local _, ns = ...
local Profiles = {}
ns.Profiles = Profiles

-- Profiles contain preferences only. Recovery CVars, consent and game keybindings
-- stay outside this schema and can never be supplied by an import.
-- Schema entries: path, default, minimum, maximum, first format version, integer-only.
local fields = {
    { "showMinimapButton", true }, { "minimapAngle", 220, -360, 360 },
    { "letterboxHeight", 10, 0, 25 }, { "permanentLetterboxHeight", 10, 0, 25 },
    { "enableAnimation", true }, { "permanentLetterbox", false },
    { "cameraOffset", 1.5, -15, 15 }, { "permanentCameraOffset", 1.5, -15, 15 },
    { "permanentCameraShift", false }, { "combinedAsEsc", false },
}
for _, effect in ipairs(ns.effects) do fields[#fields + 1] = { "effects." .. effect.id, true, nil, nil, effect.id == "fov" and 2 or 1 } end
for _, action in ipairs(ns.actions) do
    fields[#fields + 1] = { "lensEffects." .. action.effect, true }
    fields[#fields + 1] = { "combinedActions." .. action.binding, false }
end
fields[#fields + 1] = { "combinedLensCount", 1, 1, 5, 2, true }
for index = 2, 5 do
    local prefix = "extraCombinedLenses." .. index
    fields[#fields + 1] = { prefix .. ".exitAll", false, nil, nil, 2 }
    for _, action in ipairs(ns.actions) do
        fields[#fields + 1] = { prefix .. ".actions." .. action.binding, false, nil, nil, 2 }
    end
end
local byKey = {}
for _, field in ipairs(fields) do byKey[field[1]] = field end

local function Read(settings, path)
    local value = settings
    for key in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return end
        value = value[tonumber(key) or key]
    end
    return value
end
local function Write(settings, path, value)
    local keys = {}
    for key in path:gmatch("[^.]+") do keys[#keys + 1] = tonumber(key) or key end
    for index = 1, #keys - 1 do
        local key = keys[index]
        if type(settings[key]) ~= "table" then settings[key] = {} end
        settings = settings[key]
    end
    settings[keys[#keys]] = value
end
local function Valid(field, value)
    if type(field[2]) == "boolean" then return type(value) == "boolean" end
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge and
        value >= field[3] and value <= field[4] and (not field[6] or value % 1 == 0)
end
local function Snapshot(source)
    local result = {}
    for _, field in ipairs(fields) do
        local value = Read(source or {}, field[1])
        if not Valid(field, value) then value = field[2] end
        Write(result, field[1], value)
    end
    result.lensEffects.smoothmotion = false
    result.lensEffects.fov = false
    return result
end
local function Name(value)
    if type(value) ~= "string" then return end
    value = value:match("^%s*(.-)%s*$")
    if value == "" or #value > 96 or value:find("[%c|]") then return end
    return value
end
local function Existing(name)
    for stored in pairs(ns.db.profiles) do
        if stored:lower() == name:lower() then return stored end
    end
end
local function CanChange()
    if InCombatLockdown() then return false, "Profiles cannot be changed in combat." end
    return true
end
function Profiles.Save()
    if ns.db and ns.db.profiles then ns.db.profiles[ns.db.activeProfile] = Snapshot(ns.db) end
end
function Profiles.Initialize()
    if type(ns.db.profiles) ~= "table" then ns.db.profiles = {} end
    local clean = {}
    for name, data in pairs(ns.db.profiles) do
        if Name(name) == name and type(data) == "table" then clean[name] = Snapshot(data) end
    end
    ns.db.profiles = clean
    ns.db.activeProfile = Name(ns.db.activeProfile) or "Default"
    Profiles.Save()
end
function Profiles.List(excludeActive)
    local list = {}
    for name in pairs(ns.db.profiles) do
        if not excludeActive or name ~= ns.db.activeProfile then list[#list + 1] = name end
    end
    table.sort(list)
    return list
end
function Profiles.Current() return ns.db.activeProfile end
function Profiles.Activate(name)
    local ok, errorText = CanChange()
    if not ok then return false, errorText end
    if type(name) ~= "string" or not ns.db.profiles[name] then return false, "Profile not found." end
    if name == ns.db.activeProfile then return true, name end
    Profiles.Save()
    local settings = Snapshot(ns.db.profiles[name])
    ns.ApplyProfilePreferences(settings)
    ns.db.activeProfile = name
    Profiles.Save()
    if ns.RefreshProfileSettings then ns.RefreshProfileSettings() end
    return true, name
end
function Profiles.Create(name)
    local ok, errorText = CanChange()
    if not ok then return false, errorText end
    name = Name(name)
    if not name then return false, "Enter a valid profile name." end
    if Existing(name) then return false, "A profile with that name already exists." end
    ns.db.profiles[name] = Snapshot({})
    return Profiles.Activate(name)
end
function Profiles.CopyFrom(name)
    local ok, errorText = CanChange()
    if not ok then return false, errorText end
    if name == ns.db.activeProfile then return false, "Choose another profile to copy." end
    if type(name) ~= "string" or not ns.db.profiles[name] then return false, "Profile not found." end
    ns.ApplyProfilePreferences(Snapshot(ns.db.profiles[name]))
    Profiles.Save()
    if ns.RefreshProfileSettings then ns.RefreshProfileSettings() end
    return true, ns.db.activeProfile
end
function Profiles.Delete(name)
    local ok, errorText = CanChange()
    if not ok then return false, errorText end
    if name == ns.db.activeProfile then return false, "The active profile cannot be deleted." end
    if type(name) ~= "string" or not ns.db.profiles[name] then return false, "Profile not found." end
    ns.db.profiles[name] = nil
    if ns.RefreshProfileSettings then ns.RefreshProfileSettings() end
    return true, name
end
local function Encode(text)
    return (text:gsub("([^%w%-%._ ])", function(character) return string.format("%%%02X", character:byte()) end))
end
local function Decode(text)
    if text:gsub("%%[%x][%x]", ""):find("%%") then return end
    return (text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end
function Profiles.Export()
    Profiles.Save()
    local values = {}
    for _, field in ipairs(fields) do
        local value = Read(ns.db.profiles[ns.db.activeProfile], field[1])
        if type(value) == "boolean" then value = value and "true" or "false"
        else value = string.format("%.17g", value) end
        values[#values + 1] = field[1] .. "=" .. value
    end
    return "RETCINEMA_PROFILE:2|" .. Encode(ns.db.activeProfile) .. "|" .. table.concat(values, ";")
end
function Profiles.Import(text)
    local ok, errorText = CanChange()
    if not ok then return false, errorText end
    if type(text) ~= "string" or #text > 16384 then return false, "Invalid profile export." end
    text = text:match("^%s*(.-)%s*$")
    local version, encodedName, payload = text:match("^RETCINEMA_PROFILE:([12])|([^|]+)|([^|]+)$")
    if not version then return false, "Unsupported or invalid profile export." end
    version = tonumber(version)
    local name = Name(Decode(encodedName))
    if not name then return false, "Invalid profile name in export." end
    local settings, seen, count = {}, {}, 0
    for entry in payload:gmatch("[^;]+") do
        local key, raw = entry:match("^([%w_.]+)=(.+)$")
        local field = key and byKey[key]
        if not field or (field[5] or 1) > version or seen[key] then return false, "Invalid or duplicate profile setting." end
        local value
        if type(field[2]) == "boolean" then
            if raw == "true" then value = true elseif raw == "false" then value = false
            else return false, "Invalid profile setting." end
        else value = tonumber(raw) end
        if not Valid(field, value) then return false, "Invalid profile setting." end
        Write(settings, key, value)
        seen[key], count = true, count + 1
    end
    local required = 0
    for _, field in ipairs(fields) do if (field[5] or 1) <= version then required = required + 1 end end
    if count ~= required or payload:find(";;", 1, true) or payload:sub(1, 1) == ";" or payload:sub(-1) == ";" then
        return false, "Incomplete or invalid profile export."
    end
    if Existing(name) then
        local base = #name <= 70 and name or "Imported Profile"
        name = base .. " (Imported)"
        local index = 2
        while Existing(name) do name = base .. " (Imported " .. index .. ")"; index = index + 1 end
    end
    ns.db.profiles[name] = Snapshot(settings)
    return Profiles.Activate(name)
end
