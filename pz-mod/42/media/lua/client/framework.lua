EOPFramework = EOPFramework or {}
EOPFramework.Fosfori = {
    P20          = {0.10, 0.92, 0.12},
    P43          = {0.18, 0.95, 0.22},
    P22          = {0.05, 0.98, 0.08},
    P45          = {0.85, 0.92, 1.00},
    P45C         = {0.35, 0.82, 1.00},
    Amber_Yellow = {0.95, 0.68, 0.12},
    Red_Night    = {0.95, 0.20, 0.10}
}
EOPFramework.Presets = {
    ["GEN_1"] = {
        gain = 2.5, blur = 3.8, noise = 0.38,
        autoGated = 1.0, shadowBoost = 0.15,   -- старый ЭОП: тени еле видны
        color = EOPFramework.Fosfori.P20
    },
    ["GEN_2"] = {
        gain = 3.5, blur = 1.4, noise = 0.18,
        autoGated = 0.0, shadowBoost = 0.35,
        color = EOPFramework.Fosfori.P43
    },
    ["GEN_2_PLUS"] = {
        gain = 3.8, blur = 0.5, noise = 0.09,
        autoGated = 0.0, shadowBoost = 0.45,
        color = EOPFramework.Fosfori.P43
    },
    ["GEN_3_GREEN"] = {
        gain = 5.0, blur = 0.15, noise = 0.04,
        autoGated = 0.0, shadowBoost = 0.55,
        color = EOPFramework.Fosfori.P43
    },
    ["GEN_3_WHITE"] = {
        gain = 5.0, blur = 0.15, noise = 0.04,
        autoGated = 0.0, shadowBoost = 0.55,
        color = EOPFramework.Fosfori.P45
    },
    ["GEN_3_AUTOGATED"] = {
        gain = 6.5, blur = 0.0, noise = 0.01,
        autoGated = 1.0, shadowBoost = 0.70,   -- автогейт + сильный подъём теней
        color = EOPFramework.Fosfori.P45C
    }
}
function EOPFramework.ApplyPresetConfig(config)
    local ShaderBridge = NVGState
    if not ShaderBridge then
        print("[EOP] ERROR: NVGState (ShaderBridge) not found")
        return false
    end
    ShaderBridge.setPreset(
        config.gain,
        config.blur,
        config.noise,
        config.autoGated,
        config.shadowBoost or 0.5,   -- fallback, если старый пресет без shadowBoost
        config.color[1],
        config.color[2],
        config.color[3]
    )
    ShaderBridge.updateUniforms()
    return true
end
function EOPFramework.SetPreset(name)
    local preset = EOPFramework.Presets[name]
    if not preset then
        print("fatlka  preset '" .. tostring(name) .. "' not found")
        return false
    end
    EOPFramework.ApplyPresetConfig(preset)
    EOPFramework.CurrentPreset = name
    return true
end
function EOPFramework.ApplyNVG(item)
    local itemType = item and item:getFullType()
    local config = EOPFramework.ItemMappings and EOPFramework.ItemMappings[itemType]
    if not config then
        config = EOPFramework.Presets["GEN_3_AUTOGATED"]
    end
    EOPFramework.ApplyPresetConfig(config)
end
EOPFramework.ItemMappings = EOPFramework.ItemMappings or {}
function EOPFramework.RegisterItemMapping(fullType, presetName)
    local preset = EOPFramework.Presets[presetName]
    if not preset then
        print("fatalka cannot map '" .. fullType ..
              "' to unknown preset '" .. presetName .. "'")
        return false
    end
    EOPFramework.ItemMappings[fullType] = preset
    return true
end