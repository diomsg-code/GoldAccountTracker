local _, accountGoldTracker = ...

accountGoldTracker.localization = setmetatable({},{__index=function(self,key)
        geterrorhandler()("Account Gold Tracker: Missing entry for '" .. tostring(key) .. "'")
        return key
    end})

local L = accountGoldTracker.localization

L["January"] = "January"
L["February"] = "February"
L["March"] = "March"
L["April"] = "April"
L["May"] = "May"
L["June"] = "June"
L["July"] = "July"
L["August"] = "August"
L["September"] = "September"
L["October"] = "October"
L["November"] = "November"
L["December"] = "December"

L["button-next"] = "Next"
L["button-previous"] = "Previous"

L["date"] = "Date"
L["amount"] = "Amount"
L["difference"] = "Difference"

L["no-entries"] = "No entries for this month."

L["general-options"] = "General options"
L["open-on-login.name"] = "Open gold overview on login"
L["open-on-login.tooltip"] = "Activate or deactivate the automatic opening of the gold overview when logging in."

L["other-options"] = "Other Options"
L["debug.name"] = "Enable Debug Mode"
L["debug.tooltip"] = "Activates or deactivates the Debug Mode."