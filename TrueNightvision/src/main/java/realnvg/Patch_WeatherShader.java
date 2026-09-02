package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
import org.lwjgl.opengl.GL20;
@Patch(className = "zombie.iso.weather.WeatherShader", methodName = "startRenderThread")
public final class Patch_WeatherShader {
    @Patch.OnExit
    public static void applyNVGUniforms() {
        int programId = GL20.glGetInteger(GL20.GL_CURRENT_PROGRAM);
        if (programId <= 0) {
            return;
        }
        setFloat(programId, "u_Gain", NVGState.gain);
        setFloat(programId, "u_EdgeBlur", NVGState.blur);
        setFloat(programId, "u_Noise", NVGState.noise);
        setFloat(programId, "u_AutoGated", NVGState.autoGated);
        setFloat(programId, "u_ShadowBoost", NVGState.shadowBoost);
        setFloat(programId, "u_isVKL", NVGState.nvgEnabled);
        int phosphor = GL20.glGetUniformLocation(programId, "u_Phosphor");
        if (phosphor != -1) {
            GL20.glUniform3f(phosphor, NVGState.phosphorR, NVGState.phosphorG, NVGState.phosphorB);
        }
    }
    public static void setFloat(int programId, String name, float value) {
        int location = GL20.glGetUniformLocation(programId, name);
        if (location != -1) {
            GL20.glUniform1f(location, value);
        }
    }
}