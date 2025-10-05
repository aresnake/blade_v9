# Blade v9 (V9.3)

Add-on Blender minimal et robuste pour génération de forêts:
- `bl9.forest_quick` (data API)
- Presets matériaux (GREEN / DRY)
- Nettoyage `bl9.clear_forest`
- UI: N-Panel → Blade → Forest
- Logs de session + timings (fichiers dans `%USERPROFILE%\blade_logs`)

## Installation
1. Exécuter `tools/Make_V9.ps1` (Windows PowerShell 5+).
2. Blender: `Edit > Preferences > Add-ons` → activer **Blade v9** si besoin.

## Utilisation rapide (console)
```powershell
"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe" -b --addons blade_v9 --python-expr "import bpy; bpy.ops.bl9.forest_quick(count=12, seed=42); bpy.ops.bl9.apply_forest_preset(preset='GREEN')"
