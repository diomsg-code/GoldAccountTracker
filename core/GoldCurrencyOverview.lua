local _, goldCurrencyTracker = ...

local L = goldCurrencyTracker.localization

local currentMonthOffset = 0
local selectedCurrency = "gold"

local monthKeys = {
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec"
}

local tabs = {}
local contents = {}

--------------
--- Frames ---
--------------

local goldCurrencyOverviewFrame = CreateFrame("Frame", "GoldCurrencyOverviewFrame", UIParent, "ButtonFrameTemplate")
goldCurrencyOverviewFrame:SetPoint("CENTER")
goldCurrencyOverviewFrame:SetSize(450, 550)
goldCurrencyOverviewFrame:SetMovable(true)
goldCurrencyOverviewFrame:EnableMouse(true)
goldCurrencyOverviewFrame:RegisterForDrag("LeftButton")
goldCurrencyOverviewFrame:SetScript("OnDragStart", goldCurrencyOverviewFrame.StartMoving)
goldCurrencyOverviewFrame:SetScript("OnDragStop", goldCurrencyOverviewFrame.StopMovingOrSizing)
goldCurrencyOverviewFrame:SetTitle("Gold & Currency Tracker")
goldCurrencyOverviewFrame:Hide()
tinsert(UISpecialFrames, "GoldCurrencyOverviewFrame")

goldCurrencyOverviewFrame.portrait = goldCurrencyOverviewFrame:GetPortrait()
goldCurrencyOverviewFrame.portrait:SetPoint('TOPLEFT', -5, 8)
goldCurrencyOverviewFrame.portrait:SetTexture(goldCurrencyTracker.MEDIA_PATH .. "iconRound.blp")

local function ShowTab(i)
    PanelTemplates_SetTab(goldCurrencyOverviewFrame, i)
    for idx, c in ipairs(contents) do
        if idx == i then c:Show() else c:Hide() end
    end
end

for i = 1, 2 do
    local tab = CreateFrame("Button", nil, goldCurrencyOverviewFrame, "PanelTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(i == 1 and L["tab.character"] or L["tab.account"])
    PanelTemplates_TabResize(tab, 0)
    tab:SetScript("OnClick", function(self)
        ShowTab(self:GetID())
    end)
    tabs[i] = tab

    local content = CreateFrame("Frame", nil, goldCurrencyOverviewFrame)
    content:SetSize(450, 550)
    content:SetPoint("TOPLEFT", goldCurrencyOverviewFrame, "TOPLEFT", 0, 0)
    if i ~= 1 then content:Hide() end

    if i == 2 then
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("CENTER", 0, 0)
        label:SetText("An account overview will follow with the next update.")
    end

    contents[i] = content
end

PanelTemplates_SetNumTabs(goldCurrencyOverviewFrame, 2)
tabs[1]:SetPoint("TOPLEFT", goldCurrencyOverviewFrame, "BOTTOMLEFT", 10, 2)
tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", -15, 0)
PanelTemplates_SetTab(goldCurrencyOverviewFrame, 1)

goldCurrencyOverviewFrame.contentTab1 = contents[1]
goldCurrencyOverviewFrame.contentTab2 = contents[2]

-- Tab 1

goldCurrencyOverviewFrame.contentTab1.header = goldCurrencyOverviewFrame.contentTab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
goldCurrencyOverviewFrame.contentTab1.header:SetPoint("TOPLEFT", 70, -40)

goldCurrencyOverviewFrame.contentTab1.scrollFrame = CreateFrame("ScrollFrame", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelScrollFrameTemplate")
goldCurrencyOverviewFrame.contentTab1.scrollFrame:SetPoint("TOPLEFT", 10, -65)
goldCurrencyOverviewFrame.contentTab1.scrollFrame:SetPoint("BOTTOMRIGHT", -32, 29)
goldCurrencyOverviewFrame.contentTab1.scrollFrame:EnableMouseWheel(true)
goldCurrencyOverviewFrame.contentTab1.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
    self:SetVerticalScroll(newValue)
end)

goldCurrencyOverviewFrame.contentTab1.scrollFrame.content = CreateFrame("Frame", nil, goldCurrencyOverviewFrame.contentTab1.scrollFrame)
goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:SetSize(1, 1)
goldCurrencyOverviewFrame.contentTab1.scrollFrame:SetScrollChild(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content)

goldCurrencyOverviewFrame.contentTab1.nextButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
goldCurrencyOverviewFrame.contentTab1.nextButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMRIGHT", -55, 4)
goldCurrencyOverviewFrame.contentTab1.nextButton:SetSize(100, 21)
goldCurrencyOverviewFrame.contentTab1.nextButton:SetText(L["button-next"])
goldCurrencyOverviewFrame.contentTab1.nextButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset - 1
    goldCurrencyTracker:UpdateGoldCurrencyOverview()
end)

goldCurrencyOverviewFrame.contentTab1.prevButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
goldCurrencyOverviewFrame.contentTab1.prevButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMLEFT", 55, 4)
goldCurrencyOverviewFrame.contentTab1.prevButton:SetSize(100, 21)
goldCurrencyOverviewFrame.contentTab1.prevButton:SetText(L["button-prev"])
goldCurrencyOverviewFrame.contentTab1.prevButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset + 1
    goldCurrencyTracker:UpdateGoldCurrencyOverview()
end)

goldCurrencyOverviewFrame.contentTab1.currencyDropdown = CreateFrame("Frame", "GoldTrackerDropdown", goldCurrencyOverviewFrame.contentTab1, "UIDropDownMenuTemplate")
goldCurrencyOverviewFrame.contentTab1.currencyDropdown:SetPoint("TOPRIGHT", goldCurrencyOverviewFrame.contentTab1, "TOPRIGHT", 10, -30)

-- Tab2

----------------------
--- Local funtions ---
----------------------

local function GetCharacterInfo()
    local name = UnitName("player")
    local realm = GetRealmName()

    return realm, name
end

local function GetYearMonthString(offset)
    local now = time()
    local year = tonumber(date("%Y", now))
    local month = tonumber(date("%m", now))

    month = month - offset

    while month < 1 do
        month = month + 12
        year = year - 1
    end

    while month > 12 do
        month = month - 12
        year = year + 1
    end

    return string.format("%04d-%02d", year, month)
end

local function FormatMonthText(prefix)
    local year, month = strsplit("-", prefix)

    if not month or not year then return prefix end

    local key = monthKeys[tonumber(month)]
    local name = L[key] or key

    return string.format("%s %s", name, year)
end

local function FormatGold(copper)
    local gold = floor(copper / (100 * 100))
    local silver = floor((copper / 100) % 100)
    local copper = copper % 100

    return string.format("%s |T237618:0|t %02d |T237620:0|t %02d |T237617:0|t", BreakUpLargeNumbers(gold), silver, copper)
end

local function FormatGoldDiff(diff)
    local sign = diff > 0 and "+" or diff < 0 and "-" or "±"
    local absVal = math.abs(diff)

    return sign .. " " .. FormatGold(absVal)
end

local function FormatCurrency(val)
    if selectedCurrency == "gold" then
        return FormatGold(val)
    else
        return BreakUpLargeNumbers(val or 0)
    end
end

local function FormatCurrencyDiff(diff)
    if selectedCurrency == "gold" then
        return FormatGoldDiff(diff)
    else
        return (diff > 0 and "+" or diff == 0 and "±" or "") .. BreakUpLargeNumbers(diff)
    end
end

local function GetPreviousCurrencyValue(data, currentDate, currency)
    local allDates = {}
    for dateStr in pairs(data) do
        if dateStr < currentDate then
            table.insert(allDates, dateStr)
        end
    end
    table.sort(allDates, function(a, b) return a > b end)

    for _, dateStr in ipairs(allDates) do
        local val = data[dateStr][currency]
        if val ~= nil then
            return val
        end
    end

    return nil
end

local function HasAnyDataBeforeMonth(data, currentPrefix)
    for dateStr in pairs(data) do
        if dateStr < currentPrefix then
            return true
        end
    end

    return false
end

local function HasAnyDataAfterMonth(data, currentPrefix)
    for dateStr in pairs(data) do
        if dateStr > currentPrefix .. "-31" then
            return true
        end
    end

    return false
end

local function InitializeGoldCurrencyDropdown()
    UIDropDownMenu_SetWidth(goldCurrencyOverviewFrame.contentTab1.currencyDropdown, 180)
    UIDropDownMenu_SetText(goldCurrencyOverviewFrame.contentTab1.currencyDropdown, L["currency-category.gold"])

    UIDropDownMenu_Initialize(goldCurrencyOverviewFrame.contentTab1.currencyDropdown, function(self, level, menuList)
        if level == 1 then
            local goldInfo = UIDropDownMenu_CreateInfo()
            goldInfo.text = L["currency-category.gold"]
            goldInfo.notCheckable = true
            goldInfo.func = function()
                selectedCurrency = "gold"
                UIDropDownMenu_SetText(goldCurrencyOverviewFrame.contentTab1.currencyDropdown, L["currency-category.gold"])
                goldCurrencyTracker:UpdateGoldCurrencyOverview()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(goldInfo, level)

            local charInfo = UIDropDownMenu_CreateInfo()
            charInfo.text = L["currency-category.character"]
            charInfo.hasArrow = true
            charInfo.notCheckable = true
            charInfo.menuList = { type = "character" }
            UIDropDownMenu_AddButton(charInfo, level)

            local warbandInfo = UIDropDownMenu_CreateInfo()
            warbandInfo.text = L["currency-category.warband"]
            warbandInfo.hasArrow = true
            warbandInfo.notCheckable = true
            warbandInfo.menuList = { type = "warband" }
            UIDropDownMenu_AddButton(warbandInfo, level)

        elseif level == 2 and menuList then
            local groupType = menuList.type

            local groups
            if groupType == "warband" then
                groups = goldCurrencyTracker.warbandCurrencies
            elseif groupType == "character" then
                groups = goldCurrencyTracker.characterCurrencies
            end

            for _, categoryKey in ipairs(goldCurrencyTracker.currencyCategoryOrder) do
                if groups[categoryKey] then
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = L["currency-category." .. categoryKey] or categoryKey
                    info.hasArrow = true
                    info.notCheckable = true
                    info.menuList = { type = groupType, category = categoryKey }
                    UIDropDownMenu_AddButton(info, level)
                end
            end

        elseif level == 3 and menuList then
            local groupType = menuList.type
            local categoryKey = menuList.category

            local currencyList = {}
            local prefix
            if groupType == "warband" then
                currencyList = goldCurrencyTracker.warbandCurrencies[categoryKey] or {}
                prefix = "w-"
            elseif groupType == "character" then
                currencyList = goldCurrencyTracker.characterCurrencies[categoryKey] or {}
                prefix = "c-"
            end

            local sortedList = {}
            for _, currencyID in ipairs(currencyList) do
                local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if info then
                    table.insert(sortedList, {
                        id = prefix .. currencyID,
                        name = info.name,
                        icon = info.iconFileID
                    })
                else
                    goldCurrencyTracker:PrintDebug("Invalid currency ID: " .. tostring(currencyID))
                end
            end

            table.sort(sortedList, function(a, b)
                return a.name < b.name
            end)

            for _, entry in ipairs(sortedList) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = entry.name
                info.icon = entry.icon
                info.notCheckable = true
                info.func = function()
                    selectedCurrency = entry.id
                    UIDropDownMenu_SetText(goldCurrencyOverviewFrame.contentTab1.currencyDropdown, entry.name)
                    goldCurrencyTracker:UpdateGoldCurrencyOverview()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    
end

---------------------
--- Main funtions ---
---------------------

function goldCurrencyTracker:ShowGoldCurrencyOverview()
    InitializeGoldCurrencyDropdown()
    goldCurrencyTracker:UpdateGoldCurrencyOverview()

    goldCurrencyOverviewFrame:Show()
end

function goldCurrencyTracker:UpdateGoldCurrencyOverview()
    local currencyKey = selectedCurrency or "gold"
    local isGold = currencyKey == "gold"
    local isAccountCurrency = false
    local realm, char = GetCharacterInfo()
    local data

    if isGold then
        data = self.balance and self.balance[realm] and self.balance[realm][char]
    else
        if currencyKey:sub(1,1) == "w" then
            data = self.balance and self.balance["Warband"]
            isAccountCurrency = true
        else
            data = self.balance and self.balance[realm] and self.balance[realm][char]
        end
    end

    if not data then return end

    local filterPrefix = GetYearMonthString(currentMonthOffset)
    goldCurrencyOverviewFrame.contentTab1.header:SetText(FormatMonthText(filterPrefix))

    if goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows then
        for _, row in ipairs(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows = {}

    local entries = {}
    for dateStr, entry in pairs(data) do
        if dateStr:sub(1, 7) == filterPrefix then
            local value = isGold and entry["gold"] or entry[currencyKey]
            if value ~= nil then
                table.insert(entries, { date = dateStr, value = value })
            end
        end
    end

    table.sort(entries, function(a, b) return a.date > b.date end)

    local function FindPreviousCurrencyValue(currentDate)
        local allData = isGold and self.balance[realm][char] or
                        isAccountCurrency and self.balance["Warband"] or
                        self.balance[realm][char]
        local result = nil
        for dateStr, values in pairs(allData) do
            if dateStr < currentDate then
                local val = isGold and values["gold"] or values[currencyKey]
                if val ~= nil and (not result or dateStr > result.date) then
                    result = { date = dateStr, value = val }
                end
            end
        end
        return result and result.value or nil
    end

    local earliestDate = nil
    for dateStr, entry in pairs(data) do
        local value = isGold and entry["gold"] or entry[currencyKey]
        if value and value > 0 then
            if not earliestDate or dateStr < earliestDate then
                earliestDate = dateStr
            end
        end
    end

    local offsetY = -10
    local spacing = 6

    local headerDate = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["date"])

    local headerAmount = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["amount"])

    local headerDiff = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDiff:SetPoint("TOPLEFT", 225, offsetY)
    headerDiff:SetText(L["difference"])

    table.insert(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows, { headerDate, headerAmount, headerDiff })
    offsetY = offsetY - 20

    for i, entry in ipairs(entries) do
        local rowDate = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(entry.value))

        local rowDiff = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDiff:SetPoint("TOPLEFT", 225, offsetY)

        local previousValue = (i < #entries) and entries[i + 1].value or FindPreviousCurrencyValue(entry.date)
        if previousValue ~= nil and entry.date ~= earliestDate then
            local diff = entry.value - previousValue
            rowDiff:SetText(FormatCurrencyDiff(diff))
            if diff > 0 then
                rowDiff:SetTextColor(0, 1, 0)
            elseif diff < 0 then
                rowDiff:SetTextColor(1, 0.2, 0.2)
            else
                rowDiff:SetTextColor(1, 1, 1)
            end
        else
            rowDiff:SetText("-")
            rowDiff:SetTextColor(1, 1, 1)
        end

        table.insert(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows, { rowDate, rowAmount, rowDiff })
        offsetY = offsetY - 18 - spacing
    end

    if data then
        local currentPrefix = GetYearMonthString(currentMonthOffset)
        goldCurrencyOverviewFrame.contentTab1.prevButton:SetEnabled(HasAnyDataBeforeMonth(data, currentPrefix))
        goldCurrencyOverviewFrame.contentTab1.nextButton:SetEnabled(HasAnyDataAfterMonth(data, currentPrefix))
    else
        goldCurrencyOverviewFrame.contentTab1.prevButton:SetEnabled(false)
        goldCurrencyOverviewFrame.contentTab1.nextButton:SetEnabled(false)
    end
end











function goldCurrencyTracker:UpdateGoldCurrencyOverview3()
    local realm, name = GetCharacterInfo()
    local data = self.balance and self.balance[realm] and self.balance[realm][name]
    if not data then return end

    local filterPrefix = GetYearMonthString(currentMonthOffset)
    goldCurrencyOverviewFrame.contentTab1.header:SetText(FormatMonthText(filterPrefix))

    if goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows then
        for _, row in ipairs(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end
    goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows = {}

    local entries = {}
    for dateStr, currencies in pairs(data) do
        if dateStr:sub(1, 7) == filterPrefix then
            table.insert(entries, {
                date = dateStr,
                value = currencies[selectedCurrency] or 0
            })
        end
    end

    table.sort(entries, function(a, b) return a.date > b.date end)

    local offsetY = -10
    local spacing = 6

    local headerDate = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["date"])

    local headerAmount = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["amount"])

    local headerDiff = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDiff:SetPoint("TOPLEFT", 225, offsetY)
    headerDiff:SetText(L["difference"])

    table.insert(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows, {headerDate, headerAmount, headerDiff})
    offsetY = offsetY - 20

    local earliestDate = nil
    for dateStr, currencies in pairs(data) do
        if currencies[selectedCurrency] and currencies[selectedCurrency] > 0 then
            if not earliestDate or dateStr < earliestDate then
                earliestDate = dateStr
            end
        end
    end

    for i, entry in ipairs(entries) do
        local currentValue = entry.value
        local prevValue
        local hasPrevious = false

        if i < #entries then
            prevValue = entries[i + 1].value
            hasPrevious = true
        else
            local previous = GetPreviousCurrencyValue(data, entry.date, selectedCurrency)
            if previous ~= nil then
                prevValue = previous
                hasPrevious = true
            end
        end

        local rowDate = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue))

        local rowDiff = goldCurrencyOverviewFrame.contentTab1.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDiff:SetPoint("TOPLEFT", 225, offsetY)

        if hasPrevious and entry.date ~= earliestDate then
            local diff = currentValue - prevValue
            rowDiff:SetText(FormatCurrencyDiff(diff))
            if diff > 0 then
                rowDiff:SetTextColor(0, 1, 0)
            elseif diff < 0 then
                rowDiff:SetTextColor(1, 0.2, 0.2)
            else
                rowDiff:SetTextColor(1, 1, 1)
            end
        else
            rowDiff:SetText("-")
            rowDiff:SetTextColor(1, 1, 1)
        end

        table.insert(goldCurrencyOverviewFrame.contentTab1.scrollFrame.content.rows, {rowDate, rowAmount, rowDiff})
        offsetY = offsetY - 18 - spacing
    end

    if data then
        local currentPrefix = GetYearMonthString(currentMonthOffset)
        goldCurrencyOverviewFrame.contentTab1.prevButton:SetEnabled(HasAnyDataBeforeMonth(data, currentPrefix))
        goldCurrencyOverviewFrame.contentTab1.nextButton:SetEnabled(HasAnyDataAfterMonth(data, currentPrefix))
    else
        goldCurrencyOverviewFrame.contentTab1.prevButton:SetEnabled(false)
        goldCurrencyOverviewFrame.contentTab1.nextButton:SetEnabled(false)
    end
end