# TRAPSManager - Génération .exe Windows depuis WSL

## 🎯 Objectif
Générer un **exécutable Windows (.exe)** depuis WSL Ubuntu en utilisant Wine + Qt Windows.

## 🚀 Méthode Simple : Wine + Qt

### **Avantages :**
- ✅ **Simple** : Pas de Docker complexe
- ✅ **Fiable** : Wine + Qt Windows officiel
- ✅ **Rapide** : Compilation directe
- ✅ **Natif** : Vrai .exe Windows

### **Prérequis :**
```bash
# Wine installé
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y wine32:i386 wine64

# Vérifier Wine
wine --version
```

## 🔧 Utilisation

### **1. Lancer le script :**
```bash
./build-windows-exe.sh
```

### **2. Processus automatique :**
1. **Vérification** de Wine
2. **Téléchargement** de Qt Online Installer
3. **Installation** de Qt Windows via Wine
4. **Compilation** du projet avec Qt Windows
5. **Génération** du .exe Windows
6. **Package** final avec documentation

### **3. Résultat :**
Le dossier `windows-exe/` contiendra :
- ✅ **TRAPSManager.exe** - Exécutable Windows
- ✅ **TRAPSManager.bat** - Script de lancement
- ✅ **README-Windows.txt** - Instructions
- ✅ **Interface web** (si incluse)
- ✅ **Configuration** (si incluse)

## 📁 Structure Finale

```
TRAPSManager/
├── build-windows-exe.sh          # ✅ Script de build
├── README-Windows-EXE.md         # ✅ Documentation
├── windows-build/                # ✅ Dossier de travail
└── windows-exe/                  # ✅ .exe Windows
    ├── TRAPSManager.exe          # ✅ Exécutable natif
    ├── TRAPSManager.bat          # ✅ Script de lancement
    ├── README-Windows.txt        # ✅ Instructions
    ├── docroot/                  # ✅ Interface web
    └── config/                   # ✅ Configuration
```

## 🖥️ Utilisation sur Windows

1. **Copiez** le dossier `windows-exe/` sur Windows
2. **Double-cliquez** sur `TRAPSManager.exe`
3. **L'application fonctionnera nativement** sur Windows !

## 🔧 Dépannage

### **Wine non installé**
```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y wine32:i386 wine64
winecfg -v win10
```

### **Qt Online Installer ne se lance pas**
```bash
# Vérifier Wine
wine --version

# Reconfigurer Wine
winecfg -v win10

# Relancer le script
./build-windows-exe.sh
```

### **Erreur de compilation**
- Vérifiez que Qt est bien installé via Wine
- Vérifiez que le projet compile localement
- Relancez le script

## 🎉 Avantages

- ✅ **.exe Windows** (100% natif)
- ✅ **Environnement simple** (Wine + Qt)
- ✅ **Rapide** (pas de Docker)
- ✅ **Fiable** (Qt Windows officiel)
- ✅ **Maintenable** (facile à mettre à jour)
- ✅ **Compatible WSL** (fonctionne parfaitement)

## 📞 Support

- Documentation : `memory-bank/`
- Site web : http://www.traps-ck.com
- Version : 4.5
