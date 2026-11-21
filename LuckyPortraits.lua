local ADDON_NAME = "LuckyPortraits"
local BASE_PATH = "Interface\\LuckyPortraits\\"
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Starter defaults applied to new profiles
local DEFAULT_PORTRAIT_STATES = {
    spiritofredemption = "BLIZZARD",
    ghost              = "BLIZZARD",
    polymorph          = "BLIZZARD",
    noggenfogger       = "BLIZZARD",
    deviate            = "BLIZZARD",
    furbolg            = "BLIZZARD",
    orb                = "BLIZZARD",
    disguise           = "BLIZZARD",
    bear               = "BLIZZARD",
    cat                = "BLIZZARD",
    travel             = "BLIZZARD",
    aquatic            = "BLIZZARD",
    moonkin            = "BLIZZARD",
    tree               = "BLIZZARD",
    flight             = "BLIZZARD",
    ghostwolf          = "BLIZZARD",
}

-- Ordered by priority (highest to lowest)
local STATE_DEFS = {
    -- Death & Spirit
    { key = "spiritofredemption", label = "Spirit of Redemption", cat = "class" },
    { key = "ghost",              label = "Ghost / Wisp",         cat = "states" },
    { key = "dead",               label = "Dead",                 cat = "states" },
    { key = "feigndeath",         label = "Feign Death",          cat = "class" },

    -- CC, Immunities & Racials
    { key = "polymorph",          label = "Polymorph",            cat = "disguises" },
    { key = "iceblock",           label = "Ice Block",            cat = "class" },
    { key = "divineshield",       label = "Divine Shield",        cat = "class" },
    { key = "stoneform",          label = "Stoneform",            cat = "class" },

    -- Disguises & Costumes
    { key = "noggenfogger",       label = "Noggenfogger (Skel)",  cat = "disguises" },
    { key = "deviate",            label = "Savory Deviate",       cat = "disguises" },
    { key = "furbolg",            label = "Furbolg Form",         cat = "disguises" },
    { key = "orb",                label = "Orb of Deception",     cat = "disguises" },
    { key = "disguise",           label = "Other Disguise",       cat = "disguises" },

    -- Stealth
    { key = "shadowmeld",         label = "Shadowmeld",           cat = "class" },
    { key = "prowl",              label = "Prowl (Cat Stealth)",  cat = "class" },
    { key = "stealth",            label = "Stealth",              cat = "class" },

    -- Druid Forms, Ghost Wolf & Shadowform
    { key = "bear",               label = "Bear Form",            cat = "forms" },
    { key = "cat",                label = "Cat Form",             cat = "forms" },
    { key = "travel",             label = "Travel Form",          cat = "forms" },
    { key = "aquatic",            label = "Aquatic Form",         cat = "forms" },
    { key = "moonkin",            label = "Moonkin Form",         cat = "forms" },
    { key = "tree",               label = "Tree of Life",         cat = "forms" },
    { key = "flight",             label = "Flight Form",          cat = "forms" },
    { key = "ghostwolf",          label = "Ghost Wolf",           cat = "forms" },
    { key = "shadowform",         label = "Shadowform",           cat = "class" },

    -- Universal States
    { key = "afk",                label = "AFK",                  cat = "states" },
    { key = "taxi",               label = "Flight Path (Taxi)",   cat = "states" },
    { key = "mounted",            label = "Mounted",              cat = "states" },
    { key = "swimming",           label = "Swimming",             cat = "states" },
    { key = "resting",            label = "Resting (Inn/City)",   cat = "states" },

    -- Warrior Stances
    { key = "battle",             label = "Battle Stance",        cat = "forms" },
    { key = "defensive",          label = "Defensive Stance",     cat = "forms" },
    { key = "berserker",          label = "Berserker Stance",     cat = "forms" },

    -- Combat
    { key = "combat",             label = "In Combat",            cat = "states" },

    -- Paladin Auras
    { key = "devotion",           label = "Devotion Aura",        cat = "class" },
    { key = "retribution",        label = "Retribution Aura",     cat = "class" },
    { key = "concentration",      label = "Concentration Aura",   cat = "class" },
    { key = "shadowresist",       label = "Shadow Resist Aura",   cat = "class" },
    { key = "frostresist",        label = "Frost Resist Aura",    cat = "class" },
    { key = "fireresist",         label = "Fire Resist Aura",     cat = "class" },
    { key = "crusader",           label = "Crusader Aura",        cat = "class" },

    -- Hunter Aspects
    { key = "hawk",               label = "Aspect of the Hawk",   cat = "class" },
    { key = "monkey",             label = "Aspect of the Monkey", cat = "class" },
    { key = "cheetah",            label = "Aspect of the Cheetah",cat = "class" },
    { key = "pack",               label = "Aspect of the Pack",   cat = "class" },
    { key = "beast",              label = "Aspect of the Beast",  cat = "class" },
    { key = "wild",               label = "Aspect of the Wild",   cat = "class" },
    { key = "viper",              label = "Aspect of the Viper",  cat = "class" },
}

local VALID_STATE_KEYS = {}
local STATE_LABELS = { default = "Default Portrait" }
for _, def in ipairs(STATE_DEFS) do
    VALID_STATE_KEYS[def.key] = true
    STATE_LABELS[def.key] = def.label
end

local isApplyingBlizzard = false
local isUpdatingSliders = false
local pendingLevelMove = false
local lastResolvedKey = nil
local lastResolvedTarget = nil
local swimmingTicker = nil
local levelDragUnlocked = false
local selectedKey = "default"
local pendingCustomKey = nil
local rememberedCustomFile = {}

local configFrame = nil
local helpFrame = nil
local profileFrame = nil
local exportFrame = nil
local minimapButton = nil
local levelDragHandle = nil

local RefreshUI = function() end
local RefreshProfileUI = function() end
local UpdateMinimapButton = function() end
local UpdateLevelDragHandle = function() end
local ToggleConfigUI = function() end
local ToggleHelpUI = function() end
local ToggleProfileUI = function() end
local OpenExportUI = function() end

-- ============================================================================
-- Safe Value Helpers, Profiles & Import/Export Serialization
-- ============================================================================

local function Trim(str)
    if type(str) ~= "string" then return "" end
    return str:match("^%s*(.-)%s*$")
end

local function SanitizeFilename(str)
    local s = Trim(str)
    s = s:gsub("/", "\\")
    s = s:gsub("^\\+", "")
    return s
end

local function Clamp(val, minVal, maxVal)
    if val < minVal then return minVal end
    if val > maxVal then return maxVal end
    return val
end

local function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function EncodeValue(str)
    str = tostring(str or "")
    return (str:gsub("([^%w%-%._])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function DecodeValue(str)
    if type(str) ~= "string" then return "" end
    return (str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

-- Check secret guards BEFORE nil comparisons (required for WoW 12.1 / Midnight)
local function IsSafeValue(val)
    if issecretvalue and issecretvalue(val) then return false end
    if issecrettable and issecrettable(val) then return false end
    return val ~= nil
end

local function SafeGetField(tbl, key)
    if not IsSafeValue(tbl) or type(tbl) ~= "table" then return nil end
    local ok, val = pcall(rawget, tbl, key)
    if not ok or not IsSafeValue(val) then return nil end
    return val
end

local function SafeBool(fn, ...)
    if not fn then return false end
    local ok, result = pcall(fn, ...)
    if not ok or not IsSafeValue(result) then return false end
    return result == true
end

local function SafeRegisterEvent(frame, event)
    pcall(frame.RegisterEvent, frame, event)
end

local function ApplyBlizzardPortrait(tex)
    if not tex or not SetPortraitTexture or isApplyingBlizzard then return end
    tex:SetTexCoord(0, 1, 0, 1)
    isApplyingBlizzard = true
    pcall(SetPortraitTexture, tex, "player")
    isApplyingBlizzard = false
end

local function GetCharKey()
    local name = UnitName("player") or "Player"
    local realm = (GetRealmName and GetRealmName()) or ""
    if realm ~= "" then
        return name .. " - " .. realm
    end
    return name
end

local function GetStateLabel(key)
    return STATE_LABELS[key or "default"] or tostring(key)
end

local function CreateDefaultProfile()
    local p = {
        enabled = true,
        defaultPortrait = "BLIZZARD",
        levelOffsetX = 0,
        levelOffsetY = 0,
        portraitZoom = 1.0,
        portraitPanX = 0,
        portraitPanY = 0,
        minimapShown = true,
        minimapAngle = 225,
        portraits = {},
        transforms = {},
    }
    for k, v in pairs(DEFAULT_PORTRAIT_STATES) do
        p.portraits[k] = v
    end
    return p
end

local function NormalizeProfile(p)
    if type(p) ~= "table" then return CreateDefaultProfile() end
    if p.enabled == nil then p.enabled = true end
    if type(p.defaultPortrait) ~= "string" or Trim(p.defaultPortrait) == "" then
        p.defaultPortrait = "BLIZZARD"
    end
    if type(p.levelOffsetX) ~= "number" then p.levelOffsetX = 0 end
    if type(p.levelOffsetY) ~= "number" then p.levelOffsetY = 0 end
    if type(p.portraitZoom) ~= "number" then p.portraitZoom = 1.0 end
    if type(p.portraitPanX) ~= "number" then p.portraitPanX = 0 end
    if type(p.portraitPanY) ~= "number" then p.portraitPanY = 0 end
    if p.minimapShown == nil then p.minimapShown = true end
    if type(p.minimapAngle) ~= "number" then p.minimapAngle = 225 end
    if type(p.portraits) ~= "table" then p.portraits = {} end
    if type(p.transforms) ~= "table" then p.transforms = {} end
    return p
end

local function CopyProfileData(source)
    local src = NormalizeProfile(source)
    local copy = {
        enabled = src.enabled and true or false,
        defaultPortrait = src.defaultPortrait,
        levelOffsetX = src.levelOffsetX,
        levelOffsetY = src.levelOffsetY,
        portraitZoom = src.portraitZoom,
        portraitPanX = src.portraitPanX,
        portraitPanY = src.portraitPanY,
        minimapShown = src.minimapShown and true or false,
        minimapAngle = src.minimapAngle,
        portraits = {},
        transforms = {},
    }
    for k, v in pairs(src.portraits) do
        if VALID_STATE_KEYS[k] and type(v) == "string" and Trim(v) ~= "" then
            copy.portraits[k] = v
        end
    end
    for k, t in pairs(src.transforms) do
        if VALID_STATE_KEYS[k] and type(t) == "table" then
            local tz = Round(Clamp(tonumber(t.zoom) or 1.0, 1.0, 2.5), 2)
            local tpx = Round(Clamp(tonumber(t.panX) or 0, -50, 50), 0)
            local tpy = Round(Clamp(tonumber(t.panY) or 0, -50, 50), 0)
            if tz > 1.0 or tpx ~= 0 or tpy ~= 0 then
                copy.transforms[k] = { zoom = tz, panX = tpx, panY = tpy }
            end
        end
    end
    return copy
end

local function GetTransform(db, key)
    if not key or key == "default" then
        return db.portraitZoom or 1.0, db.portraitPanX or 0, db.portraitPanY or 0
    end
    local t = db.transforms and db.transforms[key]
    if type(t) == "table" then
        return tonumber(t.zoom) or 1.0, tonumber(t.panX) or 0, tonumber(t.panY) or 0
    end
    return 1.0, 0, 0
end

local function HasCustomTransform(db, key)
    local z, px, py = GetTransform(db, key)
    return (math.abs(z - 1.0) > 0.001) or (px ~= 0) or (py ~= 0)
end

local function SetTransform(db, key, zoom, panX, panY)
    local z = Round(Clamp(tonumber(zoom) or 1.0, 1.0, 2.5), 2)
    local px = Round(Clamp(tonumber(panX) or 0, -50, 50), 0)
    local py = Round(Clamp(tonumber(panY) or 0, -50, 50), 0)

    if not key or key == "default" then
        db.portraitZoom = z
        db.portraitPanX = px
        db.portraitPanY = py
    else
        if type(db.transforms) ~= "table" then db.transforms = {} end
        if z <= 1.0 and px == 0 and py == 0 then
            db.transforms[key] = nil
        else
            db.transforms[key] = { zoom = z, panX = px, panY = py }
        end
    end
end

local function GetEntryValue(db, key)
    if key == "default" then
        return SanitizeFilename(db.defaultPortrait or "")
    end
    return SanitizeFilename(db.portraits[key] or "")
end

local function InitAccountDB()
    if type(LuckyPortraitsAccountDB) ~= "table" then
        LuckyPortraitsAccountDB = {}
    end
    if type(LuckyPortraitsAccountDB.profiles) ~= "table" then
        LuckyPortraitsAccountDB.profiles = {}
    end
    if type(LuckyPortraitsAccountDB.charProfiles) ~= "table" then
        LuckyPortraitsAccountDB.charProfiles = {}
    end
    if type(LuckyPortraitsAccountDB.profiles["Default"]) ~= "table" then
        LuckyPortraitsAccountDB.profiles["Default"] = CreateDefaultProfile()
    else
        NormalizeProfile(LuckyPortraitsAccountDB.profiles["Default"])
    end

    local charKey = GetCharKey()
    local assigned = LuckyPortraitsAccountDB.charProfiles[charKey]

    if not assigned or type(LuckyPortraitsAccountDB.profiles[assigned]) ~= "table" then
        if type(LuckyPortraitsDB) == "table" and LuckyPortraitsDB.initialized then
            LuckyPortraitsAccountDB.profiles[charKey] = CopyProfileData(LuckyPortraitsDB)
            LuckyPortraitsDB.migratedToProfiles = true
        elseif type(LuckyPortraitsAccountDB.profiles[charKey]) ~= "table" then
            LuckyPortraitsAccountDB.profiles[charKey] = CreateDefaultProfile()
        end
        LuckyPortraitsAccountDB.charProfiles[charKey] = charKey
    else
        NormalizeProfile(LuckyPortraitsAccountDB.profiles[assigned])
    end

    return LuckyPortraitsAccountDB
end

local function GetActiveProfileName()
    local acct = InitAccountDB()
    local charKey = GetCharKey()
    local name = acct.charProfiles[charKey]
    if not name or type(acct.profiles[name]) ~= "table" then
        name = "Default"
        acct.charProfiles[charKey] = name
    end
    return name
end

local function GetDB()
    local acct = InitAccountDB()
    local name = GetActiveProfileName()
    return NormalizeProfile(acct.profiles[name])
end

local function FindProfileNameCaseInsensitive(query)
    local acct = InitAccountDB()
    local target = Trim(query):lower()
    if target == "" then return nil end
    for name in pairs(acct.profiles) do
        if name:lower() == target then
            return name
        end
    end
    return nil
end

local function GetSortedProfileNames()
    local acct = InitAccountDB()
    local names = {}
    for name in pairs(acct.profiles) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a:lower() < b:lower()
    end)
    return names
end

local function ExportProfileString(profile)
    local p = NormalizeProfile(profile)
    local parts = {
        "LP1",
        "en=" .. (p.enabled and "1" or "0"),
        "def=" .. EncodeValue(p.defaultPortrait or "BLIZZARD"),
        "lx=" .. tostring(Round(p.levelOffsetX or 0, 0)),
        "ly=" .. tostring(Round(p.levelOffsetY or 0, 0)),
        "z=" .. string.format("%.2f", Clamp(tonumber(p.portraitZoom) or 1.0, 1.0, 2.5)),
        "px=" .. tostring(Round(p.portraitPanX or 0, 0)),
        "py=" .. tostring(Round(p.portraitPanY or 0, 0)),
        "ms=" .. (p.minimapShown and "1" or "0"),
        "ma=" .. tostring(Round(p.minimapAngle or 225, 1)),
    }
    for _, def in ipairs(STATE_DEFS) do
        local val = p.portraits and p.portraits[def.key]
        if type(val) == "string" and Trim(val) ~= "" then
            table.insert(parts, "p." .. def.key .. "=" .. EncodeValue(val))
            if val:upper() ~= "BLIZZARD" and p.transforms and type(p.transforms[def.key]) == "table" then
                local t = p.transforms[def.key]
                local tz = Round(Clamp(tonumber(t.zoom) or 1.0, 1.0, 2.5), 2)
                local tpx = Round(Clamp(tonumber(t.panX) or 0, -50, 50), 0)
                local tpy = Round(Clamp(tonumber(t.panY) or 0, -50, 50), 0)
                if tz > 1.0 or tpx ~= 0 or tpy ~= 0 then
                    table.insert(parts, string.format("t.%s=%.2f,%d,%d", def.key, tz, tpx, tpy))
                end
            end
        end
    end
    return table.concat(parts, ";")
end

local function ParseProfileString(raw)
    if type(raw) ~= "string" then
        return nil, "Import text is empty."
    end
    local cleaned = raw:gsub("%s+", "")
    if cleaned == "" then
        return nil, "Import text is empty."
    end
    if cleaned:sub(1, 4) ~= "LP1;" then
        return nil, "Invalid format: string must start with LP1;"
    end

    local parsed = {
        enabled = true,
        defaultPortrait = "BLIZZARD",
        levelOffsetX = 0,
        levelOffsetY = 0,
        portraitZoom = 1.0,
        portraitPanX = 0,
        portraitPanY = 0,
        minimapShown = true,
        minimapAngle = 225,
        portraits = {},
        transforms = {},
    }

    local validCount = 0
    for token in cleaned:sub(5):gmatch("[^;]+") do
        local k, v = token:match("^([^=]+)=(.*)$")
        if k and v then
            if k == "en" then
                parsed.enabled = (v == "1")
                validCount = validCount + 1
            elseif k == "def" then
                local dec = SanitizeFilename(DecodeValue(v))
                if dec ~= "" then
                    parsed.defaultPortrait = (dec:upper() == "BLIZZARD") and "BLIZZARD" or dec
                    validCount = validCount + 1
                end
            elseif k == "lx" then
                local n = tonumber(v)
                if n then parsed.levelOffsetX = Clamp(Round(n, 0), -200, 200); validCount = validCount + 1 end
            elseif k == "ly" then
                local n = tonumber(v)
                if n then parsed.levelOffsetY = Clamp(Round(n, 0), -200, 200); validCount = validCount + 1 end
            elseif k == "z" then
                local n = tonumber(v)
                if n then parsed.portraitZoom = Round(Clamp(n, 1.0, 2.5), 2); validCount = validCount + 1 end
            elseif k == "px" then
                local n = tonumber(v)
                if n then parsed.portraitPanX = Clamp(Round(n, 0), -50, 50); validCount = validCount + 1 end
            elseif k == "py" then
                local n = tonumber(v)
                if n then parsed.portraitPanY = Clamp(Round(n, 0), -50, 50); validCount = validCount + 1 end
            elseif k == "ms" then
                parsed.minimapShown = (v == "1")
                validCount = validCount + 1
            elseif k == "ma" then
                local n = tonumber(v)
                if n then parsed.minimapAngle = Clamp(Round(n, 1), -360, 360); validCount = validCount + 1 end
            elseif k:sub(1, 2) == "p." then
                local stateKey = k:sub(3)
                if VALID_STATE_KEYS[stateKey] then
                    local dec = SanitizeFilename(DecodeValue(v))
                    if dec ~= "" then
                        parsed.portraits[stateKey] = (dec:upper() == "BLIZZARD") and "BLIZZARD" or dec
                        validCount = validCount + 1
                    end
                end
            elseif k:sub(1, 2) == "t." then
                local stateKey = k:sub(3)
                if VALID_STATE_KEYS[stateKey] then
                    local zs, pxs, pys = v:match("^([^,]+),([^,]+),([^,]+)$")
                    local zn, pxn, pyn = tonumber(zs), tonumber(pxs), tonumber(pys)
                    if zn and pxn and pyn then
                        local tz = Round(Clamp(zn, 1.0, 2.5), 2)
                        local tpx = Round(Clamp(pxn, -50, 50), 0)
                        local tpy = Round(Clamp(pyn, -50, 50), 0)
                        if tz > 1.0 or tpx ~= 0 or tpy ~= 0 then
                            parsed.transforms[stateKey] = { zoom = tz, panX = tpx, panY = tpy }
                        end
                        validCount = validCount + 1
                    end
                end
            end
        end
    end

    if validCount == 0 then
        return nil, "No valid LuckyPortraits settings found in string."
    end

    return parsed, nil
end

local function GetPlayerPortrait()
    if PlayerFrame and PlayerFrame.PlayerFrameContainer and PlayerFrame.PlayerFrameContainer.PlayerPortrait then
        return PlayerFrame.PlayerFrameContainer.PlayerPortrait
    end
    return (PlayerFrame and PlayerFrame.portrait) or PlayerPortrait
end

local function ApplyCircleMask(tex, parent)
    if not tex or not parent or not parent.CreateMaskTexture or not tex.AddMaskTexture then return end
    if tex._lpHasMask then return end
    if tex.GetNumMaskTextures and tex:GetNumMaskTextures() > 0 then
        tex._lpHasMask = true
        return
    end
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(tex)
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    tex:AddMaskTexture(mask)
    tex._lpHasMask = true
end

local function ApplyPortraitTexCoord(tex, zoom, panX, panY)
    if not tex then return end
    local z = Clamp(tonumber(zoom) or 1.0, 1.0, 2.5)
    local half = 0.5 / z
    local maxShift = 0.5 - half
    local shiftX = Clamp((tonumber(panX) or 0) / 100, -maxShift, maxShift)
    local shiftY = Clamp((tonumber(panY) or 0) / 100, -maxShift, maxShift)

    local left   = 0.5 - shiftX - half
    local right  = 0.5 - shiftX + half
    local top    = 0.5 + shiftY - half
    local bottom = 0.5 + shiftY + half
    tex:SetTexCoord(left, right, top, bottom)
end

-- ============================================================================
-- State Detection & Portrait Application
-- ============================================================================

local function MatchFormOrAuraName(states, lower, spellID, isHarmful)
    if isHarmful then
        if (lower and lower:find("polymorph")) or spellID == 118 or spellID == 12824 or spellID == 12825 or spellID == 12826 or spellID == 28271 or spellID == 28272 then
            states.polymorph = true
        end
        return
    end

    if spellID then
        if spellID == 27827 or spellID == 20711 then states.spiritofredemption = true end
        if spellID == 5384 then states.feigndeath = true end
        if spellID == 11958 or spellID == 45438 then states.iceblock = true end
        if spellID == 642 or spellID == 1020 then states.divineshield = true end
        if spellID == 20594 then states.stoneform = true end
        if spellID == 16591 then states.noggenfogger = true end
        if spellID == 8219 or spellID == 8220 or spellID == 8221 or spellID == 8222 then states.deviate = true end
        if spellID == 18173 then states.furbolg = true end
        if spellID == 16739 then states.orb = true end
        if spellID == 20580 or spellID == 58984 then states.shadowmeld = true end
        if spellID == 5215 or spellID == 6783 or spellID == 9913 then states.prowl = true end
        if spellID == 2645 then states.ghostwolf = true end
        if spellID == 15473 then states.shadowform = true end
    end

    if not lower then return end

    if lower:find("spirit of redemption") then states.spiritofredemption = true end
    if lower:find("feign death") then states.feigndeath = true end
    if lower:find("ice block") then states.iceblock = true end
    if lower:find("divine shield") then states.divineshield = true end
    if lower:find("stoneform") then states.stoneform = true end
    if lower:find("flip out") or lower:find("yaaarrrr") then states.deviate = true end
    if lower:find("furbolg form") then states.furbolg = true end
    if lower:find("orb of deception") then states.orb = true end
    if lower:find("costume") or lower:find("gordok ogre suit") or lower:find("illusion") or lower:find("disguise") then
        states.disguise = true
    end

    if lower:find("shadowmeld") then states.shadowmeld = true end
    if lower:find("prowl") then states.prowl = true end
    if lower == "stealth" then states.stealth = true end

    if lower:find("bear form") then states.bear = true end
    if lower:find("cat form") then states.cat = true end
    if lower:find("aquatic form") or lower:find("seal form") then states.aquatic = true end
    if lower:find("flight form") then states.flight = true end
    if lower:find("travel form") or lower:find("stag form") or lower:find("mount form") or lower:find("cheetah form") then states.travel = true end
    if lower:find("moonkin form") or lower:find("owlkin") then states.moonkin = true end
    if lower:find("tree of life") or lower:find("treant form") then states.tree = true end

    if lower:find("ghost wolf") then states.ghostwolf = true end
    if lower:find("shadowform") then states.shadowform = true end

    if lower:find("battle stance") then states.battle = true end
    if lower:find("defensive stance") then states.defensive = true end
    if lower:find("berserker stance") then states.berserker = true end

    if lower:find("devotion aura") then states.devotion = true end
    if lower:find("retribution aura") then states.retribution = true end
    if lower:find("concentration aura") then states.concentration = true end
    if lower:find("shadow resistance aura") then states.shadowresist = true end
    if lower:find("frost resistance aura") then states.frostresist = true end
    if lower:find("fire resistance aura") then states.fireresist = true end
    if lower:find("crusader aura") then states.crusader = true end

    if lower:find("aspect of the hawk") then states.hawk = true end
    if lower:find("aspect of the monkey") then states.monkey = true end
    if lower:find("aspect of the cheetah") then states.cheetah = true end
    if lower:find("aspect of the pack") then states.pack = true end
    if lower:find("aspect of the beast") then states.beast = true end
    if lower:find("aspect of the wild") then states.wild = true end
    if lower:find("aspect of the viper") then states.viper = true end
end

local function ScanAuras(states, filter, isHarmful)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local checkSecretIndex = C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret
        for i = 1, 80 do
            if checkSecretIndex then
                local okSec, isSec = pcall(checkSecretIndex, "player", i, filter)
                if okSec and IsSafeValue(isSec) and isSec == true then
                    -- Secret aura at this slot; skip reading it cleanly
                else
                    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, filter)
                    if not ok then break end
                    if issecretvalue and issecretvalue(aura) then
                        -- Secret aura; continue to next slot
                    elseif issecrettable and issecrettable(aura) then
                        -- Secret aura table; continue to next slot
                    elseif aura == nil then
                        break
                    else
                        local spellID = SafeGetField(aura, "spellId")
                        if type(spellID) ~= "number" then spellID = nil end
                        local rawName = SafeGetField(aura, "name")
                        local lower = (type(rawName) == "string") and rawName:lower() or nil
                        MatchFormOrAuraName(states, lower, spellID, isHarmful)
                    end
                end
            else
                local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, filter)
                if not ok then break end
                if issecretvalue and issecretvalue(aura) then
                    -- Secret aura; skip
                elseif issecrettable and issecrettable(aura) then
                    -- Secret aura table; skip
                elseif aura == nil then
                    break
                else
                    local spellID = SafeGetField(aura, "spellId")
                    if type(spellID) ~= "number" then spellID = nil end
                    local rawName = SafeGetField(aura, "name")
                    local lower = (type(rawName) == "string") and rawName:lower() or nil
                    MatchFormOrAuraName(states, lower, spellID, isHarmful)
                end
            end
        end
    else
        local fn = isHarmful and UnitDebuff or UnitBuff
        if fn then
            for i = 1, 80 do
                local ok, name, _, _, _, _, _, _, _, _, spellID = pcall(fn, "player", i)
                if not ok or not IsSafeValue(name) then break end
                local safeID = (IsSafeValue(spellID) and type(spellID) == "number") and spellID or nil
                local lower = (type(name) == "string") and name:lower() or nil
                MatchFormOrAuraName(states, lower, safeID, isHarmful)
            end
        end
    end
end

local function CollectActiveStates()
    local states = {}

    if SafeBool(UnitIsGhost, "player") then states.ghost = true end
    if SafeBool(UnitIsDead, "player") then states.dead = true end
    if SafeBool(UnitIsFeignDeath, "player") then states.feigndeath = true end
    if SafeBool(IsStealthed) then states.stealth = true end
    if SafeBool(UnitIsAFK, "player") then states.afk = true end
    if SafeBool(UnitOnTaxi, "player") then states.taxi = true end
    if SafeBool(IsMounted) then states.mounted = true end
    if SafeBool(IsSwimming) then states.swimming = true end
    if SafeBool(IsResting) then states.resting = true end
    if SafeBool(UnitAffectingCombat, "player") then states.combat = true end

    local index = GetShapeshiftForm and GetShapeshiftForm() or 0
    if IsSafeValue(index) and type(index) == "number" and index > 0 and GetShapeshiftFormInfo then
        local ok, _, _, _, spellID = pcall(GetShapeshiftFormInfo, index)
        local safeID = (ok and IsSafeValue(spellID) and type(spellID) == "number") and spellID or nil
        local spellName = nil
        if safeID then
            if C_Spell and C_Spell.GetSpellName then
                local okN, n = pcall(C_Spell.GetSpellName, safeID)
                if okN and IsSafeValue(n) then spellName = n end
            elseif GetSpellInfo then
                local okN, n = pcall(GetSpellInfo, safeID)
                if okN and IsSafeValue(n) then spellName = n end
            end
        end
        if type(spellName) == "string" then
            MatchFormOrAuraName(states, spellName:lower(), safeID, false)
        end
    end

    local formID = GetShapeshiftFormID and GetShapeshiftFormID()
    if IsSafeValue(formID) and type(formID) == "number" then
        if formID == 5 or formID == 8 then states.bear = true end
        if formID == 1 then states.cat = true end
        if formID == 4 then states.aquatic = true end
        if formID == 3 or formID == 36 then states.travel = true end
        if formID == 2 then states.tree = true end
        if formID == 27 or formID == 29 then states.flight = true end
        if formID == 31 or formID == 35 then states.moonkin = true end
        if formID == 16 then states.ghostwolf = true end
        if formID == 28 then states.shadowform = true end
        if formID == 17 then states.battle = true end
        if formID == 18 then states.defensive = true end
        if formID == 19 then states.berserker = true end
        if formID == 30 then states.stealth = true end
    end

    ScanAuras(states, "HELPFUL", false)
    ScanAuras(states, "HARMFUL", true)

    if states.cat and states.stealth then
        states.prowl = true
    end

    return states
end

local function ResolvePortrait()
    local db = GetDB()
    if not db.enabled then
        return "disabled", "BLIZZARD", {}
    end

    local states = CollectActiveStates()
    for _, def in ipairs(STATE_DEFS) do
        local val = SanitizeFilename(db.portraits[def.key] or "")
        if states[def.key] and val ~= "" then
            return def.key, (val:upper() == "BLIZZARD") and "BLIZZARD" or val, states
        end
    end

    local defaultFile = SanitizeFilename(db.defaultPortrait or "")
    if defaultFile == "" or defaultFile:upper() == "BLIZZARD" then
        return "default", "BLIZZARD", states
    end
    return "default", defaultFile, states
end

local function ApplyCustomPortrait()
    if PlayerFrame and PlayerFrame.state == "vehicle" then return end

    local portrait = GetPlayerPortrait()
    if not portrait then return end
    if portrait.IsForbidden and portrait:IsForbidden() then return end

    local db = GetDB()
    local stateKey, target = ResolvePortrait()
    lastResolvedKey = stateKey
    lastResolvedTarget = target

    if target == "BLIZZARD" then
        ApplyBlizzardPortrait(portrait)
    else
        local z, px, py = GetTransform(db, stateKey)
        portrait:SetTexture(BASE_PATH .. target)
        ApplyPortraitTexCoord(portrait, z, px, py)
        ApplyCircleMask(portrait, portrait:GetParent())
    end

    UpdateMinimapButton()
    if configFrame and configFrame:IsShown() then
        RefreshUI()
    end
end

-- ============================================================================
-- Level Badge Movement & Direct Drag Handle (Combat-Safe)
-- ============================================================================

local savedOrigins = {}

local function FindLevelRegions()
    local found = {}
    local seen = {}

    local function AddRegion(obj, label)
        if not obj or seen[obj] or type(obj) ~= "table" then return end
        if obj.IsForbidden and obj:IsForbidden() then return end
        if obj.GetPoint and obj.SetPoint then
            seen[obj] = true
            table.insert(found, { obj = obj, label = label })
        end
    end

    if PlayerLevelText then
        AddRegion(PlayerLevelText, "PlayerLevelText")
    end
    if PlayerHighLevelTexture then
        AddRegion(PlayerHighLevelTexture, "PlayerHighLevelTexture")
    end

    local containers = {}
    local function AddContainer(c)
        if type(c) == "table" and not (c.IsForbidden and c:IsForbidden()) then
            table.insert(containers, c)
        end
    end

    AddContainer(PlayerFrame)
    AddContainer(PlayerFrameTextureFrame)
    if PlayerFrame then
        AddContainer(PlayerFrame.PlayerFrameContainer)
        AddContainer(PlayerFrame.PlayerFrameContent)
        if PlayerFrame.PlayerFrameContent then
            AddContainer(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain)
            AddContainer(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
        end
    end

    for _, container in ipairs(containers) do
        for key, val in pairs(container) do
            if type(key) == "string" and key:lower():find("level") then
                AddRegion(val, key)
            end
        end
        if container.GetRegions then
            for _, region in ipairs({ container:GetRegions() }) do
                local name = region.GetName and region:GetName()
                if name and name:lower():find("level") then
                    AddRegion(region, name)
                end
            end
        end
        if container.GetChildren then
            for _, child in ipairs({ container:GetChildren() }) do
                local name = child.GetName and child:GetName()
                if name and name:lower():find("level") then
                    AddRegion(child, name)
                end
            end
        end
    end

    return found, seen
end

local function MoveLevelBadge()
    if PlayerFrame and PlayerFrame.state == "vehicle" then return end

    -- Never mutate PlayerFrame region anchors during combat lockdown (avoids Retail 12.1 taint)
    if InCombatLockdown() then
        pendingLevelMove = true
        return
    end
    pendingLevelMove = false

    local db = GetDB()
    local offsetX = db.levelOffsetX or 0
    local offsetY = db.levelOffsetY or 0
    local regions, regionSet = FindLevelRegions()

    for _, entry in ipairs(regions) do
        local obj = entry.obj

        if not savedOrigins[obj] then
            local point, relTo, relPoint, x, y = obj:GetPoint(1)
            if point then
                savedOrigins[obj] = {
                    point = point,
                    relTo = relTo,
                    relPoint = relPoint,
                    x = x or 0,
                    y = y or 0,
                }
            end
        end

        local orig = savedOrigins[obj]
        if orig and not regionSet[orig.relTo] then
            obj:ClearAllPoints()
            obj:SetPoint(orig.point, orig.relTo, orig.relPoint, orig.x + offsetX, orig.y + offsetY)
        end
    end

    UpdateLevelDragHandle()
end

local function SetLevelDragUnlocked(unlocked)
    if unlocked and InCombatLockdown() then
        print("|cff89cff0LuckyPortraits:|r finish combat before unlocking level badge dragging.")
        return
    end
    levelDragUnlocked = unlocked and true or false
    UpdateLevelDragHandle()
    RefreshUI()
end

local function EnsureLevelDragHandle()
    if levelDragHandle then return levelDragHandle end

    local h = CreateFrame("Button", "LuckyPortraitsLevelDragHandle", UIParent)
    h:SetSize(34, 34)
    h:SetFrameStrata("HIGH")
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:RegisterForClicks("RightButtonUp")
    h:Hide()

    local fill = h:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetVertexColor(0.54, 0.81, 0.94, 0.32)
    ApplyCircleMask(fill, h)

    local ring = h:CreateTexture(nil, "OVERLAY")
    ring:SetSize(56, 56)
    ring:SetPoint("TOPLEFT", h, "TOPLEFT", -2, 2)
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetVertexColor(0.54, 0.81, 0.94, 1)

    local dragStartCursorX, dragStartCursorY = 0, 0
    local dragOrigOffX, dragOrigOffY = 0, 0

    h:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            SetLevelDragUnlocked(false)
            return
        end
        local db = GetDB()
        dragStartCursorX, dragStartCursorY = GetCursorPosition()
        dragOrigOffX = db.levelOffsetX or 0
        dragOrigOffY = db.levelOffsetY or 0

        self:SetScript("OnUpdate", function()
            if InCombatLockdown() then
                self:SetScript("OnUpdate", nil)
                SetLevelDragUnlocked(false)
                return
            end
            local cx, cy = GetCursorPosition()
            local scale = (PlayerFrame and PlayerFrame:GetEffectiveScale()) or UIParent:GetEffectiveScale() or 1
            local newX = Clamp(Round(dragOrigOffX + (cx - dragStartCursorX) / scale, 0), -200, 200)
            local newY = Clamp(Round(dragOrigOffY + (cy - dragStartCursorY) / scale, 0), -200, 200)
            if newX ~= db.levelOffsetX or newY ~= db.levelOffsetY then
                db.levelOffsetX = newX
                db.levelOffsetY = newY
                MoveLevelBadge()
                if configFrame and configFrame:IsShown() then
                    RefreshUI()
                end
            end
        end)
    end)

    h:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        MoveLevelBadge()
        RefreshUI()
    end)

    h:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            SetLevelDragUnlocked(false)
            print("|cff89cff0LuckyPortraits:|r level badge locked.")
        end
    end)

    h:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cff89cff0Move Level Circle|r")
        GameTooltip:AddLine("Left-Drag to move around portrait", 1, 1, 1)
        GameTooltip:AddLine("Right-Click to lock position", 0.75, 0.80, 0.90)
        GameTooltip:Show()
    end)
    h:SetScript("OnLeave", function() GameTooltip:Hide() end)

    levelDragHandle = h
    return h
end

UpdateLevelDragHandle = function()
    if not levelDragUnlocked then
        if levelDragHandle then
            levelDragHandle:SetScript("OnUpdate", nil)
            levelDragHandle:Hide()
        end
        return
    end

    local h = EnsureLevelDragHandle()
    local regions = FindLevelRegions()
    local target = PlayerLevelText or (regions[1] and regions[1].obj)
    if target then
        h:ClearAllPoints()
        h:SetPoint("CENTER", target, "CENTER", 0, 0)
        h:Show()
    else
        h:Hide()
    end
end

-- ============================================================================
-- Draggable Minimap Button
-- ============================================================================

local function UpdateMinimapButtonPosition()
    if not minimapButton or not Minimap then return end
    local db = GetDB()
    local angle = math.rad(db.minimapAngle or 225)
    local radius = ((Minimap:GetWidth() or 140) / 2) + 5
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function EnsureMinimapButton()
    if minimapButton or not Minimap then return minimapButton end

    local btn = CreateFrame("Button", "LuckyPortraitsMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER", 0, 1)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    ApplyCircleMask(icon, btn)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border = border

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx or not my then return end
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale() or 1
            local angle = math.deg(math.atan2((cy / scale) - my, (cx / scale) - mx))
            GetDB().minimapAngle = angle
            UpdateMinimapButtonPosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            local db = GetDB()
            db.enabled = not db.enabled
            ApplyCustomPortrait()
            MoveLevelBadge()
            RefreshUI()
            print("|cff89cff0LuckyPortraits:|r custom portrait " .. (db.enabled and "|cff00ff00ON|r" or "|cffff5555OFF (Blizzard default)|r"))
        else
            ToggleConfigUI()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        local db = GetDB()
        local winKey, winTarget = ResolvePortrait()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff89cff0Lucky Portraits|r")
        GameTooltip:AddLine("Profile: |cffc084fc" .. GetActiveProfileName() .. "|r", 1, 1, 1)
        GameTooltip:AddLine("Status: " .. (db.enabled and "|cff00ff00ON|r" or "|cffff6b6bOFF|r") .. "  (" .. tostring(winKey) .. ")", 1, 1, 1)
        GameTooltip:AddLine("Active: " .. tostring(winTarget), 0.72, 0.78, 0.88)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Open setup window", 0.85, 0.88, 0.95)
        GameTooltip:AddLine("|cffffffffRight-Click:|r Toggle custom portrait", 0.85, 0.88, 0.95)
        GameTooltip:AddLine("|cffffffffDrag:|r Move around minimap", 0.85, 0.88, 0.95)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    minimapButton = btn
    UpdateMinimapButtonPosition()
    return btn
end

UpdateMinimapButton = function()
    local db = GetDB()
    local btn = EnsureMinimapButton()
    if not btn then return end

    if not db.minimapShown then
        btn:Hide()
        return
    end

    btn:Show()
    UpdateMinimapButtonPosition()

    local defaultFile = SanitizeFilename(db.defaultPortrait or "")
    if defaultFile ~= "" and defaultFile:upper() ~= "BLIZZARD" then
        local z, px, py = GetTransform(db, "default")
        btn.icon:SetTexture(BASE_PATH .. defaultFile)
        ApplyPortraitTexCoord(btn.icon, z, px, py)
    else
        ApplyBlizzardPortrait(btn.icon)
    end

    if db.enabled then
        btn.icon:SetVertexColor(1, 1, 1, 1)
        btn.border:SetVertexColor(0.54, 0.81, 0.94, 1)
    else
        btn.icon:SetVertexColor(0.45, 0.45, 0.50, 1)
        btn.border:SetVertexColor(0.55, 0.35, 0.40, 1)
    end
end

-- ============================================================================
-- Timers, Profile Actions & Apply Scheduler
-- ============================================================================

local function SyncSwimmingTicker()
    local db = GetDB()
    local wantsSwimming = db.portraits and db.portraits.swimming and db.portraits.swimming ~= ""
    if wantsSwimming and not swimmingTicker and C_Timer and C_Timer.NewTicker then
        swimmingTicker = C_Timer.NewTicker(0.5, function()
            local newKey, newTarget = ResolvePortrait()
            if newKey ~= lastResolvedKey or newTarget ~= lastResolvedTarget then
                ApplyCustomPortrait()
            end
        end)
    elseif not wantsSwimming and swimmingTicker then
        swimmingTicker:Cancel()
        swimmingTicker = nil
    end
end

local function ScheduleApply()
    ApplyCustomPortrait()
    MoveLevelBadge()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            ApplyCustomPortrait()
            MoveLevelBadge()
        end)
        C_Timer.After(0.5, function()
            ApplyCustomPortrait()
            MoveLevelBadge()
        end)
    end
end

local function ApplyAllAfterProfileChange()
    selectedKey = "default"
    pendingCustomKey = nil
    SyncSwimmingTicker()
    ScheduleApply()
    UpdateMinimapButton()
    RefreshUI(false)
    RefreshProfileUI()
end

local function SwitchProfile(profileName)
    local acct = InitAccountDB()
    if type(acct.profiles[profileName]) ~= "table" then return false end
    acct.charProfiles[GetCharKey()] = profileName
    ApplyAllAfterProfileChange()
    return true
end

local function ResetActiveProfile()
    local acct = InitAccountDB()
    local active = GetActiveProfileName()
    SetLevelDragUnlocked(false)
    acct.profiles[active] = CreateDefaultProfile()
    ApplyAllAfterProfileChange()
    print("|cff89cff0LuckyPortraits:|r reset profile '" .. active .. "' to defaults.")
end

local function GlobalResetAll()
    SetLevelDragUnlocked(false)
    LuckyPortraitsDB = nil
    local charKey = GetCharKey()
    LuckyPortraitsAccountDB = {
        profiles = {
            ["Default"] = CreateDefaultProfile(),
            [charKey] = CreateDefaultProfile(),
        },
        charProfiles = {
            [charKey] = charKey,
        },
    }
    ApplyAllAfterProfileChange()
    print("|cff89cff0LuckyPortraits:|r GLOBAL RESET complete. All profiles and settings reverted to defaults.")
end

-- ============================================================================
-- Styled UI Helpers & Popups (Help, Profiles, Import/Export)
-- ============================================================================

local BACKDROP_SOLID = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function AttachTooltip(widget, titleText, bodyText)
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(titleText)
        if bodyText then
            GameTooltip:AddLine(bodyText, 0.85, 0.88, 0.95, true)
        end
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateStyledButton(parent, width, height, label)
    local btn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    btn:SetSize(width, height)
    btn:SetBackdrop(BACKDROP_SOLID)
    btn:SetBackdropColor(0.14, 0.16, 0.24, 1)
    btn:SetBackdropBorderColor(0.32, 0.36, 0.50, 1)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    btn.label = text

    btn.SetStyle = function(self, active, accentR, accentG, accentB)
        self.isActive = active
        if active then
            self:SetBackdropColor(accentR or 0.49, accentG or 0.23, accentB or 0.93, 0.90)
            self:SetBackdropBorderColor(0.54, 0.81, 0.94, 1)
            self.label:SetTextColor(1, 1, 1)
        else
            self:SetBackdropColor(0.14, 0.16, 0.24, 1)
            self:SetBackdropBorderColor(0.30, 0.34, 0.46, 1)
            self.label:SetTextColor(0.85, 0.88, 0.95)
        end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.20, 0.23, 0.34, 1)
            self:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.9)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.14, 0.16, 0.24, 1)
            self:SetBackdropBorderColor(0.30, 0.34, 0.46, 1)
        end
    end)

    return btn
end

local function CreateStyledEditBox(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent, BACKDROP_TEMPLATE)
    eb:SetSize(width, height)
    eb:SetBackdrop(BACKDROP_SOLID)
    eb:SetBackdropColor(0.05, 0.06, 0.10, 1)
    eb:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)
    eb:SetFontObject("ChatFontNormal")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetTextColor(0.95, 0.97, 1)

    eb:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0.54, 0.81, 0.94, 1)
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return eb
end

local function CreateStyledSlider(parent, width, minVal, maxVal, step)
    local s = CreateFrame("Slider", nil, parent, BACKDROP_TEMPLATE)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(width, 12)
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetBackdrop(BACKDROP_SOLID)
    s:SetBackdropColor(0.05, 0.06, 0.10, 1)
    s:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)

    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(12, 16)
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.54, 0.81, 0.94, 1)
    s:SetThumbTexture(thumb)

    return s
end

-- Scrollable, Multi-Flavor Help Window
local function CreateHelpWindow()
    if helpFrame then return helpFrame end

    local hf = CreateFrame("Frame", "LuckyPortraitsHelpFrame", UIParent, BACKDROP_TEMPLATE)
    hf:SetSize(530, 510)
    hf:SetPoint("CENTER", 40, 15)
    hf:SetFrameStrata("FULLSCREEN_DIALOG")
    hf:SetMovable(true)
    hf:EnableMouse(true)
    hf:SetClampedToScreen(true)
    hf:RegisterForDrag("LeftButton")
    hf:SetScript("OnDragStart", hf.StartMoving)
    hf:SetScript("OnDragStop", hf.StopMovingOrSizing)
    hf:SetBackdrop(BACKDROP_SOLID)
    hf:SetBackdropColor(0.07, 0.08, 0.13, 0.98)
    hf:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.95)
    hf:Hide()

    table.insert(UISpecialFrames, "LuckyPortraitsHelpFrame")

    local header = CreateFrame("Frame", nil, hf, BACKDROP_TEMPLATE)
    header:SetHeight(34)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetBackdrop(BACKDROP_SOLID)
    header:SetBackdropColor(0.11, 0.12, 0.20, 1)
    header:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.6)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff89cff0Lucky Portraits|r  |cffc084fcSetup Guide & Help|r")

    local closeBtn = CreateStyledButton(header, 24, 22, "X")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() hf:Hide() end)

    local scrollWrap = CreateFrame("Frame", nil, hf, BACKDROP_TEMPLATE)
    scrollWrap:SetPoint("TOPLEFT", 12, -44)
    scrollWrap:SetPoint("BOTTOMRIGHT", -12, 46)
    scrollWrap:SetBackdrop(BACKDROP_SOLID)
    scrollWrap:SetBackdropColor(0.09, 0.10, 0.15, 0.95)
    scrollWrap:SetBackdropBorderColor(0.24, 0.27, 0.38, 1)

    local scroll = CreateFrame("ScrollFrame", "LuckyPortraitsHelpScroll", scrollWrap, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(462, 1)
    scroll:SetScrollChild(scrollChild)

    local body = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", 4, -2)
    body:SetWidth(452)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(4)
    body:SetText(
        "|cff89cff01. Create Your Update-Safe Images Folder|r\n" ..
        "Create a folder named |cffffffffLuckyPortraits|r directly inside your WoW version's |cffffffffInterface|r folder (right next to |cffffffffAddOns|r—not inside it):\n" ..
        "  - |cff89cff0Retail:|r |cffffffffWorld of Warcraft\\_retail_\\Interface\\LuckyPortraits\\|r\n" ..
        "  - |cff89cff0WoW Forever:|r |cffffffffWorld of Warcraft\\_forever_\\Interface\\LuckyPortraits\\|r\n" ..
        "  - |cff89cff0MoP Classic:|r |cffffffffWorld of Warcraft\\_classic_\\Interface\\LuckyPortraits\\|r\n" ..
        "  - |cff89cff0TBC Anniversary:|r |cffffffffWorld of Warcraft\\_anniversary_\\Interface\\LuckyPortraits\\|r\n" ..
        "  - |cff89cff0Classic Era:|r |cffffffffWorld of Warcraft\\_classic_era_\\Interface\\LuckyPortraits\\|r\n" ..
        "Keeping your images outside |cffffffffAddOns\\|r guarantees that addon updates through CurseForge or other managers will never delete your custom portraits.\n\n" ..
        "|cffc084fcQuick Shortcut (CurseForge App):|r\n" ..
        "  1. Open the |cffffffffCurseForge App|r, select your WoW flavor, and right-click |cffffffffLucky Portraits|r.\n" ..
        "  2. Click |cffffffffOpen Folder|r (opens |cffffffffInterface\\AddOns\\LuckyPortraits|r).\n" ..
        "  3. Click |cffffffffInterface|r in your folder address bar to go up two levels, then create a new folder named |cffffffffLuckyPortraits|r right beside |cffffffffAddOns|r.\n\n" ..
        "WoW's graphics engine has strict requirements for custom images:\n" ..
        "  - |cffffffffSquare power-of-two size:|r Resize images to |cffffffff256x256|r or |cffffffff512x512|r pixels (other sizes like 300x300 render as a solid green circle).\n" ..
        "  - |cffffffffSupported formats:|r .png, .tga, .jpg, or .blp. Subfolders work too (e.g. |cffffffffdruid\\cat.png|r).\n" ..
        "  - |cffffffffCircular crop:|r Keep faces or subjects near the center so corners are not clipped.\n" ..
        "  - |cffffd166Full restart required:|r Typing /reload updates settings, but you must completely close and relaunch WoW whenever you drop brand-new image files into the folder.\n\n" ..

        "|cff89cff02. How to Set Up Images in the Preview Panel|r\n" ..
        "New installs start on Blizzard's 3D portrait so you never see a green circle before adding your own files. The setup window is split into two sides:\n" ..
        "  - |cffffffffLeft Side (Portrait List):|r Click |cff89cff0Default Portrait|r at the top for your normal character image, or pick any Druid form, Shaman Ghost Wolf, Warrior stance, class buff, disguise, or status (Dead, Combat, Resting, etc.). Use the category tabs to filter the list.\n" ..
        "  - |cffffffffRight Side (Preview & Settings):|r Shows a large circular preview of whichever state you clicked on the left, along with three mode buttons:\n" ..
        "      |cffc084fcCustom Image|r - Lets you type a filename from your |cffffffffInterface\\LuckyPortraits\\|r folder (for example, |cffffffffportrait.png|r or |cffffffffcat.png|r) and click |cffffffffApply|r (or press Enter).\n" ..
        "      |cffc084fcBlizzard 3D|r - Lets WoW's real 3D character/animal portrait show during that state (great for Druid forms, Ghost Wolf, Polymorph, and disguises).\n" ..
        "      |cffc084fcUse Default|r - Ignores that state so your Default Portrait (or a lower-priority state) stays visible.\n\n" ..

        "|cff89cff03. Zoom & Position (Per-Image Framing)|r\n" ..
        "Every custom image saves its own independent framing—so your Cat Form image can have a completely different zoom and position than your Default Portrait.\n" ..
        "  - Drag the |cffffffffZoom|r slider (1.00x to 2.50x) to zoom in on your image.\n" ..
        "  - Drag |cffffffffPan X|r (left/right) and |cffffffffPan Y|r (up/down) to center the subject inside the circle. Note: Zoom must be above 1.00x to pan (moving a Pan slider at 1.00x automatically bumps Zoom to 1.15x).\n" ..
        "  - Click |cffffffff-|r / |cffffffff+|r for fine adjustments (hold |cffffffffShift|r for larger jumps), or click |cffffffffReset Framing|r to snap that image back to 1.00x centered.\n" ..
        "  - You can frame any form or state right inside the Preview Panel without having to shift into it first!\n\n" ..

        "|cff89cff04. How Priority Works|r\n" ..
        "When multiple states happen at the same time (for example, Cat Form + In Combat + Prowl), Lucky Portraits picks the highest-priority state that has a Custom Image or Blizzard 3D assigned. States set to |cffffffffUse Default|r are skipped automatically. The list order from top to bottom on the |cffffffffAll|r tab shows the exact priority order.\n\n" ..

        "|cff89cff05. Moving the Level Circle|r\n" ..
        "Click |cffffffffDrag: OFF|r in the top bar (or type |cffffffff/lp drag|r) to place a glowing circular handle over your level badge. Left-drag it anywhere around your portrait frame, then |cffffffffright-click|r the handle to lock it in place. You can also fine-tune X and Y with the number boxes or reset to |cffffffff0, 0|r.\n\n" ..

        "|cff89cff06. Character Profiles & Import / Export|r\n" ..
        "  - |cffffffffProfiles:|r Every character automatically gets its own profile saved account-wide. Click |cffffffffProfiles|r to create, clone, rename, switch, copy settings from another alt, or delete profiles.\n" ..
        "  - |cffffffffImp / Exp:|r Exports your active profile (including every image's custom Zoom & Pan) into a portable |cffffffffLP1;...|r string you can copy with Ctrl+C to back up or share.\n" ..
        "  - |cffffffffReset Profile vs Global Reset:|r Reset Profile reverts only the active profile. Global Reset wipes ALL profiles across your account back to factory defaults.\n\n" ..

        "|cff89cff07. Minimap Icon & Slash Commands|r\n" ..
        "Left-click the minimap icon to open Setup, right-click it to toggle custom portraits ON/OFF, or drag it around the minimap border.\n" ..
        "  |cffffffff/lp|r - Open or close the Setup window\n" ..
        "  |cffffffff/lp toggle|r (or |cffffffffon|r / |cffffffffoff|r) - Enable or disable custom portraits\n" ..
        "  |cffffffff/lp minimap|r - Show or hide the draggable minimap icon\n" ..
        "  |cffffffff/lp drag|r - Unlock or lock level circle dragging\n" ..
        "  |cffffffff/lp X Y|r - Set level circle offset (e.g. /lp -20 20)\n" ..
        "  |cffffffff/lp profiles|r / |cffffffff/lp profile Name|r - Open or switch profiles\n" ..
        "  |cffffffff/lp export|r / |cffffffff/lp import|r - Open Import / Export window\n" ..
        "  |cffffffff/lp status|r - Print active states, winner, and current image\n" ..
        "  |cffffffff/lp reset|r - Recenter the Setup window\n" ..
        "  |cffffffff/lp guide|r / |cffffffff/lphelp|r - Open this Help window or print chat help\n\n" ..

        "|cff89cff08. Quick Troubleshooting|r\n" ..
        "  - |cff00ff00Solid green circle?|r Double-check: (1) your file is inside your client's |cffffffffInterface\\LuckyPortraits\\|r folder (not Interface\\AddOns\\LuckyPortraits\\), (2) spelling and extension match exactly, (3) image dimensions are an exact power of two like 256x256 or 512x512, and (4) you fully closed and relaunched WoW after adding the file.\n" ..
        "  - |cff00ff00Portrait did not swap?|r Make sure |cffffffffCustom Portrait: ON|r is active, then run |cffffffff/lp status|r to see which higher-priority state is winning."
    )

    hf:SetScript("OnShow", function()
        local h = body:GetStringHeight() or 820
        scrollChild:SetHeight(math.max(400, h + 28))
        if scroll.SetVerticalScroll then
            scroll:SetVerticalScroll(0)
        end
    end)

    local okBtn = CreateStyledButton(hf, 110, 26, "Got It")
    okBtn:SetPoint("BOTTOM", 0, 10)
    okBtn:SetStyle(true)
    okBtn:SetScript("OnClick", function() hf:Hide() end)

    helpFrame = hf
    return hf
end

ToggleHelpUI = function()
    local hf = CreateHelpWindow()
    if hf:IsShown() then hf:Hide() else hf:Show() end
end

-- Profile Manager Popup
local function CreateProfileWindow()
    if profileFrame then return profileFrame end

    local pf = CreateFrame("Frame", "LuckyPortraitsProfileFrame", UIParent, BACKDROP_TEMPLATE)
    pf:SetSize(450, 440)
    pf:SetPoint("CENTER", 30, 10)
    pf:SetFrameStrata("FULLSCREEN_DIALOG")
    pf:SetMovable(true)
    pf:EnableMouse(true)
    pf:SetClampedToScreen(true)
    pf:RegisterForDrag("LeftButton")
    pf:SetScript("OnDragStart", pf.StartMoving)
    pf:SetScript("OnDragStop", pf.StopMovingOrSizing)
    pf:SetBackdrop(BACKDROP_SOLID)
    pf:SetBackdropColor(0.07, 0.08, 0.13, 0.98)
    pf:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.95)
    pf:Hide()

    table.insert(UISpecialFrames, "LuckyPortraitsProfileFrame")

    local header = CreateFrame("Frame", nil, pf, BACKDROP_TEMPLATE)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetBackdrop(BACKDROP_SOLID)
    header:SetBackdropColor(0.11, 0.12, 0.20, 1)
    header:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.6)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff89cff0Lucky Portraits|r - Character Profiles")

    local closeBtn = CreateStyledButton(header, 24, 22, "X")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() pf:Hide() end)

    local infoCard = CreateFrame("Frame", nil, pf, BACKDROP_TEMPLATE)
    infoCard:SetHeight(86)
    infoCard:SetPoint("TOPLEFT", 12, -42)
    infoCard:SetPoint("TOPRIGHT", -12, -42)
    infoCard:SetBackdrop(BACKDROP_SOLID)
    infoCard:SetBackdropColor(0.10, 0.11, 0.17, 0.95)
    infoCard:SetBackdropBorderColor(0.24, 0.27, 0.38, 1)

    local activeInfo = infoCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeInfo:SetPoint("TOPLEFT", 10, -10)
    activeInfo:SetPoint("TOPRIGHT", -10, -10)
    activeInfo:SetJustifyH("LEFT")

    local nameLabel = infoCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", 10, -34)
    nameLabel:SetText("|cff89cff0Profile Name:|r")

    local nameInput = CreateStyledEditBox(infoCard, 174, 22)
    nameInput:SetPoint("TOPLEFT", 10, -52)

    local newBtn = CreateStyledButton(infoCard, 56, 22, "New")
    newBtn:SetPoint("LEFT", nameInput, "RIGHT", 6, 0)
    AttachTooltip(newBtn, "|cff89cff0Create New Profile|r", "Creates a fresh profile with default settings and switches to it.")

    local cloneBtn = CreateStyledButton(infoCard, 60, 22, "Clone")
    cloneBtn:SetPoint("LEFT", newBtn, "RIGHT", 5, 0)
    AttachTooltip(cloneBtn, "|cff89cff0Clone Current Profile|r", "Duplicates your active profile under the new name and switches to it.")

    local renameBtn = CreateStyledButton(infoCard, 66, 22, "Rename")
    renameBtn:SetPoint("LEFT", cloneBtn, "RIGHT", 5, 0)
    AttachTooltip(renameBtn, "|cff89cff0Rename Active Profile|r", "Renames your currently active profile (Default cannot be renamed).")

    local feedbackText = pf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedbackText:SetPoint("TOPLEFT", infoCard, "BOTTOMLEFT", 2, -6)
    feedbackText:SetPoint("TOPRIGHT", infoCard, "BOTTOMRIGHT", -2, -6)
    feedbackText:SetJustifyH("LEFT")
    feedbackText:SetText(" ")

    local function SetFeedback(msg)
        feedbackText:SetText(msg or " ")
    end

    local function CreateOrCloneProfile(shouldClone)
        local raw = Trim(nameInput:GetText())
        if raw == "" then
            SetFeedback("|cffff6b6bEnter a profile name first.|r")
            return
        end
        if FindProfileNameCaseInsensitive(raw) then
            SetFeedback("|cffff6b6bA profile named '" .. raw .. "' already exists.|r")
            return
        end
        local acct = InitAccountDB()
        if shouldClone then
            acct.profiles[raw] = CopyProfileData(GetDB())
        else
            acct.profiles[raw] = CreateDefaultProfile()
        end
        acct.charProfiles[GetCharKey()] = raw
        nameInput:SetText("")
        nameInput:ClearFocus()
        SetFeedback("|cff00ff00Switched to " .. (shouldClone and "cloned" or "new") .. " profile '" .. raw .. "'.|r")
        ApplyAllAfterProfileChange()
    end

    newBtn:SetScript("OnClick", function() CreateOrCloneProfile(false) end)
    cloneBtn:SetScript("OnClick", function() CreateOrCloneProfile(true) end)
    renameBtn:SetScript("OnClick", function()
        local active = GetActiveProfileName()
        if active == "Default" then
            SetFeedback("|cffff6b6bThe 'Default' profile cannot be renamed.|r")
            return
        end
        local newName = Trim(nameInput:GetText())
        if newName == "" then
            SetFeedback("|cffff6b6bEnter a new name first.|r")
            return
        end
        if FindProfileNameCaseInsensitive(newName) then
            SetFeedback("|cffff6b6bA profile named '" .. newName .. "' already exists.|r")
            return
        end
        local acct = InitAccountDB()
        acct.profiles[newName] = acct.profiles[active]
        acct.profiles[active] = nil
        for cKey, pName in pairs(acct.charProfiles) do
            if pName == active then
                acct.charProfiles[cKey] = newName
            end
        end
        nameInput:SetText("")
        nameInput:ClearFocus()
        SetFeedback("|cff00ff00Renamed '" .. active .. "' to '" .. newName .. "'.|r")
        ApplyAllAfterProfileChange()
    end)

    local listBox = CreateFrame("Frame", nil, pf, BACKDROP_TEMPLATE)
    listBox:SetPoint("TOPLEFT", infoCard, "BOTTOMLEFT", 0, -24)
    listBox:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT", -12, 42)
    listBox:SetBackdrop(BACKDROP_SOLID)
    listBox:SetBackdropColor(0.09, 0.10, 0.15, 0.95)
    listBox:SetBackdropBorderColor(0.24, 0.27, 0.38, 1)

    local scrollFrame = CreateFrame("ScrollFrame", "LuckyPortraitsProfileScroll", listBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 6)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(386, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local rows = {}
    local pendingCopy = nil
    local pendingDelete = nil

    local function GetOrCreateProfileRow(i)
        if rows[i] then return rows[i] end

        local row = CreateFrame("Frame", nil, scrollChild, BACKDROP_TEMPLATE)
        row:SetSize(382, 30)
        row:SetBackdrop(BACKDROP_SOLID)
        row:SetBackdropColor(0.12, 0.13, 0.20, 0.9)
        row:SetBackdropBorderColor(0.20, 0.22, 0.32, 0.8)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 8, 0)
        label:SetWidth(196)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        row.label = label

        local useBtn = CreateStyledButton(row, 54, 22, "Use")
        useBtn:SetPoint("LEFT", label, "RIGHT", 6, 0)
        row.useBtn = useBtn

        local copyBtn = CreateStyledButton(row, 58, 22, "Copy")
        copyBtn:SetPoint("LEFT", useBtn, "RIGHT", 5, 0)
        AttachTooltip(copyBtn, "|cff89cff0Copy Settings From Here|r", "Copies this profile's settings into your currently active profile.")
        row.copyBtn = copyBtn

        local delBtn = CreateStyledButton(row, 44, 22, "Del")
        delBtn:SetPoint("LEFT", copyBtn, "RIGHT", 5, 0)
        row.delBtn = delBtn

        useBtn:SetScript("OnClick", function()
            if not row.profileName then return end
            pendingCopy = nil
            pendingDelete = nil
            SwitchProfile(row.profileName)
            SetFeedback("|cff00ff00Now using profile '" .. row.profileName .. "'.|r")
        end)

        copyBtn:SetScript("OnClick", function()
            if not row.profileName or row.profileName == GetActiveProfileName() then return end
            if pendingCopy ~= row.profileName then
                pendingCopy = row.profileName
                pendingDelete = nil
                SetFeedback("|cffffd166Click 'Sure?' to overwrite '" .. GetActiveProfileName() .. "' with '" .. row.profileName .. "'.|r")
                RefreshProfileUI()
            else
                local acct = InitAccountDB()
                local active = GetActiveProfileName()
                acct.profiles[active] = CopyProfileData(acct.profiles[row.profileName])
                pendingCopy = nil
                SetFeedback("|cff00ff00Copied '" .. row.profileName .. "' into '" .. active .. "'.|r")
                ApplyAllAfterProfileChange()
            end
        end)

        delBtn:SetScript("OnClick", function()
            if not row.profileName then return end
            if row.profileName == "Default" or row.profileName == GetActiveProfileName() then return end
            if pendingDelete ~= row.profileName then
                pendingDelete = row.profileName
                pendingCopy = nil
                SetFeedback("|cffff6b6bClick 'Sure?' to permanently delete profile '" .. row.profileName .. "'.|r")
                RefreshProfileUI()
            else
                local acct = InitAccountDB()
                local target = row.profileName
                acct.profiles[target] = nil
                for cKey, pName in pairs(acct.charProfiles) do
                    if pName == target then
                        acct.charProfiles[cKey] = "Default"
                    end
                end
                pendingDelete = nil
                SetFeedback("|cffffd166Deleted profile '" .. target .. "'.|r")
                RefreshProfileUI()
            end
        end)

        rows[i] = row
        return row
    end

    local expBtn = CreateStyledButton(pf, 140, 24, "Import / Export...")
    expBtn:SetPoint("BOTTOMLEFT", 12, 10)
    expBtn:SetScript("OnClick", function() OpenExportUI(true) end)

    local doneBtn = CreateStyledButton(pf, 80, 24, "Done")
    doneBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    doneBtn:SetStyle(true)
    doneBtn:SetScript("OnClick", function() pf:Hide() end)

    RefreshProfileUI = function()
        if not profileFrame or not profileFrame:IsShown() then return end
        local active = GetActiveProfileName()
        activeInfo:SetText("|cff89cff0Character:|r " .. GetCharKey() .. "    |cff89cff0Active:|r |cffc084fc" .. active .. "|r")

        local names = GetSortedProfileNames()
        for i, name in ipairs(names) do
            local row = GetOrCreateProfileRow(i)
            row.profileName = name
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, -((i - 1) * 34) - 2)
            row:Show()

            local isCurrent = (name == active)
            if isCurrent then
                row:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.95)
                row.label:SetText("|cff89cff0" .. name .. "|r")
                row.useBtn.label:SetText("Active")
                row.useBtn:SetStyle(true)
                row.copyBtn:Hide()
                row.delBtn:Hide()
            else
                row:SetBackdropBorderColor(0.20, 0.22, 0.32, 0.8)
                row.label:SetText(name)
                row.useBtn.label:SetText("Use")
                row.useBtn:SetStyle(false)

                row.copyBtn:Show()
                if pendingCopy == name then
                    row.copyBtn.label:SetText("Sure?")
                    row.copyBtn:SetStyle(true, 0.65, 0.45, 0.10)
                else
                    row.copyBtn.label:SetText("Copy")
                    row.copyBtn:SetStyle(false)
                end

                if name == "Default" then
                    row.delBtn:Hide()
                else
                    row.delBtn:Show()
                    if pendingDelete == name then
                        row.delBtn.label:SetText("Sure?")
                        row.delBtn:SetStyle(true, 0.72, 0.20, 0.24)
                    else
                        row.delBtn.label:SetText("Del")
                        row.delBtn:SetStyle(false)
                    end
                end
            end
        end

        for i = #names + 1, #rows do
            rows[i]:Hide()
        end
        scrollChild:SetHeight(math.max(1, #names * 34 + 6))
    end

    pf:SetScript("OnShow", function()
        pendingCopy = nil
        pendingDelete = nil
        SetFeedback(" ")
        RefreshProfileUI()
    end)

    profileFrame = pf
    return pf
end

ToggleProfileUI = function()
    local pf = CreateProfileWindow()
    if pf:IsShown() then pf:Hide() else pf:Show() end
end

-- Import / Export Popup
local function CreateExportWindow()
    if exportFrame then return exportFrame end

    local ef = CreateFrame("Frame", "LuckyPortraitsExportFrame", UIParent, BACKDROP_TEMPLATE)
    ef:SetSize(485, 365)
    ef:SetPoint("CENTER", 20, -10)
    ef:SetFrameStrata("FULLSCREEN_DIALOG")
    ef:SetMovable(true)
    ef:EnableMouse(true)
    ef:SetClampedToScreen(true)
    ef:RegisterForDrag("LeftButton")
    ef:SetScript("OnDragStart", ef.StartMoving)
    ef:SetScript("OnDragStop", ef.StopMovingOrSizing)
    ef:SetBackdrop(BACKDROP_SOLID)
    ef:SetBackdropColor(0.07, 0.08, 0.13, 0.98)
    ef:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.95)
    ef:Hide()

    table.insert(UISpecialFrames, "LuckyPortraitsExportFrame")

    local header = CreateFrame("Frame", nil, ef, BACKDROP_TEMPLATE)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetBackdrop(BACKDROP_SOLID)
    header:SetBackdropColor(0.11, 0.12, 0.20, 1)
    header:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.6)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff89cff0Lucky Portraits|r - Import / Export")

    local closeBtn = CreateStyledButton(header, 24, 22, "X")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() ef:Hide() end)

    local desc = ef:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 14, -42)
    desc:SetPoint("TOPRIGHT", -14, -42)
    desc:SetJustifyH("LEFT")
    desc:SetText("Copy the code below to back up or share your profile, or paste an LP1; code to import.")

    local boxWrap = CreateFrame("Frame", nil, ef, BACKDROP_TEMPLATE)
    boxWrap:SetPoint("TOPLEFT", 14, -72)
    boxWrap:SetPoint("TOPRIGHT", -14, -72)
    boxWrap:SetHeight(165)
    boxWrap:SetBackdrop(BACKDROP_SOLID)
    boxWrap:SetBackdropColor(0.04, 0.05, 0.08, 1)
    boxWrap:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)

    local scroll = CreateFrame("ScrollFrame", "LuckyPortraitsExportScroll", boxWrap, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(420)
    editBox:SetTextColor(0.92, 0.96, 1)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(editBox)

    boxWrap:EnableMouse(true)
    boxWrap:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    local newProfLabel = ef:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newProfLabel:SetPoint("TOPLEFT", boxWrap, "BOTTOMLEFT", 0, -14)
    newProfLabel:SetText("|cff89cff0Import into new profile (optional):|r")

    local newProfInput = CreateStyledEditBox(ef, 200, 22)
    newProfInput:SetPoint("LEFT", newProfLabel, "RIGHT", 8, 0)
    AttachTooltip(newProfInput, "|cff89cff0Optional Target Profile|r", "Leave blank to overwrite your currently active profile, or type a name to import into a new/specific profile.")

    local statusMsg = ef:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusMsg:SetPoint("TOPLEFT", newProfLabel, "BOTTOMLEFT", 0, -12)
    statusMsg:SetPoint("TOPRIGHT", boxWrap, "BOTTOMRIGHT", 0, -42)
    statusMsg:SetJustifyH("LEFT")
    statusMsg:SetText(" ")

    local exportBtn = CreateStyledButton(ef, 126, 26, "Export Current")
    exportBtn:SetPoint("BOTTOMLEFT", 14, 12)
    exportBtn:SetStyle(true)

    local importBtn = CreateStyledButton(ef, 120, 26, "Import String")
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)

    local clearBtn = CreateStyledButton(ef, 76, 26, "Clear Box")
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)

    local doneBtn = CreateStyledButton(ef, 74, 26, "Close")
    doneBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    doneBtn:SetScript("OnClick", function() ef:Hide() end)

    local function PopulateExport()
        local str = ExportProfileString(GetDB())
        editBox:SetText(str)
        editBox:SetFocus()
        editBox:HighlightText()
        statusMsg:SetText("|cff89cff0Exported '" .. GetActiveProfileName() .. "' (with per-state framing). Press Ctrl+C to copy.|r")
    end

    exportBtn:SetScript("OnClick", PopulateExport)

    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:SetFocus()
        statusMsg:SetText("|cff9b8ab8Paste an LP1; profile string above and click Import String.|r")
    end)

    importBtn:SetScript("OnClick", function()
        local parsed, err = ParseProfileString(editBox:GetText())
        if not parsed then
            statusMsg:SetText("|cffff6b6bImport failed: " .. tostring(err) .. "|r")
            return
        end

        local acct = InitAccountDB()
        local targetName = Trim(newProfInput:GetText())
        if targetName == "" then
            targetName = GetActiveProfileName()
        else
            local existing = FindProfileNameCaseInsensitive(targetName)
            if existing then targetName = existing end
        end

        acct.profiles[targetName] = parsed
        acct.charProfiles[GetCharKey()] = targetName
        newProfInput:SetText("")
        editBox:ClearFocus()
        ApplyAllAfterProfileChange()
        statusMsg:SetText("|cff00ff00Imported settings into profile '" .. targetName .. "'!|r")
        print("|cff89cff0LuckyPortraits:|r imported settings into profile '" .. targetName .. "'.")
    end)

    ef.PopulateExport = PopulateExport
    ef.ClearForImport = function()
        editBox:SetText("")
        newProfInput:SetText("")
        statusMsg:SetText("|cff9b8ab8Paste an LP1; profile string above and click Import String.|r")
        editBox:SetFocus()
    end

    exportFrame = ef
    return ef
end

OpenExportUI = function(autoExport)
    local ef = CreateExportWindow()
    ef:Show()
    if autoExport then
        ef.PopulateExport()
    else
        ef.ClearForImport()
    end
end

-- ============================================================================
-- Main Split-Pane Configuration Window
-- ============================================================================

local function CreateConfigWindow()
    if configFrame then return configFrame end

    local f = CreateFrame("Frame", "LuckyPortraitsConfigFrame", UIParent, BACKDROP_TEMPLATE)
    f:SetSize(700, 568)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop(BACKDROP_SOLID)
    f:SetBackdropColor(0.07, 0.08, 0.13, 0.96)
    f:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.95)
    f:Hide()

    table.insert(UISpecialFrames, "LuckyPortraitsConfigFrame")

    -- Header bar
    local header = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    header:SetHeight(34)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetBackdrop(BACKDROP_SOLID)
    header:SetBackdropColor(0.11, 0.12, 0.20, 1)
    header:SetBackdropBorderColor(0.49, 0.23, 0.93, 0.5)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff89cff0Lucky Portraits|r  |cff9b8ab8v2.6|r")

    local closeBtn = CreateStyledButton(header, 24, 22, "X")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local helpBtn = CreateStyledButton(header, 64, 22, "? Help")
    helpBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    helpBtn:SetScript("OnClick", ToggleHelpUI)
    AttachTooltip(helpBtn, "|cff89cff0Setup Guide & Help|r", "Open the full step-by-step setup guide, troubleshooting tips, and command list.")

    -- Top Control Bar (Profiles, Global ON/OFF, Minimap, Level Badge)
    local topBar = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    topBar:SetHeight(68)
    topBar:SetPoint("TOPLEFT", 12, -42)
    topBar:SetPoint("TOPRIGHT", -12, -42)
    topBar:SetBackdrop(BACKDROP_SOLID)
    topBar:SetBackdropColor(0.10, 0.11, 0.17, 0.95)
    topBar:SetBackdropBorderColor(0.24, 0.27, 0.38, 1)

    local minimapBtnToggle = CreateStyledButton(topBar, 92, 24, "Minimap: ON")
    minimapBtnToggle:SetPoint("TOPRIGHT", -8, -7)
    minimapBtnToggle:SetScript("OnClick", function()
        local db = GetDB()
        db.minimapShown = not db.minimapShown
        UpdateMinimapButton()
        RefreshUI()
    end)
    AttachTooltip(minimapBtnToggle, "|cff89cff0Minimap Icon|r", "Show or hide the draggable minimap button.")

    local toggleBtn = CreateStyledButton(topBar, 148, 24, "Custom Portrait: ON")
    toggleBtn:SetPoint("RIGHT", minimapBtnToggle, "LEFT", -6, 0)
    toggleBtn:SetScript("OnClick", function()
        local db = GetDB()
        db.enabled = not db.enabled
        ScheduleApply()
        RefreshUI()
    end)

    local impExpBtn = CreateStyledButton(topBar, 74, 24, "Imp / Exp")
    impExpBtn:SetPoint("RIGHT", toggleBtn, "LEFT", -10, 0)
    impExpBtn:SetScript("OnClick", function() OpenExportUI(true) end)
    AttachTooltip(impExpBtn, "|cff89cff0Import / Export|r", "Export your active profile as a portable string or import settings.")

    local profilesBtn = CreateStyledButton(topBar, 68, 24, "Profiles")
    profilesBtn:SetPoint("RIGHT", impExpBtn, "LEFT", -5, 0)
    profilesBtn:SetStyle(true)
    profilesBtn:SetScript("OnClick", ToggleProfileUI)
    AttachTooltip(profilesBtn, "|cff89cff0Manage Profiles|r", "Switch, create, clone, copy, rename, or delete character profiles.")

    local profPrefix = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profPrefix:SetPoint("TOPLEFT", 10, -13)
    profPrefix:SetText("|cff89cff0Profile:|r")

    local activeProfileLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeProfileLabel:SetPoint("LEFT", profPrefix, "RIGHT", 6, 0)
    activeProfileLabel:SetPoint("RIGHT", profilesBtn, "LEFT", -8, 0)
    activeProfileLabel:SetJustifyH("LEFT")
    activeProfileLabel:SetWordWrap(false)

    -- Top Row 2: Level Badge Controls
    local lvlLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lvlLabel:SetPoint("BOTTOMLEFT", 10, 13)
    lvlLabel:SetText("|cff89cff0Level Circle:|r")

    local function CreateLevelAxis(anchorTo, offX, axisLabel, dbField)
        local lbl = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", anchorTo, "RIGHT", offX, 0)
        lbl:SetText(axisLabel)

        local minusBtn = CreateStyledButton(topBar, 20, 22, "-")
        minusBtn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)

        local box = CreateStyledEditBox(topBar, 40, 22)
        box:SetPoint("LEFT", minusBtn, "RIGHT", 2, 0)
        box:SetJustifyH("CENTER")

        local plusBtn = CreateStyledButton(topBar, 20, 22, "+")
        plusBtn:SetPoint("LEFT", box, "RIGHT", 2, 0)

        local function ApplyAxis(val)
            local db = GetDB()
            db[dbField] = Clamp(Round(val, 0), -200, 200)
            MoveLevelBadge()
            RefreshUI()
        end

        minusBtn:SetScript("OnClick", function()
            local step = IsShiftKeyDown() and 5 or 1
            ApplyAxis((GetDB()[dbField] or 0) - step)
        end)
        plusBtn:SetScript("OnClick", function()
            local step = IsShiftKeyDown() and 5 or 1
            ApplyAxis((GetDB()[dbField] or 0) + step)
        end)
        box:SetScript("OnEnterPressed", function(self)
            local num = tonumber(Trim(self:GetText()))
            if num then ApplyAxis(num) else self:SetText(self.lastText or "0") end
            self:ClearFocus()
        end)
        box:SetScript("OnEditFocusLost", function(self)
            self:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)
            local num = tonumber(Trim(self:GetText()))
            if num and tostring(Round(num, 0)) ~= self.lastText then
                ApplyAxis(num)
            else
                self:SetText(self.lastText or "0")
            end
        end)

        return box, plusBtn
    end

    local xBox, xEnd = CreateLevelAxis(lvlLabel, 8, "X", "levelOffsetX")
    local yBox, yEnd = CreateLevelAxis(xEnd, 10, "Y", "levelOffsetY")

    local dragToggleBtn = CreateStyledButton(topBar, 84, 22, "Drag: OFF")
    dragToggleBtn:SetPoint("LEFT", yEnd, "RIGHT", 10, 0)
    dragToggleBtn:SetScript("OnClick", function()
        SetLevelDragUnlocked(not levelDragUnlocked)
        if levelDragUnlocked then
            print("|cff89cff0LuckyPortraits:|r drag the glowing circle on your portrait frame (right-click it to lock).")
        end
    end)
    AttachTooltip(dragToggleBtn, "|cff89cff0Drag Level Circle|r", "Shows a glowing drag handle directly over your level circle so you can drag it around your portrait frame.")

    local lvlResetBtn = CreateStyledButton(topBar, 40, 22, "0, 0")
    lvlResetBtn:SetPoint("LEFT", dragToggleBtn, "RIGHT", 6, 0)
    lvlResetBtn:SetScript("OnClick", function()
        local db = GetDB()
        db.levelOffsetX = 0
        db.levelOffsetY = 0
        MoveLevelBadge()
        RefreshUI()
    end)

    local charLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charLabel:SetPoint("BOTTOMRIGHT", -10, 13)
    charLabel:SetTextColor(0.62, 0.67, 0.78)
    charLabel:SetText("Character: " .. (UnitName("player") or "Player"))

    -- ========================================================================
    -- LEFT PANE: Portrait & State Selector List
    -- ========================================================================

    local leftPane = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    leftPane:SetPoint("TOPLEFT", 12, -118)
    leftPane:SetPoint("BOTTOMLEFT", 12, 44)
    leftPane:SetWidth(312)
    leftPane:SetBackdrop(BACKDROP_SOLID)
    leftPane:SetBackdropColor(0.09, 0.10, 0.15, 0.95)
    leftPane:SetBackdropBorderColor(0.24, 0.27, 0.38, 1)

    local listHeader = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listHeader:SetPoint("TOPLEFT", 10, -8)
    listHeader:SetText("|cff89cff01. Pick a Portrait or State to Edit:|r")

    local defaultRow = CreateFrame("Button", nil, leftPane, BACKDROP_TEMPLATE)
    defaultRow:SetPoint("TOPLEFT", 8, -26)
    defaultRow:SetPoint("TOPRIGHT", -8, -26)
    defaultRow:SetHeight(32)
    defaultRow:SetBackdrop(BACKDROP_SOLID)
    defaultRow:SetBackdropColor(0.13, 0.14, 0.22, 1)
    defaultRow:SetBackdropBorderColor(0.32, 0.36, 0.50, 1)

    local defThumb = defaultRow:CreateTexture(nil, "ARTWORK")
    defThumb:SetSize(22, 22)
    defThumb:SetPoint("LEFT", 6, 0)
    ApplyCircleMask(defThumb, defaultRow)

    local defBadge = defaultRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    defBadge:SetPoint("CENTER", defThumb, "CENTER")

    local defNameText = defaultRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    defNameText:SetPoint("LEFT", defThumb, "RIGHT", 7, 0)
    defNameText:SetText("Default Portrait")

    local defStatusTag = defaultRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    defStatusTag:SetPoint("RIGHT", -8, 0)
    defStatusTag:SetWidth(115)
    defStatusTag:SetJustifyH("RIGHT")
    defStatusTag:SetWordWrap(false)

    local categories = {
        { id = "all",       label = "All",    width = 40 },
        { id = "forms",     label = "Forms",  width = 58 },
        { id = "states",    label = "States", width = 58 },
        { id = "class",     label = "Class",  width = 54 },
        { id = "disguises", label = "Misc",  width = 62 },
    }
    local activeCategory = "all"
    local tabButtons = {}

    local prevTab = nil
    for _, cat in ipairs(categories) do
        local tb = CreateStyledButton(leftPane, cat.width, 22, cat.label)
        if not prevTab then
            tb:SetPoint("TOPLEFT", 8, -64)
        else
            tb:SetPoint("LEFT", prevTab, "RIGHT", 4, 0)
        end
        tb.catID = cat.id
        tb:SetScript("OnClick", function()
            activeCategory = cat.id
            RefreshUI(true)
        end)
        table.insert(tabButtons, tb)
        prevTab = tb
    end

    local listWrap = CreateFrame("Frame", nil, leftPane, BACKDROP_TEMPLATE)
    listWrap:SetPoint("TOPLEFT", 8, -92)
    listWrap:SetPoint("BOTTOMRIGHT", -8, 8)
    listWrap:SetBackdrop(BACKDROP_SOLID)
    listWrap:SetBackdropColor(0.06, 0.07, 0.11, 0.95)
    listWrap:SetBackdropBorderColor(0.20, 0.22, 0.32, 1)

    local scrollFrame = CreateFrame("ScrollFrame", "LuckyPortraitsScrollFrame", listWrap, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(262, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- ========================================================================
    -- RIGHT PANE: Dedicated Preview & Image Settings Panel
    -- ========================================================================

    local rightPane = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 10, 0)
    rightPane:SetPoint("BOTTOMRIGHT", -12, 44)
    rightPane:SetBackdrop(BACKDROP_SOLID)
    rightPane:SetBackdropColor(0.09, 0.10, 0.15, 0.95)
    rightPane:SetBackdropBorderColor(0.36, 0.26, 0.62, 0.95)

    local editTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    editTitle:SetPoint("TOPLEFT", 12, -10)
    editTitle:SetPoint("TOPRIGHT", -12, -10)
    editTitle:SetJustifyH("CENTER")

    local editSubTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    editSubTitle:SetPoint("TOP", editTitle, "BOTTOM", 0, -2)
    editSubTitle:SetWidth(330)
    editSubTitle:SetJustifyH("CENTER")

    local previewWrap = CreateFrame("Frame", nil, rightPane, BACKDROP_TEMPLATE)
    previewWrap:SetSize(112, 112)
    previewWrap:SetPoint("TOP", editSubTitle, "BOTTOM", 0, -8)
    previewWrap:SetBackdrop(BACKDROP_SOLID)
    previewWrap:SetBackdropColor(0.05, 0.06, 0.10, 1)
    previewWrap:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.95)

    local previewTex = previewWrap:CreateTexture(nil, "ARTWORK")
    previewTex:SetSize(100, 100)
    previewTex:SetPoint("CENTER")
    ApplyCircleMask(previewTex, previewWrap)

    local previewCaption = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    previewCaption:SetPoint("TOP", previewWrap, "BOTTOM", 0, -5)
    previewCaption:SetWidth(330)
    previewCaption:SetJustifyH("CENTER")

    local modeRow = CreateFrame("Frame", nil, rightPane)
    modeRow:SetSize(310, 24)
    modeRow:SetPoint("TOP", previewCaption, "BOTTOM", 0, -8)

    local modeCustomBtn  = CreateStyledButton(modeRow, 104, 24, "Custom Image")
    local modeBlizzBtn   = CreateStyledButton(modeRow, 94, 24, "Blizzard 3D")
    local modeDefaultBtn = CreateStyledButton(modeRow, 94, 24, "Use Default")

    AttachTooltip(modeCustomBtn, "|cff89cff0Custom Image|r", "Assign your own square image file from Interface\\LuckyPortraits\\.")
    AttachTooltip(modeBlizzBtn, "|cffc084fcBlizzard 3D Portrait|r", "Show WoW's real 3D character or shapeshift portrait during this state.")
    AttachTooltip(modeDefaultBtn, "|cff9b8ab8Use Default Portrait|r", "Skip this state and fall back to your Default Portrait (or a lower-priority state).")

    local settingsArea = CreateFrame("Frame", nil, rightPane)
    settingsArea:SetPoint("TOPLEFT", 14, -226)
    settingsArea:SetPoint("BOTTOMRIGHT", -14, 10)

    local modeNote = settingsArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeNote:SetPoint("TOPLEFT", 8, -28)
    modeNote:SetPoint("TOPRIGHT", -8, -28)
    modeNote:SetJustifyH("CENTER")
    modeNote:SetSpacing(4)

    local customControls = CreateFrame("Frame", nil, settingsArea)
    customControls:SetAllPoints()

    local fileLabel = customControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileLabel:SetPoint("TOPLEFT", 0, 0)
    fileLabel:SetText("|cff89cff0Image Filename|r |cff7f889e(e.g. portrait.png or cat.png):|r")

    local fileInput = CreateStyledEditBox(customControls, 248, 24)
    fileInput:SetPoint("TOPLEFT", 0, -16)

    local fileApplyBtn = CreateStyledButton(customControls, 72, 24, "Apply")
    fileApplyBtn:SetPoint("LEFT", fileInput, "RIGHT", 6, 0)
    fileApplyBtn:SetStyle(true)

    local framingBox = CreateFrame("Frame", nil, customControls)
    framingBox:SetPoint("TOPLEFT", 0, -48)
    framingBox:SetPoint("BOTTOMRIGHT", 0, 0)

    local framingPrompt = framingBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    framingPrompt:SetPoint("TOPLEFT", 8, -20)
    framingPrompt:SetPoint("TOPRIGHT", -8, -20)
    framingPrompt:SetJustifyH("CENTER")
    framingPrompt:SetTextColor(0.75, 0.80, 0.90)
    framingPrompt:SetText("Type a filename from Interface\\LuckyPortraits\\ above\nand click Apply to preview and adjust Zoom & Position.")

    local slidersWrap = CreateFrame("Frame", nil, framingBox)
    slidersWrap:SetAllPoints()

    local function CreateSliderRow(yOffset, labelText, minVal, maxVal, step, shiftStep, formatFn, getVal, setVal)
        local row = CreateFrame("Frame", nil, slidersWrap)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", 0, yOffset)
        row:SetHeight(24)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 0, 0)
        lbl:SetWidth(46)
        lbl:SetJustifyH("LEFT")
        lbl:SetText("|cff89cff0" .. labelText .. "|r")

        local minusBtn = CreateStyledButton(row, 20, 20, "-")
        minusBtn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)

        local slider = CreateStyledSlider(row, 182, minVal, maxVal, step)
        slider:SetPoint("LEFT", minusBtn, "RIGHT", 5, 0)

        local plusBtn = CreateStyledButton(row, 20, 20, "+")
        plusBtn:SetPoint("LEFT", slider, "RIGHT", 5, 0)

        local valText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("LEFT", plusBtn, "RIGHT", 4, 0)
        valText:SetPoint("RIGHT", 0, 0)
        valText:SetJustifyH("RIGHT")

        minusBtn:SetScript("OnClick", function()
            local delta = IsShiftKeyDown() and shiftStep or step
            setVal(getVal() - delta)
        end)
        plusBtn:SetScript("OnClick", function()
            local delta = IsShiftKeyDown() and shiftStep or step
            setVal(getVal() + delta)
        end)
        slider:SetScript("OnValueChanged", function(_, value)
            if isUpdatingSliders then return end
            setVal(value)
        end)

        return {
            slider = slider,
            valText = valText,
            formatFn = formatFn,
        }
    end

    local function UpdateSelectedZoom(val)
        local db = GetDB()
        local _, px, py = GetTransform(db, selectedKey)
        SetTransform(db, selectedKey, val, px, py)
        ApplyCustomPortrait()
        RefreshUI()
    end

    local function UpdateSelectedPan(axis, val)
        local db = GetDB()
        local z, px, py = GetTransform(db, selectedKey)
        if z <= 1.0 and Round(val, 0) ~= 0 then
            z = 1.15
        end
        if axis == "x" then px = val else py = val end
        SetTransform(db, selectedKey, z, px, py)
        ApplyCustomPortrait()
        RefreshUI()
    end

    local zoomRow = CreateSliderRow(
        -2, "Zoom", 1.0, 2.5, 0.05, 0.20,
        function(v) return string.format("%.2fx", v) end,
        function() local z = GetTransform(GetDB(), selectedKey); return z end,
        UpdateSelectedZoom
    )
    local panXRow = CreateSliderRow(
        -31, "Pan X", -50, 50, 1, 10,
        function(v) local n = Round(v, 0); return (n > 0 and ("+" .. n) or tostring(n)) end,
        function() local _, px = GetTransform(GetDB(), selectedKey); return px end,
        function(v) UpdateSelectedPan("x", v) end
    )
    local panYRow = CreateSliderRow(
        -60, "Pan Y", -50, 50, 1, 10,
        function(v) local n = Round(v, 0); return (n > 0 and ("+" .. n) or tostring(n)) end,
        function() local _, _, py = GetTransform(GetDB(), selectedKey); return py end,
        function(v) UpdateSelectedPan("y", v) end
    )

    local resetFrameBtn = CreateStyledButton(slidersWrap, 108, 22, "Reset Framing")
    resetFrameBtn:SetPoint("TOPLEFT", 0, -92)
    resetFrameBtn:SetScript("OnClick", function()
        local db = GetDB()
        SetTransform(db, selectedKey, 1.0, 0, 0)
        ApplyCustomPortrait()
        RefreshUI()
    end)

    local frameTip = slidersWrap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frameTip:SetPoint("LEFT", resetFrameBtn, "RIGHT", 8, 0)
    frameTip:SetTextColor(0.58, 0.63, 0.74)
    frameTip:SetText("Saved per image (Shift+Click +/-)")

    local function SelectEntry(key)
        if selectedKey ~= key then
            selectedKey = key
            pendingCustomKey = nil
            fileInput:ClearFocus()
        end
        RefreshUI()
    end

    defaultRow:SetScript("OnClick", function() SelectEntry("default") end)

    local function CommitFilename()
        local db = GetDB()
        local cleaned = SanitizeFilename(fileInput:GetText())
        if cleaned == "" then
            if selectedKey == "default" then
                db.defaultPortrait = "BLIZZARD"
            else
                db.portraits[selectedKey] = nil
            end
            pendingCustomKey = nil
        elseif cleaned:upper() == "BLIZZARD" then
            if selectedKey == "default" then
                db.defaultPortrait = "BLIZZARD"
            else
                db.portraits[selectedKey] = "BLIZZARD"
            end
            pendingCustomKey = nil
        else
            if selectedKey == "default" then
                db.defaultPortrait = cleaned
            else
                db.portraits[selectedKey] = cleaned
            end
            rememberedCustomFile[selectedKey] = cleaned
            pendingCustomKey = nil
        end
        SyncSwimmingTicker()
        ScheduleApply()
        RefreshUI()
    end

    fileInput:SetScript("OnEnterPressed", function(self)
        CommitFilename()
        self:ClearFocus()
    end)
    fileInput:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)
    end)
    fileApplyBtn:SetScript("OnClick", function()
        CommitFilename()
        fileInput:ClearFocus()
    end)

    modeCustomBtn:SetScript("OnClick", function()
        local db = GetDB()
        local curVal = GetEntryValue(db, selectedKey)
        if curVal ~= "" and curVal:upper() ~= "BLIZZARD" then
            pendingCustomKey = nil
            fileInput:SetFocus()
            RefreshUI()
            return
        end

        local remembered = rememberedCustomFile[selectedKey]
        if remembered and remembered ~= "" and remembered:upper() ~= "BLIZZARD" then
            if selectedKey == "default" then
                db.defaultPortrait = remembered
            else
                db.portraits[selectedKey] = remembered
            end
            pendingCustomKey = nil
            SyncSwimmingTicker()
            ScheduleApply()
            RefreshUI()
        else
            pendingCustomKey = selectedKey
            RefreshUI()
            fileInput:SetText("")
            fileInput:SetFocus()
        end
    end)

    modeBlizzBtn:SetScript("OnClick", function()
        local db = GetDB()
        local curVal = GetEntryValue(db, selectedKey)
        if curVal ~= "" and curVal:upper() ~= "BLIZZARD" then
            rememberedCustomFile[selectedKey] = curVal
        end
        pendingCustomKey = nil
        fileInput:ClearFocus()
        if selectedKey == "default" then
            db.defaultPortrait = "BLIZZARD"
        else
            db.portraits[selectedKey] = "BLIZZARD"
        end
        SyncSwimmingTicker()
        ScheduleApply()
        RefreshUI()
    end)

    modeDefaultBtn:SetScript("OnClick", function()
        if selectedKey == "default" then return end
        local db = GetDB()
        local curVal = GetEntryValue(db, selectedKey)
        if curVal ~= "" and curVal:upper() ~= "BLIZZARD" then
            rememberedCustomFile[selectedKey] = curVal
        end
        pendingCustomKey = nil
        fileInput:ClearFocus()
        db.portraits[selectedKey] = nil
        SyncSwimmingTicker()
        ScheduleApply()
        RefreshUI()
    end)

    -- Left list row pool
    local rowPool = {}

    local function GetOrCreateRow(index)
        if rowPool[index] then return rowPool[index] end

        local row = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
        row:SetSize(258, 28)
        row:SetBackdrop(BACKDROP_SOLID)
        row:SetBackdropColor(0.11, 0.12, 0.18, 0.9)
        row:SetBackdropBorderColor(0.19, 0.21, 0.30, 0.8)

        local thumb = row:CreateTexture(nil, "ARTWORK")
        thumb:SetSize(20, 20)
        thumb:SetPoint("LEFT", 5, 0)
        ApplyCircleMask(thumb, row)
        row.thumb = thumb

        local badge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badge:SetPoint("CENTER", thumb, "CENTER")
        row.badge = badge

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", thumb, "RIGHT", 6, 0)
        nameText:SetWidth(128)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        row.nameText = nameText

        local statusTag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        statusTag:SetPoint("RIGHT", -6, 0)
        statusTag:SetWidth(90)
        statusTag:SetJustifyH("RIGHT")
        statusTag:SetWordWrap(false)
        row.statusTag = statusTag

        row:SetScript("OnClick", function(self)
            if self.stateKey then
                SelectEntry(self.stateKey)
            end
        end)

        row:SetScript("OnEnter", function(self)
            if self.stateKey ~= selectedKey then
                self:SetBackdropColor(0.16, 0.18, 0.27, 1)
                self:SetBackdropBorderColor(0.45, 0.60, 0.80, 0.85)
            end
        end)
        row:SetScript("OnLeave", function(self)
            if self.stateKey ~= selectedKey then
                self:SetBackdropColor(0.11, 0.12, 0.18, 0.9)
                self:SetBackdropBorderColor(self.isLiveWin and 0.54 or 0.19, self.isLiveWin and 0.81 or 0.21, self.isLiveWin and 0.94 or 0.30, 0.9)
            end
        end)

        rowPool[index] = row
        return row
    end

    -- Footer bar: click-to-copy folder path + Reset Profile + Global Reset
    local copyShortcut = (IsMacClient and IsMacClient()) and "Cmd+C" or "Ctrl+C"

    local pathLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pathLabel:SetPoint("BOTTOMLEFT", 14, 17)
    pathLabel:SetText("|cff89cff0Folder:|r")

    local pathCopyBox = CreateStyledEditBox(f, 192, 22)
    pathCopyBox:SetPoint("LEFT", pathLabel, "RIGHT", 6, 0)
    pathCopyBox:SetText(BASE_PATH)

    local copyPathBtn = CreateStyledButton(f, 48, 22, "Copy")
    copyPathBtn:SetPoint("LEFT", pathCopyBox, "RIGHT", 5, 0)

    local copyHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copyHint:SetPoint("LEFT", copyPathBtn, "RIGHT", 8, 0)
    copyHint:SetTextColor(0.58, 0.63, 0.74)
    copyHint:SetText("Safe from updates")

    local function SelectFolderPath()
        pathCopyBox:SetText(BASE_PATH)
        if not pathCopyBox:HasFocus() then
            pathCopyBox:SetFocus()
        end
        pathCopyBox:HighlightText()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if pathCopyBox:HasFocus() then
                    pathCopyBox:HighlightText()
                end
            end)
        end
        copyHint:SetText("|cff5ce09ePress " .. copyShortcut .. "!|r")
    end

    pathCopyBox:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0.54, 0.81, 0.94, 1)
        SelectFolderPath()
    end)
    pathCopyBox:SetScript("OnMouseUp", function()
        SelectFolderPath()
    end)
    pathCopyBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(BASE_PATH)
            self:HighlightText()
        end
    end)
    pathCopyBox:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.28, 0.32, 0.44, 1)
        self:HighlightText(0, 0)
        self:SetText(BASE_PATH)
        copyHint:SetText("Safe from updates")
    end)
    pathCopyBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    copyPathBtn:SetScript("OnClick", SelectFolderPath)
    AttachTooltip(pathCopyBox, "|cff89cff0Update-Safe Images Folder|r", "Click to select, then press " .. copyShortcut .. " to copy this folder path.")
    AttachTooltip(copyPathBtn, "|cff89cff0Copy Folder Path|r", "Highlights Interface\\LuckyPortraits\\ so you can press " .. copyShortcut .. " to copy it.")

    local globalConfirmPending = false
    local globalResetBtn = CreateStyledButton(f, 96, 24, "Global Reset")
    globalResetBtn:SetPoint("BOTTOMRIGHT", -12, 11)
    AttachTooltip(globalResetBtn, "|cffff6b6bGlobal Reset|r", "Wipes ALL saved profiles and character assignments across your account, reverting everything to factory defaults.")
    globalResetBtn:SetScript("OnClick", function(self)
        if not globalConfirmPending then
            globalConfirmPending = true
            self.label:SetText("Wipe ALL?")
            self:SetStyle(true, 0.76, 0.16, 0.20)
            if C_Timer and C_Timer.After then
                C_Timer.After(3.5, function()
                    if globalConfirmPending then
                        globalConfirmPending = false
                        self.label:SetText("Global Reset")
                        self:SetStyle(false)
                    end
                end)
            end
        else
            globalConfirmPending = false
            self.label:SetText("Global Reset")
            self:SetStyle(false)
            GlobalResetAll()
        end
    end)

    local resetConfirmPending = false
    local resetBtn = CreateStyledButton(f, 96, 24, "Reset Profile")
    resetBtn:SetPoint("RIGHT", globalResetBtn, "LEFT", -6, 0)
    AttachTooltip(resetBtn, "|cff89cff0Reset Active Profile|r", "Reverts only the currently active profile back to default settings.")
    resetBtn:SetScript("OnClick", function(self)
        if not resetConfirmPending then
            resetConfirmPending = true
            self.label:SetText("Confirm?")
            self:SetStyle(true, 0.65, 0.42, 0.12)
            if C_Timer and C_Timer.After then
                C_Timer.After(3, function()
                    if resetConfirmPending then
                        resetConfirmPending = false
                        self.label:SetText("Reset Profile")
                        self:SetStyle(false)
                    end
                end)
            end
        else
            resetConfirmPending = false
            self.label:SetText("Reset Profile")
            self:SetStyle(false)
            ResetActiveProfile()
        end
    end)

    -- ========================================================================
    -- Refresh UI
    -- ========================================================================

    RefreshUI = function(resetScroll)
        if not configFrame then return end
        local db = GetDB()
        local winKey = ResolvePortrait()

        -- Top Bar
        activeProfileLabel:SetText("|cffc084fc" .. GetActiveProfileName() .. "|r")

        toggleBtn.label:SetText(db.enabled and "Custom Portrait: ON" or "Custom Portrait: OFF")
        toggleBtn:SetStyle(db.enabled, 0.16, 0.45, 0.30)

        minimapBtnToggle.label:SetText(db.minimapShown and "Minimap: ON" or "Minimap: OFF")
        minimapBtnToggle:SetStyle(db.minimapShown)

        dragToggleBtn.label:SetText(levelDragUnlocked and "Drag: ON" or "Drag: OFF")
        dragToggleBtn:SetStyle(levelDragUnlocked, 0.18, 0.48, 0.62)

        if not xBox:HasFocus() then
            local xStr = tostring(db.levelOffsetX or 0)
            xBox:SetText(xStr)
            xBox.lastText = xStr
        end
        if not yBox:HasFocus() then
            local yStr = tostring(db.levelOffsetY or 0)
            yBox:SetText(yStr)
            yBox.lastText = yStr
        end

        -- Pinned Default Portrait row
        local defVal = SanitizeFilename(db.defaultPortrait or "")
        local defIsSelected = (selectedKey == "default")
        if defIsSelected then
            defaultRow:SetBackdropColor(0.22, 0.16, 0.38, 1)
            defaultRow:SetBackdropBorderColor(0.54, 0.81, 0.94, 1)
            defNameText:SetText("|cff89cff0Default Portrait|r")
        elseif winKey == "default" then
            defaultRow:SetBackdropColor(0.13, 0.15, 0.23, 1)
            defaultRow:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.85)
            defNameText:SetText("|cffffffffDefault Portrait|r")
        else
            defaultRow:SetBackdropColor(0.11, 0.12, 0.19, 1)
            defaultRow:SetBackdropBorderColor(0.26, 0.30, 0.42, 1)
            defNameText:SetText("Default Portrait")
        end

        if defVal == "" or defVal:upper() == "BLIZZARD" then
            defThumb:Hide()
            defBadge:SetText("|cffc084fc3D|r")
            defBadge:Show()
            defStatusTag:SetText("|cffc084fcBlizzard 3D|r")
        else
            defBadge:Hide()
            local dz, dpx, dpy = GetTransform(db, "default")
            defThumb:SetTexture(BASE_PATH .. defVal)
            ApplyPortraitTexCoord(defThumb, dz, dpx, dpy)
            defThumb:Show()
            local star = HasCustomTransform(db, "default") and " *" or ""
            defStatusTag:SetText("|cff89cff0" .. defVal .. star .. "|r")
        end

        -- Category tabs
        for _, tb in ipairs(tabButtons) do
            tb:SetStyle(tb.catID == activeCategory)
        end

        -- State list rows
        local visibleIndex = 0
        for _, def in ipairs(STATE_DEFS) do
            if activeCategory == "all" or def.cat == activeCategory then
                visibleIndex = visibleIndex + 1
                local row = GetOrCreateRow(visibleIndex)
                row.stateKey = def.key
                row.isLiveWin = (winKey == def.key)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 1, -((visibleIndex - 1) * 31) - 1)
                row:Show()

                local val = SanitizeFilename(db.portraits[def.key] or "")
                local isSelected = (selectedKey == def.key)

                if isSelected then
                    row:SetBackdropColor(0.22, 0.16, 0.38, 1)
                    row:SetBackdropBorderColor(0.54, 0.81, 0.94, 1)
                    row.nameText:SetText("|cff89cff0" .. def.label .. "|r")
                elseif row.isLiveWin then
                    row:SetBackdropColor(0.13, 0.15, 0.23, 1)
                    row:SetBackdropBorderColor(0.54, 0.81, 0.94, 0.85)
                    row.nameText:SetText("|cffffffff" .. def.label .. "|r")
                else
                    row:SetBackdropColor(0.11, 0.12, 0.18, 0.9)
                    row:SetBackdropBorderColor(0.19, 0.21, 0.30, 0.8)
                    row.nameText:SetText(def.label)
                end

                if val:upper() == "BLIZZARD" then
                    row.thumb:Hide()
                    row.badge:SetText("|cffc084fc3D|r")
                    row.badge:Show()
                    row.statusTag:SetText("|cffc084fc3D|r")
                elseif val ~= "" then
                    row.badge:Hide()
                    local rz, rpx, rpy = GetTransform(db, def.key)
                    row.thumb:SetTexture(BASE_PATH .. val)
                    ApplyPortraitTexCoord(row.thumb, rz, rpx, rpy)
                    row.thumb:Show()
                    local star = HasCustomTransform(db, def.key) and "*" or ""
                    row.statusTag:SetText("|cff89cff0" .. val .. star .. "|r")
                else
                    row.thumb:Hide()
                    row.badge:SetText("|cff4e556b--|r")
                    row.badge:Show()
                    row.statusTag:SetText("|cff5e657cDefault|r")
                end
            end
        end

        for i = visibleIndex + 1, #rowPool do
            rowPool[i]:Hide()
        end

        scrollChild:SetHeight(math.max(1, visibleIndex * 31 + 4))
        if resetScroll and scrollFrame.SetVerticalScroll then
            scrollFrame:SetVerticalScroll(0)
        end

        -- ====================================================================
        -- RIGHT PANE: Preview & Settings for `selectedKey`
        -- ====================================================================

        local entryVal = GetEntryValue(db, selectedKey)
        local isDefaultSlot = (selectedKey == "default")
        local mode = "default"
        if pendingCustomKey == selectedKey then
            mode = "custom"
        elseif entryVal:upper() == "BLIZZARD" then
            mode = "blizzard"
        elseif entryVal ~= "" then
            mode = "custom"
        elseif isDefaultSlot then
            mode = "blizzard"
        else
            mode = "default"
        end

        editTitle:SetText("|cff89cff0" .. GetStateLabel(selectedKey) .. "|r")
        if not db.enabled then
            editSubTitle:SetText("|cffff6b6bAddon is currently toggled OFF (showing Blizzard portrait)|r")
        elseif winKey == selectedKey then
            editSubTitle:SetText("|cff5ce09eCurrently live on your character portrait|r")
        else
            editSubTitle:SetText("|cff8d96abPreviewing settings (changes save automatically)|r")
        end

        modeCustomBtn:ClearAllPoints()
        modeBlizzBtn:ClearAllPoints()
        modeDefaultBtn:ClearAllPoints()
        if isDefaultSlot then
            modeCustomBtn:SetSize(134, 24)
            modeBlizzBtn:SetSize(134, 24)
            modeCustomBtn:SetPoint("LEFT", modeRow, "LEFT", 18, 0)
            modeBlizzBtn:SetPoint("LEFT", modeCustomBtn, "RIGHT", 8, 0)
            modeDefaultBtn:Hide()
        else
            modeCustomBtn:SetSize(102, 24)
            modeBlizzBtn:SetSize(96, 24)
            modeDefaultBtn:SetSize(96, 24)
            modeCustomBtn:SetPoint("LEFT", modeRow, "LEFT", 2, 0)
            modeBlizzBtn:SetPoint("LEFT", modeCustomBtn, "RIGHT", 6, 0)
            modeDefaultBtn:SetPoint("LEFT", modeBlizzBtn, "RIGHT", 6, 0)
            modeDefaultBtn:Show()
        end

        modeCustomBtn:SetStyle(mode == "custom")
        modeBlizzBtn:SetStyle(mode == "blizzard")
        modeDefaultBtn:SetStyle(mode == "default")

        local hasSavedCustomFile = (mode == "custom" and entryVal ~= "" and entryVal:upper() ~= "BLIZZARD")

        if mode == "custom" then
            modeNote:Hide()
            customControls:Show()

            if not fileInput:HasFocus() then
                fileInput:SetText(hasSavedCustomFile and entryVal or "")
            end

            if hasSavedCustomFile then
                local z, px, py = GetTransform(db, selectedKey)
                previewTex:SetTexture(BASE_PATH .. entryVal)
                ApplyPortraitTexCoord(previewTex, z, px, py)
                previewCaption:SetText("|cff89cff0" .. entryVal .. "|r")

                framingPrompt:Hide()
                slidersWrap:Show()

                isUpdatingSliders = true
                zoomRow.slider:SetValue(z)
                zoomRow.valText:SetText(zoomRow.formatFn(z))
                panXRow.slider:SetValue(px)
                panXRow.valText:SetText(panXRow.formatFn(px))
                panYRow.slider:SetValue(py)
                panYRow.valText:SetText(panYRow.formatFn(py))
                isUpdatingSliders = false
            else
                if defVal ~= "" and defVal:upper() ~= "BLIZZARD" then
                    local dz, dpx, dpy = GetTransform(db, "default")
                    previewTex:SetTexture(BASE_PATH .. defVal)
                    ApplyPortraitTexCoord(previewTex, dz, dpx, dpy)
                else
                    ApplyBlizzardPortrait(previewTex)
                end
                previewCaption:SetText("|cffffd166Enter a filename below and click Apply|r")
                slidersWrap:Hide()
                framingPrompt:Show()
            end
        elseif mode == "blizzard" then
            customControls:Hide()
            modeNote:Show()
            ApplyBlizzardPortrait(previewTex)
            previewCaption:SetText("|cffc084fcBlizzard 3D Portrait|r")
            modeNote:SetText(
                "Using WoW's built-in 3D portrait for |cffffffff" .. GetStateLabel(selectedKey) .. "|r.\n\n" ..
                "|cff8d96abClick |r|cffffffffCustom Image|r|cff8d96ab above to assign your own picture\nfrom Interface\\LuckyPortraits\\ and unlock Zoom & Position.|r"
            )
        else
            customControls:Hide()
            modeNote:Show()
            if defVal ~= "" and defVal:upper() ~= "BLIZZARD" then
                local dz, dpx, dpy = GetTransform(db, "default")
                previewTex:SetTexture(BASE_PATH .. defVal)
                ApplyPortraitTexCoord(previewTex, dz, dpx, dpy)
                previewCaption:SetText("|cff8d96abUsing Default:|r |cff89cff0" .. defVal .. "|r")
            else
                ApplyBlizzardPortrait(previewTex)
                previewCaption:SetText("|cff8d96abUsing Default:|r |cffc084fcBlizzard 3D|r")
            end
            modeNote:SetText(
                "|cffffffff" .. GetStateLabel(selectedKey) .. "|r is set to follow your |cff89cff0Default Portrait|r.\n\n" ..
                "|cff8d96abClick |r|cffffffffCustom Image|r|cff8d96ab above to give this state its own picture,\nor |r|cffc084fcBlizzard 3D|r|cff8d96ab to show your character's 3D model.|r"
            )
        end
    end

    f:SetScript("OnShow", function()
        local winKey = ResolvePortrait()
        if winKey and winKey ~= "disabled" then
            selectedKey = winKey
        else
            selectedKey = "default"
        end
        pendingCustomKey = nil
        RefreshUI(false)
    end)

    configFrame = f
    return f
end

ToggleConfigUI = function()
    local f = CreateConfigWindow()
    if f:IsShown() then f:Hide() else f:Show() end
end

-- Launcher inside Esc - Options - AddOns (Modern Settings API + Legacy Classic fallback)
local function RegisterSettingsLauncher()
    local panel = CreateFrame("Frame")
    panel.name = "Lucky Portraits"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff89cff0Lucky Portraits|r")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText("Configure custom portraits, per-state zoom/pan, character profiles, and level badge placement.")

    local openBtn = CreateStyledButton(panel, 210, 30, "Open Lucky Portraits Setup")
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    openBtn:SetStyle(true)
    openBtn:SetScript("OnClick", function()
        if HideUIPanel and SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if HideUIPanel and InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
        ToggleConfigUI()
    end)

    local profOpenBtn = CreateStyledButton(panel, 110, 30, "Profiles")
    profOpenBtn:SetPoint("LEFT", openBtn, "RIGHT", 10, 0)
    profOpenBtn:SetScript("OnClick", function()
        if HideUIPanel and SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if HideUIPanel and InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
        ToggleProfileUI()
    end)

    local helpOpenBtn = CreateStyledButton(panel, 120, 30, "Setup Guide")
    helpOpenBtn:SetPoint("LEFT", profOpenBtn, "RIGHT", 10, 0)
    helpOpenBtn:SetScript("OnClick", function()
        if HideUIPanel and SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if HideUIPanel and InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
        ToggleHelpUI()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        pcall(function()
            local category = Settings.RegisterCanvasLayoutCategory(panel, "Lucky Portraits")
            Settings.RegisterAddOnCategory(category)
        end)
    elseif InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
    end
end

-- ============================================================================
-- Hooks & Events
-- ============================================================================

if UnitFramePortrait_Update then
    hooksecurefunc("UnitFramePortrait_Update", function(frame)
        if frame == PlayerFrame then
            ScheduleApply()
        end
    end)
end

if SetPortraitTexture then
    hooksecurefunc("SetPortraitTexture", function(texture)
        if isApplyingBlizzard then return end
        if texture == GetPlayerPortrait() then
            ScheduleApply()
        end
    end)
end

if PlayerFrame_ToPlayerArt then
    hooksecurefunc("PlayerFrame_ToPlayerArt", function()
        ScheduleApply()
    end)
end

if PlayerFrame_UpdateLevel then
    hooksecurefunc("PlayerFrame_UpdateLevel", function()
        MoveLevelBadge()
    end)
end

if PlayerFrame_UpdateLevelTextAnchor then
    hooksecurefunc("PlayerFrame_UpdateLevelTextAnchor", function()
        MoveLevelBadge()
    end)
end

local loader = CreateFrame("Frame")
local events = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "PORTRAITS_UPDATED",
    "UNIT_PORTRAIT_UPDATE",
    "UNIT_MODEL_CHANGED",
    "UPDATE_SHAPESHIFT_FORM",
    "UPDATE_SHAPESHIFT_FORMS",
    "UNIT_AURA",
    "UPDATE_STEALTH",
    "PLAYER_DEAD",
    "PLAYER_ALIVE",
    "PLAYER_UNGHOST",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_UPDATE_RESTING",
    "PLAYER_FLAGS_CHANGED",
    "PLAYER_MOUNT_DISPLAY_CHANGED",
    "PLAYER_CONTROL_LOST",
    "PLAYER_CONTROL_GAINED",
    "PLAYER_LEVEL_UP",
}
for _, ev in ipairs(events) do
    SafeRegisterEvent(loader, ev)
end

loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if IsSafeValue(arg1) and arg1 == ADDON_NAME then
            InitAccountDB()
            SyncSwimmingTicker()
            UpdateMinimapButton()
            RegisterSettingsLauncher()
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" and levelDragUnlocked then
        SetLevelDragUnlocked(false)
    end

    if event == "PLAYER_REGEN_ENABLED" and pendingLevelMove then
        MoveLevelBadge()
    end

    if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" or event == "UNIT_AURA" or event == "PLAYER_FLAGS_CHANGED" then
        if not IsSafeValue(arg1) or arg1 ~= "player" then
            return
        end
    end

    if event == "UNIT_AURA" or event == "PLAYER_FLAGS_CHANGED" then
        local newKey, newTarget = ResolvePortrait()
        if newKey == lastResolvedKey and newTarget == lastResolvedTarget then
            return
        end
    end

    ScheduleApply()
end)

-- ============================================================================
-- Slash Commands
-- ============================================================================

local function PrintHelp()
    print("|cff7c3aed========================================|r")
    print("|cff89cff0Lucky Portraits|r - Quick-Start Guide (v2.6)")
    print("|cff7c3aed========================================|r")
    print("|cff89cff01. Add Your Images (Update-Safe Folder):|r")
    print("  Create folder: |cffffffffInterface\\LuckyPortraits\\|r (right next to |cffffffffInterface\\AddOns\\|r)")
    print("  Use square power-of-two sizes (|cffffffff256x256|r or |cffffffff512x512|r) in .png, .tga, .jpg, or .blp.")
    print("  |cffffd166Important:|r Fully close and relaunch WoW after adding brand-new image files.")
    print("|cff89cff02. Set Up Portraits & Framing:|r")
    print("  Type |cffffffff/lp|r, click Default Portrait or any state on the left, then pick |cffffffffCustom Image|r, |cffc084fcBlizzard 3D|r, or |cffffffffUse Default|r on the right.")
    print("  Type your filename (e.g. |cffffffffportrait.png|r or |cffffffffcat.png|r), click |cffffffffApply|r, and use the Zoom & Pan sliders.")
    print("|cff89cff03. Slash Commands:|r")
    print("  |cffffffff/lp|r - Open Setup window   |   |cffffffff/lp guide|r - Open full in-game Help window")
    print("  |cffffffff/lp toggle|r (or |cffffffffon|r / |cffffffffoff|r) - Enable or disable custom portrait")
    print("  |cffffffff/lp minimap|r - Show or hide minimap icon   |   |cffffffff/lp drag|r - Drag level circle")
    print("  |cffffffff/lp profiles|r / |cffffffff/lp profile Name|r - Manage or switch profiles")
    print("  |cffffffff/lp export|r / |cffffffff/lp import|r - Open Import / Export window")
    print("  |cffffffff/lp X Y|r - Set level circle offset   |   |cffffffff/lp status|r - Active states")
    print("  |cffffffff/lp reset|r - Recenter window   |   |cffffffff/lp globalreset confirm|r - Wipe all profiles")
    print("|cff9b8ab8Tip: Click '? Help' in /lp (or type /lp guide) for the full scrollable guide & troubleshooting.|r")
end

SLASH_LUCKYPORTRAITSHELP1 = "/lphelp"
SlashCmdList["LUCKYPORTRAITSHELP"] = PrintHelp

SLASH_LUCKYPORTRAITS1 = "/lp"
SLASH_LUCKYPORTRAITS2 = "/luckyportraits"
SlashCmdList["LUCKYPORTRAITS"] = function(msg)
    local cmd = Trim(msg or "")
    local lower = cmd:lower()

    if cmd == "" or lower == "ui" or lower == "config" or lower == "options" then
        ToggleConfigUI()
        return
    end

    if lower == "guide" then
        ToggleHelpUI()
        return
    end

    if lower == "help" or lower == "?" then
        PrintHelp()
        return
    end

    if lower == "profiles" then
        ToggleProfileUI()
        return
    end

    if lower == "export" then
        OpenExportUI(true)
        return
    end

    if lower == "import" then
        OpenExportUI(false)
        return
    end

    local switchTarget = cmd:match("^[Pp][Rr][Oo][Ff][Ii][Ll][Ee]%s+(.+)$")
    if switchTarget then
        local found = FindProfileNameCaseInsensitive(switchTarget)
        if found then
            SwitchProfile(found)
            print("|cff89cff0LuckyPortraits:|r switched to profile '|cffc084fc" .. found .. "|r'.")
        else
            print("|cff89cff0LuckyPortraits:|r profile '" .. Trim(switchTarget) .. "' not found. Type |cffffffff/lp profiles|r to view saved profiles.")
        end
        return
    end

    if lower == "globalreset confirm" then
        GlobalResetAll()
        return
    elseif lower == "globalreset" then
        print("|cff89cff0LuckyPortraits:|r this wipes ALL profiles across your account. Type |cffffffff/lp globalreset confirm|r to proceed.")
        return
    end

    local db = GetDB()
    local x, y = cmd:match("^(-?%d+)%s+(-?%d+)$")
    if x and y then
        db.levelOffsetX = Clamp(tonumber(x), -200, 200)
        db.levelOffsetY = Clamp(tonumber(y), -200, 200)
        MoveLevelBadge()
        RefreshUI()
        print(string.format("|cff89cff0LuckyPortraits:|r saved level badge position X=%d, Y=%d", db.levelOffsetX, db.levelOffsetY))
    elseif lower == "toggle" then
        db.enabled = not db.enabled
        ScheduleApply()
        RefreshUI()
        print("|cff89cff0LuckyPortraits:|r custom portrait " .. (db.enabled and "|cff00ff00ON|r" or "|cffff5555OFF (Blizzard default)|r"))
    elseif lower == "on" or lower == "enable" then
        db.enabled = true
        ScheduleApply()
        RefreshUI()
        print("|cff89cff0LuckyPortraits:|r custom portrait |cff00ff00ON|r")
    elseif lower == "off" or lower == "disable" then
        db.enabled = false
        ScheduleApply()
        RefreshUI()
        print("|cff89cff0LuckyPortraits:|r custom portrait |cffff5555OFF (Blizzard default)|r")
    elseif lower == "minimap" or lower == "map" then
        db.minimapShown = not db.minimapShown
        UpdateMinimapButton()
        RefreshUI()
        print("|cff89cff0LuckyPortraits:|r minimap icon " .. (db.minimapShown and "|cff00ff00SHOWN|r" or "|cffff5555HIDDEN|r"))
    elseif lower == "drag" or lower == "unlock" or lower == "lock" then
        local targetState = (lower == "unlock") and true or (lower == "lock" and false or not levelDragUnlocked)
        SetLevelDragUnlocked(targetState)
        print("|cff89cff0LuckyPortraits:|r level circle drag " .. (levelDragUnlocked and "|cff00ff00UNLOCKED (drag glowing circle, right-click to lock)|r" or "|cffff5555LOCKED|r"))
    elseif lower == "status" or lower == "form" then
        local winKey, winTarget, states = ResolvePortrait()
        local activeList = {}
        for _, def in ipairs(STATE_DEFS) do
            if states[def.key] then
                table.insert(activeList, def.key)
            end
        end
        local activeText = (#activeList > 0) and table.concat(activeList, ", ") or "none"
        print(string.format("|cff89cff0LuckyPortraits:|r profile=%s | enabled=%s | active=[%s] | winner=%s | portrait=%s",
            GetActiveProfileName(), tostring(db.enabled), activeText, tostring(winKey), tostring(winTarget)))
    elseif lower == "reset" then
        local f = CreateConfigWindow()
        f:ClearAllPoints()
        f:SetPoint("CENTER")
        f:Show()
        print("|cff89cff0LuckyPortraits:|r window centered.")
    else
        print("|cff89cff0LuckyPortraits:|r unknown command. Type |cffffffff/lphelp|r or |cffffffff/lp guide|r for help.")
    end
end