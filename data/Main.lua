local addonName, goldAccountTracker = ...

goldAccountTracker.MEDIA_PATH = "Interface\\AddOns\\" .. addonName .. "\\media\\"

goldAccountTracker.currencyGroupOrder = {
    "classic",
    "burningCrusade",
    "wrath",
    "cataclysm",
    "mists",
    "wod",
    "legion",
    "bfa",
    "shadowlands",
    "dragonflight"
}

goldAccountTracker.currencyGroups = {
    classic = { 1792 },
    burningCrusade = { 1191 },
    wrath = { 1900 },
    cataclysm = { 395 },
    mists = { 697 },
    wod = { 994 },
    legion = { 1220 },
    bfa = { 1560 },
    shadowlands = { 1813 },
    dragonflight = { 2003, 2245 },
}

