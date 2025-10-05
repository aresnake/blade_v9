param(
  [string]$Root = "D:\V9",
  [string]$BlenderExe = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe",
  [Parameter()][object]$UseSandbox = $true
)

$ErrorActionPreference = "Stop"

function Convert-ToBool([object]$v){
  if ($null -eq $v) { return $true }
  $s = "$v"
  switch -regex ($s.ToLower()) {
    '^(true|1|yes|y)$'  { return $true }
    '^(false|0|no|n)$'  { return $false }
    default { try { return [bool]$v } catch { return $true } }
  }
}
function Write-UTF8NoBOM([string]$Path,[string]$Content){
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path,$Content,$enc)
}

$zip = Join-Path $Root "blade_v9.zip"
if (!(Test-Path $zip)) { throw "Zip introuvable: $zip (lance Clean_V9/Release_V9 avant)" }

# Version depuis source (optionnel)
$srcInit = Join-Path $Root "blade_v9\__init__.py"
$verTuple = "9, 0, 0"
if (Test-Path $srcInit) {
  $src = Get-Content $srcInit -Raw -Encoding UTF8
  if ($src -match '["'']version["'']\s*:\s*\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\)') {
    $verTuple = "$($Matches[1]), $($Matches[2]), $($Matches[3])"
  }
}

$SB = Convert-ToBool $UseSandbox
$oldUserScripts = $env:BLENDER_USER_SCRIPTS
if ($SB) {
  $sandbox = Join-Path $env:TEMP "bl_user_scripts_empty"
  New-Item -ItemType Directory -Force -Path (Join-Path $sandbox "addons") | Out-Null
  $env:BLENDER_USER_SCRIPTS = $sandbox
  $inst = Join-Path $sandbox "addons\blade_v9"
  if (Test-Path $inst) { Remove-Item $inst -Recurse -Force -ErrorAction SilentlyContinue }
  Write-Host "[Smoke] BLENDER_USER_SCRIPTS=$sandbox"
}

$py = @"
import bpy, os, re, traceback

MOD = "blade_v9"
ZIPF = r"$($zip.Replace('\','\\'))"
VER_TUPLE = ($verTuple)

def log(msg): print(f"[Smoke] {msg}")

def installed_dir():
    u = os.environ.get("BLENDER_USER_SCRIPTS")
    if u:
        return os.path.join(u, "addons", MOD)
    try:
        user_addons = bpy.utils.user_resource('SCRIPTS', path="addons", create=True)
        return os.path.join(user_addons, MOD)
    except Exception:
        return os.path.expanduser(os.path.join("~","AppData","Roaming","Blender Foundation","Blender","4.5","scripts","addons",MOD))

HEADER = f'''bl_info = {{
    "name": "Blade v9",
    "author": "Adrien / ARES",
    "version": {VER_TUPLE},
    "blender": (4, 5, 0),
    "location": "N-Panel > Blade v9",
    "description": "Blade v9 Ops quick panel and safe defaults.",
    "category": "3D View"
}}

'''

def _decode_no_bom(b):
    if b[:3] == b'\xEF\xBB\xBF':
        b = b[3:]
    return b.decode('utf-8', errors='replace')

def normalize_installed_init(path):
    try:
        with open(path, 'rb') as f:
            t = _decode_no_bom(f.read())
        # retire lignes orphelines "x, y, z),"
        t = "\n".join([ln for ln in t.splitlines() if not re.match(r'^\s*\d+\s*,\s*\d+\s*,\s*\d+\)\s*,?\s*$', ln)])
        patt = re.compile(r'(?s)^\s*bl_info\s*=\s*\{.*?\}', re.MULTILINE)
        if patt.search(t):
            t = patt.sub(HEADER.strip(), t, count=1)
        else:
            t = HEADER + t
        t = t.replace("\uFEFF","").replace("’","'").replace("“",'"').replace("”",'"').replace("–","-").replace("—","-")
        with open(path, 'wb') as f:
            f.write(t.encode('utf-8'))
        log(f"bl_info normalized at: {path}")
    except Exception as e:
        log(f"normalize_installed_init FAILED: {e}")
        traceback.print_exc()

def try_op(fn, name):
    try:
        res = fn()
        log(f"{name}: {res}")
    except Exception as e:
        log(f"{name} FAILED: {e}")
        traceback.print_exc()

try:
    log(f"Installing: {ZIPF}")
    bpy.ops.preferences.addon_install(filepath=ZIPF, overwrite=True)

    ini = os.path.join(installed_dir(), "__init__.py")
    if os.path.isfile(ini):
        normalize_installed_init(ini)

    bpy.ops.preferences.addon_enable(module=MOD)
    log("Enabled OK")

    if hasattr(bpy.ops, "bladev9"):
        if hasattr(bpy.ops.bladev9, "reset_scene"):
            try_op(lambda: bpy.ops.bladev9.reset_scene(), "reset_scene")
        if hasattr(bpy.ops.bladev9, "export_zip"):
            try_op(lambda: bpy.ops.bladev9.export_zip(), "export_zip")
    else:
        log("bpy.ops.bladev9 indisponible")

finally:
    bpy.ops.wm.quit_blender()
"@

$tmp = Join-Path $env:TEMP "blade_smoketest_v9.py"
Write-UTF8NoBOM $tmp $py

& $BlenderExe -b --factory-startup --python $tmp

if ($SB) { $env:BLENDER_USER_SCRIPTS = $oldUserScripts }
