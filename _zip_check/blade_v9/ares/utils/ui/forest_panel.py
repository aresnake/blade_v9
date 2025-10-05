# -*- coding: utf-8 -*-
import bpy
from ..utils.log import get_logger
log = get_logger()

# --- Menu dans la barre du 3D View ---
class ARES_MT_forest_menu(bpy.types.Menu):
    bl_idname = "ARES_MT_forest_menu"
    bl_label  = "ARES ▸ Forest"

    def draw(self, context):
        layout = self.layout
        layout.operator("ares.forest_quick", icon="OUTLINER_OB_TREE")
        layout.operator("ares.forest_paint_helper", icon="BRUSH_DATA")
        layout.operator("ares.forest_make_instances", icon="OUTLINER_OB_EMPTY")

def draw_into_view3d_menu(self, context):
    self.layout.menu(AresMenuRef.bl_idname, text="ARES ▸ Forest")

# Petit conteneur pour éviter les ref manquantes lors du register
class AresMenuRef:
    bl_idname = ARES_MT_forest_menu.bl_idname

# --- Panneau N ---
class ARES_PT_forest_panel(bpy.types.Panel):
    bl_idname = "ARES_PT_forest_panel"
    bl_label  = "ARES — Forest"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category   = "ARES"

    def draw(self, context):
        layout = self.layout
        col = layout.column(align=True)
        col.label(text="Workflows")
        col.operator("ares.forest_quick", text="Generate Quick Forest", icon="OUTLINER_OB_TREE")
        col.operator("ares.forest_paint_helper", text="Paint Density Helper", icon="BRUSH_DATA")
        col.operator("ares.forest_make_instances", text="Convert to Linked Data", icon="OUTLINER_OB_EMPTY")
        layout.separator()
        layout.label(text="(min demo — robuste & safe)")

classes = (
    ARES_MT_forest_menu,
    ARES_PT_forest_panel,
)

def register():
    for c in classes:
        bpy.utils.register_class(c)
    # Injecte le menu dans la barre du 3D View
    bpy.types.VIEW3D_MT_editor_menus.append(draw_into_view3d_menu)
    log.info("[Forest UI] Registered (menu + panel).")

def unregister():
    try:
        bpy.types.VIEW3D_MT_editor_menus.remove(draw_into_view3d_menu)
    except Exception:
        pass
    for c in reversed(classes):
        try:
            bpy.utils.unregister_class(c)
        except Exception:
            pass
    log.info("[Forest UI] Unregistered.")
