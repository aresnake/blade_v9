# blade_v9/ops/__init__.py
from . import forest
from . import preset_forest
from . import clear_forest
from . import compat_smoke  # <-- ajout

def register():
    forest.register()
    preset_forest.register()
    clear_forest.register()
    compat_smoke.register()  # <-- ajout

def unregister():
    compat_smoke.unregister()  # <-- ajout
    clear_forest.unregister()
    preset_forest.unregister()
    forest.unregister()
