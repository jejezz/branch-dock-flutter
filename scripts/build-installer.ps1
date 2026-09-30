<#
.SYNOPSIS
  Build the Windows installer locally (Inno Setup), the same way
  .github/workflows/release.yml's `build-windows` job does.

.DESCRIPTION
  Reads the app metadata from the same sources as the workflow:
    display name  macos/Runner/Configs/AppInfo.xcconfig  (PRODUCT_NAME)
    file name     display name without non-alphanumerics
    version       pubspec.yaml (the `+build` part is dropped)
    exe name      windows/CMakeLists.txt (BINARY_NAME)
  then runs `flutter build windows --release` and ISCC on
  installer/windows/app.iss.

  Output: dist\<FileName>-<version>-windows-x64-setup.exe

.EXAMPLE
  scripts\build-installer.ps1
  scripts\build-installer.ps1 -SkipBuild
  scripts\build-installer.ps1 -Version 1.5.0-rc.1
#>
[CmdletBinding()]
param(
  # Reuse the existing build\windows\x64\runner\Release instead of rebuilding.
  [switch]$SkipBuild,
  # Override the version taken from pubspec.yaml (e.g. 1.5.0-rc.1).
  [string]$Version
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Get-FirstMatch([string]$Path, [string]$Pattern) {
  $m = Select-String -Path $Path -Pattern $Pattern | Select-Object -First 1
  if (-not $m) { throw "Cannot find /$Pattern/ in $Path" }
  $m.Matches[0].Groups[1].Value.Trim()
}

$displayName = Get-FirstMatch 'macos\Runner\Configs\AppInfo.xcconfig' '^PRODUCT_NAME\s*=\s*(.+)$'
$fileName    = $displayName -replace '[^A-Za-z0-9]', ''
$binaryName  = Get-FirstMatch 'windows\CMakeLists.txt' 'set\(BINARY_NAME "([^"]+)"\)'
if (-not $Version) {
  $Version = Get-FirstMatch 'pubspec.yaml' '^version:\s*([^\s+]+)'
}
# VersionInfoVersion only takes digits: 1.5.0-rc.1 -> 1.5.0
$numericVersion = ($Version -split '-')[0]

$iscc = @(
  (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source,
  "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
  "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
  "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $iscc) {
  throw 'Inno Setup 6 not found. Install it: choco install innosetup -y (or https://jrsoftware.org/isdl.php)'
}

Write-Host "$displayName $Version -> $fileName-$Version-windows-x64-setup.exe"

if (-not $SkipBuild) {
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
}
$releaseDir = "build\windows\x64\runner\Release\$binaryName.exe"
if (-not (Test-Path $releaseDir)) {
  throw "$releaseDir not found. Run without -SkipBuild."
}

& $iscc `
  "/DMyAppName=$displayName" `
  "/DMyFileName=$fileName" `
  "/DMyAppVersion=$Version" `
  "/DMyAppNumericVersion=$numericVersion" `
  "/DMyAppExeName=$binaryName.exe" `
  installer\windows\app.iss
if ($LASTEXITCODE -ne 0) { throw 'ISCC failed' }

$out = Join-Path (Get-Location) "dist\$fileName-$Version-windows-x64-setup.exe"
Write-Host "Done: $out"
