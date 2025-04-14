local _, goldCurrencyTracker = ...

local L = goldCurrencyTracker.localization

local currentMonthOffset = 0
local selectedCurrency = "gold"

local monthKeys = {
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec"
}

--------------
--- Frames ---
--------------

local goldCurrencyOverviewFrame = CreateFrame("Frame", "GoldCurrencyOverview", UIParent, "ButtonFrameTemplate")
goldCurrencyOverviewFrame:SetPoint("CENTER")
goldCurrencyOverviewFrame:SetSize(450, 550)
goldCurrencyOverviewFrame:SetMovable(true)
goldCurrencyOverviewFrame:EnableMouse(true)
goldCurrencyOverviewFrame:RegisterForDrag("LeftButton")
goldCurrencyOverviewFrame:SetScript("OnDragStart", goldCurrencyOverviewFrame.StartMoving)
goldCurrencyOverviewFrame:SetScript("OnDragStop", goldCurrencyOverviewFrame.StopMovingOrSizing)
goldCurrencyOverviewFrame:SetTitle("Gold & Currency Tracker")

goldCurrencyOverviewFrame:Hide()

goldCurrencyOverviewFrame.portrait = goldCurrencyOverviewFrame:GetPortrait()
goldCurrencyOverviewFrame.portrait:SetPoint('TOPLEFT', -5, 8)
goldCurrencyOverviewFrame.portrait:SetTexture(goldCurrencyTracker.MEDIA_PATH .. "iconRound.blp")

goldCurrencyOverviewFrame.header = goldCurrencyOverviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
goldCurrencyOverviewFrame.header:SetPoint("TOPLEFT", 70, -40)

goldCurrencyOverviewFrame.scrollFrame = CreateFrame("ScrollFrame", nil, goldCurrencyOverviewFrame, "UIPanelScrollFrameTemplate")
goldCurrencyOverviewFrame.scrollFrame:SetPoint("TOPLEFT", 10, -65)
goldCurrencyOverviewFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -32, 29)
goldCurrencyOverviewFrame.scrollFrame:EnableMouseWheel(true)
goldCurrencyOverviewFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
    self:SetVerticalScroll(newValue)
end)

goldCurrencyOverviewFrame.scrollFrame.content = CreateFrame("Frame", nil, goldCurrencyOverviewFrame.scrollFrame)
goldCurrencyOverviewFrame.scrollFrame.content:SetSize(1, 1)
goldCurrencyOverviewFrame.scrollFrame:SetScrollChild(goldCurrencyOverviewFrame.scrollFrame.content)

goldCurrencyOverviewFrame.nextButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame, "UIPanelButtonTemplate")
goldCurrencyOverviewFrame.nextButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame, "BOTTOMRIGHT", -55, 4)
goldCurrencyOverviewFrame.nextButton:SetSize(100, 21)
goldCurrencyOverviewFrame.nextButton:SetText(L["button-next"])
goldCurrencyOverviewFrame.nextButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset - 1
    goldCurrencyTracker:UpdateGoldCurrencyOverview()
end)

goldCurrencyOverviewFrame.prevButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame, "UIPanelButtonTemplate")
goldCurrencyOverviewFrame.prevButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame, "BOTTOMLEFT", 55, 4)
goldCurrencyOverviewFrame.prevButton:SetSize(100, 21)
goldCurrencyOverviewFrame.prevButton:SetText(L["button-prev"])
goldCurrencyOverviewFrame.prevButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset + 1
    goldCurrencyTracker:UpdateGoldCurrencyOverview()
end)

goldCurrencyOverviewFrame.currencyDropdown = CreateFrame("Frame", "GoldTrackerDropdown", goldCurrencyOverviewFrame, "UIDropDownMenuTemplate")
goldCurrencyOverviewFrame.currencyDropdown:SetPoint("TOPRIGHT", goldCurrencyOverviewFrame, "TOPRIGHT", 10, -30)

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

local function FormatAmount(val)
    if selectedCurrency == "gold" then
        return FormatGold(val)
    else
        return BreakUpLargeNumbers(val or 0)
    end
end

local function FormatAmountDiff(diff)
    if selectedCurrency == "gold" then
        return FormatGoldDiff(diff)
    else
        return (diff >= 0 and "+" or "") .. BreakUpLargeNumbers(diff)
    end
end

local function FindLastEntryBeforeMonth(data, prefix)
    local lastEntry = nil

    for dateStr, value in pairs(data) do
        if dateStr < prefix then
            if not lastEntry or dateStr > lastEntry.date then
                lastEntry = {date = dateStr, value = value}
            end
        end
    end

    return lastEntry
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
    UIDropDownMenu_SetWidth(goldCurrencyOverviewFrame.currencyDropdown, 180)
    UIDropDownMenu_SetText(goldCurrencyOverviewFrame.currencyDropdown, L["currency-category.gold"])

    UIDropDownMenu_Initialize(goldCurrencyOverviewFrame.currencyDropdown , function(self, level)
        if level == 1 then
            local goldInfo = UIDropDownMenu_CreateInfo()
            goldInfo.text = L["currency-category.gold"]
            goldInfo.notCheckable = true
            goldInfo.func = function()
                selectedCurrency = "gold"
                UIDropDownMenu_SetText(goldCurrencyOverviewFrame.currencyDropdown , L["currency-category.gold"])
                goldCurrencyTracker:UpdateGoldCurrencyOverview()
                CloseDropDownMenus()
            end

            UIDropDownMenu_AddButton(goldInfo, level)

            for _, key in ipairs(goldCurrencyTracker.currencyCategoryOrder) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L["currency-category." .. key]
                info.hasArrow = true
                info.notCheckable = true
                info.menuList = goldCurrencyTracker.currencyCategories[key]
                UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 then
            local sortedList = {}

            for _, currencyID in ipairs(self.menuList) do
                local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if info then
                    table.insert(sortedList, { id = currencyID, name = info.name, icon = info.iconFileID })
                else
                    goldCurrencyTracker:PrintDebug(tostring("The following currency ID does not exist: " .. currencyID))
                end
            end

            table.sort(sortedList, function(a, b)
                return a.id < b.id
            end)

            for _, entry in ipairs(sortedList) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = entry.name
                info.icon = entry.icon
                info.notCheckable = true
                info.func = function()
                    selectedCurrency = entry.id
                    UIDropDownMenu_SetText(goldCurrencyOverviewFrame.currencyDropdown, entry.name)
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
    local realm, name = GetCharacterInfo()
    local data
    local entries = {}
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    goldCurrencyOverviewFrame.header:SetText(FormatMonthText(filterPrefix))

    if goldCurrencyOverviewFrame.scrollFrame.content.rows then
        for _, row in ipairs(goldCurrencyOverviewFrame.scrollFrame.content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    goldCurrencyOverviewFrame.scrollFrame.content.rows = {}

    if selectedCurrency == "gold" then
        data = goldCurrencyTracker.goldBalance and goldCurrencyTracker.goldBalance[realm] and goldCurrencyTracker.goldBalance[realm][name]
    else
        local allData = goldCurrencyTracker.currencyBalance and goldCurrencyTracker.currencyBalance[realm] and goldCurrencyTracker.currencyBalance[realm][name]

        if allData then
            data = {}
            for dateStr, currencies in pairs(allData) do
                if currencies[selectedCurrency] ~= nil then
                    data[dateStr] = currencies[selectedCurrency]
                end
            end
        end
    end

    if data then
        for dateStr, gold in pairs(data) do
            if dateStr:sub(1, 7) == filterPrefix then
                table.insert(entries, {date = dateStr, value = gold})
            end
        end
        table.sort(entries, function(a, b) return a.date > b.date end)
    end

    if #entries == 0 then
        local row = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetPoint("TOPLEFT", 10, -10)
        row:SetText(L["no-entries"])
        table.insert(goldCurrencyOverviewFrame.scrollFrame.content.rows, {row})
        return
    end

    local previousEntry = FindLastEntryBeforeMonth(data, filterPrefix)

    local offsetY = -10
    local spacing = 6

    local headerDate = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["date"])

    local headerAmount = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["amount"])

    local headerDiff = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDiff:SetPoint("TOPLEFT", 250, offsetY)
    headerDiff:SetText(L["difference"])

    table.insert(goldCurrencyOverviewFrame.scrollFrame.content.rows, {headerDate, headerAmount, headerDiff})
    offsetY = offsetY - 20

    for i, entry in ipairs(entries) do
        local rowDate = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatAmount(entry.value))

        local rowDiff = goldCurrencyOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDiff:SetPoint("TOPLEFT", 250, offsetY)

        local prev
        if i < #entries then
            prev = entries[i + 1]
        elseif previousEntry then
            prev = previousEntry
        end

        if prev then
            local diff = entry.value - prev.value
            rowDiff:SetText(FormatAmountDiff(diff))
            if diff > 0 then
                rowDiff:SetTextColor(0, 1, 0)
            elseif diff < 0 then
                rowDiff:SetTextColor(1, 0.2, 0.2)
            else
                rowDiff:SetTextColor(1, 1, 1)
            end
        else
            rowDiff:SetText("-")
        end

        table.insert(goldCurrencyOverviewFrame.scrollFrame.content.rows, {rowDate, rowAmount, rowDiff})
        offsetY = offsetY - 18 - spacing
    end

    if data then
        local currentPrefix = GetYearMonthString(currentMonthOffset)
        goldCurrencyOverviewFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(data, currentPrefix))
        goldCurrencyOverviewFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(data, currentPrefix))
    else
        goldCurrencyOverviewFrame.prevButton:SetEnabled(false)
        goldCurrencyOverviewFrame.nextButton:SetEnabled(false)
    end
end