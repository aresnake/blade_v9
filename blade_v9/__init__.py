# Blade v9 — __init__.py (safe loader + session logs + timings)

bl_info = {
    "name": "Blade v9",
    "author": "Adrien / ARES",
    "version": (9, 3, 0),
    "blender": (4, 5, 0),
    "location": "View3D > N-Panel > Blade",
    "description": "Blade v9 base addon (safe loader + logs + ops/ui)",
    "category": "Object",
}

import importlib
import pkgutil
import sys
import types
from time import perf_counter

# --- LOGS ---
try:
    from .core import logs as bl9logs
    _LOGGER, _LOGFILE = bl9logs.setup_session_logger("blade_v9")
    def _log_info(msg):  _LOGGER.info(msg)
    def _log_warn(msg):  _LOGGER.warning(msg)
    def _log_err(msg):   _LOGGER.error(msg)
except Exception as _e:
    # Fallback console-only
    _LOGGER = None
    _LOGFILE = None
    def _log_info(msg):  print(f"[Blade v9] {msg}")
    def _log_warn(msg):  print(f"[Blade v9][WARN] {msg}")
    def _log_err(msg):   print(f"[Blade v9][ERROR] {msg}")

# Sous-mods chargés
_loaded_submodules = []  # [(relname, module)]

# Modules candidats : ajuste cette liste au fil des versions
CANDIDATE_MODULES = [
    "ops.forest",
    "ops.preset_forest",
    "ops.clear_forest",
    "ui.panel_forest",
    "core.materials",
]

def _safe_import(relmodname: str):
    fullname = f"{__name__}.{relmodname}"
    t0 = perf_counter()
    try:
        mod = importlib.import_module(fullname)
        dt = (perf_counter() - t0) * 1000.0
        _log_info(f"Imported: {relmodname} ({dt:.2f} ms)")
        return mod
    except ModuleNotFoundError:
        _log_info(f"Skipped (not found): {relmodname}")
        return None
    except Exception as e:
        _log_err(f"ERROR while importing {relmodname}: {e}")
        return None

def _call_if_exists(mod: types.ModuleType, func_name: str):
    func = getattr(mod, func_name, None)
    if callable(func):
        try:
            t_key = f"{mod.__name__}.{func_name}"
            if _LOGGER:
                bl9logs.start_timer(t_key)
            func()
            if _LOGGER:
                bl9logs.end_timer(t_key, _LOGGER, label=f"Call {t_key}")
            return True
        except Exception as e:
            _log_err(f"ERROR {func_name}() in {mod.__name__}: {e}")
            return False
    return False

def register():
    _log_info("Register start")
    if _LOGFILE:
        _log_info(f"Writing session logs to: {_LOGFILE}")

    for rel in list(CANDIDATE_MODULES):
        mod = _safe_import(rel)
        if mod is None:
            continue
        if _call_if_exists(mod, "register"):
            _loaded_submodules.append((rel, mod))
            _log_info(f"Registered: {rel}")
        else:
            _loaded_submodules.append((rel, mod))
            _log_info(f"Loaded (no register()): {rel}")

    if _loaded_submodules:
        names = ", ".join(rel for rel, _ in _loaded_submodules)
        _log_info(f"Register done. Loaded: {names}")
    else:
        _log_info("Register done. No submodules loaded (base only).")

def unregister():
    _log_info("Unregister start")
    for rel, mod in reversed(_loaded_submodules):
        if _call_if_exists(mod, "unregister"):
            _log_info(f"Unregistered: {rel}")
        else:
            _log_info(f"Unloaded (no unregister()): {rel}")
    _loaded_submodules.clear()
    _log_info("Unregister done")
