local _, GCT = ...

if GetLocale() ~= "deDE" then return end

local L = GCT.localization

L["addon-name"] = "Gold & Currency Tracker"

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
L["currency-category.warband"] = "Kriegsmeutewährungen"
L["currency-category.character"] = "Charakterwährungen"
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

L["tab.character"] = "Charakter"
L["tab.account"] = "Account"

L["button-next"] = "Weiter"
L["button-prev"] = "Zurück"

L["date"] = "Datum"
L["amount"] = "Betrag"
L["difference"] = "Differenz"

L["no-entries"] = "Keine Einträge für diesen Monat."

L["minimap-button.tooltip"] = "|c%sLinksklick|r zum Öffnen der Gold- und Währungsübersicht.\n|c%sRechtsklick|r zum Öffnen der Einstellungen."

-- Options

L["options.general"] = "allgemeine Einstellungen"
L["options.open-on-login.name"] = "Gold- und Währungsübersicht"
L["options.open-on-login.tooltip"] = "Bei Aktivierung öffnet sich die Gold- und Währungsübersicht beim Login automatisch."
L["options.minimap-button-hide.name"] = "Minimap Button"
L["options.minimap-button-hide.tooltip"] = "Bei Aktivierung wird der Minimap Button angezeigt."
L["options.minimap-button-position.name"] = "Position"
L["options.minimap-button-position.tooltip"] = "Legt die Position des Minimap Buttons fest."

L["options.other"] = "sonstige Einstellungen"
L["options.debug-mode.name"] = "Debugmodus"
L["options.debug-mode.tooltip"] = "Die Aktivierung des Debugmodus zeigt zusätzliche Informationen im Chat an."
