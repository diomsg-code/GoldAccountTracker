local _, accountGoldTracker = ...

local L = accountGoldTracker.localization

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
goldOverviewFrame:SetSize(400, 500)
goldOverviewFrame:SetMovable(true)
goldOverviewFrame:EnableMouse(true)
goldOverviewFrame:RegisterForDrag("LeftButton")
goldOverviewFrame:SetScript("OnDragStart", goldOverviewFrame.StartMoving)
goldOverviewFrame:SetScript("OnDragStop", goldOverviewFrame.StopMovingOrSizing)
goldOverviewFrame:SetTitle("Account Gold Tracker")

goldOverviewFrame:Hide()

goldOverviewFrame.portrait = goldOverviewFrame:GetPortrait()
goldOverviewFrame.portrait:SetPoint('TOPLEFT', -5, 8)
goldOverviewFrame.portrait:SetTexture(accountGoldTracker.MEDIA_PATH .. "iconRound.blp")

goldOverviewFrame.header = goldOverviewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
goldOverviewFrame.header:SetPoint("TOP", 0, -40)
goldOverviewFrame.header:SetText("???")

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

goldOverviewFrame.closeButton = CreateFrame("Button", nil, goldOverviewFrame, "UIPanelButtonTemplate")
goldOverviewFrame.closeButton:SetPoint("BOTTOM", goldOverviewFrame, "BOTTOMRIGHT", -55, 4)
goldOverviewFrame.closeButton:SetSize(100, 21)
goldOverviewFrame.closeButton:SetText(L["button-next"])
goldOverviewFrame.closeButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset - 1
    accountGoldTracker:UpdateGoldOverview()
end)

goldOverviewFrame.closeButton = CreateFrame("Button", nil, goldOverviewFrame, "UIPanelButtonTemplate")
goldOverviewFrame.closeButton:SetPoint("BOTTOM", goldOverviewFrame, "BOTTOMLEFT", 55, 4)
goldOverviewFrame.closeButton:SetSize(100, 21)
goldOverviewFrame.closeButton:SetText(L["button-previous"])
goldOverviewFrame.closeButton:SetScript("OnClick", function()
    currentMonthOffset = currentMonthOffset + 1
    accountGoldTracker:UpdateGoldOverview()
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
        "%s|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t %02d|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t %02d|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t",
        FormatThousands(gold), silver, copper
    )
end

---------------------
--- Main funtions ---
---------------------

function accountGoldTracker:ShowGoldOverview()
    self:UpdateGoldOverview()
    goldOverviewFrame:Show()
end

function accountGoldTracker:UpdateGoldOverview()
    local realm, name = GetCharacterInfo()
    local data = self.goldBalance and self.goldBalance[realm] and self.goldBalance[realm][name]
    local entries = {}
    local filterPrefix = GetYearMonthString(currentMonthOffset)

    goldOverviewFrame.header:SetText((FormatMonthText(filterPrefix)))

    if goldOverviewFrame.scrollFrame.content.rows then
        for _, row in ipairs(goldOverviewFrame.scrollFrame.content.rows) do
            row:Hide()
            row:SetParent(nil)
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
        table.insert(goldOverviewFrame.scrollFrame.content.rows, row)
        return
    end

    local offsetY = -10
    local spacing = 6

    for i, entry in ipairs(entries) do
        local row = goldOverviewFrame.scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetPoint("TOPLEFT", 10, offsetY)
        row:SetWidth(400)
        row:SetJustifyH("LEFT")
        row:SetText(entry.date .. ":  " .. FormatGold(entry.value))

        offsetY = offsetY - row:GetStringHeight() - math.abs(spacing)
        table.insert(goldOverviewFrame.scrollFrame.content.rows, row)
    end
end