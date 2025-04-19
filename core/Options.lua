local _, GCT = ...

local L = GCT.localization

local Options = {}

---------------------
--- Main funtions ---
---------------------

function Options:LoadOptions()
    local variableTable = GCT.data.options
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

GCT.options = Options