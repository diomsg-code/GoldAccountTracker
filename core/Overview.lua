local _, GCT = ...

local L =  GCT.localization
local Utils = GCT.utils

local Overview = {}

local currentMonthOffset = 0
local selectedCurrency = "gold"

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

local portrait = goldCurrencyOverviewFrame:GetPortrait()
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

local t1_header = goldCurrencyOverviewFrame.contentTab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
t1_header:SetPoint("TOPLEFT", 70, -40)

local t1_scrollFrame = CreateFrame("ScrollFrame", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelScrollFrameTemplate")
t1_scrollFrame:SetPoint("TOPLEFT", 10, -65)
t1_scrollFrame:SetPoint("BOTTOMRIGHT", -32, 29)
t1_scrollFrame:EnableMouseWheel(true)
t1_scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
    self:SetVerticalScroll(newValue)
end)

local t1_content = CreateFrame("Frame", nil, goldCurrencyOverviewFrame.contentTab1.scrollFrame)
t1_content:SetSize(1, 1)
t1_scrollFrame:SetScrollChild(t1_content)

local t1_nextButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
t1_nextButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMRIGHT", -55, 4)
t1_nextButton:SetSize(100, 21)
t1_nextButton:SetText(L["button-next"])

local t1_prevButton = CreateFrame("Button", nil, goldCurrencyOverviewFrame.contentTab1, "UIPanelButtonTemplate")
t1_prevButton:SetPoint("BOTTOM", goldCurrencyOverviewFrame.contentTab1, "BOTTOMLEFT", 55, 4)
t1_prevButton:SetSize(100, 21)
t1_prevButton:SetText(L["button-prev"])

local t1_currencyDropdown = CreateFrame("Frame", "GoldCurrencyTrackerDropdown", goldCurrencyOverviewFrame.contentTab1, "UIDropDownMenuTemplate")
t1_currencyDropdown:SetPoint("TOPRIGHT", goldCurrencyOverviewFrame.contentTab1, "TOPRIGHT", 10, -30)

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

local function UpdateGoldCurrencyOverview()
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
    t1_header:SetText( FormatMonthText(filterPrefix) )

    if t1_content.rows then
        for _, row in ipairs(t1_content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end
    t1_content.rows = {}

    local entries = {}
    for dateStr, rec in pairs(data) do
        if dateStr:sub(1,7) == filterPrefix then
            local id
            if currencyKey == "gold" then
                id = "gold"
            elseif isWarband or isChar then
                id = currencyKey
            end
            local value = rec[id]
            table.insert(entries, { date = dateStr, value = value })
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

    local earliestDate = nil
    for dateStr in pairs(data) do
        if not earliestDate or dateStr < earliestDate then
            earliestDate = dateStr
        end
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
                prevOutside = Utils:GetPreviousValue(
                    GCT.data.balance,
                    (isWarband and "Warband") or realm,
                    char,
                    entry.date,
                    currencyKey
                ) or 0
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

        if entry.date ~= earliestDate then
            local diff = currentValue - prevValue
            rowDifference:SetText( FormatCurrencyDiff(diff) )
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

    if data then
        local currentPrefix = GetYearMonthString(currentMonthOffset)
        t1_prevButton:SetEnabled(HasAnyDataBeforeMonth(data, currentPrefix))
        t1_nextButton:SetEnabled(HasAnyDataAfterMonth(data, currentPrefix))
    else
        t1_prevButton:SetEnabled(false)
        t1_nextButton:SetEnabled(false)
    end
end

local function InitializeGoldCurrencyDropdown()
    UIDropDownMenu_SetWidth(t1_currencyDropdown, 180)
    UIDropDownMenu_SetText(t1_currencyDropdown, L["currency-category.gold"])

    UIDropDownMenu_Initialize(t1_currencyDropdown, function(self, level, menuList)
        if level == 1 then
            local goldInfo = UIDropDownMenu_CreateInfo()
            goldInfo.text = L["currency-category.gold"]
            goldInfo.notCheckable = true
            goldInfo.func = function()
                selectedCurrency = "gold"
                UIDropDownMenu_SetText(t1_currencyDropdown, L["currency-category.gold"])
                UpdateGoldCurrencyOverview()
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
                    table.insert(sortedList, {
                        id = prefix .. currencyID,
                        name = info.name,
                        icon = info.iconFileID
                    })
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
                    UIDropDownMenu_SetText(t1_currencyDropdown, entry.name)
                    UpdateGoldCurrencyOverview()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

t1_nextButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset - 1
    UpdateGoldCurrencyOverview()
end)
t1_prevButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset + 1
    UpdateGoldCurrencyOverview()
end)

---------------------
--- Main funtions ---
---------------------

function Overview:Init()
    InitializeGoldCurrencyDropdown()
end

function Overview:Show()
    UpdateGoldCurrencyOverview()

    goldCurrencyOverviewFrame:Show()
end

function Overview:Hide()
    goldCurrencyOverviewFrame:Hide()
end

function Overview:IsShown()
    return goldCurrencyOverviewFrame:IsShown()
end

GCT.overview = Overview