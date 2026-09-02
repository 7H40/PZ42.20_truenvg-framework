package bridge;
import me.zed_0xff.zombie_buddy.Exposer;
import zombie.GameTime;
import zombie.core.Core;
import zombie.iso.IsoCell;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoLightSource;
import zombie.iso.IsoWorld;
import com.eich.realnvg.NVGState;
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
        if (NVGState.nvgEnabled <= 0.5f || NVGState.irLightEnabled <= 0.5f) {
            removeLocalLight();
            return;
        }
        IsoCell cell = IsoWorld.instance.currentCell;
        if (cell == null) return;
        int lx = Math.round(x + directionX * 1.5F);
        int ly = Math.round(y + directionY * 1.5F);

        if (source == null || sourceCell != cell) {
            removeLocalLight();
            source = new IsoLightSource(lx, ly, z,
                                        red * intensity,
                                        green * intensity,
                                        blue * intensity,
                                        radius);
            source.setActive(true);
            source.life = -1;
            cell.getLamppostPositions().add(source);
            sourceCell = cell;
        } else {
            if (source.x != lx || source.y != ly) {
                cell.removeLamppost(source);
                source = new IsoLightSource(lx, ly, z,
                                            red * intensity,
                                            green * intensity,
                                            blue * intensity,
                                            radius);
                source.setActive(true);
                source.life = -1;
                cell.getLamppostPositions().add(source);
            } else {
                source.setR(red * intensity);
                source.setG(green * intensity);
                source.setB(blue * intensity);
                source.setRadius(radius);
            }
        }

        IsoGridSquare.setRecalcLightTime(-1.0F);
        GameTime.instance.lightSourceUpdate = 0.0F; 
    }
    public static void removeLocalLight() {
        if (source != null && sourceCell != null) {
            sourceCell.removeLamppost(source);
        }
        source = null;
        sourceCell = null;
        IsoGridSquare.setRecalcLightTime(-1.0F);
        GameTime.instance.lightSourceUpdate = 0.0F;
    }
}
