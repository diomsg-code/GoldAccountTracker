local _, GCT = ...

local L =  GCT.localization
local Utils = GCT.utils

local Overview = {}

local currentMonthOffset = {}
local selectedCurrency = {}
selectedCurrency[1] = "gold"
selectedCurrency[2] = "w-2032"
selectedCurrency[3] = "gold"
local selectedRealm, selectedChar = Utils:GetCharacterInfo()

--------------
--- Frames ---
--------------

local overviewFrame
local contentFrames = {}

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
    local temp = {}
    local entries = {}

    for realm, realmData in pairs(GCT.data.balance) do
        if realm ~= "Warband" then
            for char, _ in pairs(realmData) do
                local characterHistory = BuildCharacterHistoryLookup(realm, char, currencyKey)

                table.insert(temp, {id = realm .. "-" .. char ,characterHistory = characterHistory})
            end
        end
    end

    for _, date in ipairs(dates) do
        local value = 0
        local hasValue = false

        for _, characterHistory in ipairs(temp) do
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

local function UpdateOverview(selectedCurrency, currentMonthOffset, history, contentFrame)
    local filterPrefix = GetYearMonthString(currentMonthOffset)
    local monthHistory = BuildMonthHistory(history, filterPrefix)

    if contentFrame.rows then
        for _, row in ipairs(contentFrame.rows) do
            for _, element in ipairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    contentFrame.rows = {}

    local header = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOP", 0, -40)
    header:SetText(FormatMonthText(filterPrefix))
    table.insert(contentFrame.rows, {header})

    if #monthHistory == 0 then
        local noEntry = contentFrame.scrollFrame.scrollView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noEntry:SetPoint("TOPLEFT", 15, -10)
        noEntry:SetText(L["table.no-entries"])
        table.insert(contentFrame.rows, {noEntry})
        return
    end

    local offsetY = -10
    local spacing = 10

    local headerDate = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 15, offsetY)
    headerDate:SetText(L["table.date"])

    local headerAmount  = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["table.amount"])

    local headerDifference = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontNormal")
    headerDifference:SetPoint("TOPLEFT", 250, offsetY)
    headerDifference:SetText(L["table.difference"])

    table.insert(contentFrame.rows, {headerDate, headerAmount, headerDifference})

    offsetY = offsetY - 20

    for i, entry in ipairs(monthHistory) do
        local dateStr = entry.date
        local currentValue = entry.value

        local prevValue
        if i < #monthHistory then
            prevValue = monthHistory[i+1].value
        else
            prevValue = GetPreviousValueFromHistory(history, dateStr) or 0
        end

        local rowDate = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 15, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatCurrency(currentValue, selectedCurrency))

        local rowDifference = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rowDifference:SetPoint("TOPLEFT", 250, offsetY)

        local firstDate = history[1].date

        if entry.date ~= firstDate then
            local diff = currentValue - prevValue
            rowDifference:SetText(FormatCurrencyDiff(diff, selectedCurrency))
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

        table.insert(contentFrame.rows, {rowDate, rowAmount, rowDifference})
        offsetY = offsetY - rowDate:GetHeight() - spacing
    end

    local lastLine = contentFrame.scrollFrame.scrollView:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    lastLine:SetPoint("TOPLEFT", 10, offsetY)

    table.insert(contentFrame.rows, {lastLine})

    contentFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(history, filterPrefix))
    contentFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(history, filterPrefix))
end

local function UpdateCharacterOverview()
    local characterHistory = BuildCharacterHistory(selectedRealm, selectedChar, selectedCurrency[1])

    UpdateOverview(selectedCurrency[1], currentMonthOffset[1], characterHistory, contentFrames[1])
end

local function UpdateWarbandOverview()
    local warbandHistory = BuildWarbandHistory(selectedCurrency[2])

    UpdateOverview(selectedCurrency[2], currentMonthOffset[2], warbandHistory, contentFrames[2])
end

local function UpdateAccountOverview()
    local accountHistory = BuildAccountHistory(selectedCurrency[3])

    UpdateOverview(selectedCurrency[3], currentMonthOffset[3], accountHistory, contentFrames[3])
end

local function InitializeFrames()
    local tabs = {}

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
    tinsert(UISpecialFrames, overviewFrame:GetName())

    local portrait = overviewFrame:GetPortrait()
    portrait:SetPoint('TOPLEFT', -5, 8)
    portrait:SetTexture(GCT.MEDIA_PATH .. "iconRound.blp")

    local background = CreateFrame("Frame", nil, overviewFrame, "AccountStoreInsetFrameTemplate")
    background:SetSize(440, 415)
    background:SetPoint("TOPLEFT", overviewFrame, "TOPLEFT", 5, -100)

    local function ShowTab(i)
        PanelTemplates_SetTab(overviewFrame, i)
        for idx, c in ipairs(contentFrames) do
            if idx == i then c:Show() else c:Hide() end
        end
    end

    for i = 1, 3 do
        local tab = CreateFrame("Button", nil, overviewFrame, "PanelTabButtonTemplate")
        tab:SetID(i)

        currentMonthOffset[i] = 0

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

        local contentFrame = CreateFrame("Frame", nil, overviewFrame)
        contentFrame:SetPoint("TOPLEFT", 0, 0)
        contentFrame:SetSize(450, 550)
        if i ~= 1 then contentFrame:Hide() end

        contentFrame.scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "QuestScrollFrameTemplate")
        contentFrame.scrollFrame:SetPoint("TOPLEFT", 5, -104)
        contentFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -32, 37)
        contentFrame.scrollFrame:EnableMouseWheel(true)
        contentFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
            self:SetVerticalScroll(newValue)
        end)

        contentFrame.scrollFrame.scrollView = CreateFrame("Frame", nil, contentFrame.scrollFrame)
        contentFrame.scrollFrame.scrollView:SetSize(200, 200)
        contentFrame.scrollFrame:SetScrollChild(contentFrame.scrollFrame.scrollView)

        contentFrame.nextButton = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
        contentFrame.nextButton:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -10, 8)
        contentFrame.nextButton:SetSize(100, 22)
        contentFrame.nextButton:SetText(L["button.next"])
        contentFrame.nextButton:SetScript("OnClick", function()
            currentMonthOffset[i] = currentMonthOffset[i] - 1

            if i == 1 then
                UpdateCharacterOverview()
            elseif i == 2 then
                UpdateWarbandOverview()
            else
                UpdateAccountOverview()
            end
        end)

        contentFrame.prevButton = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
        contentFrame.prevButton:SetPoint("BOTTOMLEFT", contentFrame, "BOTTOMLEFT", 10, 8)
        contentFrame.prevButton:SetSize(100, 22)
        contentFrame.prevButton:SetText(L["button.prev"])
        contentFrame.prevButton:SetScript("OnClick", function()
            currentMonthOffset[i] = currentMonthOffset[i] + 1

            if i == 1 then
                UpdateCharacterOverview()
            elseif i == 2 then
                UpdateWarbandOverview()
            else
                UpdateAccountOverview()
            end
        end)

        local currencyDropdown = CreateFrame("DropdownButton", nil, contentFrame, "WowStyle1DropdownTemplate")
        currencyDropdown:SetPoint("TOPRIGHT", overviewFrame, "TOPRIGHT", -10, -70)
        currencyDropdown:SetSize(200, 25)

        if i == 1 or i == 3 then
            currencyDropdown:SetupMenu(function(self, root)
                local function IsSelected(value)
                    return value == selectedCurrency[i]
                end

                local function SetSelected(value)
                    selectedCurrency[i] = value
                    currentMonthOffset[i] = 0
                    if i == 1 then
                        UpdateCharacterOverview()
                    else
                        UpdateAccountOverview()
                    end
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
        else
            currencyDropdown:SetupMenu(function(self, root)
                local function IsSelected(value)
                    return value == selectedCurrency[i]
                end

                local function SetSelected(value)
                    selectedCurrency[i] = value
                    currentMonthOffset[i] = 0
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
        end

        if i == 1 then
            local characterDropdown = CreateFrame("DropdownButton", nil, contentFrame, "WowStyle1DropdownTemplate")
            characterDropdown:SetPoint("TOPLEFT", overviewFrame, "TOPLEFT", 10, -70)
            characterDropdown:SetSize(125, 25)

            characterDropdown:SetupMenu(function(self, root)
                local function IsSelected(value)
                    return value == selectedRealm .. "-" .. selectedChar
                end

                local function SetSelected(value)
                    local pos = value:find("-", 1, true)
                    selectedRealm = value:sub(1, pos - 1)
                    selectedChar = value:sub(pos + 1)
                    currentMonthOffset[i] = 0
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
        end

        contentFrames[i] = contentFrame
    end

    PanelTemplates_SetNumTabs(overviewFrame, 3)
    tabs[1]:SetPoint("TOPLEFT", overviewFrame, "BOTTOMLEFT", 10, 2)
    tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", -15, 0)
    tabs[3]:SetPoint("LEFT", tabs[2], "RIGHT", -15, 0)
    PanelTemplates_SetTab(overviewFrame, 1)
end

---------------------
--- Main Funtions ---
---------------------

function Overview:Initialize()
    InitializeFrames()
end

function Overview:Show()
    UpdateCharacterOverview()
    UpdateWarbandOverview()
    UpdateAccountOverview()

    overviewFrame:Show()
end

function Overview:Hide()
    overviewFrame:Hide()
end

function Overview:IsShown()
    return overviewFrame:IsShown()
end

GCT.overview = Overview
