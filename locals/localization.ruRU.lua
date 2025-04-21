local _, GCT = ...

if GetLocale() ~= "ruRU" then return end

local L = GCT.localization

local linkFontColor = "ff66BBFF"

L["addon-name"] = "Gold & Currency Tracker"

L["jan"] = "Январь"
L["feb"] = "Февраль"
L["mar"] = "Март "
L["apr"] = "Апрель"
L["may"] = "Май"
L["jun"] = "Июнь"
L["jul"] = "Июль"
L["aug"] = "Август"
L["sep"] = "Сентябрь"
L["oct"] = "Октябрь"
L["nov"] = "Ноябрь"
L["dec"] = "Декабрь"

L["currency-category.gold"] = "Золото"
L["currency-category.warband"] = "Валюты Отряда"
L["currency-category.character"] = "Валюты персонажа"
L["currency-category.misc"] = "Разное"
L["currency-category.pvp"] = "Игрок против игрока"
L["currency-category.dungeonraid"] = "Подземелье и рейд"
L["currency-category.classic"] = "Classic"
L["currency-category.tbc"] = "Burning Crusade"
L["currency-category.wotlk"] = "Гнев Короля-лича"
L["currency-category.cata"] = "Катаклизм"
L["currency-category.mop"] = "Пандария"
L["currency-category.wod"] = "Дренор"
L["currency-category.legion"] = "Легион"
L["currency-category.bfa"] = "Битва за Азерот"
L["currency-category.sl"] = "Темные Земли"
L["currency-category.df"] = "Драконы"
L["currency-category.tww"] = "Война Внутри"

L["tab.character"] = "Персонаж"
L["tab.account"] = "Аккаунт"

L["button-next"] = "Вперёд"
L["button-prev"] = "Назад"

L["date"] = "Дата"
L["amount"] = "Количество"
L["difference"] = "Разница"

L["no-entries"] = "Нет записей за этот месяц."

L["minimap-button.tooltip"] = "|c" .. linkFontColor .. "Left-click|r to open the gold and currency overview.\n|c" .. linkFontColor .. "Right-click|r to open the options."

-- Options

L["options.general"] = "General Options"
L["options.open-on-login.name"] = "Gold and Currency Overview"
L["options.open-on-login.tooltip"] = "When this is enabled, the gold and currency overview opens automatically when logging in."
L["options.minimap-button-hide.name"] = "Minimap Button"
L["options.minimap-button-hide.tooltip"] = "When this is enabled, the minimap button is displayed."
L["options.minimap-button-position.name"] = "Position"
L["options.minimap-button-position.tooltip"] = "Determines the position of the minimap button."

L["options.other"] = "Other Options"
L["options.debug-mode.name"] = "Debug Mode"
L["options.debug-mode.tooltip"] = "Enabling the debug mode displays additional information in the chat."
