EOPFramework = EOPFramework or {}
EOPFramework.Version = "1.1.0"
EOPFramework.Config = EOPFramework.Config or {
    defaultPreset = "GEN_3_AUTOGATED",
    defaultToggleMode = "AUTO",
    defaultEnabled = true,
    debug = true,
    irLight = {
        enabled = false,
        radius = 12,
        intensity = 0.28,
        offset = 1.5,
        color = {0.90, 0.96, 1.00},
        updateInterval = 0.08
    },
    viewCone = {
        enabled = false,
        strength = 0.0,
        inner = 0.0,
        outer = 1.0
    }
}

EOPFramework.Fosfori = EOPFramework.Fosfori or {
    P20          = {0.10, 0.92, 0.12},
    P43          = {0.18, 0.95, 0.22},
    P22          = {0.05, 0.98, 0.08},
    P45          = {0.85, 0.92, 1.00},
    P45C         = {0.35, 0.82, 1.00},
    Amber_Yellow = {0.95, 0.68, 0.12},
    Red_Night    = {0.95, 0.20, 0.10}
}

EOPFramework.Presets = EOPFramework.Presets or {}
EOPFramework.Items = EOPFramework.Items or {
    mappings = {},
    defaultHandlers = {}
}
EOPFramework.Custom = EOPFramework.Custom or {}
EOPFramework.Events = EOPFramework.Events or {
    listeners = {}
}
EOPFramework.State = EOPFramework.State or {
    currentPresetName = "GEN_3_AUTOGATED",
    enabled = false,
    mode = "AUTO",
    viewCone = {
        enabled = false,
        strength = 0.0,
        inner = 0.0,
        outer = 1.0
    },
    irLight = {
        enabled = false,
        lastUpdate = 0.0
    }
}

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function numberOr(value, fallback)
    local v = tonumber(value)
    if v == nil then
        return fallback
    end
    return v
end

local function normalizeColor(color, fallback)
    local fallbackColor = fallback or EOPFramework.Fosfori.P45C
    if type(color) ~= "table" then
        return {
            numberOr(fallbackColor[1], 1.0),
            numberOr(fallbackColor[2], 1.0),
            numberOr(fallbackColor[3], 1.0)
        }
    end
    return {
        numberOr(color[1], fallbackColor[1] or 1.0),
        numberOr(color[2], fallbackColor[2] or 1.0),
        numberOr(color[3], fallbackColor[3] or 1.0)
    }
end

local function log(message)
    if EOPFramework.Config.debug then
        print("[EOPFramework] " .. tostring(message))
    end
end

EOPFramework.Settings = EOPFramework.Settings or {}
EOPFramework.Runtime = EOPFramework.Runtime or {}
EOPFramework.Debug = EOPFramework.Debug or {}

-- Compatibility aliases for older call sites and legacy loader code.
EOPFramework.RegisterPreset = EOPFramework.Settings.RegisterPreset or function(name, values)
    return EOPFramework.Settings.RegisterPreset(name, values)
end
EOPFramework.SetPreset = function(name)
    return EOPFramework.Settings.ApplyPreset(name)
end
EOPFramework.ApplyPresetConfig = function(config)
    if type(config) == "string" then
        return EOPFramework.Settings.ApplyPreset(config)
    end
    return EOPFramework.Runtime.ApplyPreset(config)
end
EOPFramework.Enable = EOPFramework.Runtime.Enable or function()
    return EOPFramework.Runtime.Enable()
end
EOPFramework.Disable = EOPFramework.Runtime.Disable or function()
    return EOPFramework.Runtime.Disable()
end
EOPFramework.Toggle = EOPFramework.Runtime.Toggle or function()
    return EOPFramework.Runtime.Toggle()
end
EOPFramework.SetViewCone = EOPFramework.Runtime.SetViewCone or function(enabled, strength, inner, outer)
    return EOPFramework.Runtime.SetViewCone(enabled, strength, inner, outer)
end
EOPFramework.ApplyByItem = EOPFramework.Runtime.ApplyEquipment or function(item)
    return EOPFramework.Runtime.ApplyEquipment(item)
end
EOPFramework.OnPlayerEquipped = EOPFramework.Runtime.OnPlayerEquipped or function(item)
    return EOPFramework.Runtime.OnPlayerEquipped(item)
end
EOPFramework.OnPlayerUnequipped = EOPFramework.Runtime.OnPlayerUnequipped or function(item)
    return EOPFramework.Runtime.OnPlayerUnequipped(item)
end

function EOPFramework.Settings.RegisterPreset(name, values)
    if type(name) ~= "string" or name == "" then
        return false
    end

    local preset = values or {}
    preset.name = name
    preset.gain = numberOr(preset.gain, 5.0)
    preset.blur = numberOr(preset.blur, 0.2)
    preset.noise = numberOr(preset.noise, 0.05)
    preset.autoGated = numberOr(preset.autoGated, 0.0)
    preset.shadowBoost = numberOr(preset.shadowBoost, 0.5)
    preset.color = normalizeColor(preset.color, EOPFramework.Fosfori.P45C)

    EOPFramework.Presets[name] = preset
    return preset
end

function EOPFramework.Settings.GetPreset(name)
    return EOPFramework.Presets[name]
end

function EOPFramework.Settings.SetPresetValue(name, key, value)
    local preset = EOPFramework.Settings.GetPreset(name)
    if not preset then
        return false
    end

    if key == "color" then
        preset.color = normalizeColor(value, preset.color or EOPFramework.Fosfori.P45C)
        return true
    end

    if key == "gain" or key == "blur" or key == "noise" or key == "autoGated" or key == "shadowBoost" then
        preset[key] = numberOr(value, preset[key] or 0.0)
        return true
    end

    preset[key] = value
    return true
end

function EOPFramework.Settings.ApplyPreset(name)
    local preset = EOPFramework.Settings.GetPreset(name)
    if not preset then
        log("Preset '" .. tostring(name) .. "' not found")
        return false
    end
    return EOPFramework.Runtime.ApplyPreset(preset)
end

function EOPFramework.Settings.GetCurrentPreset()
    return EOPFramework.Settings.GetPreset(EOPFramework.State.currentPresetName)
end

function EOPFramework.Settings.GetEditableFields()
    return {
        { key = "gain", label = "Gain", min = 0.0, max = 20.0, step = 0.1 },
        { key = "blur", label = "Blur", min = 0.0, max = 10.0, step = 0.05 },
        { key = "noise", label = "Noise", min = 0.0, max = 2.0, step = 0.01 },
        { key = "autoGated", label = "Autogate", min = 0.0, max = 1.0, step = 0.05 },
        { key = "shadowBoost", label = "Shadow Boost", min = 0.0, max = 2.0, step = 0.05 },
        { key = "colorR", label = "Phosphor R", min = 0.0, max = 1.0, step = 0.01 },
        { key = "colorG", label = "Phosphor G", min = 0.0, max = 1.0, step = 0.01 },
        { key = "colorB", label = "Phosphor B", min = 0.0, max = 1.0, step = 0.01 },
        { key = "viewConeEnabled", label = "Cone Enabled", min = 0.0, max = 1.0, step = 1.0 },
        { key = "viewConeStrength", label = "Cone Strength", min = 0.0, max = 1.0, step = 0.05 },
        { key = "viewConeInner", label = "Cone Inner", min = 0.0, max = 1.0, step = 0.05 },
        { key = "viewConeOuter", label = "Cone Outer", min = 0.0, max = 1.0, step = 0.05 }
    }
end

function EOPFramework.Runtime.ApplyPreset(preset)
    if not preset then
        log("ApplyPreset called with nil preset")
        return false
    end
    if not NVGState then
        log("NVGState unavailable")
        return false
    end

    local color = normalizeColor(preset.color, EOPFramework.Fosfori.P45C)
    NVGState.setPreset(
        preset.gain or 5.0,
        preset.blur or 0.2,
        preset.noise or 0.05,
        preset.autoGated or 0.0,
        preset.shadowBoost or 0.5,
        color[1],
        color[2],
        color[3]
    )
    NVGState.updateUniforms()

    EOPFramework.State.currentPresetName = preset.name or EOPFramework.State.currentPresetName
    EOPFramework.State.enabled = true
    return true
end

function EOPFramework.Runtime.Enable()
    if not NVGState then
        return false
    end
    NVGState.setEnabled(1.0)
    NVGState.updateUniforms()
    EOPFramework.State.enabled = true
    return true
end

function EOPFramework.Runtime.Disable()
    if not NVGState then
        return false
    end
    NVGState.setEnabled(0.0)
    NVGState.updateUniforms()
    EOPFramework.State.enabled = false
    return true
end

function EOPFramework.Runtime.Toggle()
    if EOPFramework.State.enabled then
        return EOPFramework.Runtime.Disable()
    end
    return EOPFramework.Runtime.Enable()
end

function EOPFramework.Runtime.SetViewCone(enabled, strength, inner, outer)
    EOPFramework.State.viewCone = {
        enabled = enabled == true,
        strength = numberOr(strength, EOPFramework.State.viewCone.strength or 0.0),
        inner = numberOr(inner, EOPFramework.State.viewCone.inner or 0.0),
        outer = numberOr(outer, EOPFramework.State.viewCone.outer or 1.0)
    }
    if NVGState then
        NVGState.setViewCone(
            enabled and 1.0 or 0.0,
            EOPFramework.State.viewCone.strength,
            EOPFramework.State.viewCone.inner,
            EOPFramework.State.viewCone.outer
        )
        NVGState.updateUniforms()
    end
    return EOPFramework.State.viewCone
end

function EOPFramework.Runtime.SetIRLight(enabled, radius, intensity, color)
    local ir = EOPFramework.State.irLight
    ir.enabled = enabled == true
    ir.radius = math.max(1, math.min(20, tonumber(radius) or EOPFramework.Config.irLight.radius))
    ir.intensity = math.max(0.0, math.min(0.5, tonumber(intensity) or EOPFramework.Config.irLight.intensity))
    ir.color = normalizeColor(color, EOPFramework.Config.irLight.color)

    if not ir.enabled and IRLightBridge then
        IRLightBridge.removeLocalLight()
    end

    return ir
end

function EOPFramework.Runtime.ToggleIRLight()
    local ir = EOPFramework.State.irLight
    return EOPFramework.Runtime.SetIRLight(
        not ir.enabled,
        ir.radius,
        ir.intensity,
        ir.color
    )
end

function EOPFramework.Runtime.UpdateIRLight(player, force)
    local ir = EOPFramework.State.irLight
    if not ir.enabled or not player or not IRLightBridge then
        return false
    end

    local now = getTimestampMs and getTimestampMs() / 1000.0 or 0.0
    if not force and now > 0.0 and now - ir.lastUpdate < EOPFramework.Config.irLight.updateInterval then
        return false
    end

    local directionX = player:getForwardDirectionX()
    local directionY = player:getForwardDirectionY()
    local color = ir.color or EOPFramework.Config.irLight.color
    IRLightBridge.setLocalLight(
        player:getX(),
        player:getY(),
        player:getZ(),
        directionX,
        directionY,
        ir.radius,
        ir.intensity,
        color[1],
        color[2],
        color[3]
    )
    ir.lastUpdate = now
    return true
end

function EOPFramework.Runtime.ApplyEquipment(item)
    if not item then
        return false
    end

    local itemType = item:getFullType()
    local mapping = EOPFramework.Items.mappings[itemType]
    local presetName = (mapping and mapping.presetName) or EOPFramework.Config.defaultPreset
    local preset = EOPFramework.Presets[presetName]

    if not preset then
        log("No preset found for item '" .. tostring(itemType) .. "'")
        return false
    end

    if mapping and mapping.mode == "OFF" then
        return false
    end

    if mapping and mapping.mode == "CUSTOM" and mapping.custom then
        local handler = EOPFramework.Custom[mapping.custom]
        if not handler then
            log("Custom handler '" .. tostring(mapping.custom) .. "' not found")
            return false
        end
        return handler(item, preset)
    end

    return EOPFramework.Runtime.ApplyPreset(preset)
end

function EOPFramework.Runtime.OnPlayerEquipped(item)
    return EOPFramework.Runtime.ApplyEquipment(item)
end

function EOPFramework.Runtime.OnPlayerUnequipped(item)
    return EOPFramework.Runtime.Disable()
end

function EOPFramework.RegisterCustom(name, callback)
    if type(name) ~= "string" or type(callback) ~= "function" then
        return false
    end
    EOPFramework.Custom[name] = callback
    return true
end

function EOPFramework.RegisterItemMapping(fullType, presetName, options)
    local preset = EOPFramework.Presets[presetName]
    if not preset then
        log("Cannot map '" .. tostring(fullType) .. "' to unknown preset '" .. tostring(presetName) .. "'")
        return false
    end

    local mode = (options and options.mode) or EOPFramework.Config.defaultToggleMode
    EOPFramework.Items.mappings[fullType] = {
        fullType = fullType,
        presetName = presetName,
        mode = mode,
        custom = (options and options.custom) or nil,
        toggle = (options and options.toggle) or "DEFAULT"
    }
    return true
end

function EOPFramework.RegisterVanillaDefault(itemType, presetName, mode, custom)
    return EOPFramework.RegisterItemMapping(itemType, presetName, {
        mode = mode or EOPFramework.Config.defaultToggleMode,
        custom = custom,
        toggle = "DEFAULT"
    })
end

function EOPFramework.Init()
    if not NVGState then
        log("NVGState missing")
        return false
    end

    local defaultPreset = EOPFramework.Presets[EOPFramework.Config.defaultPreset]
    if defaultPreset then
        EOPFramework.Runtime.ApplyPreset(defaultPreset)
    end

    if EOPFramework.Config.defaultEnabled then
        EOPFramework.Runtime.Enable()
    else
        EOPFramework.Runtime.Disable()
    end

    return true
end

EOPFramework.RegisterPreset("GEN_1", {
    gain = 2.5, blur = 3.8, noise = 0.38,
    autoGated = 1.0, shadowBoost = 0.15,
    color = EOPFramework.Fosfori.P20
})
EOPFramework.RegisterPreset("GEN_2", {
    gain = 3.5, blur = 1.4, noise = 0.18,
    autoGated = 0.0, shadowBoost = 0.35,
    color = EOPFramework.Fosfori.P43
})
EOPFramework.RegisterPreset("GEN_2_PLUS", {
    gain = 3.8, blur = 0.5, noise = 0.09,
    autoGated = 0.0, shadowBoost = 0.45,
    color = EOPFramework.Fosfori.P43
})
EOPFramework.RegisterPreset("GEN_3_GREEN", {
    gain = 5.0, blur = 0.15, noise = 0.04,
    autoGated = 0.0, shadowBoost = 0.55,
    color = EOPFramework.Fosfori.P43
})
EOPFramework.RegisterPreset("GEN_3_WHITE", {
    gain = 5.0, blur = 0.15, noise = 0.04,
    autoGated = 0.0, shadowBoost = 0.55,
    color = EOPFramework.Fosfori.P45
})
EOPFramework.RegisterPreset("GEN_3_AUTOGATED", {
    gain = 6.5, blur = 0.0, noise = 0.01,
    autoGated = 1.0, shadowBoost = 0.70,
    color = EOPFramework.Fosfori.P45C
})

EOPFramework.RegisterCustom("HeadgearToggle", function(item, preset)
    EOPFramework.Runtime.ApplyPreset(preset)
    EOPFramework.Runtime.Enable()
    EOPFramework.Runtime.SetViewCone(true, 0.35, 0.10, 0.85)
    EOPFramework.Runtime.SetIRLight(false)
    return true
end)

EOPFramework.RegisterCustom("ViewConeBoost", function(item, preset)
    EOPFramework.Runtime.ApplyPreset(preset)
    EOPFramework.Runtime.SetViewCone(true, 0.65, 0.15, 0.90)
    EOPFramework.Runtime.SetIRLight(false)
    EOPFramework.Runtime.Enable()
    return true
end)

EOPFramework.RegisterCustom("MenuToggle", function(item, preset)
    EOPFramework.Runtime.ApplyPreset(preset)
    EOPFramework.Runtime.Toggle()
    return true
end)

EOPFramework.RegisterVanillaDefault("Base.NVG", "GEN_3_AUTOGATED", "AUTO", "HeadgearToggle")
EOPFramework.RegisterVanillaDefault("Base.Hat", "GEN_2_PLUS", "AUTO", "ViewConeBoost")
EOPFramework.RegisterVanillaDefault("Base.Glasses", "GEN_3_GREEN", "AUTO")

Events.OnPlayerUpdate.Add(function(player)
    if player == getPlayer() then
        EOPFramework.Runtime.UpdateIRLight(player, false)
    end
end)

return EOPFramework