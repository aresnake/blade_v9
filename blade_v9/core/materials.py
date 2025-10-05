# Blade v9 - core.materials
# Helpers sûrs pour créer/assurer/assigner des matériaux (Eevee/Cycles agnostique)

import bpy

def ensure_material(name: str, rgba=(0.8, 0.8, 0.8, 1.0)) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if not mat:
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
    # set Principled base color if node tree exists
    nt = getattr(mat, "node_tree", None)
    if nt and nt.nodes:
        principled = nt.nodes.get("Principled BSDF")
        if principled and hasattr(principled.inputs.get("Base Color"), "default_value"):
            principled.inputs["Base Color"].default_value = rgba
    return mat

def assign_material(obj: bpy.types.Object, mat: bpy.types.Material):
    if not obj or obj.type != 'MESH' or not mat:
        return
    # ensure slot exists
    if len(obj.material_slots) == 0:
        obj.data.materials.append(mat)
    else:
        # assign first slot (simple & safe)
        obj.material_slots[0].material = mat

def get_collection(name: str) -> bpy.types.Collection | None:
    return bpy.data.collections.get(name)
