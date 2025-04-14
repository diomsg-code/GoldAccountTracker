local addonName, goldCurrencyTracker = ...

local L = goldCurrencyTracker.localization

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

local function TrackGold()
    local realm, name = GetCharacterInfo()
    local today = GetToday()
    local gold = GetGold()

    goldCurrencyTracker.goldBalance = goldCurrencyTracker.goldBalance or {}
    goldCurrencyTracker.goldBalance[realm] = goldCurrencyTracker.goldBalance[realm] or {}
    goldCurrencyTracker.goldBalance[realm][name] = goldCurrencyTracker.goldBalance[realm][name] or {}
    goldCurrencyTracker.goldBalance[realm][name][today] = gold

    goldCurrencyTracker:PrintDebug("Gold balance saved.")
end

local function TrackCurrencies()
    local realm, name = GetCharacterInfo()
    local today = GetToday()

    goldCurrencyTracker.currencyBalance = goldCurrencyTracker.currencyBalance or {}
    goldCurrencyTracker.currencyBalance[realm] = goldCurrencyTracker.currencyBalance[realm] or {}
    goldCurrencyTracker.currencyBalance[realm][name] = goldCurrencyTracker.currencyBalance[realm][name] or {}
    goldCurrencyTracker.currencyBalance[realm][name][today] = goldCurrencyTracker.currencyBalance[realm][name][today] or {}

    for _, currencies in pairs(goldCurrencyTracker.currencyCategories) do
        for _, currencyID in ipairs(currencies) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info then
                goldCurrencyTracker.currencyBalance[realm][name][today][currencyID] = info.quantity
            end
        end
    end

    goldCurrencyTracker:PrintDebug("Currency balance saved.")
end

local function SlashCommand(msg, editbox)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("Gold & Currency Tracker")
    elseif msg:trim() == "overview" then
        goldCurrencyTracker:ShowGoldCurrencyOverview()
	else
        goldCurrencyTracker:PrintDebug("These arguments are not accepted.")
	end
end

--------------
--- Frames ---
--------------

local goldCurrencyTrackerFrame = CreateFrame("Frame", "GoldCurrencyTracker")

---------------------
--- Main funtions ---
---------------------

function goldCurrencyTrackerFrame:OnEvent(event, ...)
	self[event](self, event, ...)
end

function goldCurrencyTrackerFrame:ADDON_LOADED(_, addOnName)
    if addOnName == addonName then
        goldCurrencyTracker:LoadOptions()
        goldCurrencyTracker:PrintDebug("Addon fully loaded.")
    end
end

function goldCurrencyTrackerFrame:PLAYER_ENTERING_WORLD(...)
    goldCurrencyTracker:PrintDebug("Event 'PLAYER_ENTERING_WORLD' fired.")

    TrackGold()
    TrackCurrencies()

    if goldCurrencyTracker.options["QKywRlN7-open-on-login"] then
        goldCurrencyTracker:ShowGoldCurrencyOverview()
    end
end

function goldCurrencyTrackerFrame:PLAYER_MONEY(...)
    goldCurrencyTracker:PrintDebug("Event 'PLAYER_MONEY' fired.")

    TrackGold()
end

function goldCurrencyTrackerFrame:CURRENCY_DISPLAY_UPDATE(...)
    goldCurrencyTracker:PrintDebug("Event 'CURRENCY_DISPLAY_UPDATE' fired.")

    TrackCurrencies()
end

goldCurrencyTrackerFrame:RegisterEvent("ADDON_LOADED")
goldCurrencyTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
goldCurrencyTrackerFrame:RegisterEvent("PLAYER_MONEY")
goldCurrencyTrackerFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
goldCurrencyTrackerFrame:SetScript("OnEvent", goldCurrencyTrackerFrame.OnEvent)

SLASH_GoldCurrencyTracker1, SLASH_GoldCurrencyTracker2 = '/gct', '/GoldCurrencyTracker'

SlashCmdList["GoldCurrencyTracker"] = SlashCommand