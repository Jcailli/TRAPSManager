#!/bin/bash
# Script pour déboguer le problème de build

echo "🔍 Débogage du problème de build .exe"

# Vérifier les dossiers créés
echo "📁 Dossiers créés:"
ls -la

echo ""
echo "📁 Contenu de windows-build:"
if [ -d "windows-build" ]; then
    ls -la windows-build/
else
    echo "❌ Dossier windows-build non trouvé"
fi

echo ""
echo "📁 Contenu de windows-exe:"
if [ -d "windows-exe" ]; then
    ls -la windows-exe/
else
    echo "❌ Dossier windows-exe non trouvé"
fi

echo ""
echo "📁 Contenu de windows-build/App:"
if [ -d "windows-build/App" ]; then
    ls -la windows-build/App/
    echo ""
    echo "🔍 Recherche de fichiers .exe:"
    find windows-build/ -name "*.exe" -type f
    echo ""
    echo "🔍 Recherche de fichiers exécutables:"
    find windows-build/ -name "TRAPSManager*" -type f
else
    echo "❌ Dossier windows-build/App non trouvé"
fi

echo ""
echo "🔍 Vérification de MinGW:"
if command -v x86_64-w64-mingw32-g++ &> /dev/null; then
    echo "✅ MinGW installé: $(x86_64-w64-mingw32-g++ --version | head -1)"
else
    echo "❌ MinGW non installé"
fi

echo ""
echo "🔍 Vérification de qmake:"
if command -v qmake &> /dev/null; then
    echo "✅ qmake installé: $(qmake --version | head -1)"
else
    echo "❌ qmake non installé"
fi
