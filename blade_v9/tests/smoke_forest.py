# Smoke test Blade v9: génère, preset, clear. Exit code 0 = OK.

import bpy, sys

def main():
    try:
        res1 = bpy.ops.bl9.forest_quick(count=8, seed=9)
        if 'FINISHED' not in res1: raise RuntimeError("forest_quick failed")

        res2 = bpy.ops.bl9.apply_forest_preset(preset='GREEN')
        if 'FINISHED' not in res2: raise RuntimeError("apply_forest_preset failed")

        res3 = bpy.ops.bl9.clear_forest()
        if 'FINISHED' not in res3: raise RuntimeError("clear_forest failed")

        print("[SMOKE] OK")
        return 0
    except Exception as e:
        print(f"[SMOKE] ERROR: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
