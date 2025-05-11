local _, GCT = ...

local L = GCT.localization

---------------------
--- Main Funtions ---
---------------------

function GoldCurrencyTracker_CompartmentOnEnter(self, button)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:SetText(L["addon.name"])
    GameTooltip:AddLine(WrapTextInColorCode(GCT.ADDON_VERSION .. " (" .. GCT.ADDON_BUILD_DATE .. ")", GCT.WHITE_FONT_COLOR))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["minimap-button.tooltip"]:format(GCT.LINK_FONT_COLOR, GCT.LINK_FONT_COLOR), 1, 1, 1)
	GameTooltip:Show()
end

function GoldCurrencyTracker_CompartmentOnLeave()
    GameTooltip:Hide()
end

function GoldCurrencyTracker_CompartmentOnClick(_, button)
    if button == "LeftButton" then
        if GCT.overview:IsShown() then
            GCT.overview:Hide()
        else
            GCT.overview:Show()
        end
    elseif button == "RightButton" then
        Settings.OpenToCategory("Gold & Currency Tracker")
    end
end