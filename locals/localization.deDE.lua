local _, goldCurrencyTracker = ...

if GetLocale() ~= "deDE" then return end

local L = goldCurrencyTracker.localization

L["jan"] = "Januar"
L["feb"] = "Februar"
L["mar"] = "März"
L["apr"] = "April"
L["may"] = "Mai"
L["jun"] = "Juni"
L["jul"] = "Juli"
L["aug"] = "August"
L["sep"] = "September"
L["oct"] = "Oktober"
L["nov"] = "November"
L["dec"] = "Dezember"

L["currency-category.gold"] = "Gold"
L["currency-category.misc"] = "Verschiedenes"
L["currency-category.pvp"] = "Spieler gegen Spieler"
L["currency-category.dungeonraid"] = "Dungeon und Schlachtzug"
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

L["button-next"] = "Weiter"
L["button-prev"] = "Zurück"

L["date"] = "Datum"
L["amount"] = "Betrag"
L["difference"] = "Differenz"

L["no-entries"] = "Keine Einträge für diesen Monat."

L["general-options"] = "allgemeine Einstellungen"
L["open-on-login.name"] = "Übersicht bei Login öffnen"
L["open-on-login.tooltip"] = "Aktiviere oder deaktiviere die automatische Öffnung der Gold- und Währungsübersicht beim Login."

L["other-options"] = "sonstige Optionen"
L["debug.name"] = "Debugmodus aktivieren"
L["debug.tooltip"] = "Aktiviert oder deaktiviert den Debugmodus."