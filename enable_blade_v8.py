import os, sys, zipfile, shutil, traceback

ADDONS_MARKER = os.path.normpath(os.path.join("scripts", "addons"))

def find_addons_dirs():
    paths = []
    for p in sys.path:
        if isinstance(p, str):
            np = os.path.normpath(p)
            if np.endswith(ADDONS_MARKER) or (ADDONS_MARKER + os.sep) in (np + os.sep):
                paths.append(np)
    app = os.getenv("APPDATA", "")
    if app:
        for v in ("4.5","4.4"):
            default = os.path.normpath(os.path.join(app, "Blender Foundation", "Blender", v, "scripts", "addons"))
            if os.path.isdir(default) and default not in paths:
                paths.append(default)
    return paths

def install_zip(zip_path, addons_dir):
    if not os.path.isfile(zip_path):
        print(f"[Blade v8 bootstrap] Zip introuvable: {zip_path}"); return False
    dst = os.path.join(addons_dir, "blade_v8")
    shutil.rmtree(dst, ignore_errors=True)
    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(addons_dir)
    print(f"[Blade v8 bootstrap] Modules Installed (blade_v8) into '{addons_dir}'")
    return True

def main():
    base = os.path.dirname(os.path.abspath(__file__))
    zip_path = os.path.abspath(os.path.join(base, "..", "blade_v8.zip"))
    print(f"[Blade v8 bootstrap] Installing from: {zip_path}")
    ok = False
    for ad in find_addons_dirs():
        try:
            os.makedirs(ad, exist_ok=True)
            if install_zip(zip_path, ad): ok = True
        except Exception:
            traceback.print_exc()
    print("[Blade v8 bootstrap] Add-on enabled: blade_v8" if ok else "[Blade v8 bootstrap] Aucun install réussi.")

if __name__ == "__main__":
    main()
