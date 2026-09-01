package bridge;

import me.zed_0xff.zombie_buddy.Exposer;
import zombie.GameTime;
import zombie.core.Core;
import zombie.iso.IsoCell;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoLightSource;
import zombie.iso.IsoWorld;
//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK//DOESNTWORK
@Exposer.LuaClass
public final class IRLightBridge {
    private static IsoLightSource source;
    private static IsoCell sourceCell;

    private IRLightBridge() {
    }

    public static void setLocalLight(float x, float y, int z,
                                     float directionX, float directionY,
                                     int radius, float intensity,
                                     float red, float green, float blue) {
        IsoWorld world = IsoWorld.instance;
        if (world == null) {
            return;
        }

        IsoCell cell = world.currentCell != null ? world.currentCell : world.getCell();
        if (cell == null) {
            return;
        }

        int lightX = Math.round(x + directionX * 1.5F);
        int lightY = Math.round(y + directionY * 1.5F);
        int safeRadius = Math.max(1, Math.min(radius, 20));
        float safeIntensity = Math.max(0.0F, Math.min(intensity, 0.5F));

        if (source == null || sourceCell != cell) {
            removeLocalLight();
            source = new IsoLightSource(
                lightX,
                lightY,
                z,
                red * safeIntensity,
                green * safeIntensity,
                blue * safeIntensity,
                safeRadius
            );
            source.life = -1;
            source.active = true;
            sourceCell = cell;
            cell.addLamppost(source);
        } else {
            source.setX(lightX);
            source.setY(lightY);
            source.setZ(z);
            source.setRadius(safeRadius);
            source.setR(red * safeIntensity);
            source.setG(green * safeIntensity);
            source.setB(blue * safeIntensity);
            source.setActive(true);
            source.life = -1;
            source.id = 0;
            IsoGridSquare.setRecalcLightTime(-1.0F);
            if (Core.dirtyGlobalLightsCount < 10000) {
                Core.dirtyGlobalLightsCount++;
            }
            GameTime.instance.lightSourceUpdate = 100.0F;
        }
    }

    public static void removeLocalLight() {
        if (source != null && sourceCell != null) {
            sourceCell.removeLamppost(source);
            source.id = 0;
            source.active = false;
        }
        source = null;
        sourceCell = null;
    }
}
