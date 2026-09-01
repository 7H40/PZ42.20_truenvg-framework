package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Exposer;
import bridge.NVGShaderBridge;
@Exposer.LuaClass
public final class NVGState {
    public static volatile float gain = 1.8F;
    public static volatile float blur = 0.2F;
    public static volatile float noise = 0.18F;
    public static volatile float autoGated = 0.0F;
    public static volatile float phosphorR = 0.18F;
    public static volatile float phosphorG = 0.95F;
    public static volatile float phosphorB = 0.22F;
    public static volatile float nvgEnabled = 0.0F;
    public static volatile float shadowBoost = 0.5F;
    public static volatile float coneAngle = 40.0F;
    public static String ping() {
        return "hi from java!";
    }
    public static void setEnabled(float value) {
        nvgEnabled = value;
    }
    public static void setPreset(float newGain, float newBlur, float newNoise,
                                float newAutoGated, float newShadowBoost,
                                float red, float green, float blue) {
        gain = newGain;
        blur = newBlur;
        noise = newNoise;
        autoGated = newAutoGated;
        shadowBoost = newShadowBoost;
        phosphorR = red;
        phosphorG = green;
        phosphorB = blue;
    }
    public static void updateUniforms() {
        NVGShaderBridge.applyAllUniforms(gain, blur, noise, autoGated,
                                        shadowBoost,
                                        nvgEnabled, phosphorR, phosphorG, phosphorB);
    }
    public static void setConeAngle(float value) {
        coneAngle = value;
    }
}