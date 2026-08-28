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
        autoGated = 1.0, shadowBoost = 0.15,
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
        autoGated = 1.0, shadowBoost = 0.70,
        color = EOPFramework.Fosfori.P45C
    }
}
function EOPFramework.ApplyPresetConfig(config)
    if not NVGState then
        print("ERROR fatalka 502")
        return false
    end
    NVGState.setPreset(
        config.gain,
        config.blur,
        config.noise,
        config.autoGated,
        config.shadowBoost or 0.5,
        config.color[1],
        config.color[2],
        config.color[3]
    )
    NVGState.updateUniforms()
    return true
end
function EOPFramework.SetPreset(name)
    local preset = EOPFramework.Presets[name]
    if not preset then
        print("ERROR fatalka 401'" .. tostring(name) .. "' не найдено")
        return false
    end
    EOPFramework.ApplyPresetConfig(preset)
    EOPFramework.CurrentPreset = name
    return true
end
EOPFramework.ItemMappings = EOPFramework.ItemMappings or {}
function EOPFramework.RegisterItemMapping(fullType, presetName)
    local preset = EOPFramework.Presets[presetName]
    if not preset then
        print("fatalka cannot map '" .. tostring(fullType) ..
              "' to unknown preset '" .. tostring(presetName) .. "'")
        return false
    end
    EOPFramework.ItemMappings[fullType] = preset
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

NVGDebug = NVGDebug or {}
NVGDebug.Active = true
NVGDebug.NVGOn = true
NVGDebug.Index = 1
NVGDebug.NeedsUpdate = true
NVGDebug.PresetNames = {}
for k, _ in pairs(EOPFramework.Presets) do
    table.insert(NVGDebug.PresetNames, k)
end
table.sort(NVGDebug.PresetNames)
function NVGDebug.ApplyShaderUniforms()
    if not NVGState then
        print("fatalka  nvgstate not exposed yet")
        return
    end
    local presetName = NVGDebug.PresetNames[NVGDebug.Index]
    local preset = EOPFramework.Presets[presetName]
    if not preset then
        print("fatalka preset not found for index " .. tostring(NVGDebug.Index))
        return
    end
    EOPFramework.ApplyPresetConfig(preset)
    NVGState.setEnabled(NVGDebug.NVGOn and 1.0 or 0.0)
    NVGState.updateUniforms()
    NVGDebug.NeedsUpdate = false
end

local function OnKeyPressed(key)
    if key == 67 then
        NVGDebug.Active = not NVGDebug.Active
        return
    end
    if key == 74 then
        NVGDebug.NVGOn = not NVGDebug.NVGOn
        NVGDebug.NeedsUpdate = true
        return
    end
    if not NVGDebug.Active then return end
    if key == 203 then
        NVGDebug.Index = NVGDebug.Index - 1
        if NVGDebug.Index < 1 then NVGDebug.Index = #NVGDebug.PresetNames end
        NVGDebug.NeedsUpdate = true
    elseif key == 205 then
        NVGDebug.Index = NVGDebug.Index + 1
        if NVGDebug.Index > #NVGDebug.PresetNames then NVGDebug.Index = 1 end
        NVGDebug.NeedsUpdate = true
    end
end
local function OnPostRender()
    if NVGDebug.NeedsUpdate then
        NVGDebug.ApplyShaderUniforms()
    end
    if not NVGDebug.Active then return end
    local tm = getTextManager()
    if not tm then return end
    local presetName = NVGDebug.PresetNames[NVGDebug.Index]
    local p = EOPFramework.Presets[presetName]
    if not p then return end
    local x, y, h = 20, 250, 20
    local font = UIFont.Small
    tm:DrawString(font, x, y + h,
        string.format("preset [%d/%d]: %s", NVGDebug.Index, #NVGDebug.PresetNames, presetName),
        0.2, 1.0, 0.2, 1.0)
    tm:DrawString(font, x, y + h*2,
        string.format("Gain: %.2f | Blur: %.2f | Noise: %.2f", p.gain, p.blur, p.noise),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h*3,
        string.format("Autogate: %.1f | ShadowBoost: %.2f", p.autoGated, p.shadowBoost or 0.5),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h*4,
        string.format("Phosphor RGB: %.2f, %.2f, %.2f", p.color[1], p.color[2], p.color[3]),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h*5,
        "effect: " .. (NVGDebug.NVGOn and "ON" or "OFF"),
        1.0, 0.8, 0.0, 1.0)
end
Events.OnKeyPressed.Add(OnKeyPressed)
Events.OnPostRender.Add(OnPostRender)

print("KRUTO!! debugger loaded, " .. #NVGDebug.PresetNames .. " presets")
