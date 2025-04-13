local addonName, accountGoldTracker = ...

local L = accountGoldTracker.localization

function accountGoldTracker:LoadOptions()
    if (not AccountGoldTracker_Options) then
        AccountGoldTracker_Options = {}
    end

    self.options = AccountGoldTracker_Options

    if (not AccountGoldTracker_DataGoldBalance) then
        AccountGoldTracker_DataGoldBalance = {}
    end

    self.goldBalance = AccountGoldTracker_DataGoldBalance

    local variableTable = self.options
    local category, layout = Settings.RegisterVerticalLayoutCategory("Gold Account Balance")
    category.ID = "Gold Account Balance"

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["other-options"]))

    do
        local name = L["debug.name"]
        local tooltip = L["debug.tooltip"]
        local variable = "gba-debug"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTable, Settings.VarType.Boolean, name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
end
