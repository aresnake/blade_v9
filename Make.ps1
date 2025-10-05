param([ValidateSet('pack','install','open','test','dev','all')][string]$task='all')

$BLENDER = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
$ROOT = "D:\V8"
$ZIP = Join-Path $ROOT "blade_v8.zip"
$SRC = Join-Path $ROOT "blade_v8"
$BOOT = Join-Path $ROOT "tools\enable_blade_v8.py"
$TEST = Join-Path $ROOT "tests\smoke_v8_1.py"

function Pack {
  $path = Join-Path $SRC "__init__.py"
  $bytes = [System.IO.File]::ReadAllBytes($path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    [System.IO.File]::WriteAllBytes($path, $bytes[3..($bytes.Length-1)])
    "BOM retiré de __init__.py (source)."
  }
  if (Test-Path $ZIP) { Remove-Item $ZIP -Force }
  Compress-Archive -Path "$SRC\" -DestinationPath $ZIP -Force
  "Pack OK: $ZIP"
}

function Install { & $BLENDER -con --factory-startup --python $BOOT }
function Open    { Start-Process $BLENDER }
function TestHeadless { & $BLENDER -b --factory-startup --python $TEST }

function Dev {
  $addons = "$env:APPDATA\Blender Foundation\Blender\4.5\scripts\addons"
  New-Item -ItemType Directory -Force -Path $addons | Out-Null
  Remove-Item -Recurse -Force "$addons\blade_v8" -ErrorAction SilentlyContinue
  Copy-Item -Recurse -Force $SRC "$addons\blade_v8"
  & $BLENDER -con --factory-startup --python-expr "import bpy; bpy.ops.preferences.addon_disable(module='blade_v8'); bpy.ops.preferences.addon_enable(module='blade_v8'); bpy.ops.wm.save_userpref();"
  "Dev install OK."
}

switch ($task) {
  'pack'    { Pack }
  'install' { Pack; Install }
  'open'    { Open }
  'test'    { Pack; Install; TestHeadless }
  'dev'     { Dev }
  'all'     { Pack; Install; TestHeadless; Open }
}