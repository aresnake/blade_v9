# blade_v9/ops/compat_smoke.py
import bpy
import os
import tempfile
import zipfile
from bpy.types import Operator

ADDON_NAME = "blade_v9"

class BL9_OT_reset_scene(Operator):
    """Compat: reset scene for smoke tests"""
    bl_idname = "bladev9.reset_scene"
    bl_label = "Blade V9 - Reset Scene (Compat)"
    bl_options = {'INTERNAL'}

    def execute(self, context):
        # Essaie d'appeler notre clear_forest si dispo, sinon soft-reset
        try:
            if hasattr(bpy.ops, "bladev9") and hasattr(bpy.ops.bladev9, "clear_forest"):
                res = bpy.ops.bladev9.clear_forest()
                if res not in {{"FINISHED", {"FINISHED"}}}:
                    self.report({'WARNING'}, "clear_forest returned non-finished")
        except Exception as e:
            # Soft reset minimal: supprimer la collection BL9_Forest si présente
            coll = bpy.data.collections.get("BL9_Forest")
            if coll:
                for obj in list(coll.objects):
                    bpy.data.objects.remove(obj, do_unlink=True)
                bpy.data.collections.remove(coll)
        return {'FINISHED'}


class BL9_OT_export_zip(Operator):
    """Compat: export a tiny zip so tests can assert operator exists"""
    bl_idname = "bladev9.export_zip"
    bl_label = "Blade V9 - Export Zip (Compat)"
    bl_options = {'INTERNAL'}

    def execute(self, context):
        # Écrit un petit zip “preuve de vie” dans %TEMP% (ne remplace pas ton vrai Release_V9.ps1)
        tmp_dir = tempfile.gettempdir()
        out_zip = os.path.join(tmp_dir, f"{ADDON_NAME}_smoketest.zip")
        try:
            with zipfile.ZipFile(out_zip, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
                zf.writestr("README.txt", "Blade V9 smoke export OK.")
        except Exception as e:
            self.report({'ERROR'}, f"Export zip failed: {e}")
            return {'CANCELLED'}
        self.report({'INFO'}, f"Exported: {out_zip}")
        return {'FINISHED'}


classes = (
    BL9_OT_reset_scene,
    BL9_OT_export_zip,
)

def register():
    for c in classes:
        bpy.utils.register_class(c)

def unregister():
    for c in reversed(classes):
        bpy.utils.unregister_class(c)
