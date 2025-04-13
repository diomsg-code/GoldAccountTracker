local addonName, accountGoldTracker = ...

local L = accountGoldTracker.localization

accountGoldTracker.goldBalance = GoldAccountBalance_DataGoldBalance

----------------------
--- Local funtions ---
----------------------

local function GetToday()
    return date("%Y-%m-%d")
end

local function GetGold()
    return GetMoney()
end

local function GetCharacterInfo()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm, name
end

local function SaveGold()
    local realm, name = GetCharacterInfo()
    local today = GetToday()
    local gold = GetGold()

    accountGoldTracker.goldBalance = accountGoldTracker.goldBalance or {}
    accountGoldTracker.goldBalance[realm] = accountGoldTracker.goldBalance[realm] or {}
    accountGoldTracker.goldBalance[realm][name] = accountGoldTracker.goldBalance[realm][name] or {}
    accountGoldTracker.goldBalance[realm][name][today] = gold

    accountGoldTracker:PrintDebug("Gold balance saved.")
end

local function FormatGold(copper)
    local gold = floor(copper / (100 * 100))
    local silver = floor((copper / 100) % 100)
    local copper = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

local historyFrame = nil
-- UI: Create History Window
local function CreateHistoryWindow()
    if historyFrame then
        historyFrame:Show()
        return
    end

    historyFrame = CreateFrame("Frame", "GoldTrackerHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
    historyFrame:SetSize(300, 400)
    historyFrame:SetPoint("CENTER")
    historyFrame:SetMovable(true)
    historyFrame:EnableMouse(true)
    historyFrame:RegisterForDrag("LeftButton")
    historyFrame:SetScript("OnDragStart", historyFrame.StartMoving)
    historyFrame:SetScript("OnDragStop", historyFrame.StopMovingOrSizing)

    historyFrame.title = historyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    historyFrame.title:SetPoint("CENTER", historyFrame.TitleBg, "CENTER", 0, 0)
    historyFrame.title:SetText("Gold Verlauf")

    historyFrame.scrollFrame = CreateFrame("ScrollFrame", nil, historyFrame, "UIPanelScrollFrameTemplate")
    historyFrame.scrollFrame:SetPoint("TOPLEFT", 10, -30)
    historyFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    historyFrame.content = CreateFrame("Frame", nil, historyFrame.scrollFrame)
    historyFrame.scrollFrame:SetScrollChild(historyFrame.content)
    historyFrame.content:SetSize(1, 1)

    historyFrame.content.text = historyFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    historyFrame.content.text:SetJustifyH("LEFT")
    historyFrame.content.text:SetPoint("TOPLEFT")
    historyFrame.content.text:SetWidth(240)

    local realm, name = GetCharacterInfo()
    local data = accountGoldTracker.goldBalance and accountGoldTracker.goldBalance[realm] and accountGoldTracker.goldBalance[realm][name]
    local lines = {}

    if data then
        for dateStr, gold in pairs(data) do
            table.insert(lines, string.format("%s: %s", dateStr, FormatGold(gold)))
        end
        table.sort(lines) -- sort by date
    else
        table.insert(lines, "Keine Daten verfügbar.")
    end

    historyFrame.content.text:SetText(table.concat(lines, "\n"))
end



local function SlashCommand(msg, editbox)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("Gold Account Balance")
    elseif msg:trim() == "overview" then
        CreateHistoryWindow()
	else
        accountGoldTracker:PrintDebug("These arguments are not accepted.")
	end
end
--------------
--- Frames ---
--------------

local accountGoldTrackerFrame = CreateFrame("Frame", "GoldAccountBalance")

---------------------
--- Main funtions ---
---------------------



function accountGoldTrackerFrame:OnEvent(event, ...)
	self[event](self, event, ...)
end

function accountGoldTrackerFrame:ADDON_LOADED(_, addOnName)
    if addOnName == addonName then
        accountGoldTracker:LoadOptions()
        accountGoldTracker:PrintDebug("Addon fully loaded.")
    end
end

function accountGoldTrackerFrame:PLAYER_ENTERING_WORLD(...)
    accountGoldTracker:PrintDebug("Event 'PLAYER_ENTERING_WORLD' fired.")
    SaveGold()
end

function accountGoldTrackerFrame:PLAYER_MONEY(...)
    accountGoldTracker:PrintDebug("Event 'PLAYER_MONEY' fired.")
    SaveGold()
end

accountGoldTrackerFrame:RegisterEvent("ADDON_LOADED")
accountGoldTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
accountGoldTrackerFrame:RegisterEvent("PLAYER_MONEY")
accountGoldTrackerFrame:SetScript("OnEvent", accountGoldTrackerFrame.OnEvent)

SLASH_GoldAccountBalance1, SLASH_GoldAccountBalance2 = '/agt', '/AccountGoldTracker'

SlashCmdList["AccountGoldTracker"] = SlashCommand