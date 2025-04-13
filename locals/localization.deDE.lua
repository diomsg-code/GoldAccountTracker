local _, accountGoldTracker = ...

if GetLocale() ~= "deDE" then return end

local L = accountGoldTracker.localization

L["January"] = "Januar"
L["February"] = "Februar"
L["March"] = "März"
L["April"] = "April"
L["May"] = "Mai"
L["June"] = "Juni"
L["July"] = "Juli"
L["August"] = "August"
L["September"] = "September"
L["October"] = "Oktober"
L["November"] = "November"
L["December"] = "Dezember"

L["button-next"] = "Weiter"
L["button-previous"] = "Zurück"

L["date"] = "Datum"
L["amount"] = "Betrag"
L["difference"] = "Differenz"

L["no-entries"] = "Keine Einträge für diesen Monat."

L["general-options"] = "allgemeine Einstellungen"
L["open-on-login.name"] = "Goldübersicht bei Login öffnen"
L["open-on-login.tooltip"] = "Aktiviere oder deaktiviere die automatische Öffnung der Goldübersicht beim Login."

L["other-options"] = "sonstige Optionen"
L["debug.name"] = "Debugmodus aktivieren"
L["debug.tooltip"] = "Aktiviert oder deaktiviert den Debugmodus."