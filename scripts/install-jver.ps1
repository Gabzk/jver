Param(
  [string]$Version = "latest",
  [string]$InstallDir = "$env:LOCALAPPDATA\\jver"
)

Write-Host "==> Installing JVer ($Version) to $InstallDir" -ForegroundColor Cyan

if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }

$repo = "babiel/jver"  # adjust to real owner/repo

if ($Version -eq "latest") {
  $api = "https://api.github.com/repos/$repo/releases/latest"
} else {
  $api = "https://api.github.com/repos/$repo/releases/tags/$Version"
}

try {
  $release = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'jver-installer' }
} catch {
  Write-Error "Failed to fetch release metadata: $_"; exit 1
}

$asset = $release.assets | Where-Object { $_.name -eq 'jver.exe' } | Select-Object -First 1
if (-not $asset) { Write-Error "No jver.exe asset found in release."; exit 1 }

$downloadPath = Join-Path $InstallDir 'jver.exe'
Write-Host "==> Downloading $($asset.browser_download_url)" -ForegroundColor Cyan
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath -UseBasicParsing

if (-not (Test-Path $downloadPath)) { Write-Error "Download failed."; exit 1 }

Write-Host "==> Download complete." -ForegroundColor Green

# Ensure install dir is on user PATH
$envKey = 'HKCU:Environment'
$pathValue = (Get-ItemProperty -Path $envKey -Name Path -ErrorAction SilentlyContinue).Path
if (-not $pathValue) { $pathValue = '' }

$paths = $pathValue -split ';' | Where-Object { $_.Trim() }
if ($paths -notcontains $InstallDir) {
  Write-Host "==> Adding $InstallDir to PATH" -ForegroundColor Cyan
  $newPath = ($InstallDir + ';' + ($paths -join ';')).TrimEnd(';')
  Set-ItemProperty -Path $envKey -Name Path -Value $newPath
  Write-Host "   PATH updated. Open a NEW terminal to use 'jver'." -ForegroundColor Yellow
} else {
  Write-Host "==> Install directory already on PATH." -ForegroundColor DarkGray
}

Write-Host "==> Done. Try:  jver list" -ForegroundColor Green