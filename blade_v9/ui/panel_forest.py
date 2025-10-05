# Blade v9 - UI Panel for Forest (with preset button)
# Indentation: 4 spaces everywhere, no tabs.

import bpy
from bpy.types import Panel, PropertyGroup
from bpy.props import IntProperty, FloatProperty, EnumProperty

PANEL_CATEGORY = "Blade"


class BL9_PG_ForestProps(PropertyGroup):
    bl9_count: IntProperty(
        name="Count",
        default=20, min=1, max=500,
        description="Nombre d'arbres",
    )
    bl9_seed: IntProperty(
        name="Seed",
        default=123,
        description="Graine aléatoire",
    )
    bl9_trunk_h: FloatProperty(
        name="Trunk Height",
        default=2.0, min=0.1, max=100.0,
    )
    bl9_trunk_r: FloatProperty(
        name="Trunk Radius",
        default=0.08, min=0.005, max=2.0,
    )
    bl9_leaf_r: FloatProperty(
        name="Leaf Radius",
        default=0.35, min=0.05, max=5.0,
    )
    bl9_spread: FloatProperty(
        name="Spread",
        default=6.0, min=0.5, max=100.0,
        description="Rayon de dispersion",
    )
    bl9_preset: EnumProperty(
        name="Preset",
        items=(
            ("GREEN", "Green", "Green foliage / brown trunk"),
            ("DRY",   "Dry",   "Dry/olive foliage / light brown trunk"),
        ),
        default="GREEN",
    )


class BL9_PT_ForestPanel(Panel):
    bl_label = "Forest"
    bl_idname = "BL9_PT_ForestPanel"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = PANEL_CATEGORY

    def draw(self, context):
        layout = self.layout
        scene = context.scene
        props = getattr(scene, "bl9_forest", None)
        if props is None:
            layout.label(text="Props not ready.", icon='ERROR')
            return

        col = layout.column(align=True)
        col.prop(props, "bl9_count")
        col.prop(props, "bl9_seed")
        col.separator()
        col.prop(props, "bl9_trunk_h")
        col.prop(props, "bl9_trunk_r")
        col.prop(props, "bl9_leaf_r")
        col.separator()
        col.prop(props, "bl9_spread")

        layout.separator()
        row = layout.row(align=True)
        op = row.operator("bl9.forest_quick", text="Generate Forest", icon="PARTICLES")
        op.count = props.bl9_count
        op.seed = props.bl9_seed
        op.trunk_h = props.bl9_trunk_h
        op.trunk_r = props.bl9_trunk_r
        op.leaf_r = props.bl9_leaf_r
        op.spread = props.bl9_spread

        layout.separator()
        col = layout.column(align=True)
        col.prop(props, "bl9_preset", text="Preset")
        op2 = col.operator("bl9.apply_forest_preset", text="Apply Preset", icon="COLOR")
        op2.preset = props.bl9_preset

        layout.separator()
        row2 = layout.row(align=True)
        row2.operator("bl9.clear_forest", text="Clear Forest", icon="TRASH")


classes = (
    BL9_PG_ForestProps,
    BL9_PT_ForestPanel,
)


def register():
    for cls in classes:
        bpy.utils.register_class(cls)
    bpy.types.Scene.bl9_forest = bpy.props.PointerProperty(type=BL9_PG_ForestProps)


def unregister():
    if hasattr(bpy.types.Scene, "bl9_forest"):
        del bpy.types.Scene.bl9_forest
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
