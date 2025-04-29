local _, GCT = ...

if GetLocale() ~= "ruRU" then return end

local L = GCT.localization

L["addon-name"] = "Трекер золота и валюты"

L["month.jan"] = "Январь"
L["month.feb"] = "Февраль"
L["month.mar"] = "Март "
L["month.apr"] = "Апрель"
L["month.may"] = "Май"
L["month.jun"] = "Июнь"
L["month.jul"] = "Июль"
L["month.aug"] = "Август"
L["month.sep"] = "Сентябрь"
L["month.oct"] = "Октябрь"
L["month.nov"] = "Ноябрь"
L["month.dec"] = "Декабрь"

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
L["tab.warband"] = "Warband"
L["tab.account"] = "Аккаунт"

L["button.next"] = "Вперёд"
L["button.prev"] = "Назад"

L["table.date"] = "Дата"
L["table.amount"] = "Количество"
L["table.difference"] = "Разница"
L["table.no-entries"] = "Нет записей за этот месяц."

L["minimap-button.tooltip"] = "|c%sЛКМ|r - открыть обзор золота и валюты.\n|c%sПКМ|r - открыть настройки."

-- Options

L["options.general"] = "Общие параметры"
L["options.open-on-login.name"] = "Обзор золота и валюты"
L["options.open-on-login.tooltip"] = "Если эта функция включена, обзор золота и валюты открывается автоматически при входе в систему."
L["options.minimap-button-hide.name"] = "Кнопка миникарты"
L["options.minimap-button-hide.tooltip"] = "Если эта функция включена, отображается кнопка на миникарте."
L["options.minimap-button-position.name"] = "Положение"
L["options.minimap-button-position.tooltip"] = "Определяет положение кнопки миникарты."

L["options.other"] = "Другие параметры"
L["options.debug-mode.name"] = "Режим отладки"
L["options.debug-mode.tooltip"] = "Включение режима отладки отображает дополнительную информацию в чате."
