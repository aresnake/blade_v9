# Blade v9 - ops.forest
# Opérateur minimal bl9.forest_quick (data-API only, no bpy.ops)
# - Crée une collection "BL9_Forest"
# - Génère N "arbres" simples: un tronc (cylindre via bmesh.create_cone r1=r2) + une "canopée" (uvsphere)
# - Aucun besoin d'objet actif/sélection (robuste background)

import bpy
import bmesh
import random
from math import pi, sin, cos
from mathutils import Vector
from bpy.types import Operator
from bpy.props import IntProperty, FloatProperty

COLL_NAME = "BL9_Forest"

def ensure_collection(name: str) -> bpy.types.Collection:
    coll = bpy.data.collections.get(name)
    if not coll:
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
    return coll

def link_object(obj: bpy.types.Object, coll: bpy.types.Collection):
    if obj.name not in coll.objects:
        coll.objects.link(obj)
    return obj

def new_mesh_object(name: str, mesh: bpy.types.Mesh) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def make_cylinder(radius: float, height: float, segments: int = 16) -> bpy.types.Object:
    mesh = bpy.data.meshes.new("BL9_Trunk")
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm,
        segments=segments,
        radius1=radius,
        radius2=radius,
        depth=height,
        cap_ends=True,
    )
    bm.to_mesh(mesh)
    bm.free()
    obj = new_mesh_object("BL9_Trunk", mesh)
    obj.location.z = height * 0.5
    return obj

def make_uv_sphere(radius: float, segments: int = 16, rings: int = 8) -> bpy.types.Object:
    mesh = bpy.data.meshes.new("BL9_Leaves")
    bm = bmesh.new()
    # NOTE: 'diameter' n'existe pas ici → utiliser 'radius'
    bmesh.ops.create_uvsphere(
        bm,
        u_segments=segments,
        v_segments=rings,
        radius=radius,
    )
    bm.to_mesh(mesh)
    bm.free()
    obj = new_mesh_object("BL9_Leaves", mesh)
    return obj

def place_tree(coll: bpy.types.Collection, pos: Vector, trunk_h: float, trunk_r: float, leaf_r: float):
    trunk = make_cylinder(trunk_r, trunk_h, segments=14)
    leaves = make_uv_sphere(leaf_r, segments=16, rings=10)

    trunk.location.xy = pos.xy
    leaves.location.xy = pos.xy
    leaves.location.z = trunk_h + (leaf_r * 0.2)

    link_object(trunk, coll)
    link_object(leaves, coll)

class BL9_OT_forest_quick(Operator):
    bl_idname = "bl9.forest_quick"
    bl_label  = "BL9 Forest Quick (data-API)"
    bl_options = {'REGISTER', 'UNDO'}

    count: IntProperty(name="Count", default=20, min=1, max=500)
    seed: IntProperty(name="Seed", default=123)
    trunk_h: FloatProperty(name="Trunk Height", default=2.0, min=0.1, max=100.0)
    trunk_r: FloatProperty(name="Trunk Radius", default=0.08, min=0.005, max=2.0)
    leaf_r: FloatProperty(name="Leaf Radius", default=0.35, min=0.05, max=5.0)
    spread: FloatProperty(name="Spread", default=6.0, min=0.5, max=100.0, description="Rayon de dispersion")

    def execute(self, context):
        print("[Blade v9] forest_quick: start")
        try:
            random.seed(int(self.seed))
            coll = ensure_collection(COLL_NAME)

            created = 0
            attempts = 0
            while created < self.count and attempts < self.count * 10:
                attempts += 1
                # Échantillonnage polaire ~ uniforme
                u = random.random()
                r = (u ** 0.5) * self.spread
                theta = random.random() * 2.0 * pi
                x = r * cos(theta)
                y = r * sin(theta)
                pos = Vector((x, y, 0.0))
                place_tree(coll, pos, self.trunk_h, self.trunk_r, self.leaf_r)
                created += 1

            print(f"[Blade v9] forest_quick: created {created}/{self.count} trees in '{COLL_NAME}'")
            return {'FINISHED'}
        except Exception as e:
            print(f"[Blade v9] ERROR forest_quick: {e}")
            return {'CANCELLED'}

def register():
    bpy.utils.register_class(BL9_OT_forest_quick)

def unregister():
    bpy.utils.unregister_class(BL9_OT_forest_quick)
