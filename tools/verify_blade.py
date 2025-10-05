import importlib, traceback
NAME = "blade_v9"

def main():
    try:
        mod = importlib.import_module(NAME)
        importlib.reload(mod)
        if hasattr(mod, "register"):
            mod.register()
            print(f"[CHECK] {NAME} register() OK")
        else:
            print(f"[CHECK] {NAME} sans register()")
    except Exception:
        traceback.print_exc()
    finally:
        try:
            if "mod" in locals() and hasattr(mod, "unregister"):
                mod.unregister()
                print(f"[CHECK] {NAME} unregister() OK")
        except Exception:
            traceback.print_exc()

if __name__ == "__main__":
    main()
