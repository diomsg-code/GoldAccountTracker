local _, GCT = ...

local L = GCT.localization

local Utils = {}

---------------------
--- Main Funtions ---
---------------------

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

    if (not GoldCurrencyTracker_DataBalance_v2) then
        GoldCurrencyTracker_DataBalance_v2 = {}
    end

    GCT.data.balance = GoldCurrencyTracker_DataBalance_v2

    GCT.data.balance =  GCT.data.balance or {}
    GCT.data.balance["Warband"] =  GCT.data.balance["Warband"] or {}

    GCT.data.balance[realm] =  GCT.data.balance[realm] or {}
    GCT.data.balance[realm][char] =  GCT.data.balance[realm][char] or {}

    if (not GoldCurrencyTracker_DataDates) then
        GoldCurrencyTracker_DataDates = {}
    end

    GCT.data.dates = GoldCurrencyTracker_DataDates
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
            tooltip:AddLine(L["minimap-button.tooltip"]:format(GCT.LINK_FONT_COLOR, GCT.LINK_FONT_COLOR), 1, 1, 1)
        end,
    })

    local zone = {}
    zone.hide = GCT.data.options["minimap-button-hide"]
    zone.minimapPos = GCT.data.options["minimap-button-position"]

    self.minimapButton = LibStub("LibDBIcon-1.0")
    self.minimapButton:Register("GoldCurrencyTracker", LDB, zone)
    self.minimapButton:Lock("GoldCurrencyTracker")
end

GCT.utils = Utils
