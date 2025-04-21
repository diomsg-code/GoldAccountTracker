local _, goldCurrencyTracker = ...

if GetLocale() ~= "ruRU" then return end

local L = goldCurrencyTracker.localization

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

-- Options

L["options.general"] = "General Options"
L["options.open-on-login.name"] = "Open Overview on Login"
L["options.open-on-login.tooltip"] = "Activate or deactivate the automatic opening of the gold & currency overview when logging in."
L["options.minimap-button-hide.name"] = "Minimap Button"
L["options.minimap-button-hide.tooltip"] = "Activate or deactivate the display of the minimap button."
L["options.minimap-button-position.name"] = "Position"
L["options.minimap-button-position.tooltip"] = "Defines the position of the minimap button."

L["options.other"] = "Other Options"
L["options.debug-mode.name"] = "Debug Mode"
L["options.debug-mode.tooltip"] = "Activates or deactivates the debug mode."
