local _, GCT = ...

local L = GCT.localization

local Utils = {}

----------------------
--- Local funtions ---
----------------------

local function binarySearch(dates, target)
    local lo, hi = 1, #dates
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if dates[mid] < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return hi
end

---------------------
--- Main funtions ---
---------------------

function Utils:PrintDebug(msg)
    if GCT.data.options["QKywRlN7-debug"] then
        local notfound = true

        for i = 1, NUM_CHAT_WINDOWS do 
            local name, _, _, _, _, _, shown, locked, docked, uni = GetChatWindowInfo(i)

            if name == "Debug" and docked ~= nil then
                _G['ChatFrame' .. i]:AddMessage(WrapTextInColorCode("Gold & Currency Tracker (Debug): ", "ffFF8040") .. msg)
                notfound = false
                break
            end
        end

        if notfound then
            DEFAULT_CHAT_FRAME:AddMessage(WrapTextInColorCode("Gold & Currency Tracker (Debug): ", "ffFF8040")  .. msg)
        end
	end
end

function Utils:InitDatabase()
    local realm, char = Utils:GetCharacterInfo()

    if (not GoldCurrencyTracker_Options) then
        GoldCurrencyTracker_Options = {}
    end

    GCT.data = {}
    GCT.data.options = GoldCurrencyTracker_Options

    if (not GoldCurrencyTracker_DataBalance) then
        GoldCurrencyTracker_DataBalance = {}
    end

    GCT.data.balance = GoldCurrencyTracker_DataBalance

    GCT.data.balance =  GCT.data.balance or {}
    GCT.data.balance["Warband"] =  GCT.data.balance["Warband"] or {}

    GCT.data.balance[realm] =  GCT.data.balance[realm] or {}
    GCT.data.balance[realm][char] =  GCT.data.balance[realm][char] or {}
end

function Utils:BuildDateIndex(balance)
    self.dateIndex = {}

    for realmKey, realmData in pairs(balance or {}) do
        self.dateIndex[realmKey] = {}

        if realmKey == "Warband" then
            local dates = {}
            for dateStr in pairs(realmData) do
                table.insert(dates, dateStr)
            end
            table.sort(dates)
            self.dateIndex[realmKey]["Warband"] = dates
        else
            for charName, charData in pairs(realmData) do
                local dates = {}
                for dateStr in pairs(charData) do
                    table.insert(dates, dateStr)
                end
                table.sort(dates)
                self.dateIndex[realmKey][charName] = dates
            end
        end
    end
end

function Utils:GetPreviousValue(balance, realmKey, charName, currentDate, currencyKey)
    local lookupChar = (realmKey == "Warband") and "Warband" or charName
    local dates = self.dateIndex[realmKey] and self.dateIndex[realmKey][lookupChar]
    if not dates then return nil end

    local idx = binarySearch(dates, currentDate)
    while idx > 0 do
        local dateStr = dates[idx]
        local rec = (realmKey == "Warband")
                    and balance["Warband"][dateStr]
                    or balance[realmKey][charName][dateStr]
        if rec then
            local id
            if currencyKey == "gold" then
                id = "gold"
            elseif currencyKey:match("^w%-(%d+)$") then
                id = currencyKey:match("^w%-(%d+)$")
            elseif currencyKey:match("^c%-(%d+)$") then
                id = currencyKey:match("^c%-(%d+)$")
            end
            local val = rec[id]
            if val ~= nil then
                return val
            end
        end
        idx = idx - 1
    end
    return nil
end

function Utils:GetToday()
    return date("%Y-%m-%d")
end

function Utils:GetGold()
    return GetMoney()
end

function Utils:GetCharacterInfo()
    local char = UnitName("player")
    local realm = GetRealmName()

    return realm, char
end

GCT.utils = Utils