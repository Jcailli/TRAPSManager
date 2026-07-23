# TRAPS — monorepo

Passerelle et applications pour la gestion de compétitions canoë-kayak (slalom, kayak cross, etc.).

## Structure

| Dossier | Contenu |
|---------|---------|
| **`trapsmanager/`** | Sources **TRAPSManager** (PC, Qt/C++/QML) — serveur / passerelle |
| **`traps-ck/`** | Sources **TRAPS-CK** (Android, juges) — slalom / kayak cross |
| **`memory-bank/`** | Documentation projet (Cursor) |
| **`dist/`** | Artefacts build / installeur (gitignoré) |

## TRAPSManager

```text
trapsmanager/App/TRAPSPaperless.pro   ← ouvrir dans Qt Creator
trapsmanager/packaging/build-dist.bat ← build + installeur Windows
```

Voir aussi `trapsmanager/README-Windows-EXE.md` et `trapsmanager/packaging/README.md`.

## TRAPS-CK

Application Android native (`com.traps.trapsapp`) pour les juges / chronométreurs.

```text
traps-ck/   ← ouvrir dans Android Studio
```

Voir `traps-ck/README.md` (build, signature, Docker) et **`traps-ck/ROADMAP-4.0.md`** (évolution 4.0).

## Licence

- Manager : `trapsmanager/LICENSE`
- TRAPS-CK : `traps-ck/LICENSE`
