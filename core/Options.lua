local addonName, GCT = ...

local L = GCT.localization
local Utils = GCT.utils

local Options = {}

---------------------
--- Main funtions ---
---------------------

local minimapProxy = setmetatable({}, {
    __index = function(_, key)
        if key == "minimap-button-hide" then
            return not GCT.data.options["minimap-button-hide"]
        else
            return GCT.data.options[key]
        end
    end,
    __newindex = function(_, key, value)
        if key == "minimap-button-hide" then
            GCT.data.options["minimap-button-hide"] = not value

            if value then
                Utils.minimapButton:Show("GoldCurrencyTracker")
            else
                Utils.minimapButton:Hide("GoldCurrencyTracker")
            end
        elseif key == "minimap-button-position" then
            GCT.data.options["minimap-button-position"] = value

            local zone = {}
            zone.hide = GCT.data.options["minimap-button-hide"]
            zone.minimapPos = GCT.data.options["minimap-button-position"]

            Utils.minimapButton:Refresh("GoldCurrencyTracker", zone)
            Utils.minimapButton:Lock("GoldCurrencyTracker")
        else
            GCT.data.options[key] = value
        end
    end,
})

---------------------
--- Main funtions ---
---------------------

function Options:Initialize()
    local variableTable = GCT.data.options
    local category, layout = Settings.RegisterVerticalLayoutCategory("Gold & Currency Tracker")
    category.ID = "Gold & Currency Tracker"

    local parentSettingMinimapButton

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.general"]))

    do
        local name = L["options.open-on-login.name"]
        local tooltip = L["options.open-on-login.tooltip"]
        local variable = "open-on-login"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. variable, variable, variableTable, Settings.VarType.Boolean, name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = L["options.minimap-button-hide.name"]
        local tooltip = L["options.minimap-button-hide.tooltip"]
        local variable = "minimap-button-hide"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. variable, variable, minimapProxy, Settings.VarType.Boolean, name, not defaultValue)
        parentSettingMinimapButton = Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = L["options.minimap-button-position.name"]
        local tooltip = L["options.minimap-button-position.tooltip"]
        local variable = "minimap-button-position"
        local defaultValue = 250

        local minValue = 0
        local maxValue = 360
        local step = 1

        local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. variable, variable, minimapProxy, Settings.VarType.Number, name, defaultValue)
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)

        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        local subSetting = Settings.CreateSlider(category, setting, options, tooltip)

        subSetting:SetParentInitializer(parentSettingMinimapButton, function() return not GCT.data.options["minimap-button-hide"] end)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.other"]))

    do
        local name = L["options.debug-mode.name"]
        local tooltip = L["options.debug-mode.tooltip"]
        local variable = "debug-mode"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. variable, variable, variableTable, Settings.VarType.Boolean, name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
end

GCT.options = Options