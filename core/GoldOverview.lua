local _, goldAccountTracker = ...

local L = goldAccountTracker.localization

local currentMonthOffset = 0

local MONTH_KEYS = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

--------------
--- Frames ---
--------------

local goldOverviewFrame = CreateFrame("Frame", "GoldOverview", UIParent, "ButtonFrameTemplate")
goldOverviewFrame:SetPoint("CENTER")
goldOverviewFrame:SetSize(450, 550)
goldOverviewFrame:SetMovable(true)
goldOverviewFrame:EnableMouse(true)
goldOverviewFrame:RegisterForDrag("LeftButton")
goldOverviewFrame:SetScript("OnDragStart", goldOverviewFrame.StartMoving)
goldOverviewFrame:SetScript("OnDragStop", goldOverviewFrame.StopMovingOrSizing)
goldOverviewFrame:SetTitle("Gold Account Tracker")

goldOverviewFrame:Hide()

goldOverviewFrame.portrait = goldOverviewFrame:GetPortrait()
goldOverviewFrame.portrait:SetPoint('TOPLEFT', -5, 8)
goldOverviewFrame.portrait:SetTexture(goldAccountTracker.MEDIA_PATH .. "iconRound.blp")

goldOverviewFrame.header = goldOverviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
goldOverviewFrame.header:SetPoint("TOP", 0, -40)

goldOverviewFrame.scrollFrame = CreateFrame("ScrollFrame", nil, goldOverviewFrame, "UIPanelScrollFrameTemplate")
goldOverviewFrame.scrollFrame:SetPoint("TOPLEFT", 10, -65)
goldOverviewFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -32, 29)
goldOverviewFrame.scrollFrame:EnableMouseWheel(true)
goldOverviewFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
    self:SetVerticalScroll(newValue)
end)

goldOverviewFrame.scrollFrame.content = CreateFrame("Frame", nil, goldOverviewFrame.scrollFrame)
goldOverviewFrame.scrollFrame.content:SetSize(1, 1)
goldOverviewFrame.scrollFrame:SetScrollChild(goldOverviewFrame.scrollFrame.content)

goldOverviewFrame.nextButton = CreateFrame("Button", nil, goldOverviewFrame, "UIPanelButtonTemplate")
goldOverviewFrame.nextButton:SetPoint("BOTTOM", goldOverviewFrame, "BOTTOMRIGHT", -55, 4)
goldOverviewFrame.nextButton:SetSize(100, 21)
goldOverviewFrame.nextButton:SetText(L["button-next"])
goldOverviewFrame.nextButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset - 1
    goldAccountTracker:UpdateGoldOverview()
end)

goldOverviewFrame.previousButton = CreateFrame("Button", nil, goldOverviewFrame, "UIPanelButtonTemplate")
goldOverviewFrame.previousButton:SetPoint("BOTTOM", goldOverviewFrame, "BOTTOMLEFT", 55, 4)
goldOverviewFrame.previousButton:SetSize(100, 21)
goldOverviewFrame.previousButton:SetText(L["button-previous"])
goldOverviewFrame.previousButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset + 1
    goldAccountTracker:UpdateGoldOverview()
end)

----------------------
--- Local funtions ---
----------------------

local function FormatMonthText(prefix)
    local year, month = strsplit("-", prefix)

    if not month or not year then return prefix end

    local key = MONTH_KEYS[tonumber(month)]
    local name = L[key] or key

    return string.format("%s %s", name, year)
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

local function GetCharacterInfo()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm, name
end

local function FormatThousands(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function FormatGold(copper)
    local gold = floor(copper / (100 * 100))
    local silver = floor((copper / 100) % 100)
    local copper = copper % 100

    return string.format(
        "%s |TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t %02d |TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t %02d |TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t",
        FormatThousands(gold), silver, copper
    )
end

local function FormatGoldDiff(diff)
    local sign = diff > 0 and "+" or diff < 0 and "-" or "±"
    local absVal = math.abs(diff)
    return sign .. " " .. FormatGold(absVal)
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

---------------------
--- Main funtions ---
---------------------

function goldAccountTracker:ShowGoldOverview()
    self:UpdateGoldOverview()
    goldOverviewFrame:Show()
end

function goldAccountTracker:UpdateGoldOverview()
    local realm, name = GetCharacterInfo()
    local data = self.goldBalance and self.goldBalance[realm] and self.goldBalance[realm][name]
    local entries = {}
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    goldOverviewFrame.header:SetText((FormatMonthText(filterPrefix)))

    if goldOverviewFrame.scrollFrame.content.rows then
        for _, row in ipairs(goldOverviewFrame.scrollFrame.content.rows) do
            for _, element in pairs(row) do
                element:Hide()
                element:SetParent(nil)
            end
        end
    end

    goldOverviewFrame.scrollFrame.content.rows = {}

    if data then
        for dateStr, gold in pairs(data) do
            if dateStr:sub(1, 7) == filterPrefix then
                table.insert(entries, {date = dateStr, value = gold})
            end
        end
        table.sort(entries, function(a, b) return a.date > b.date end)
    end

    if #entries == 0 then
        local row = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetPoint("TOPLEFT", 10, -10)
        row:SetText(L["no-entries"])
        table.insert(goldOverviewFrame.scrollFrame.content.rows, {row})
        return
    end

    local previousEntry = FindLastEntryBeforeMonth(data, filterPrefix)

    local offsetY = -10
    local spacing = 6

    local headerDate = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDate:SetPoint("TOPLEFT", 10, offsetY)
    headerDate:SetText(L["date"])

    local headerAmount = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerAmount:SetPoint("TOPLEFT", 100, offsetY)
    headerAmount:SetText(L["amount"])

    local headerDiff = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerDiff:SetPoint("TOPLEFT", 250, offsetY)
    headerDiff:SetText(L["difference"])

    table.insert(goldOverviewFrame.scrollFrame.content.rows, {headerDate, headerAmount, headerDiff})
    offsetY = offsetY - 20

    for i, entry in ipairs(entries) do
        local rowDate = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDate:SetPoint("TOPLEFT", 10, offsetY)
        rowDate:SetText(entry.date)

        local rowAmount = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowAmount:SetPoint("TOPLEFT", 100, offsetY)
        rowAmount:SetText(FormatGold(entry.value))

        local rowDiff = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowDiff:SetPoint("TOPLEFT", 250, offsetY)

        local prev
        if i < #entries then
            prev = entries[i + 1]
        elseif previousEntry then
            prev = previousEntry
        end

        if prev then
            local diff = entry.value - prev.value
            rowDiff:SetText(FormatGoldDiff(diff))
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

        table.insert(goldOverviewFrame.scrollFrame.content.rows, {rowDate, rowAmount, rowDiff})
        offsetY = offsetY - 18 - spacing
    end

    if data then
        local currentPrefix = GetYearMonthString(currentMonthOffset)
        goldOverviewFrame.previousButton:SetEnabled(HasAnyDataBeforeMonth(data, currentPrefix))
        goldOverviewFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(data, currentPrefix))
    else
        goldOverviewFrame.previousButton:SetEnabled(false)
        goldOverviewFrame.nextButton:SetEnabled(false)
    end
end
