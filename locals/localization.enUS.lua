local _, goldAccountBalance = ...

goldAccountBalance.localization = setmetatable({},{__index=function(self,key)
        geterrorhandler()("Gold Account Balance: Missing entry for '" .. tostring(key) .. "'")
        return key
    end})

local L = goldAccountBalance.localization

L["other-options"] = "Other Options"
L["debug.name"] = "Enable Debug Mode"
L["debug.tooltip"] = "Activates or deactivates the Debug Mode."