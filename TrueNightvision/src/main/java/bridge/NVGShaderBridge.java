package bridge;

import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL20;
import zombie.core.opengl.RenderThread;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class NVGShaderBridge {
    private static int cachedShaderID = -1;

    // Тоггл из Lua через NVGConfig.setDebug(...)
    public static volatile boolean debug = false;

    // Кеш уже предупреждённых uniform'ов — логируем каждый ровно один раз
    private static final Set<String> warnedUniforms =
        Collections.synchronizedSet(new HashSet<>());

    private static int getShaderID() {
        if (cachedShaderID != -1 && GL20.glIsProgram(cachedShaderID)) {
            return cachedShaderID;
        }
        for (int i = 1; i < 1000; ++i) {
            if (GL20.glIsProgram(i) && GL20.glGetUniformLocation(i, "u_Phosphor") != -1) {
                cachedShaderID = i;
                log("[NVGBridge] Found shader ID: " + i);
                return cachedShaderID;
            }
        }
        return -1;
    }

    public static void setDebug(boolean v) {
        debug = v;
    }

    public static void applyAllUniforms(float gain, float blur, float noise,
                                        float autoGated, float shadowBoost,
                                        float nvgEnabled,
                                        float phosphorR, float phosphorG, float phosphorB) {
        RenderThread.invokeOnRenderContext(() -> {
            int program = getShaderID();
            if (program <= 0) {
                if (debug) log("[NVGBridge] Shader not found, skipped");
                return;
            }

            int previousProgram = GL11.glGetInteger(35725);
            GL20.glUseProgram(program);

            setFloatInternal(program, "u_Gain", gain);
            setFloatInternal(program, "u_EdgeBlur", blur);
            setFloatInternal(program, "u_Noise", noise);
            setFloatInternal(program, "u_AutoGated", autoGated);
            setFloatInternal(program, "u_ShadowBoost", shadowBoost);
            setFloatInternal(program, "u_NVGEnabled", nvgEnabled);

            int phosphorLoc = GL20.glGetUniformLocation(program, "u_Phosphor");
            if (phosphorLoc != -1) {
                GL20.glUniform3f(phosphorLoc, phosphorR, phosphorG, phosphorB);
            } else {
                warnOnce("u_Phosphor");
            }

            GL20.glUseProgram(previousProgram);
        });
    }

    private static void setFloatInternal(int program, String name, float value) {
        int location = GL20.glGetUniformLocation(program, name);
        if (location != -1) {
            GL20.glUniform1f(location, value);
        } else {
            warnOnce(name);
        }
    }

    private static void warnOnce(String uniform) {
        if (!warnedUniforms.contains(uniform)) {
            warnedUniforms.add(uniform);
            log("[NVGBridge] Uniform '" + uniform + "' not found (logged once)");
        }
    }

    private static void log(String msg) {
        if (debug) {
            System.out.println(msg);
        }
    }
}