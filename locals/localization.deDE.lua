local _, goldAccountBalance = ...

if GetLocale() ~= "deDE" then return end

local L = goldAccountBalance.localization

L["other-options"] = "sonstige Optionen"
L["debug.name"] = "Debugmodus aktivieren"
L["debug.tooltip"] = "Aktiviert oder deaktiviert den Debugmodus."