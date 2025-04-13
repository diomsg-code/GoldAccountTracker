local addonName, accountGoldTracker = ...

local L = accountGoldTracker.localization

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

local function SlashCommand(msg, editbox)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("Account Gold Tracker")
    elseif msg:trim() == "overview" then
        accountGoldTracker:ShowGoldOverview()
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

    if accountGoldTracker.options["QKywRlN7-open-on-login"] then
        accountGoldTracker:ShowGoldOverview()
    end
end

function accountGoldTrackerFrame:PLAYER_MONEY(...)
    accountGoldTracker:PrintDebug("Event 'PLAYER_MONEY' fired.")
    SaveGold()
end

accountGoldTrackerFrame:RegisterEvent("ADDON_LOADED")
accountGoldTrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
accountGoldTrackerFrame:RegisterEvent("PLAYER_MONEY")
accountGoldTrackerFrame:SetScript("OnEvent", accountGoldTrackerFrame.OnEvent)

SLASH_AccountGoldTracker1, SLASH_AccountGoldTracker2 = '/agt', '/AccountGoldTracker'

SlashCmdList["AccountGoldTracker"] = SlashCommand