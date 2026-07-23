# Build dist\TRAPSManager (Release + windeployqt)
$ErrorActionPreference = "Stop"

$QtRoot = "C:\Qt\Qt5.10.1"
$QtBin = "$QtRoot\5.10.1\mingw53_32\bin"
$MingwBin = "$QtRoot\Tools\mingw530_32\bin"
$Repo = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Repo "build-competffck-list"
$Dist = Join-Path $Repo "dist\TRAPSManager"
$Pro = Join-Path $Repo "App\TRAPSPaperless.pro"

$env:PATH = "$MingwBin;$QtBin;" + $env:PATH

if (-not (Test-Path $Build)) {
    New-Item -ItemType Directory -Force -Path $Build | Out-Null
}

Push-Location $Build
try {
    & "$QtBin\qmake.exe" $Pro -spec win32-g++ "CONFIG+=release"
    if ($LASTEXITCODE -ne 0) { throw "qmake failed" }
    & mingw32-make -j4
    if ($LASTEXITCODE -ne 0) { throw "make failed" }
} finally {
    Pop-Location
}

$ExeSrc = Join-Path $Build "release\TRAPSManager.exe"
if (-not (Test-Path $ExeSrc)) { throw "Missing $ExeSrc" }

if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Copy-Item $ExeSrc $Dist -Force

foreach ($dll in @("libgcc_s_dw2-1.dll","libstdc++-6.dll","libwinpthread-1.dll")) {
    $src = Join-Path $MingwBin $dll
    if (Test-Path $src) { Copy-Item $src $Dist -Force }
}

& "$QtBin\windeployqt.exe" --release --compiler-runtime --qmldir (Join-Path $Repo "App\qml") (Join-Path $Dist "TRAPSManager.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed" }

Write-Host "OK: $Dist"
