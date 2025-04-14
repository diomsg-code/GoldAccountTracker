local addonName, goldAccountTracker = ...

local L = goldAccountTracker.localization

----------------------
--- Local funtions ---
----------------------

local function GetToday()
    return date("%Y-%m-%d")
end

local function GetGold()
    return GetMoney()
end

local function GetCharacterInfo()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm, name
end

local function SaveGold()
    local realm, name = GetCharacterInfo()
    local today = GetToday()
    local gold = GetGold()

    goldAccountTracker.goldBalance = goldAccountTracker.goldBalance or {}
    goldAccountTracker.goldBalance[realm] = goldAccountTracker.goldBalance[realm] or {}
    goldAccountTracker.goldBalance[realm][name] = goldAccountTracker.goldBalance[realm][name] or {}
    goldAccountTracker.goldBalance[realm][name][today] = gold

    goldAccountTracker:PrintDebug("Gold balance saved.")
end

function TrackCurrencies()
    local realm, name = GetCharacterInfo()
    goldAccountTracker.currencyBalance = goldAccountTracker.currencyBalance or {}
    goldAccountTracker.currencyBalance[realm] = goldAccountTracker.currencyBalance[realm] or {}
    goldAccountTracker.currencyBalance[realm][name] = goldAccountTracker.currencyBalance[realm][name] or {}

    local dateKey = date("%Y-%m-%d")
    goldAccountTracker.currencyBalance[realm][name][dateKey] = goldAccountTracker.currencyBalance[realm][name][dateKey] or {}


    for _, currencies in pairs(goldAccountTracker.currencyGroups) do
        for _, currencyID in ipairs(currencies) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info then
                goldAccountTracker.currencyBalance[realm][name][dateKey][currencyID] = info.quantity
            end
        end
    end
end

local function SlashCommand(msg, editbox)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("Gold Account Tracker")
    elseif msg:trim() == "overview" then
        goldAccountTracker:ShowGoldOverview()
	else
        goldAccountTracker:PrintDebug("These arguments are not accepted.")
	end
end

--------------
--- Frames ---
--------------

local goldAccountTrackerFrame = CreateFrame("Frame", "GoldAccountTracker")

---------------------
--- Main funtions ---
---------------------

function goldAccountTrackerFrame:OnEvent(event, ...)
	self[event](self, event, ...)
end

function goldAccountTrackerFrame:ADDON_LOADED(_, addOnName)
    if addOnName == addonName then
        goldAccountTracker:LoadOptions()
        goldAccountTracker:PrintDebug("Addon fully loaded.")
    end
end

function goldAccountTrackerFrame:PLAYER_ENTERING_WORLD(...)
    goldAccountTracker:PrintDebug("Event 'PLAYER_ENTERING_WORLD' fired.")
    SaveGold()
    TrackCurrencies()

    if goldAccountTracker.options["QKywRlN7-open-on-login"] then
        goldAccountTracker:ShowGoldOverview()
    end
end

function goldAccountTrackerFrame:PLAYER_MONEY(...)
    goldAccountTracker:PrintDebug("Event 'PLAYER_MONEY' fired.")
    SaveGold()
end

goldAccountTrackerFrame:RegisterEvent("ADDON_LOADED")
goldAccountTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
goldAccountTrackerFrame:RegisterEvent("PLAYER_MONEY")
goldAccountTrackerFrame:SetScript("OnEvent", goldAccountTrackerFrame.OnEvent)

SLASH_GoldAccountTracker1, SLASH_GoldAccountTracker2 = '/gat', '/GoldAccountTracker'

SlashCmdList["GoldAccountTracker"] = SlashCommand