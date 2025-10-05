# Blade v9 - ops.preset_forest
# Applique un preset matériaux simple (GREEN / DRY) sur la collection "BL9_Forest"

import bpy
from bpy.types import Operator
from bpy.props import EnumProperty

from ..core.materials import ensure_material, assign_material, get_collection

COLL_NAME = "BL9_Forest"

PRESETS = {
    "GREEN": {
        "TRUNK": (0.26, 0.16, 0.08, 1.0),   # brun
        "LEAF":  (0.16, 0.45, 0.12, 1.0),   # vert
    },
    "DRY": {
        "TRUNK": (0.33, 0.22, 0.12, 1.0),   # brun plus clair
        "LEAF":  (0.55, 0.50, 0.32, 1.0),   # feuille sèche/olive
    }
}

def _apply_to_forest(preset_key: str):
    coll = get_collection(COLL_NAME)
    if not coll:
        print(f"[Blade v9] preset_forest: collection '{COLL_NAME}' not found")
        return 0, 0

    col_trunk = PRESETS[preset_key]["TRUNK"]
    col_leaf  = PRESETS[preset_key]["LEAF"]
    mat_trunk = ensure_material(f"BL9_Trunk_{preset_key}", col_trunk)
    mat_leaf  = ensure_material(f"BL9_Leaf_{preset_key}",  col_leaf)

    n_trunk = n_leaf = 0
    # parcourt les objets de la collection (non récursif pour rester simple)
    for obj in list(coll.objects):
        if not obj or obj.type != 'MESH':
            continue
        if obj.name.startswith("BL9_Trunk"):
            assign_material(obj, mat_trunk)
            n_trunk += 1
        elif obj.name.startswith("BL9_Leaves"):
            assign_material(obj, mat_leaf)
            n_leaf += 1
    return n_trunk, n_leaf

class BL9_OT_apply_forest_preset(Operator):
    bl_idname = "bl9.apply_forest_preset"
    bl_label  = "BL9 Apply Forest Preset"
    bl_options = {'REGISTER', 'UNDO'}

    preset: EnumProperty(
        name="Preset",
        items=(
            ("GREEN", "Green", "Green foliage / brown trunk"),
            ("DRY",   "Dry",   "Dry/olive foliage / light brown trunk"),
        ),
        default="GREEN",
    )

    def execute(self, context):
        print(f"[Blade v9] apply_forest_preset: {self.preset}")
        try:
            n_trunk, n_leaf = _apply_to_forest(self.preset)
            print(f"[Blade v9] preset applied: trunks={n_trunk}, leaves={n_leaf}")
            return {'FINISHED'}
        except Exception as e:
            print(f"[Blade v9] ERROR apply_forest_preset: {e}")
            return {'CANCELLED'}

def register():
    bpy.utils.register_class(BL9_OT_apply_forest_preset)

def unregister():
    bpy.utils.unregister_class(BL9_OT_apply_forest_preset)
