package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
@Patch(className = "zombie.core.opengl.ShaderUnit", methodName = "preProcessShaderFile", warmUp = true)
public class Patch_ScreenShader {
    @Patch.OnExit
    public static void onExit(
            @Patch.Argument(0) String fileName,
            @Patch.Argument(1) java.util.ArrayList<String> includeList,
            @Patch.Return(readOnly = false) String returnValue) {
        System.out.println("Processing shader: " + fileName);
        if (fileName == null || !fileName.endsWith("screen.frag")) {
            return;
        }
        System.out.println("Patching screen.frag!");
        String source = returnValue;
        StringBuilder sb = new StringBuilder(source);
        String uniforms = """
            uniform float u_NVGEnabled;
            uniform float u_Gain;
            uniform float u_ShadowBoost;
            uniform float u_EdgeBlur;
            uniform float u_Noise;
            uniform float u_AutoGated;
            uniform vec3  u_Phosphor;
            """;
        String nvgFunction = """
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
        int versionEnd = sb.indexOf("\n", sb.indexOf("#version"));
        if (versionEnd != -1) {
            sb.insert(versionEnd + 1, uniforms);
        } 
        int mainIndex = sb.indexOf("void main()");
        if (mainIndex != -1) {
            sb.insert(mainIndex, nvgFunction + "\n");
        }
        String target = "col = screenWorld(col, noise);";
        String replacement = "col = u_NVGEnabled > 0.5 ? EOP_NVG(col, noise) : screenWorld(col, noise);";
        String result = sb.toString();
        if (result.contains(target)) {
            result = result.replace(target, replacement);
        }
        returnValue = result;
    }
}