# Blade v9 - ops.clear_forest
# Supprime proprement la collection BL9_Forest (si présente) et son contenu.

import bpy
from bpy.types import Operator

COLL_NAME = "BL9_Forest"

def _unlink_collection_from_parents(coll: bpy.types.Collection):
    """Délie la collection de tous ses parents pour permettre la suppression."""
    # Les parents sont dans l'arbre de scènes; on itère sur toutes les collections pour laquelle coll est enfant
    for c in list(bpy.data.collections):
        if coll.name in c.children:
            try:
                c.children.unlink(coll)
            except Exception:
                pass
    # Et la Master Scene Collection :
    try:
        for scene in bpy.data.scenes:
            if coll.name in scene.collection.children:
                scene.collection.children.unlink(coll)
    except Exception:
        pass

def _delete_collection(coll: bpy.types.Collection):
    # Supprime d'abord les objets de la collection
    for obj in list(coll.objects):
        try:
            # Délier des autres collections pour éviter les références multiples
            for parent in list(obj.users_collection):
                try:
                    parent.objects.unlink(obj)
                except Exception:
                    pass
            # Supprimer le datablock
            bpy.data.objects.remove(obj, do_unlink=True)
        except Exception as e:
            print(f"[Blade v9] clear_forest: error removing object {obj.name}: {e}")

    # Supprime les sous-collections éventuelles (peu probable ici)
    for sub in list(coll.children):
        try:
            _unlink_collection_from_parents(sub)
            bpy.data.collections.remove(sub)
        except Exception:
            pass

    # Enfin, supprime la collection elle-même
    try:
        _unlink_collection_from_parents(coll)
        bpy.data.collections.remove(coll)
    except Exception as e:
        print(f"[Blade v9] clear_forest: error removing collection {coll.name}: {e}")

class BL9_OT_clear_forest(Operator):
    bl_idname = "bl9.clear_forest"
    bl_label  = "BL9 Clear Forest"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        print("[Blade v9] clear_forest: start")
        coll = bpy.data.collections.get(COLL_NAME)
        if not coll:
            print(f"[Blade v9] clear_forest: '{COLL_NAME}' not found (nothing to do)")
            return {'CANCELLED'}
        try:
            _delete_collection(coll)
            print(f"[Blade v9] clear_forest: '{COLL_NAME}' removed")
            return {'FINISHED'}
        except Exception as e:
            print(f"[Blade v9] ERROR clear_forest: {e}")
            return {'CANCELLED'}

def register():
    bpy.utils.register_class(BL9_OT_clear_forest)

def unregister():
    bpy.utils.unregister_class(BL9_OT_clear_forest)
