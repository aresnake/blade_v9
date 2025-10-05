# === Lancer Blender + installer & activer Blade v8 ===
$BLENDER = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
$ZIP = "D:\V8\blade_v8.zip"

$py = @"
import bpy, addon_utils
print('[Blade] Installing from zip:', r"$ZIP")
bpy.ops.preferences.addon_install(filepath=r"$ZIP", overwrite=True)
addon_utils.enable("blade_v8", default_set=False, persistent=False)
print('[Blade] Enabled (no save)')
"@

& "$BLENDER" -con --factory-startup --disable-autoexec --python-expr $py
