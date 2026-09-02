package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
@Patch(className = "zombie.core.opengl.ShaderUnit", methodName = "preProcessShaderFile", warmUp = true)
public class Patch_ScreenVert {
    @Patch.OnExit
    public static void onExit(
            @Patch.Argument(0) String fileName,
            @Patch.Argument(1) java.util.ArrayList<String> includeList,
            @Patch.Return(readOnly = false) String returnValue) {
        if (fileName == null || !fileName.endsWith("screen.vert")) {
            return;
        }
        System.out.println("Patching screen.vert!");
        String source = returnValue;
        String uniformLine = "uniform float u_Distortion;\n";
        int versionEnd = source.indexOf("\n", source.indexOf("#version"));
        if (versionEnd != -1) {
            source = source.substring(0, versionEnd + 1) + uniformLine + source.substring(versionEnd + 1);
        }
        String targetAssign = "vUV = aUV;";
        if (source.contains(targetAssign)) {
            String replacement = 
                "    vec2 uv = aUV - 0.5;\n" +
                "    float r = length(uv);\n" +
                "    float distortion = 1.0 + u_Distortion * r * r;\n" +
                "    vUV = uv * distortion + 0.5;";
            source = source.replace(targetAssign, replacement);
        } else {
            System.out.println("bebebebebe");
            //яебланебланскойупаковки
        }
        returnValue = source;
    }
}