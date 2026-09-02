EOPFramework = EOPFramework or {}
EOPFramework.Config = EOPFramework.Config or {
    defaultPreset = "GEN_3_AUTOGATED",
    defaultToggleMode = "AUTO",
    debug = true
}
NVGDebug = NVGDebug or {}
NVGDebug.Active = true
NVGDebug.PanelVisible = true
NVGDebug.NVGOn = true
NVGDebug.Index = 1
NVGDebug.FieldIndex = 1
NVGDebug.Initialized = false
NVGDebug.PresetNames = {}
local function refreshPresetList()
    NVGDebug.PresetNames = {}
    for k, _ in pairs(EOPFramework.Presets or {}) do
        table.insert(NVGDebug.PresetNames, k)
    end
    table.sort(NVGDebug.PresetNames)
    if #NVGDebug.PresetNames == 0 then
        NVGDebug.Index = 1
    elseif NVGDebug.Index > #NVGDebug.PresetNames then
        NVGDebug.Index = 1
    end
end
local function getFieldConfig()
    return {
        { key = "gain", label = "Gain", min = 0.0, max = 20.0, step = 0.1 },
        { key = "blur", label = "Blur", min = 0.0, max = 10.0, step = 0.05 },
        { key = "noise", label = "Noise", min = 0.0, max = 2.0, step = 0.01 },
        { key = "autoGated", label = "AutoGated", min = 0.0, max = 1.0, step = 0.05 },
        { key = "shadowBoost", label = "ShadowBoost", min = 0.0, max = 2.0, step = 0.05 },
        { key = "colorR", label = "Phosphor R", min = 0.0, max = 1.0, step = 0.01 },
        { key = "colorG", label = "Phosphor G", min = 0.0, max = 1.0, step = 0.01 },
        { key = "colorB", label = "Phosphor B", min = 0.0, max = 1.0, step = 0.01 },
        { key = "viewConeEnabled", label = "Cone Enabled", min = 0.0, max = 1.0, step = 1.0 },
        { key = "viewConeStrength", label = "Cone Strength", min = 0.0, max = 1.0, step = 0.05 },
        { key = "viewConeInner", label = "Cone Inner", min = 0.0, max = 1.0, step = 0.05 },
        { key = "viewConeOuter", label = "Cone Outer", min = 0.0, max = 1.0, step = 0.05 }
    }
end
local function getSelectedPreset()
    refreshPresetList()
    local presetName = NVGDebug.PresetNames[NVGDebug.Index]
    if not presetName then
        return nil
    end
    return EOPFramework.Presets[presetName]
end
local function applyCurrentPresetFromDebug()
    local preset = getSelectedPreset()
    if not preset then
        return false
    end
    return EOPFramework.Runtime.ApplyPreset(preset)
end
local function isKey(key, ...)
    for index = 1, select("#", ...) do
        if key == select(index, ...) then
            return true
        end
    end
    return false
end
local function setCurrentFieldValue(delta)
    local preset = getSelectedPreset()
    if not preset then
        return false
    end
    local fields = getFieldConfig()
    local field = fields[NVGDebug.FieldIndex]
    if not field then
        return false
    end
    if field.key == "gain" then
        preset.gain = math.max(0.0, preset.gain + delta * field.step)
    elseif field.key == "blur" then
        preset.blur = math.max(0.0, preset.blur + delta * field.step)
    elseif field.key == "noise" then
        preset.noise = math.max(0.0, preset.noise + delta * field.step)
    elseif field.key == "autoGated" then
        preset.autoGated = math.max(0.0, math.min(1.0, preset.autoGated + delta * field.step))
    elseif field.key == "shadowBoost" then
        preset.shadowBoost = math.max(0.0, preset.shadowBoost + delta * field.step)
    elseif field.key == "colorR" then
        preset.color[1] = math.max(0.0, math.min(1.0, (preset.color[1] or 0.0) + delta * field.step))
    elseif field.key == "colorG" then
        preset.color[2] = math.max(0.0, math.min(1.0, (preset.color[2] or 0.0) + delta * field.step))
    elseif field.key == "colorB" then
        preset.color[3] = math.max(0.0, math.min(1.0, (preset.color[3] or 0.0) + delta * field.step))
    elseif field.key == "viewConeEnabled" then
        EOPFramework.Runtime.SetViewCone(delta > 0, EOPFramework.State.viewCone.strength, EOPFramework.State.viewCone.inner, EOPFramework.State.viewCone.outer)
        return true
    elseif field.key == "viewConeStrength" then
        local cone = EOPFramework.State.viewCone
        cone.strength = math.max(0.0, math.min(1.0, (cone.strength or 0.0) + delta * field.step))
        EOPFramework.Runtime.SetViewCone(cone.enabled, cone.strength, cone.inner, cone.outer)
        return true
    elseif field.key == "viewConeInner" then
        local cone = EOPFramework.State.viewCone
        cone.inner = math.max(0.0, math.min(1.0, (cone.inner or 0.0) + delta * field.step))
        EOPFramework.Runtime.SetViewCone(cone.enabled, cone.strength, cone.inner, cone.outer)
        return true
    elseif field.key == "viewConeOuter" then
        local cone = EOPFramework.State.viewCone
        cone.outer = math.max(0.0, math.min(1.0, (cone.outer or 1.0) + delta * field.step))
        EOPFramework.Runtime.SetViewCone(cone.enabled, cone.strength, cone.inner, cone.outer)
        return true
    end
    return applyCurrentPresetFromDebug()
end

    if NVGDebug.Initialized then
        return true
    end

    if not EOPFramework or not EOPFramework.Settings then
        print("ERROR FATALKA: framework.lua не загружен, Settings = nil")
        return false
    end

    refreshPresetList()
function NVGDebug.Init()
    if NVGDebug.Initialized then
        return true
    end
    refreshPresetList()
    if not NVGState then
        print("ERROR FATALKA: NVGState еще не инициализирован")
        return false
    end
    local success = EOPFramework.Settings.ApplyPreset(EOPFramework.Config.defaultPreset or "GEN_3_AUTOGATED")
    if not success then
        print("ERROR FATALKA: Failed to apply initial preset")
        return false
    end
    NVGState.setEnabled(1.0)
    NVGState.updateUniforms()
    NVGDebug.Initialized = true
    print("KRUTO!: NVG initialized successfully")
    return true
end

local function OnKeyPressed(key)
    if isKey(key, 46, 67) then
        NVGDebug.PanelVisible = not NVGDebug.PanelVisible
        return
    end
    if isKey(key, 74, 36) then
        NVGDebug.NVGOn = not NVGDebug.NVGOn
        if NVGDebug.NVGOn then
            EOPFramework.Runtime.Enable()
        else
            EOPFramework.Runtime.Disable()
        end
        return
    end
    if key == 203 then
        NVGDebug.Index = NVGDebug.Index - 1
        if NVGDebug.Index < 1 then NVGDebug.Index = #NVGDebug.PresetNames end
        if #NVGDebug.PresetNames > 0 then
            applyCurrentPresetFromDebug()
        end
    elseif key == 205 then
        NVGDebug.Index = NVGDebug.Index + 1
        if NVGDebug.Index > #NVGDebug.PresetNames then NVGDebug.Index = 1 end
        if #NVGDebug.PresetNames > 0 then
            applyCurrentPresetFromDebug()
        end
    elseif isKey(key, 44, 51) then
        NVGDebug.FieldIndex = NVGDebug.FieldIndex - 1
        if NVGDebug.FieldIndex < 1 then NVGDebug.FieldIndex = #getFieldConfig() end
    elseif isKey(key, 52) then
        NVGDebug.FieldIndex = NVGDebug.FieldIndex + 1
        if NVGDebug.FieldIndex > #getFieldConfig() then NVGDebug.FieldIndex = 1 end
    elseif isKey(key, 82, 19) then
        setCurrentFieldValue(-1.0)
    elseif isKey(key, 84, 20) then
        setCurrentFieldValue(1.0)
    end
end
local function OnPostRender()
    if not NVGDebug.Initialized then
        NVGDebug.Init()
    end
    local tm = getTextManager()
    if not tm or not NVGDebug.PanelVisible then return end
    refreshPresetList()
    local presetName = NVGDebug.PresetNames[NVGDebug.Index]
    local preset = EOPFramework.Presets[presetName]
    if not preset then return end
    local x, y, h = 20, 220, 18
    local font = UIFont.Small
    local fields = getFieldConfig()
    local field = fields[NVGDebug.FieldIndex]
    --
    tm:DrawString(font, x, y + h * 0,
        string.format("Preset: %s [%d/%d]", presetName, NVGDebug.Index, #NVGDebug.PresetNames),
        0.2, 1.0, 0.2, 1.0)
    tm:DrawString(font, x, y + h * 1,
        string.format("NVG: %s | Selected: %s",
            NVGDebug.NVGOn and "ON" or "OFF",
            field and field.label or "-"),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h * 2,
        string.format("Gain: %.2f | Blur: %.2f | Noise: %.2f", preset.gain, preset.blur, preset.noise),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h * 3,
        string.format("Auto: %.2f | Shadow: %.2f", preset.autoGated, preset.shadowBoost),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h * 4,
        string.format("Phosphor: %.2f, %.2f, %.2f", preset.color[1], preset.color[2], preset.color[3]),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h * 5,
        string.format("Cone: enabled=%s strength=%.2f inner=%.2f outer=%.2f",
            tostring(EOPFramework.State.viewCone.enabled),
            EOPFramework.State.viewCone.strength,
            EOPFramework.State.viewCone.inner,
            EOPFramework.State.viewCone.outer),
        0.9, 0.9, 0.9, 1.0)
    tm:DrawString(font, x, y + h * 6,
        "Bind: C panel | J NVG | <-/-> preset | ,/. field | R/T value",
        1.0, 0.8, 0.0, 1.0)
end

Events.OnKeyPressed.Add(OnKeyPressed)
Events.OnPostRender.Add(OnPostRender)
print("INFUSHKA Debugger готов Presets: " .. tostring(#(EOPFramework.Presets or {})))
