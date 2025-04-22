local _, GCT = ...

local L = GCT.localization

local Utils = {}

---------------------
--- Main funtions ---
---------------------

function Utils:PrintDebug(msg)
    if GCT.data.options["debug-mode"] then
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

function Utils:InitializeDatabase()
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

function Utils:InitializeMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("GoldCurrencyTracker", {
        type     = "launcher",
        text     = "GoldCurrencyTracker",
        icon     = GCT.MEDIA_PATH .. "iconRound.blp",
        OnClick  = function(self, button)
            if button == "LeftButton" then
                if GCT.overview:IsShown() then
                    GCT.overview:Hide()
                else
                    GCT.overview:Show()
                end
            elseif button == "RightButton" then
                Settings.OpenToCategory("Gold & Currency Tracker")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine(L["addon-name"], GCT.ADDON_VERSION)
            tooltip:AddLine(" ")
            tooltip:AddLine(L["minimap-button.tooltip"], 1, 1, 1)
        end,
    })

    local zone = {}
    zone.hide = GCT.data.options["minimap-button-hide"]
    zone.minimapPos = GCT.data.options["minimap-button-position"]

    self.minimapButton = LibStub("LibDBIcon-1.0")
    self.minimapButton:Register("GoldCurrencyTracker", LDB, zone)
    self.minimapButton:Lock("GoldCurrencyTracker")
end

function Utils:CleanZeroEntries()
    for realmKey, realmData in pairs(GCT.data.balance) do
        if realmKey == "Warband" then
            for dateStr, rec in pairs(realmData) do
                for key, val in pairs(rec) do
                    if val == 0 then
                        rec[key] = nil
                    end
                end

            end
        else
            for charName, charData in pairs(realmData) do
                for dateStr, rec in pairs(charData) do
                    for key, val in pairs(rec) do
                        if val == 0 then
                            rec[key] = nil
                        end
                    end
                    if next(rec) == nil then
                        charData[dateStr] = nil
                    end
                end

            end
        end
    end

    Utils:PrintDebug("All zero values are adjusted.")
end

function Utils:GetFirstPositiveDate(currencyKey)
    local bal = GCT.data.balance
    local realm, char = self:GetCharacterInfo()
    local isWarband = currencyKey:match("^w%-%d+$")

    -- Welches Sub-Table durchsuchen?
    local data
    if isWarband then
        data = bal["Warband"]
    else
        data = bal[realm] and bal[realm][char]
    end
    if not data then return nil end

    local earliestDate

    -- durch alle gespeicherten Tage iterieren
    for dateStr, rec in pairs(data) do
        -- Wert holen (nil → 0)
        local val = rec[currencyKey] or 0
        if val > 0 then
            -- neues Minimum?
            if not earliestDate or dateStr < earliestDate then
                earliestDate = dateStr
            end
        end
    end

    return earliestDate
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