@echo off
setlocal
cd /d "%~dp0.."

echo === TRAPSManager : build Release + windeployqt ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-dist.ps1"
if errorlevel 1 (
  echo.
  echo ECHEC du build dist.
  pause
  exit /b 1
)

echo.
echo === Inno Setup : creation de l'installeur ===
set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" (
  echo ISCC.exe introuvable. Installez Inno Setup 6.
  pause
  exit /b 1
)

"%ISCC%" "%~dp0TRAPSManager.iss"
if errorlevel 1 (
  echo.
  echo ECHEC Inno Setup.
  pause
  exit /b 1
)

echo.
echo OK - Installeur : dist\installer\TRAPSManager-Setup-4.6.exe
pause
