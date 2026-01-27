#!/bin/bash
# Script de lancement phase 2 (email et téléphone depuis fiches)
# Usage: ./run_phase2.sh [--from-row N] [--to-row M]

cd "$(dirname "$0")" || exit 1

# Activer l'environnement virtuel
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "Erreur: Environnement virtuel non trouvé. Lancez d'abord setup_ubuntu.sh"
    exit 1
fi

# Vérifier que le CSV d'entrée existe
if [ ! -f "annuaire_etablissements.csv" ]; then
    echo "Erreur: annuaire_etablissements.csv introuvable"
    echo "Lancez d'abord la phase 1: ./run_phase1.sh"
    exit 1
fi

# Lancer le scraper phase 2
python scraper_fiches.py \
    --input annuaire_etablissements.csv \
    --output annuaire_etablissements_complet.csv \
    --curl-cffi \
    "$@"
