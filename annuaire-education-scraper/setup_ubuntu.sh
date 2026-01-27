#!/bin/bash
# Script d'installation automatique pour Ubuntu 24
# Usage: bash setup_ubuntu.sh

set -e  # Arrêter en cas d'erreur

echo "=========================================="
echo "Installation annuaire-education-scraper"
echo "=========================================="
echo ""

# Vérifier qu'on est sur Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    echo "Erreur: Ce script est conçu pour Ubuntu/Debian"
    exit 1
fi

# 1. Mettre à jour le système
echo "[1/6] Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# 2. Installer les prérequis système
echo ""
echo "[2/6] Installation des prérequis système..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    curl \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev

# 3. Créer le dossier du projet (si pas déjà fait)
echo ""
echo "[3/6] Préparation du dossier du projet..."
PROJECT_DIR="$HOME/annuaire-education-scraper"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 4. Créer l'environnement virtuel
echo ""
echo "[4/6] Création de l'environnement virtuel Python..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Environnement virtuel créé"
else
    echo "✓ Environnement virtuel existe déjà"
fi

# 5. Activer et installer les dépendances
echo ""
echo "[5/6] Installation des dépendances Python..."
source venv/bin/activate
pip install --upgrade pip setuptools wheel

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "✓ Dépendances installées depuis requirements.txt"
else
    echo "⚠ requirements.txt introuvable, installation manuelle..."
    pip install requests beautifulsoup4 lxml tqdm playwright selenium undetected-chromedriver curl_cffi
fi

# 6. Installer les navigateurs pour Playwright
echo ""
echo "[6/6] Installation des navigateurs pour Playwright..."
playwright install chromium || echo "⚠ Playwright install échoué (optionnel)"

echo ""
echo "=========================================="
echo "Installation terminée !"
echo "=========================================="
echo ""
echo "Pour utiliser le scraper :"
echo "  1. cd $PROJECT_DIR"
echo "  2. source venv/bin/activate"
echo "  3. python scraper_annuaire.py --no-gui --curl-cffi"
echo ""
echo "Ou pour la phase 2 :"
echo "  python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_etablissements_complet.csv --curl-cffi"
echo ""
