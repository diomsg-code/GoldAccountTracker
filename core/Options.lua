local _, goldCurrencyTracker = ...

local L = goldCurrencyTracker.localization

function goldCurrencyTracker:LoadOptions()
    if (not GoldCurrencyTracker_Options) then
        GoldCurrencyTracker_Options = {}
    end

    self.options = GoldCurrencyTracker_Options

    if (not GoldCurrencyTracker_DataGoldBalance) then
        GoldCurrencyTracker_DataGoldBalance = {}
    end

    self.goldBalance = GoldCurrencyTracker_DataGoldBalance

    if (not GoldCurrencyTracker_DataCurrencyBalance) then
        GoldCurrencyTracker_DataCurrencyBalance = {}
    end

    self.currencyBalance = GoldCurrencyTracker_DataCurrencyBalance

    if (not GoldCurrencyTracker_DataBalance) then
        GoldCurrencyTracker_DataBalance = {}
    end

    self.balance = GoldCurrencyTracker_DataBalance

    local variableTable = self.options
    local category, layout = Settings.RegisterVerticalLayoutCategory("Gold & Currency Tracker")
    category.ID = "Gold & Currency Tracker"

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
