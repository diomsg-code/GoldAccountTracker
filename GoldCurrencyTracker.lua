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
    local char = UnitName("player")
    local realm = GetRealmName()

    return realm, char
end

local function InitDatabase()
    local realm, char = GetCharacterInfo()

    if (not GoldCurrencyTracker_Options) then
        GoldCurrencyTracker_Options = {}
    end

    goldCurrencyTracker.options = GoldCurrencyTracker_Options

    if (not GoldCurrencyTracker_DataGoldBalance) then
        GoldCurrencyTracker_DataGoldBalance = {}
    end

    goldCurrencyTracker.goldBalance = GoldCurrencyTracker_DataGoldBalance

    if (not GoldCurrencyTracker_DataCurrencyBalance) then
        GoldCurrencyTracker_DataCurrencyBalance = {}
    end

    goldCurrencyTracker.currencyBalance = GoldCurrencyTracker_DataCurrencyBalance

    if (not GoldCurrencyTracker_DataBalance) then
        GoldCurrencyTracker_DataBalance = {}
    end

    goldCurrencyTracker.balance = GoldCurrencyTracker_DataBalance

    goldCurrencyTracker.balance = goldCurrencyTracker.balance or {}
    goldCurrencyTracker.balance["Warband"] = goldCurrencyTracker.balance["Warband"] or {}

    goldCurrencyTracker.balance[realm] = goldCurrencyTracker.balance[realm] or {}
    goldCurrencyTracker.balance[realm][char] = goldCurrencyTracker.balance[realm][char] or {}
end

local function SaveBalance()
    local realm, char = GetCharacterInfo()
    local today = GetToday()
    local currentGold = GetGold()

    goldCurrencyTracker.balance["Warband"][today] = goldCurrencyTracker.balance["Warband"][today] or {}
    goldCurrencyTracker.balance[realm][char][today] = goldCurrencyTracker.balance[realm][char][today] or {}

    goldCurrencyTracker.balance[realm][char][today]["gold"] = currentGold

    for _, currencies in pairs(goldCurrencyTracker.characterCurrencies) do
        for _, currencyID in ipairs(currencies) do
            local key = "c-" .. tostring(currencyID)
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)

            if info then
                goldCurrencyTracker.balance[realm][char][today][key] = info.quantity
            end
        end
    end

    for _, currencies in pairs(goldCurrencyTracker.warbandCurrencies) do
        for _, currencyID in ipairs(currencies) do
            local key = "w-" .. tostring(currencyID)
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)

            if info then
                goldCurrencyTracker.balance["Warband"][today][key] = info.quantity
            end
        end
    end

    goldCurrencyTracker:PrintDebug("Gold and curreny balance saved.")
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
        InitDatabase()

        goldCurrencyTracker:LoadOptions()
        goldCurrencyTracker:MigrateOldData()
        goldCurrencyTracker:PrintDebug("Addon fully loaded.")
    end
end

function goldCurrencyTrackerFrame:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    goldCurrencyTracker:PrintDebug("Event 'PLAYER_ENTERING_WORLD' fired. Payload: isInitialLogin=" .. tostring(isInitialLogin) .. ", isReloadingUi=" .. tostring(isReloadingUi))

    SaveBalance()

    if goldCurrencyTracker.options["QKywRlN7-open-on-login"] and (isInitialLogin or isReloadingUi) then
        goldCurrencyTracker:ShowGoldCurrencyOverview()
    end
end

function goldCurrencyTrackerFrame:PLAYER_MONEY(...)
    goldCurrencyTracker:PrintDebug("Event 'PLAYER_MONEY' fired. No payload.")

    SaveBalance()
end

function goldCurrencyTrackerFrame:CURRENCY_DISPLAY_UPDATE(...)
    goldCurrencyTracker:PrintDebug("Event 'CURRENCY_DISPLAY_UPDATE' fired. No payload.")

    SaveBalance()
end

goldCurrencyTrackerFrame:RegisterEvent("ADDON_LOADED")
goldCurrencyTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
goldCurrencyTrackerFrame:RegisterEvent("PLAYER_MONEY")
goldCurrencyTrackerFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
goldCurrencyTrackerFrame:SetScript("OnEvent", goldCurrencyTrackerFrame.OnEvent)

SLASH_GoldCurrencyTracker1, SLASH_GoldCurrencyTracker2 = '/gct', '/GoldCurrencyTracker'

SlashCmdList["GoldCurrencyTracker"] = SlashCommand

--------------------------------------------------------------

function goldCurrencyTracker:MigrateOldData()
    self.balance = self.balance or {}

    if self.goldBalance then
        for realm, realmData in pairs(self.goldBalance) do
            self.balance[realm] = self.balance[realm] or {}

            for charName, charData in pairs(realmData) do
                self.balance[realm][charName] = self.balance[realm][charName] or {}

                for dateStr, goldValue in pairs(charData) do
                    self.balance[realm][charName][dateStr] = self.balance[realm][charName][dateStr] or {}
                    self.balance[realm][charName][dateStr]["gold"] = goldValue
                end
            end
        end
    end

    if self.currencyBalance then
        for realm, realmData in pairs(self.currencyBalance) do
            self.balance[realm] = self.balance[realm] or {}

            for charName, charData in pairs(realmData) do
                self.balance[realm][charName] = self.balance[realm][charName] or {}

                for dateStr, history in pairs(charData) do
                    for currencyID, amount in pairs(history) do
                        if currencyID ~= 2032 then
                            local key = "c-" .. tostring(currencyID)
                            self.balance[realm][charName][dateStr] = self.balance[realm][charName][dateStr] or {}
                            self.balance[realm][charName][dateStr][key] = amount
                        end
                    end
                end
            end
        end
    end

    wipe(self.goldBalance)
    wipe(self.currencyBalance)
    self.goldBalance = nil
    self.currencyBalance = nil
end