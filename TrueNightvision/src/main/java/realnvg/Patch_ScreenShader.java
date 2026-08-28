package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
@Patch(className = "zombie.core.opengl.ShaderUnit", methodName = "preProcessShaderFile", warmUp = true)
public class Patch_ScreenShader {
    @Patch.OnExit
    public static void onExit(
            @Patch.Argument(0) String fileName,
            @Patch.Return(readOnly = false) String returnValue) {

        if (fileName == null || !fileName.endsWith("screen.frag")) {
            return;
        }
        System.out.println("patching screen.frag, source length = " + returnValue.length());
        System.out.println("fsnippet:\n" + returnValue.substring(0, Math.min(1200, returnValue.length())));
        StringBuilder sb = new StringBuilder(returnValue);
        String addition = """
            uniform float u_NVGEnabled;
            uniform float u_Gain;
            uniform float u_ShadowBoost;
            uniform float u_EdgeBlur;
            uniform float u_Noise;
            uniform float u_AutoGated;
            uniform vec3  u_Phosphor;

            vec3 EOP_NVG(vec3 pixel, vec3 noise) {
                vec2 centerOffset = vUV.st - vec2(0.5);
                float d = length(centerOffset);

                float luminance = dot(pixel, lumvec);

                float amplified = luminance * u_Gain;
                float lifted = pow(luminance + 0.002, 0.35) * u_ShadowBoost * 1.2;

                float signal = amplified + lifted;

                if (u_AutoGated > 0.5) {
                    signal = signal / (1.0 + amplified * 0.35);
                }

                float tubeNoise = fract(sin(dot(vUV.st + vec2(timer * 0.08), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
                float noiseMask = 1.0 - smoothstep(0.0, 0.35, luminance);
                signal += tubeNoise * u_Noise * (0.3 + noiseMask);

                float vignette = 1.0 - smoothstep(0.25, 0.70, d);
                signal *= vignette;

                return clamp(signal * u_Phosphor, 0.0, 1.0);
            }
            """;
        int mainIndex = sb.indexOf("void main()");
        if (mainIndex != -1) {
            sb.insert(mainIndex, addition);
            System.out.println("inserted EOP_NVG before main()");
        } else {
            sb.append(addition);
            System.out.println("okolo fatalka ERROR ||||'void main()' not found, appended EOP_NVG at end");
        }
        String target = "col = screenWorld(col, noise);";
        String modified = sb.toString();
        if (modified.contains(target)) {
            modified = modified.replace(
                target, //заменяю оригинал
                "if (u_NVGEnabled > 0.5) {\n" +
                "        col = EOP_NVG(col, noise);\n" +
                "    } else {\n" +
                "        col = screenWorld(col, noise);\n" +
                "    }"
            );
        } else {
            System.out.println("fatalka ERROR ||||| target line '" + target + "' NOT FOUND in shader");
        }
        returnValue = modified;
    }
}