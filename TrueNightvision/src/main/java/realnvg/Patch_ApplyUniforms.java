package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
import org.lwjgl.opengl.GL20;
import zombie.core.opengl.RenderThread;
@Patch(className = "zombie.iso.weather.WeatherShader", methodName = "render", warmUp = true)
public final class Patch_ApplyUniforms {
    @Patch.OnExit
    public static void onRenderExit() {
        RenderThread.invokeOnRenderContext(() -> {
            int programId = GL20.glGetInteger(GL20.GL_CURRENT_PROGRAM);
            if (programId <= 0) {
                return;
            }
            setFloat(programId, "u_Gain", NVGState.gain);
            setFloat(programId, "u_EdgeBlur", NVGState.blur);
            setFloat(programId, "u_Noise", NVGState.noise);
            setFloat(programId, "u_AutoGated", NVGState.autoGated);
            setFloat(programId, "u_ShadowBoost", NVGState.shadowBoost);
            setFloat(programId, "u_NVGEnabled", NVGState.nvgEnabled);
            
            int phosphorLoc = GL20.glGetUniformLocation(programId, "u_Phosphor");
            if (phosphorLoc != -1) {
                GL20.glUniform3f(phosphorLoc, NVGState.phosphorR, NVGState.phosphorG, NVGState.phosphorB);
            }
        });
    }
    private static void setFloat(int programId, String name, float value) {
        int location = GL20.glGetUniformLocation(programId, name);
        if (location != -1) {
            GL20.glUniform1f(location, value);
        }
    }
}

