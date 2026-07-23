# Packaging Windows — TRAPSManager

## Prérequis
- Qt 5.10.1 MinGW 32-bit (`C:\Qt\Qt5.10.1`)
- Inno Setup 6 (`ISCC.exe`)

## Étapes

### Tout-en-un (recommandé sous Windows)
Double-clic ou en invite de commandes :
```bat
packaging\build-dist.bat
```
Cela contourne la politique d’exécution PowerShell, rebuild le dossier `dist\TRAPSManager`, puis lance Inno Setup.

### Manuellement
```powershell
powershell -ExecutionPolicy Bypass -File .\packaging\build-dist.ps1
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" packaging\TRAPSManager.iss
```

### Résultat
- Portable : `dist\TRAPSManager\`
- Installeur : `dist\installer\TRAPSManager-Setup-4.6.exe`
