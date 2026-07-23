#!/bin/bash
# Script pour corriger les problèmes Wine

echo "🔧 Correction des problèmes Wine..."

# Supprimer l'ancienne configuration Wine
echo "🗑️ Suppression de l'ancienne configuration Wine..."
rm -rf ~/.wine
rm -rf ~/.wine32

# Réinstaller Wine proprement
echo "📦 Réinstallation de Wine..."
sudo apt-get remove --purge wine* -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# Ajouter l'architecture i386
sudo dpkg --add-architecture i386
sudo apt-get update

# Installer Wine
sudo apt-get install -y wine32:i386 wine64

# Configurer Wine
echo "⚙️ Configuration de Wine..."
export WINEARCH=win64
export WINEPREFIX=~/.wine
winecfg -v win10

# Vérifier Wine
echo "✅ Vérification de Wine..."
wine --version

if [ $? -eq 0 ]; then
    echo "🎉 Wine fonctionne correctement !"
else
    echo "❌ Wine ne fonctionne toujours pas"
    echo "💡 Essayez de redémarrer WSL ou votre session"
fi
