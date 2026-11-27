# Keeps Hollow Desert's Lively thumbnail in sync with the scene/palette chosen in Customise.
# Lively gives wallpapers no way to change their own thumbnail, so this copies thumbs\s{scene}p{palette}.jpg
# over thumbnail.jpg whenever Lively's saved settings change. Started hidden at logon by a scheduled task.
# -Once: sync a single time and print what was chosen (used as the self-check).
param([switch]$Once)

$root  = Join-Path $env:LOCALAPPDATA 'Packages\12030rocksdanister.LivelyWallpaper_97hta09mmv6hy\LocalCache\Local\Lively Wallpaper\Library\SaveData'
$wall  = Join-Path $root 'wptmp\hollow-desert'
$saved = Join-Path $root 'wpdata\hollow-desert'   # Lively's per-screen copies: <screen>\LivelyProperties.json
$last  = ''

function Sync {
  # Settings Lively saved after Customise; before the first Customise only the wallpaper's own defaults exist.
  $f = Get-ChildItem $saved -Recurse -Filter LivelyProperties.json -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $f = if ($f) { $f.FullName } else { Join-Path $wall 'LivelyProperties.json' }
  try { $p = Get-Content $f -Raw -ErrorAction Stop | ConvertFrom-Json } catch { return }  # mid-write: next tick

  $s = [math]::Max(0, [math]::Min(2, [int]$p.scene.value))
  $c = [math]::Max(0, [math]::Min(2, [int]$p.palette.value))
  $src = Join-Path $wall "thumbs\s${s}p${c}.jpg"
  $dst = Join-Path $wall 'thumbnail.jpg'
  if (-not (Test-Path $src)) { return }
  if ((Test-Path $dst) -and (Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash) { return "s${s}p${c} (already)" }
  Copy-Item $src $dst -Force
  "s${s}p${c}"
}

if ($Once) { Sync; return }

# ponytail: polls every 3 s instead of a FileSystemWatcher; costs nothing measurable and survives Lively
# replacing the folder. Switch to a watcher only if instant updates ever matter.
while ($true) {
  $stamp = (Get-ChildItem $saved -Recurse -Filter LivelyProperties.json -ErrorAction SilentlyContinue |
            ForEach-Object { $_.LastWriteTimeUtc.Ticks }) -join ','
  if ($stamp -ne $last) { $last = $stamp; $null = Sync }
  Start-Sleep -Seconds 3
}