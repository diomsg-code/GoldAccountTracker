local _, GCT = ...

local L =  GCT.localization
local Utils = GCT.utils

local Overview = {}

local currentMonthOffset = 0

local t1_selectedCurrency = "gold"
local t2_selectedCurrency = "w-2032"
local t3_selectedCurrency = "gold"

local selectedRealm, selectedChar = Utils:GetCharacterInfo()

--------------
--- Frames ---
--------------

local overviewFrame
local header
local portrait

-- Tab 1

local t1_content
local t1_currencyDropdown
local t1_characterDropdown
local t1_nextButton
local t1_prevButton

-- Tab2

local t2_content
local t2_currencyDropdown
local t2_nextButton
local t2_prevButton

-- Tab3

local t3_content
local t3_currencyDropdown
local t3_nextButton
local t3_prevButton

----------------------
--- Local Funtions ---
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

local function FormatCurrency(val, selectedCurrency)
    local v = val or 0
    if selectedCurrency == "gold" then
        return FormatGold(v)
    else
        return BreakUpLargeNumbers(v)
    end
end

local function FormatCurrencyDiff(diff, selectedCurrency)
    local d = diff or 0
    if selectedCurrency == "gold" then
        return FormatGoldDiff(d)
    else
        local sign = (d > 0 and "+" or d == 0 and "±" or "")
        return sign .. BreakUpLargeNumbers(d)
    end
end

local function BuildCharacterHistory(realm, char, currencyKey)
    local rawData = GCT.data.balance[realm][char]

    local entries = {}
    local lastValue = 0
    local dates = GCT.data.dates
    local startIndex = nil

    for i, date in ipairs(dates) do
        local dayData = rawData[date] or {}
        local v = dayData[currencyKey]
        if v and v > 0 then
            startIndex = i
            break
        end
    end

    if not startIndex then
        local today = Utils:GetToday()
        return {{date = today, value = 0}}
    end

    for i = startIndex, #dates do
        local date = dates[i]
        local dayData = rawData[date] or {}
        local value = dayData[currencyKey]

        if value == nil then
            value = lastValue
        end

        table.insert(entries, {date = date, value = value})
        lastValue = value
    end

    table.sort(entries, function(a,b) return a.date < b.date end)
    return entries
end

local function BuildCharacterHistoryLookup(realm, char, currencyKey)
    local rawData = GCT.data.balance[realm][char]

    local entries = {}
    local lastValue = 0
    local dates = GCT.data.dates
    local startIndex = nil

    for i, date in ipairs(dates) do
        local dayData = rawData[date] or {}
        local v = dayData[currencyKey]
        if v and v > 0 then
            startIndex = i
            break
        end
    end

    if not startIndex then
        local today = Utils:GetToday()
        entries[today] = 0
        return entries
    end

    for i = startIndex, #dates do
        local date = dates[i]
        local dayData = rawData[date] or {}
        local value = dayData[currencyKey]

        if value == nil then
            value = lastValue
        end

        entries[date] = value
        lastValue = value
    end

    return entries
end

local function BuildWarbandHistory(currencyKey)
    local rawData = GCT.data.balance["Warband"]

    local entries = {}
    local lastValue = 0
    local dates = GCT.data.dates
    local startIndex = nil

    for i, date in ipairs(dates) do
        local dayData = rawData[date] or {}
        local v = dayData[currencyKey]
        if v and v > 0 then
            startIndex = i
            break
        end
    end

    if not startIndex then
        local today = Utils:GetToday()
        return {{date = today, value = 0}}
    end

    for i = startIndex, #dates do
        local date = dates[i]
        local dayData = rawData[date] or {}
        local value = dayData[currencyKey]

        if value == nil then
            value = lastValue
        end

        table.insert(entries, {date = date, value = value})
        lastValue = value
    end

    table.sort(entries, function(a,b) return a.date < b.date end)
    return entries
end

local function BuildAccountHistory(currencyKey)
    local dates = GCT.data.dates
    local ttt = {}
    local entries = {}

    for realm, realmData in pairs(GCT.data.balance) do
        if realm ~= "Warband" then
            for char, _ in pairs(realmData) do
                local characterHistory = BuildCharacterHistoryLookup(realm, char, currencyKey)

                table.insert(ttt, {id = realm .. "-" .. char ,characterHistory = characterHistory})
            end
        end
    end

    for _, date in ipairs(dates) do
        local value = 0
        local hasValue = false

        for _, characterHistory in ipairs(ttt) do
            local c = characterHistory.characterHistory[date]

            if c then
                value = value + c
                hasValue = true
            end
        end

        if hasValue then
            table.insert(entries, {date = date, value = value})
        end
    end

    table.sort(entries, function(a,b) return a.date < b.date end)
    return entries
end

local function BuildMonthHistory(history, monthPrefix)
    local month = {}
    for _, e in ipairs(history) do
        if e.date:sub(1,7) == monthPrefix then
            table.insert(month, e)
        end
    end

    table.sort(month, function(a,b) return a.date > b.date end)
    return month
end

local function HasAnyDataBeforeMonth(history, monthPrefix)
    local monthStart = monthPrefix .. "-01"
    for i,e in ipairs(history) do
        if e.date >= monthStart then
            return i > 1
        end
    end
    return false
end

local function HasAnyDataAfterMonth(history, monthPrefix)
    local monthEnd = monthPrefix .. "-31"
    for j = #history, 1, -1 do
        if history[j].date <= monthEnd then
            return j < #history
        end
    end
    return false
end

local function GetPreviousValueFromHistory(history, currentDate)
    local lo, hi, idx = 1, #history, 0
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if history[mid].date < currentDate then
            idx = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return idx > 0 and history[idx].value or nil
end

----------------------
--- Frame Funtions ---
----------------------

local function UpdateCharacterOverview()
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    local t0 = debugprofilestop()

    local characterHistory = BuildCharacterHistory(selectedRealm, selectedChar, t1_selectedCurrency)

    local t1 = debugprofilestop()
    print(("C-Dauer: %.3f ms"):format(t1 - t0))

    local monthHistory = BuildMonthHistory(characterHistory, filterPrefix)

    header:SetText(FormatMonthText(filterPrefix))

    if t1_content.rows then
        for _, row in ipairs(t1_content.rows) do
            for _, element in ipairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    t1_content.rows = {}

    if #monthHistory == 0 then
        local noEntry = t1_content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noEntry:SetPoint("TOPLEFT", 10, -10)
        noEntry:SetText(L["table.no-entries"])
        table.insert(t1_content.rows, {noEntry})
        return
    end

    local offsetY = -10
    local spacing = 10

    local headerDate = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["table.date"])

    local headerAmount  = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["table.amount"])

    local headerDifference = t1_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDifference:SetPoint("TOPLEFT", 250, offsetY)
    headerDifference:SetText(L["table.difference"])

    table.insert(t1_content.rows, {headerDate, headerAmount, headerDifference})

    offsetY = offsetY - 20

    for i, entry in ipairs(monthHistory) do
        local dateStr = entry.date
        local currentValue = entry.value

        local prevValue
        if i < #monthHistory then
            prevValue = monthHistory[i+1].value
        else
            prevValue = GetPreviousValueFromHistory(characterHistory, dateStr) or 0
        end

        local rowDate = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue, t1_selectedCurrency))

        local rowDifference = t1_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDifference:SetPoint("TOPLEFT", 250, offsetY)

        local firstDate = characterHistory[1].date

        if entry.date ~= firstDate then
            local diff = currentValue - prevValue
            rowDifference:SetText(FormatCurrencyDiff(diff, t1_selectedCurrency))
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
        offsetY = offsetY - rowDate:GetHeight() - spacing
    end

    t1_prevButton:SetEnabled(HasAnyDataBeforeMonth(characterHistory, filterPrefix))
    t1_nextButton:SetEnabled(HasAnyDataAfterMonth(characterHistory, filterPrefix))
end

local function UpdateWarbandOverview()
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    local warbandHistory = BuildWarbandHistory(t2_selectedCurrency)
    local monthHistory = BuildMonthHistory(warbandHistory, filterPrefix)

    header:SetText(FormatMonthText(filterPrefix))

    if t2_content.rows then
        for _, row in ipairs(t2_content.rows) do
            for _, element in ipairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    t2_content.rows = {}

    if #monthHistory == 0 then
        local noEntry = t2_content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noEntry:SetPoint("TOPLEFT", 10, -10)
        noEntry:SetText(L["table.no-entries"])
        table.insert(t2_content.rows, {noEntry})
        return
    end

    local offsetY = -10
    local spacing = 10

    local headerDate = t2_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["table.date"])

    local headerAmount  = t2_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["table.amount"])

    local headerDifference = t2_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDifference:SetPoint("TOPLEFT", 250, offsetY)
    headerDifference:SetText(L["table.difference"])

    table.insert(t2_content.rows, {headerDate, headerAmount, headerDifference})

    offsetY = offsetY - 20

    for i, entry in ipairs(monthHistory) do
        local dateStr = entry.date
        local currentValue = entry.value

        local prevValue
        if i < #monthHistory then
            prevValue = monthHistory[i+1].value
        else
            prevValue = GetPreviousValueFromHistory(warbandHistory, dateStr) or 0
        end

        local rowDate = t2_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = t2_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue, t2_selectedCurrency))

        local rowDifference = t2_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDifference:SetPoint("TOPLEFT", 250, offsetY)

        local firstDate = warbandHistory[1].date

        if entry.date ~= firstDate then
            local diff = currentValue - prevValue
            rowDifference:SetText(FormatCurrencyDiff(diff, t2_selectedCurrency))
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

        table.insert(t2_content.rows, {rowDate, rowAmount, rowDifference})
        offsetY = offsetY - rowDate:GetHeight() - spacing
    end

    t2_prevButton:SetEnabled(HasAnyDataBeforeMonth(warbandHistory, filterPrefix))
    t2_nextButton:SetEnabled(HasAnyDataAfterMonth(warbandHistory, filterPrefix))
end

local function UpdateAccountOverview()
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    local t0 = debugprofilestop()

    local accountHistory = BuildAccountHistory(t3_selectedCurrency)

    local t1 = debugprofilestop()
    print(("A Dauer: %.3f ms"):format(t1 - t0))

    local monthHistory = BuildMonthHistory(accountHistory, filterPrefix)

    header:SetText(FormatMonthText(filterPrefix))

    if t3_content.rows then
        for _, row in ipairs(t3_content.rows) do
            for _, element in ipairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    t3_content.rows = {}

    if #monthHistory == 0 then
        local noEntry = t3_content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noEntry:SetPoint("TOPLEFT", 10, -10)
        noEntry:SetText(L["table.no-entries"])
        table.insert(t3_content.rows, {noEntry})
        return
    end

    local offsetY = -10
    local spacing = 10

    local headerDate = t3_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["table.date"])

    local headerAmount  = t3_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["table.amount"])

    local headerDifference = t3_content:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDifference:SetPoint("TOPLEFT", 250, offsetY)
    headerDifference:SetText(L["table.difference"])

    table.insert(t3_content.rows, {headerDate, headerAmount, headerDifference})

    offsetY = offsetY - 20

    for i, entry in ipairs(monthHistory) do
        local dateStr = entry.date
        local currentValue = entry.value

        local prevValue
        if i < #monthHistory then
            prevValue = monthHistory[i+1].value
        else
            prevValue = GetPreviousValueFromHistory(accountHistory, dateStr) or 0
        end

        local rowDate = t3_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = t3_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue, t3_selectedCurrency))

        local rowDifference = t3_content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDifference:SetPoint("TOPLEFT", 250, offsetY)

        local firstDate = accountHistory[1].date

        if entry.date ~= firstDate then
            local diff = currentValue - prevValue
            rowDifference:SetText(FormatCurrencyDiff(diff, t3_selectedCurrency))
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

        table.insert(t3_content.rows, {rowDate, rowAmount, rowDifference})
        offsetY = offsetY - rowDate:GetHeight() - spacing
    end

    t3_prevButton:SetEnabled(HasAnyDataBeforeMonth(accountHistory, filterPrefix))
    t3_nextButton:SetEnabled(HasAnyDataAfterMonth(accountHistory, filterPrefix))
end

local function UpdateOverview()
    UpdateCharacterOverview()
    UpdateWarbandOverview()
    UpdateAccountOverview()
end

local function InitializeFrames()
    local tabs = {}
    local scrollFrames = {}

    overviewFrame = CreateFrame("Frame", "GCT_OverviewFrame", UIParent, "PortraitFrameTemplate")
    overviewFrame:SetPoint("CENTER")
    overviewFrame:SetSize(450, 550)
    overviewFrame:SetMovable(true)
    overviewFrame:EnableMouse(true)
    overviewFrame:RegisterForDrag("LeftButton")
    overviewFrame:SetScript("OnDragStart", overviewFrame.StartMoving)
    overviewFrame:SetScript("OnDragStop", overviewFrame.StopMovingOrSizing)
    overviewFrame:SetTitle(L["addon-name"])
    overviewFrame:Hide()
    tinsert(UISpecialFrames, "GCT_OverviewFrame")

    portrait = overviewFrame:GetPortrait()
    portrait:SetPoint('TOPLEFT', -5, 8)
    portrait:SetTexture(GCT.MEDIA_PATH .. "iconRound.blp")

    header = overviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOP", 0, -40)

    local background = CreateFrame("Frame", nil, overviewFrame, "AccountStoreInsetFrameTemplate")
    background:SetSize(440, 415)
    background:SetPoint("TOPLEFT", overviewFrame, "TOPLEFT", 5, -100)

    local function ShowTab(i)
        PanelTemplates_SetTab(overviewFrame, i)
        for idx, c in ipairs(scrollFrames) do
            if idx == i then c:Show() else c:Hide() end
        end
    end

    for i = 1, 3 do
        local tab = CreateFrame("Button", nil, overviewFrame, "PanelTabButtonTemplate")
        tab:SetID(i)

        if i == 1 then
            tab:SetText(L["tab.character"])
        elseif i == 2 then
            tab:SetText(L["tab.warband"])
        else
            tab:SetText(L["tab.account"])
        end

        PanelTemplates_TabResize(tab, 0)
        tab:SetScript("OnClick", function(self)
            ShowTab(self:GetID())
        end)
        tabs[i] = tab

        local scrollFrame = CreateFrame("ScrollFrame", nil, background, "QuestScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -27, 2)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
            self:SetVerticalScroll(newValue)
        end)
        if i ~= 1 then scrollFrame:Hide() end

        scrollFrames[i] = scrollFrame
    end

    PanelTemplates_SetNumTabs(overviewFrame, 3)
    tabs[1]:SetPoint("TOPLEFT", overviewFrame, "BOTTOMLEFT", 10, 2)
    tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", -15, 0)
    tabs[3]:SetPoint("LEFT", tabs[2], "RIGHT", -15, 0)
    PanelTemplates_SetTab(overviewFrame, 1)

    overviewFrame.t1_scrollFrame = scrollFrames[1]
    overviewFrame.t2_scrollFrame = scrollFrames[2]
    overviewFrame.t3_scrollFrame = scrollFrames[3]

    -- Tab 1

    t1_content = CreateFrame("Frame", nil, overviewFrame.t1_scrollFrame)
    t1_content:SetSize(1, 1)
    overviewFrame.t1_scrollFrame:SetScrollChild(t1_content)

    t1_nextButton = CreateFrame("Button", nil, overviewFrame.t1_scrollFrame, "UIPanelButtonTemplate")
    t1_nextButton:SetPoint("BOTTOMRIGHT", overviewFrame, "BOTTOMRIGHT", -10, 8)
    t1_nextButton:SetSize(100, 22)
    t1_nextButton:SetText(L["button.next"])
    t1_nextButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset - 1
        UpdateOverview()
    end)

    t1_prevButton = CreateFrame("Button", nil, overviewFrame.t1_scrollFrame, "UIPanelButtonTemplate")
    t1_prevButton:SetPoint("BOTTOMLEFT", overviewFrame, "BOTTOMLEFT", 10, 8)
    t1_prevButton:SetSize(100, 22)
    t1_prevButton:SetText(L["button.prev"])
    t1_prevButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset + 1
        UpdateOverview()
    end)

    t1_currencyDropdown = CreateFrame("DropdownButton", nil, overviewFrame.t1_scrollFrame, "WowStyle1DropdownTemplate")
    t1_currencyDropdown:SetPoint("TOPRIGHT", overviewFrame, "TOPRIGHT", -10, -70)
    t1_currencyDropdown:SetSize(200, 25)

    t1_currencyDropdown:SetupMenu(function(self, root)
        local function IsSelected(value)
            return value == t1_selectedCurrency
        end

        local function SetSelected(value)
            t1_selectedCurrency = value
            currentMonthOffset = 0
            UpdateCharacterOverview()
        end

        local goldButton = root:CreateRadio("Gold", IsSelected, SetSelected, "gold");
        goldButton:AddInitializer(function(button, description, menu)
            local rightTexture = button:AttachTexture()
            rightTexture:SetSize(18, 18)
            rightTexture:SetPoint("RIGHT")
            rightTexture:SetTexture(237618)

            local fontString = button.fontString
            fontString:SetPoint("RIGHT")

            local pad = 20
            local width = pad + fontString:GetUnboundedStringWidth() + rightTexture:GetWidth()
            local height = 20
            return width, height
        end)

        root:CreateDivider()

        for _, categoryKey in ipairs(GCT.CURRENCY_CATEGORY_ORDER) do
            if GCT.CHARACTER_CURRENCIES[categoryKey] then
                local categoryButton = root:CreateButton(L["currency-category." .. categoryKey])

                local sortedList = {}

                for _, currencyID in ipairs(GCT.CHARACTER_CURRENCIES[categoryKey]) do
                    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                    if info then
                        table.insert(sortedList, {id = "c-" .. currencyID, name = info.name, iconFileID = info.iconFileID})
                    else
                         Utils:PrintDebug("Invalid currency ID: " .. tostring(currencyID))
                    end
                end

                table.sort(sortedList, function(a, b)
                    return a.name < b.name
                end)

                for _, entry in ipairs(sortedList) do
                    local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.id)
                    currencyButton:AddInitializer(function(button, description, menu)
                        local rightTexture = button:AttachTexture()
                        rightTexture:SetSize(18, 18)
                        rightTexture:SetPoint("RIGHT")
                        rightTexture:SetTexture(entry.iconFileID)

                        local fontString = button.fontString
                        fontString:SetPoint("RIGHT")

                        local pad = 20
                        local width = pad + fontString:GetUnboundedStringWidth() + rightTexture:GetWidth()
                        local height = 20
                        return width, height
                    end);
                end
            end
        end
    end)

    t1_characterDropdown = CreateFrame("DropdownButton", nil, overviewFrame.t1_scrollFrame, "WowStyle1DropdownTemplate")
    t1_characterDropdown:SetPoint("TOPLEFT", overviewFrame, "TOPLEFT", 10, -70)
    t1_characterDropdown:SetSize(125, 25)

    t1_characterDropdown:SetupMenu(function(self, root)
        local function IsSelected(value)
            return value == selectedRealm .. "-" .. selectedChar
        end

        local function SetSelected(value)
            local pos = value:find("-", 1, true)
            selectedRealm = value:sub(1, pos - 1)
            selectedChar = value:sub(pos + 1)
            currentMonthOffset = 0
            UpdateCharacterOverview()
        end

        local realms = {}
        for realm, _ in pairs(GCT.data.balance) do
            if realm ~= "Warband" then
                table.insert(realms, realm)
            end
        end
        table.sort(realms)

        for _, realmKey in ipairs(realms) do
            local realmButton = root:CreateButton(realmKey)

            local chars = {}
            for charName, _ in pairs(GCT.data.balance[realmKey]) do
                table.insert(chars, charName)
            end

            table.sort(chars)

            local info = C_CurrencyInfo.GetCurrencyInfo(2032)

            for _, charKey in ipairs(chars) do
                local charButton = realmButton:CreateRadio(charKey, IsSelected, SetSelected, realmKey .. "-" .. charKey)
                charButton:AddInitializer(function(button, description, menu)
                    local fontString = button.fontString
                    fontString:SetPoint("RIGHT")

                    local pad = 20
                    local width = pad + fontString:GetUnboundedStringWidth()
                    local height = 20
                    return width, height
                end)
            end
        end
    end)

    -- Tab2

    t2_content = CreateFrame("Frame", nil, overviewFrame.t2_scrollFrame)
    t2_content:SetSize(1, 1)
    overviewFrame.t2_scrollFrame:SetScrollChild(t2_content)

    t2_nextButton = CreateFrame("Button", nil, overviewFrame.t2_scrollFrame, "UIPanelButtonTemplate")
    t2_nextButton:SetPoint("BOTTOMRIGHT", overviewFrame, "BOTTOMRIGHT", -10, 8)
    t2_nextButton:SetSize(100, 22)
    t2_nextButton:SetText(L["button.next"])
    t2_nextButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset - 1
        UpdateOverview()
    end)

    t2_prevButton = CreateFrame("Button", nil, overviewFrame.t2_scrollFrame, "UIPanelButtonTemplate")
    t2_prevButton:SetPoint("BOTTOMLEFT", overviewFrame, "BOTTOMLEFT", 10, 8)
    t2_prevButton:SetSize(100, 22)
    t2_prevButton:SetText(L["button.prev"])
    t2_prevButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset + 1
        UpdateOverview()
    end)

    t2_currencyDropdown = CreateFrame("DropdownButton", nil, overviewFrame.t2_scrollFrame, "WowStyle1DropdownTemplate")
    t2_currencyDropdown:SetPoint("TOPRIGHT", overviewFrame, "TOPRIGHT", -10, -70)
    t2_currencyDropdown:SetSize(200, 25)

    t2_currencyDropdown:SetupMenu(function(self, root)
        local function IsSelected(value)
            return value == t2_selectedCurrency
        end

        local function SetSelected(value)
            t2_selectedCurrency = value
            currentMonthOffset = 0
            UpdateWarbandOverview()
        end

        for _, categoryKey in ipairs(GCT.CURRENCY_CATEGORY_ORDER) do
            if GCT.WARBAND_CURRENCIES[categoryKey] then
                local categoryButton = root:CreateButton(L["currency-category." .. categoryKey])

                local sortedList = {}

                for _, currencyID in ipairs(GCT.WARBAND_CURRENCIES[categoryKey]) do
                    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                    if info then
                        table.insert(sortedList, {id = "w-" .. currencyID, name = info.name, iconFileID = info.iconFileID})
                    else
                         Utils:PrintDebug("Invalid currency ID: " .. tostring(currencyID))
                    end
                end

                table.sort(sortedList, function(a, b)
                    return a.name < b.name
                end)

                for _, entry in ipairs(sortedList) do
                    local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.id);
                    currencyButton:AddInitializer(function(button, description, menu)
                        local rightTexture = button:AttachTexture()
                        rightTexture:SetSize(18, 18)
                        rightTexture:SetPoint("RIGHT")
                        rightTexture:SetTexture(entry.iconFileID)
    
                        local fontString = button.fontString
                        fontString:SetPoint("RIGHT")
    
                        local pad = 20
                        local width = pad + fontString:GetUnboundedStringWidth() + rightTexture:GetWidth()
                        local height = 20
                        return width, height
                    end);
                end
            end
        end
    end)

    -- Tab3

    t3_content = CreateFrame("Frame", nil, overviewFrame.t3_scrollFrame)
    t3_content:SetSize(1, 1)
    overviewFrame.t3_scrollFrame:SetScrollChild(t3_content)

    t3_nextButton = CreateFrame("Button", nil, overviewFrame.t3_scrollFrame, "UIPanelButtonTemplate")
    t3_nextButton:SetPoint("BOTTOMRIGHT", overviewFrame, "BOTTOMRIGHT", -10, 8)
    t3_nextButton:SetSize(100, 22)
    t3_nextButton:SetText(L["button.next"])
    t3_nextButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset - 1
        UpdateOverview()
    end)

    t3_prevButton = CreateFrame("Button", nil, overviewFrame.t3_scrollFrame, "UIPanelButtonTemplate")
    t3_prevButton:SetPoint("BOTTOMLEFT", overviewFrame, "BOTTOMLEFT", 10, 8)
    t3_prevButton:SetSize(100, 22)
    t3_prevButton:SetText(L["button.prev"])
    t3_prevButton:SetScript("OnClick", function()
        currentMonthOffset = currentMonthOffset + 1
        UpdateOverview()
    end)

    t3_currencyDropdown = CreateFrame("DropdownButton", nil, overviewFrame.t3_scrollFrame, "WowStyle1DropdownTemplate")
    t3_currencyDropdown:SetPoint("TOPRIGHT", overviewFrame, "TOPRIGHT", -10, -70)
    t3_currencyDropdown:SetSize(200, 25)

    t3_currencyDropdown:SetupMenu(function(self, root)
        local function IsSelected(value)
            return value == t3_selectedCurrency
        end

        local function SetSelected(value)
            t3_selectedCurrency = value
            currentMonthOffset = 0
            UpdateAccountOverview()
        end

        local goldButton = root:CreateRadio("Gold", IsSelected, SetSelected, "gold");
        goldButton:AddInitializer(function(button, description, menu)
            local rightTexture = button:AttachTexture()
            rightTexture:SetSize(18, 18)
            rightTexture:SetPoint("RIGHT")
            rightTexture:SetTexture(237618)

            local fontString = button.fontString
            fontString:SetPoint("RIGHT", rightTexture, "LEFT")

            local pad = 20
            local width = pad + fontString:GetUnboundedStringWidth() + rightTexture:GetWidth()
            local height = 20
            return width, height
        end)

        root:CreateDivider()

        for _, categoryKey in ipairs(GCT.CURRENCY_CATEGORY_ORDER) do
            if GCT.CHARACTER_CURRENCIES[categoryKey] then
                local categoryButton = root:CreateButton(L["currency-category." .. categoryKey])

                local sortedList = {}

                for _, currencyID in ipairs(GCT.CHARACTER_CURRENCIES[categoryKey]) do
                    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                    if info then
                        table.insert(sortedList, {id = "c-" .. currencyID, name = info.name, iconFileID = info.iconFileID})
                    else
                         Utils:PrintDebug("Invalid currency ID: " .. tostring(currencyID))
                    end
                end

                table.sort(sortedList, function(a, b)
                    return a.name < b.name
                end)

                for _, entry in ipairs(sortedList) do
                    local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.id);
                    currencyButton:AddInitializer(function(button, description, menu)
                        local rightTexture = button:AttachTexture();
                        rightTexture:SetSize(18, 18);
                        rightTexture:SetPoint("RIGHT");
                        rightTexture:SetTexture(entry.iconFileID);

                        local fontString = button.fontString;
                        fontString:SetPoint("RIGHT", rightTexture, "LEFT");

                        local pad = 20;
                        local width = pad + fontString:GetUnboundedStringWidth() + rightTexture:GetWidth();
                        local height = 20;
                        return width, height;
                    end);
                end
            end
        end
    end)
end

---------------------
--- Main Funtions ---
---------------------

function Overview:Initialize()
    InitializeFrames()
    --InitializeDropdown()
end

function Overview:Show()
    UpdateOverview()

    overviewFrame:Show()
end

function Overview:Hide()
    overviewFrame:Hide()
end

function Overview:IsShown()
    return overviewFrame:IsShown()
end

GCT.overview = Overview
