<#
.SYNOPSIS
  Gera o build release do Nexa Messaging para Windows, o .zip portátil e o instalador.

.DESCRIPTION
  1. Executa `flutter build windows --release` (a menos que -SkipBuild seja usado).
  2. Copia as DLLs do runtime Visual C++ para a pasta do app, para que ele rode
     em máquinas sem o Visual C++ Redistributable instalado.
  3. Compacta a pasta Release em dist/nexa-messaging-<versão>-windows-x64.zip.
  4. Compila o instalador com o Inno Setup em dist/nexa-messaging-<versão>-windows-x64-setup.exe.
  5. Gera dist/SHA256SUMS.txt.

.EXAMPLE
  ./tool/build_windows_release.ps1
  ./tool/build_windows_release.ps1 -SkipBuild
#>
[CmdletBinding()]
param(
  [switch]$SkipBuild,
  [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$releaseDir = Join-Path $root 'build\windows\x64\runner\Release'
$distDir = Join-Path $root 'dist'
$issFile = Join-Path $root 'installer\windows\nexa_messaging_desktop.iss'

$versionLine = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
if (-not $versionLine) { throw 'Não foi possível ler a versão do pubspec.yaml.' }
$version = ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]

Write-Host "Nexa Messaging $version" -ForegroundColor Cyan

if (-not $SkipBuild) {
  Push-Location $root
  try {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows falhou.' }
  } finally {
    Pop-Location
  }
}

if (-not (Test-Path (Join-Path $releaseDir 'nexa_messaging_desktop.exe'))) {
  throw "Build não encontrado em $releaseDir. Execute sem -SkipBuild."
}

function Find-VcRuntimeDir {
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -products * -property installationPath
    if ($vsPath) {
      $crt = Get-ChildItem (Join-Path $vsPath 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT') -Directory -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
      if ($crt) { return $crt.FullName }
    }
  }
  return Join-Path $env:WINDIR 'System32'
}

$vcRuntimeDir = Find-VcRuntimeDir
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  $source = Join-Path $vcRuntimeDir $dll
  if (-not (Test-Path $source)) { throw "DLL do runtime Visual C++ não encontrada: $source" }
  Copy-Item $source $releaseDir -Force
}
Write-Host "Runtime Visual C++ copiado de $vcRuntimeDir"

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$zipPath = Join-Path $distDir "nexa-messaging-$version-windows-x64.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath
Write-Host "Zip portátil: $zipPath" -ForegroundColor Green

$artifacts = @($zipPath)

if (-not $SkipInstaller) {
  $iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source
  if (-not $iscc) {
    $iscc = @(
      "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
      "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
      "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $iscc) {
    throw 'Inno Setup 6 não encontrado. Instale com: winget install --id JRSoftware.InnoSetup -e'
  }

  & $iscc "/DAppVersion=$version" "/DSourceDir=$releaseDir" "/DOutputDir=$distDir" $issFile
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o instalador.' }

  $setupPath = Join-Path $distDir "nexa-messaging-$version-windows-x64-setup.exe"
  Write-Host "Instalador: $setupPath" -ForegroundColor Green
  $artifacts += $setupPath
}

$sums = $artifacts | ForEach-Object {
  $hash = (Get-FileHash $_ -Algorithm SHA256).Hash.ToLower()
  "$hash  $(Split-Path $_ -Leaf)"
}
$sums | Set-Content (Join-Path $distDir 'SHA256SUMS.txt') -Encoding ascii
$sums | ForEach-Object { Write-Host $_ }
