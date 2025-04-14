local _, goldCurrencyTracker = ...

goldCurrencyTracker.localization = setmetatable({},{__index=function(self,key)
        geterrorhandler()("Gold & Currency Tracker (Debug): Missing entry for '" .. tostring(key) .. "'")
        return key
    end})

local L = goldCurrencyTracker.localization

L["jan"] = "January"
L["feb"] = "February"
L["mar"] = "March"
L["apr"] = "April"
L["may"] = "May"
L["jun"] = "June"
L["jul"] = "July"
L["aug"] = "August"
L["sep"] = "September"
L["oct"] = "October"
L["nov"] = "November"
L["dec"] = "December"

L["currency-category.gold"] = "Gold"
L["currency-category.misc"] = "Miscellaneous"
L["currency-category.pvp"] = "Player vs. Player"
L["currency-category.dungeonraid"] = "Dungeon and Raid"
L["currency-category.classic"] = "Classic"
L["currency-category.tbc"] = "Burning Crusade"
L["currency-category.wotlk"] = "Wrath of the Lich King"
L["currency-category.cata"] = "Cataclysm"
L["currency-category.mop"] = "Mists of Pandaria"
L["currency-category.wod"] = "Warlords of Draenor"
L["currency-category.legion"] = "Legion"
L["currency-category.bfa"] = "Battle for Azeroth"
L["currency-category.sl"] = "Shadowlands"
L["currency-category.df"] = "Dragonflight"
L["currency-category.tww"] = "The War Within"

L["button-next"] = "Next"
L["button-prev"] = "Previous"

L["date"] = "Date"
L["amount"] = "Amount"
L["difference"] = "Difference"

L["no-entries"] = "No entries for this month."

L["general-options"] = "General Options"
L["open-on-login.name"] = "Open Overview on Login"
L["open-on-login.tooltip"] = "Activate or deactivate the automatic opening of the gold & currency overview when logging in."

L["other-options"] = "Other Options"
L["debug.name"] = "Enable Debug Mode"
L["debug.tooltip"] = "Activates or deactivates the Debug Mode."