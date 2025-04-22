local _, GCT = ...

local L =  GCT.localization
local Utils = GCT.utils

local Overview = {}

local currentMonthOffset = 0
local selectedCurrency = "gold"

--------------
--- Frames ---
--------------

local goldCurrencyOverviewFrame
local portrait

-- Tab 1

local t1_header
local t1_scrollFrame
local t1_content
local t1_nextButton
local t1_prevButton
local t1_currencyDropdown

-- Tab2

----------------------
--- Local funtions ---
----------------------

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

    local key = GCT.MONTH_KEYS[tonumber(month)]
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
    local v = val or 0
    if selectedCurrency == "gold" then
        return FormatGold(v)
    else
        return BreakUpLargeNumbers(v)
    end
end

local function FormatCurrencyDiff(diff)
    local d = diff or 0
    if selectedCurrency == "gold" then
        return FormatGoldDiff(d)
    else
        local sign = (d > 0 and "+" or d == 0 and "±" or "")
        return sign .. BreakUpLargeNumbers(d)
    end
end

local function HasAnyDataBeforeMonth(dates, currentPrefix, firstPositiveDate)
    if not dates or #dates == 0 then return false end

    -- finde Start‑Index ≥ firstPositiveDate
    local startIdx = 1
    if firstPositiveDate then
        while startIdx <= #dates and dates[startIdx] < firstPositiveDate do
            startIdx = startIdx + 1
        end
    end

    local firstDate = dates[startIdx]
    return firstDate and firstDate < currentPrefix or false
end

local function HasAnyDataAfterMonth(dates, currentPrefix, firstPositiveDate)
    if not dates or #dates == 0 then return false end

    if firstPositiveDate and dates[#dates] < firstPositiveDate then
        return false
    end

    local suffix   = currentPrefix .. "-31"
    local lastDate = dates[#dates]
    return lastDate and lastDate > suffix or false
end

local function BuildDateIndex(balance)
    Overview.dateIndex = {}

    for realmKey, realmData in pairs(balance or {}) do
        Overview.dateIndex[realmKey] = {}

        if realmKey == "Warband" then
            local dates = {}
            for dateStr in pairs(realmData) do
                table.insert(dates, dateStr)
            end
            table.sort(dates)
            Overview.dateIndex[realmKey]["Warband"] = dates
        else
            for charName, charData in pairs(realmData) do
                local dates = {}
                for dateStr in pairs(charData) do
                    table.insert(dates, dateStr)
                end
                table.sort(dates)
                Overview.dateIndex[realmKey][charName] = dates
            end
        end
    end
end

local function binarySearch(dates, target)
    local lo, hi = 1, #dates
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if dates[mid] < target then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return hi
end

local function GetPreviousValue(balance, realm, char, currentDate, currencyKey, firstPositiveDate)
    local charKey = (realm == "Warband") and "Warband" or char
    local realmKey = realm
    local dates = Overview.dateIndex[realmKey] and Overview.dateIndex[realmKey][charKey]
    if not dates then return nil end

    local idx = binarySearch(dates, currentDate)
    while idx > 0 do
        local date = dates[idx]

        if firstPositiveDate and date < firstPositiveDate then
            return nil
        end

        local rec = (realmKey == "Warband") and balance["Warband"][date] or balance[realm][char][date]
        if rec then
            return rec[currencyKey] or 0
        end
        idx = idx - 1
    end
    return nil
end

----------------------
--- Frame funtions ---
----------------------

local function UpdateOverview()
    local realm, char = Utils:GetCharacterInfo()
    local currencyKey = selectedCurrency or "gold"
    local isWarband = currencyKey:match("^w%-%d+$")
    local isChar = currencyKey:match("^c%-%d+$")

    local data
    if currencyKey == "gold" then
        data = GCT.data.balance[realm] and GCT.data.balance[realm][char]
    elseif isWarband then
        data = GCT.data.balance["Warband"]
    elseif isChar then
        data = GCT.data.balance[realm] and GCT.data.balance[realm][char]
    end
    if not data then return end

    local filterPrefix = GetYearMonthString(currentMonthOffset)
    t1_header:SetText(FormatMonthText(filterPrefix))

    if t1_content.rows then
        for _, row in ipairs(t1_content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end
    t1_content.rows = {}

    local firstPositiveDate = Utils:GetFirstPositiveDate(selectedCurrency or "gold")
    if not firstPositiveDate then
        firstPositiveDate = Utils:GetToday()
    end

    local entries = {}
    for dateStr, rec in pairs(data) do
        if dateStr:sub(1,7) == filterPrefix then
            if not firstPositiveDate or dateStr >= firstPositiveDate then
                local raw = rec[currencyKey] or 0
                table.insert(entries, {date = dateStr, value = raw})
            end
        end
    end

    if #entries == 0 then
        local row = t1_content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetPoint("TOPLEFT", 10, -10)
        row:SetText(L["no-entries"])
        table.insert(t1_content.rows, {row})
        return
    else
        table.sort(entries, function(a,b) return a.date > b.date end)
    end

    local offsetY = -10
    local spacing = 6

    local headerDate = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["date"])

    local headerAmount  = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["amount"])

    local headerDifference = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDifference:SetPoint("TOPLEFT", 225, offsetY)
    headerDifference:SetText(L["difference"])

    table.insert(t1_content.rows, {headerDate, headerAmount, headerDifference})
    offsetY = offsetY - 20

    local prevOutside

    for i, entry in ipairs(entries) do
        local currentValue = entry.value
        local prevValue
        if i < #entries then
            prevValue = entries[i+1].value
        else
            if prevOutside == nil then
                prevOutside = GetPreviousValue(GCT.data.balance, (isWarband and "Warband") or realm, char, entry.date, currencyKey, firstPositiveDate) or 0
            end
            prevValue = prevOutside
        end

        local rowDate = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue))

        local rowDifference = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDifference:SetPoint("TOPLEFT", 225, offsetY)

        if entry.date ~= firstPositiveDate then
            local diff = currentValue - prevValue
            rowDifference:SetText(FormatCurrencyDiff(diff))
            if diff > 0 then
                rowDifference:SetTextColor(0,1,0)
            elseif diff < 0 then
                rowDifference:SetTextColor(1,0.2,0.2)
            else
                rowDifference:SetTextColor(1,1,1)
            end
        else
            rowDifference:SetText("-")
            rowDifference:SetTextColor(1,1,1)
        end

        table.insert(t1_content.rows, {rowDate, rowAmount, rowDifference})
        offsetY = offsetY - 18 - spacing
    end

    local currentPrefix = GetYearMonthString(currentMonthOffset)

    local a = (isWarband and "Warband") or realm
    local b = (isWarband and "Warband") or char
    local dates = Overview.dateIndex[a] and Overview.dateIndex[a][b]

    if dates then
        t1_prevButton:SetEnabled(HasAnyDataBeforeMonth(dates, currentPrefix, firstPositiveDate))
        t1_nextButton:SetEnabled(HasAnyDataAfterMonth(dates, currentPrefix, firstPositiveDate))
    else
        t1_prevButton:SetEnabled(false)
        t1_nextButton:SetEnabled(false)
    end
end

local function InitializeDropdown()
    UIDropDownMenu_SetWidth(t1_currencyDropdown, 180)
    UIDropDownMenu_SetText(t1_currencyDropdown, L["currency-category.gold"])

    UIDropDownMenu_Initialize(t1_currencyDropdown, function(self, level, menuList)
        if level == 1 then
            local goldInfo = UIDropDownMenu_CreateInfo()
            goldInfo.text = L["currency-category.gold"]
            goldInfo.notCheckable = true
            goldInfo.func = function()
                selectedCurrency = "gold"
                currentMonthOffset = 0
                UIDropDownMenu_SetText(t1_currencyDropdown, L["currency-category.gold"])
                UpdateOverview()
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
                groups =  GCT.WARBAND_CURRENCIES
            elseif groupType == "character" then
                groups =  GCT.CHARACTER_CURRENCIES
            end

            for _, categoryKey in ipairs( GCT.CURRENCY_CATEGORY_ORDER) do
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
                currencyList =  GCT.WARBAND_CURRENCIES[categoryKey] or {}
                prefix = "w-"
            elseif groupType == "character" then
                currencyList =  GCT.CHARACTER_CURRENCIES[categoryKey] or {}
                prefix = "c-"
            end

            local sortedList = {}
            for _, currencyID in ipairs(currencyList) do
                local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if info then
                    table.insert(sortedList, {id = prefix .. currencyID, name = info.name, icon = info.iconFileID})
                else
                     Utils:PrintDebug("Invalid currency ID: " .. tostring(currencyID))
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
                    currentMonthOffset = 0
                    UIDropDownMenu_SetText(t1_currencyDropdown, entry.name)
                    UpdateOverview()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

local function InitializeFrames()
    local tabs = {}
    local contents = {}

    goldCurrencyOverviewFrame = CreateFrame("Frame", "GoldCurrencyOverviewFrame", UIParent, "ButtonFrameTemplate")
    goldCurrencyOverviewFrame:SetPoint("CENTER")
    goldCurrencyOverviewFrame:SetSize(450, 550)
    goldCurrencyOverviewFrame:SetMovable(true)
    goldCurrencyOverviewFrame:EnableMouse(true)
    goldCurrencyOverviewFrame:RegisterForDrag("LeftButton")
    goldCurrencyOverviewFrame:SetScript("OnDragStart", goldCurrencyOverviewFrame.StartMoving)
    goldCurrencyOverviewFrame:SetScript("OnDragStop", goldCurrencyOverviewFrame.StopMovingOrSizing)
    goldCurrencyOverviewFrame:SetTitle(L["addon-name"])
    goldCurrencyOverviewFrame:Hide()
    tinsert(UISpecialFrames, "GoldCurrencyOverviewFrame")

    portrait = goldCurrencyOverviewFrame:GetPortrait()
    portrait:SetPoint('TOPLEFT', -5, 8)
    portrait:SetTexture(GCT.MEDIA_PATH .. "iconRound.blp")

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
    t1_header = goldCurrencyOverviewFrame.contentTab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    t1_header:SetPoint("TOPLEFT", 70, -40)

    t1_scrollFrame = CreateFrame("ScrollFrame", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelScrollFrameTemplate")
    t1_scrollFrame:SetPoint("TOPLEFT", 10, -65)
    t1_scrollFrame:SetPoint("BOTTOMRIGHT", -32, 29)
    t1_scrollFrame:EnableMouseWheel(true)
    t1_scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
        self:SetVerticalScroll(newValue)
    end)

    t1_content = CreateFrame("Frame", nil, goldCurrencyOverviewFrame.contentTab1.scrollFrame)
    t1_content:SetSize(1, 1)
    t1_scrollFrame:SetScrollChild(t1_content)

    t1_nextButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
    t1_nextButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMRIGHT", -55, 4)
    t1_nextButton:SetSize(100, 21)
    t1_nextButton:SetText(L["button-next"])
    t1_nextButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset - 1
        UpdateOverview()
    end)

    t1_prevButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
    t1_prevButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMLEFT", 55, 4)
    t1_prevButton:SetSize(100, 21)
    t1_prevButton:SetText(L["button-prev"])

    t1_currencyDropdown = CreateFrame("Frame", "GoldCurrencyTrackerDropdown", goldCurrencyOverviewFrame.contentTab1, "UIDropDownMenuTemplate")
    t1_currencyDropdown:SetPoint("TOPRIGHT", goldCurrencyOverviewFrame.contentTab1, "TOPRIGHT", 10, -30)
    t1_prevButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset + 1
        UpdateOverview()
    end)

    -- Tab2
end

---------------------
--- Main funtions ---
---------------------

function Overview:Initialize()
    BuildDateIndex(GCT.data.balance)
    InitializeFrames()
    InitializeDropdown()
end

function Overview:Show()
    UpdateOverview()

    goldCurrencyOverviewFrame:Show()
end

function Overview:Hide()
    goldCurrencyOverviewFrame:Hide()
end

function Overview:IsShown()
    return goldCurrencyOverviewFrame:IsShown()
end

GCT.overview = Overview