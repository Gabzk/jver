function Install-Jver {
  param(
    [string]$Version = "latest",
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "jver"),
    [string]$Repo = "Gabzk/jver",
    [switch]$Force,
    [switch]$SkipPath,
    [switch]$Verbose
  )

  Write-Host "==> Installing jver ($Version) to $InstallDir" -ForegroundColor Cyan
  if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }

  if ($Version -eq "latest") { $api = "https://api.github.com/repos/$Repo/releases/latest" }
  else { $api = "https://api.github.com/repos/$Repo/releases/tags/$Version" }

  try {
    $release = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'jver-installer' }
  } catch {
    if ($Version -eq "latest") {
      Write-Warning "No stable release found. Trying 'nightly' tag..."
      try {
        $api = "https://api.github.com/repos/$Repo/releases/tags/nightly"
        $release = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'jver-installer' }
      } catch {
        Write-Error "No releases available (stable or nightly). Create one first."; return
      }
    } else {
      Write-Error "Failed to fetch release '$Version': $_"; return
    }
  }

  if ($Verbose) { Write-Host "Release tag: $($release.tag_name)" -ForegroundColor DarkCyan }

  $asset = $release.assets | Where-Object { $_.name -eq 'jver.exe' } | Select-Object -First 1
  if (-not $asset) { Write-Error "Release has no jver.exe asset."; return }

  $downloadPath = Join-Path $InstallDir 'jver.exe'
  if ((Test-Path $downloadPath) -and -not $Force) {
    Write-Host "jver.exe already exists. Use -Force to overwrite." -ForegroundColor Yellow
  } else {
    Write-Host "==> Downloading $($asset.browser_download_url)" -ForegroundColor Cyan
    try {
      Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
    } catch {
      Write-Error "Download failed: $_"; return
    }
    if (-not (Test-Path $downloadPath)) { Write-Error "Download failed (file missing)."; return }
    Write-Host "==> Download complete." -ForegroundColor Green
  }

  # Optional checksum verification if .sha256 asset exists
  $shaAsset = $release.assets | Where-Object { $_.name -eq 'jver.exe.sha256' } | Select-Object -First 1
  if ($shaAsset) {
    try {
      $shaTemp = Join-Path $env:TEMP "jver.exe.sha256"
      Invoke-WebRequest -Uri $shaAsset.browser_download_url -OutFile $shaTemp -UseBasicParsing -ErrorAction Stop
      $expected = (Get-Content $shaTemp).Split(' ')[0].Trim()
      $actual = (Get-FileHash $downloadPath -Algorithm SHA256).Hash.ToLower()
      if ($actual -ne $expected.ToLower()) {
        Write-Error "Checksum mismatch! Expected $expected got $actual"; return
      } else { Write-Host "Checksum OK." -ForegroundColor DarkGreen }
    } catch { Write-Warning "Checksum download/verify failed: $_" }
  }

  if (-not $SkipPath) {
    $envKey = 'HKCU:Environment'
    $pathValue = (Get-ItemProperty -Path $envKey -Name Path -ErrorAction SilentlyContinue).Path
    if (-not $pathValue) { $pathValue = '' }
    $paths = $pathValue -split ';' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
    if ($paths -notcontains $InstallDir) {
      Write-Host "==> Adding $InstallDir to PATH" -ForegroundColor Cyan
      $newPath = ($InstallDir + ';' + ($paths -join ';')).TrimEnd(';')
      Set-ItemProperty -Path $envKey -Name Path -Value $newPath
      Write-Host "PATH updated. Open a NEW terminal to use 'jver'." -ForegroundColor Yellow
    } else {
      Write-Host "Install directory already on PATH." -ForegroundColor DarkGray
    }
  } else {
    Write-Host "Skipped PATH modification (user chose -SkipPath)." -ForegroundColor DarkGray
  }

  Write-Host "==> Done. Try:  jver list" -ForegroundColor Green
}

# Auto-run only if not already defined in current session (prevents duplicate when re-sourcing)
if (-not (Get-Command Install-Jver -ErrorAction SilentlyContinue)) {
  Set-Alias Install-Jver Install-Jver -Scope Script
}

# If invoked through iwr|iex the function will auto-run with defaults
if ($MyInvocation.InvocationName -eq '.') { } else { 
  if ($PSCommandPath -and $PSCommandPath.EndsWith('install-jver.ps1')) { Install-Jver }
  elseif (-not $PSCommandPath) { Install-Jver }
}