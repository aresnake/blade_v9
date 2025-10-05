import bpy, os, zipfile, datetime, subprocess

class BLADEV9_OT_reset_scene(bpy.types.Operator):
    bl_idname = "bladev9.reset_scene"
    bl_label = "Reset Scene (Safe)"
    def execute(self, context):
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete(use_global=False)
        bpy.ops.mesh.primitive_cube_add(size=2)
        try:
            context.scene.render.engine = "BLENDER_EEVEE_NEXT"
        except Exception:
            pass
        return {"FINISHED"}

class BLADEV9_OT_export_zip(bpy.types.Operator):
    bl_idname = "bladev9.export_zip"
    bl_label = "Export Add-on .ZIP (V9)"
    def execute(self, context):
        addon_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        addon_name = os.path.basename(addon_root)  # 'blade_v9'
        zip_dir    = os.path.dirname(addon_root)
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M")
        zip_path = os.path.join(zip_dir, f"{addon_name}_{ts}.zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(addon_root):
                for f in files:
                    full = os.path.join(root, f)
                    rel  = os.path.relpath(full, start=os.path.dirname(addon_root))  # -> blade_v9/...
                    zf.write(full, rel)
        self.report({"INFO"}, f"Exported: {zip_path}")
        return {"FINISHED"}

class BLADEV9_OT_open_addons(bpy.types.Operator):
    bl_idname = "bladev9.open_addons"
    bl_label = "Open Add-ons Folder"
    def execute(self, context):
        path = bpy.utils.user_resource('SCRIPTS', path='addons', create=True)
        try:
            if os.name == "nt": subprocess.Popen(["explorer", path])
            elif sys.platform == "darwin": subprocess.Popen(["open", path])
            else: subprocess.Popen(["xdg-open", path])
        except Exception:
            self.report({"WARNING"}, f"Folder: {path}")
        return {"FINISHED"}

class BLADEV9_OT_reload_scripts(bpy.types.Operator):
    bl_idname = "bladev9.reload_scripts"
    bl_label = "Reload Scripts"
    def execute(self, context):
        try:
            bpy.ops.script.reload()
            self.report({"INFO"}, "Scripts reloaded")
        except Exception as e:
            self.report({"ERROR"}, f"Reload failed: {e}")
        return {"FINISHED"}

class BLADEV9_PT_utilities(bpy.types.Panel):
    bl_label = "Utilities"
    bl_idname = "BLADEV9_PT_utilities"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Blade"
    def draw(self, context):
        layout = self.layout
        col = layout.column(align=True)
        col.operator("bladev9.reset_scene", icon="FILE_REFRESH")
        col.operator("bladev9.export_zip", icon="EXPORT")
        col.separator()
        col.operator("bladev9.reload_scripts", icon="FILE_REFRESH")
        col.operator("bladev9.open_addons", icon="FILE_FOLDER")

_CLASSES = (
    BLADEV9_OT_reset_scene,
    BLADEV9_OT_export_zip,
    BLADEV9_OT_open_addons,
    BLADEV9_OT_reload_scripts,
    BLADEV9_PT_utilities,
)

def register():
    for c in _CLASSES:
        try: bpy.utils.register_class(c)
        except Exception: pass

def unregister():
    for c in reversed(_CLASSES):
        try: bpy.utils.unregister_class(c)
        except Exception: pass