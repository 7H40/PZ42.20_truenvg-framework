package bridge;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL20;
import zombie.core.opengl.RenderThread;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
public class NVGShaderBridge {
    private static int cachedShaderID = -1;
    public static volatile boolean debug = false;
    private static final Set<String> warnedUniforms =
        Collections.synchronizedSet(new HashSet<>());
    private static int getShaderID() {
            if (cachedShaderID != -1 && GL20.glIsProgram(cachedShaderID)) {
                return cachedShaderID;
            }
            for (int i = 1; i < 1000; ++i) {
                if (GL20.glIsProgram(i) && GL20.glGetUniformLocation(i, "u_Phosphor") != -1) {
                    cachedShaderID = i;
                    System.out.println("INFO Nashel Found shader ID: " + i);
                    return cachedShaderID;
                }
            }
            System.out.println("error fatalka:Shader NOT found!(java)");
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
                if (debug) log("error fatalka:Shader not found, skipped");
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
            System.out.println("error fatalka:Uniform '" + uniform + "' not found (loggiroval edin)");
        }
    }
    private static void log(String msg) {
        if (debug) {
            System.out.println(msg);
        }
    }
}