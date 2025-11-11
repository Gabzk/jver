Param(
  [string]$InstallDir = "$env:LOCALAPPDATA\\jver"
)

Write-Host "==> Uninstalling JVer from $InstallDir" -ForegroundColor Cyan

if (Test-Path $InstallDir) {
  Remove-Item -Path $InstallDir -Recurse -Force
  Write-Host "Removed directory." -ForegroundColor Green
} else {
  Write-Host "Directory not found, skipping removal." -ForegroundColor Yellow
}

# Remove from PATH
$envKey = 'HKCU:Environment'
$pathValue = (Get-ItemProperty -Path $envKey -Name Path -ErrorAction SilentlyContinue).Path
if ($pathValue) {
  $paths = $pathValue -split ';' | Where-Object { $_.Trim() -and ($_ -ne $InstallDir) }
  $newPath = ($paths -join ';').TrimEnd(';')
  Set-ItemProperty -Path $envKey -Name Path -Value $newPath
  Write-Host "PATH cleaned. Open a NEW terminal to finalize." -ForegroundColor Yellow
} else {
  Write-Host "PATH not found, nothing to clean." -ForegroundColor DarkGray
}

Write-Host "==> Uninstall complete." -ForegroundColor Green