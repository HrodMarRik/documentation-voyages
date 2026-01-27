#!/bin/bash
# Script de lancement phase 1 (liste des écoles)
# Usage: ./run_phase1.sh

cd "$(dirname "$0")" || exit 1

# Activer l'environnement virtuel
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "Erreur: Environnement virtuel non trouvé. Lancez d'abord setup_ubuntu.sh"
    exit 1
fi

# Lancer le scraper phase 1
python scraper_annuaire.py --no-gui --curl-cffi "$@"
