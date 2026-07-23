# Packaging Windows — TRAPSManager

## Prérequis
- Qt 5.10.1 MinGW 32-bit (`C:\Qt\Qt5.10.1`)
- Inno Setup 6 (`ISCC.exe`)

## Étapes

### Tout-en-un (recommandé sous Windows)
Depuis la racine du monorepo ou depuis `trapsmanager/` :
```bat
trapsmanager\packaging\build-dist.bat
```
Cela rebuild `dist\TRAPSManager` à la racine du monorepo, puis lance Inno Setup.

### Manuellement
```powershell
powershell -ExecutionPolicy Bypass -File .\trapsmanager\packaging\build-dist.ps1
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" trapsmanager\packaging\TRAPSManager.iss
```

### Résultat (racine monorepo)
- Portable : `dist\TRAPSManager\`
- Installeur : `dist\installer\TRAPSManager-Setup-4.6.exe`

### Projet Qt
Ouvrir dans Qt Creator : `trapsmanager/App/TRAPSPaperless.pro`
