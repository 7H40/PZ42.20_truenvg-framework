package com.eich.realnvg;
import me.zed_0xff.zombie_buddy.Patch;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoPlayer;
import java.lang.reflect.Method;
@Patch(className = "zombie.iso.LightingJNI", methodName = "calculateVisionCone", warmUp = true)
public class Patch_VisionConeAngle {
    public static Method degreesToConeMethod;
    @Patch.OnExit
    public static void onExit(
            @Patch.Argument(0) IsoGameCharacter player,
            @Patch.Return(readOnly = false) float returnValue) {
        if (NVGState.nvgEnabled <= 0.5f) {
            return;
        }
        if (!(player instanceof IsoPlayer) || player != IsoPlayer.getInstance()) {
            return;
        }
        try {
            if (degreesToConeMethod == null) {
                Class<?> clazz = Class.forName("zombie.iso.LightingJNI");
                degreesToConeMethod = clazz.getDeclaredMethod("degreesToCone", float.class);
                degreesToConeMethod.setAccessible(true);
            }
            returnValue = (Float) degreesToConeMethod.invoke(null, NVGState.coneAngle);
        } catch (Exception e) {
            //aaaaaaaa
        }
    }
}