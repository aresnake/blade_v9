import bpy

class BL8_PT_panel(bpy.types.Panel):
    bl_idname = "BL8_PT_panel"
    bl_label = "Blade v9"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Blade v9"

    def draw(self, ctx):
        col = self.layout.column(align=True)
        col.operator("bl8.smoke_test", icon="INFO", text="Smoke test")
        col.separator()
        col.label(text="Dev â€¢ Utils")
        row = col.row(align=True)
        row.operator("bl8.self_check", icon="CHECKMARK", text="Self-check")
        row.operator("bl8.reload_addon", icon="FILE_REFRESH", text="Reload")


def register():
    for c in classes:
        bpy.utils.register_class(c)

def unregister():
    for c in reversed(classes):
        bpy.utils.unregister_class(c)




