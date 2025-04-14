local _, goldAccountTracker = ...

local L = goldAccountTracker.localization

function goldAccountTracker:LoadOptions()
    if (not GoldAccountTracker_Options) then
        GoldAccountTracker_Options = {}
    end

    self.options = GoldAccountTracker_Options

    if (not GoldAccountTracker_DataGoldBalance) then
        GoldAccountTracker_DataGoldBalance = {}
    end

    self.goldBalance = GoldAccountTracker_DataGoldBalance

    if (not GoldAccountTracker_DataCurrencyBalance) then
        GoldAccountTracker_DataCurrencyBalance = {}
    end

    self.currencyBalance = GoldAccountTracker_DataCurrencyBalance

    local variableTable = self.options
    local category, layout = Settings.RegisterVerticalLayoutCategory("Gold Account Tracker")
    category.ID = "Gold Account Tracker"

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
