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
    local category, layout = Settings.RegisterVerticalLayoutCategory("Account Gold Tracker")
    category.ID = "Account Gold Tracker"

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["general-options"]))

    do
        local name = L["open-on-login.name"]
        local tooltip = L["open-on-login.tooltip"]
        local variable = "QKywRlN7-open-on-login"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTable, Settings.VarType.Boolean, name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["other-options"]))

    do
        local name = L["debug.name"]
        local tooltip = L["debug.tooltip"]
        local variable = "QKywRlN7-debug"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTable, Settings.VarType.Boolean, name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
end
