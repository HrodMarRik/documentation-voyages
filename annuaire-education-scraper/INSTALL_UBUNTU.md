# Installation et utilisation sur Ubuntu 24

## Prérequis

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Python 3 et pip
sudo apt install -y python3 python3-pip python3-venv

# Installer les dépendances système pour les navigateurs
sudo apt install -y \
    wget \
    curl \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev
```

## Installation du projet

### 1. Copier les fichiers sur Ubuntu

Depuis Windows, copiez ces fichiers vers Ubuntu (via SCP, USB, réseau, etc.) :

**Fichiers essentiels :**
- `scraper_annuaire.py`
- `scraper_fiches.py`
- `test_fetch_page.py`
- `requirements.txt`
- `README.md`
- `annuaire_etablissements.csv` (si vous avez déjà le CSV de la phase 1)

**Optionnel :**
- `fetch_curl.sh`
- `fetch_dom_chrome.sh`

### 2. Sur Ubuntu, créer le dossier et copier les fichiers

```bash
# Créer le dossier du projet
mkdir -p ~/annuaire-education-scraper
cd ~/annuaire-education-scraper

# Copier tous les fichiers .py, requirements.txt, README.md ici
# (via SCP, USB, ou autre méthode)
```

### 3. Créer un environnement virtuel Python

```bash
cd ~/annuaire-education-scraper

# Créer l'environnement virtuel
python3 -m venv venv

# Activer l'environnement virtuel
source venv/bin/activate

# Mettre à jour pip
pip install --upgrade pip setuptools wheel
```

### 4. Installer les dépendances Python

```bash
# Toujours dans l'environnement virtuel (venv)
pip install -r requirements.txt

# Installer les navigateurs pour Playwright (si vous utilisez --browser ou --cdp)
playwright install chromium
```

## Utilisation

### Activer l'environnement virtuel (à faire à chaque fois)

```bash
cd ~/annuaire-education-scraper
source venv/bin/activate
```

### Phase 1 : Récupérer toutes les données des écoles

```bash
# Mode curl_cffi (recommandé, souvent non détecté)
python scraper_annuaire.py --no-gui --curl-cffi

# Ou avec d'autres modes :
# python scraper_annuaire.py --no-gui --uc
# python scraper_annuaire.py --no-gui --flaresolverr
# python scraper_annuaire.py --no-gui --cdp
```

**Options utiles :**
```bash
# Traiter seulement quelques pages pour tester
python scraper_annuaire.py --no-gui --from-page 0 --to-page 10 --curl-cffi

# Reprendre depuis une page spécifique
python scraper_annuaire.py --no-gui --from-page 500 --to-page 1000 --curl-cffi
```

### Phase 2 : Récupérer email et téléphone depuis chaque fiche

```bash
# Après avoir généré annuaire_etablissements.csv en phase 1
python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_etablissements_complet.csv --curl-cffi
```

**Options utiles :**
```bash
# Traiter seulement quelques lignes pour tester
python scraper_fiches.py --from-row 0 --to-row 10 --curl-cffi

# Reprendre depuis une ligne spécifique (ex. après interruption)
python scraper_fiches.py --from-row 3979 --curl-cffi

# Ajuster les délais entre requêtes (défaut: 3-8 secondes)
python scraper_fiches.py --delay-min 5 --delay-max 10 --curl-cffi
```

## Modes de fetch disponibles

### 1. `--curl-cffi` (recommandé)
```bash
python scraper_annuaire.py --no-gui --curl-cffi
python scraper_fiches.py --curl-cffi
```
- **Avantage** : Empreinte TLS Chrome, souvent non détecté, pas de navigateur
- **Installation** : Inclus dans `requirements.txt`

### 2. `--uc` (undetected-chromedriver)
```bash
# Installer Chrome/Chromium d'abord
sudo apt install -y chromium-browser

python scraper_annuaire.py --no-gui --uc
python scraper_fiches.py --uc
```
- **Avantage** : Chrome réel, anti-détection
- **Note** : Peut nécessiter `--uc-version N` (ex. `--uc-version 131`)

### 3. `--flaresolverr`
```bash
# Installer Docker d'abord
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Lancer FlareSolverr
docker run -d -p 8191:8191 ghcr.io/flaresolverr/flaresolverr:latest

# Utiliser
python scraper_annuaire.py --no-gui --flaresolverr
python scraper_fiches.py --flaresolverr
```

### 4. `--cdp` (Chrome DevTools Protocol)
```bash
# Lancer Chrome avec le port de debug
chromium-browser --remote-debugging-port=9222 &

# Dans un autre terminal, utiliser
python scraper_annuaire.py --no-gui --cdp
python scraper_fiches.py --cdp
```

### 5. `--browser` (Playwright)
```bash
python scraper_annuaire.py --no-gui --browser
python scraper_fiches.py --browser
```

## Fichiers générés

- **`annuaire_etablissements.csv`** : Sortie de la phase 1 (toutes les données + téléphone depuis la carte)
- **`annuaire_etablissements_complet.csv`** : Sortie de la phase 2 (toutes les colonnes + email + téléphone depuis la fiche)
- **`progress.json`** : Progression de la phase 1

## Scripts shell utiles

### Script de lancement rapide (créer `run_phase1.sh`)

```bash
#!/bin/bash
cd ~/annuaire-education-scraper
source venv/bin/activate
python scraper_annuaire.py --no-gui --curl-cffi
```

Rendre exécutable :
```bash
chmod +x run_phase1.sh
./run_phase1.sh
```

### Script de lancement phase 2 (créer `run_phase2.sh`)

```bash
#!/bin/bash
cd ~/annuaire-education-scraper
source venv/bin/activate
python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_etablissements_complet.csv --curl-cffi
```

Rendre exécutable :
```bash
chmod +x run_phase2.sh
./run_phase2.sh
```

## Dépannage

### Erreur "curl_cffi not found"
```bash
source venv/bin/activate
pip install curl_cffi --upgrade
```

### Erreur "Chrome/Chromium not found" (pour --uc ou --cdp)
```bash
sudo apt install -y chromium-browser
```

### Erreur de permissions (pour Playwright)
```bash
playwright install chromium --with-deps
```

### Vérifier l'installation
```bash
source venv/bin/activate
python -c "import curl_cffi; print('curl_cffi OK')"
python -c "import bs4; print('beautifulsoup4 OK')"
python -c "import playwright; print('playwright OK')"
```

## Commandes rapides (copier-coller)

### Installation complète (une seule fois)

```bash
# 1. Prérequis système
sudo apt update && sudo apt install -y python3 python3-pip python3-venv wget curl git build-essential libssl-dev libffi-dev python3-dev

# 2. Créer le projet
mkdir -p ~/annuaire-education-scraper
cd ~/annuaire-education-scraper

# 3. Créer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate

# 4. Installer les dépendances
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
playwright install chromium

# 5. Vérifier
python -c "import curl_cffi; print('Installation OK')"
```

### Lancement phase 1

```bash
cd ~/annuaire-education-scraper
source venv/bin/activate
python scraper_annuaire.py --no-gui --curl-cffi
```

### Lancement phase 2

```bash
cd ~/annuaire-education-scraper
source venv/bin/activate
python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_etablissements_complet.csv --curl-cffi
```

## Notes importantes

- **Toujours activer l'environnement virtuel** avec `source venv/bin/activate` avant de lancer les scripts
- Le CSV d'entrée doit être en **UTF-8 avec BOM** (utf-8-sig) pour Excel
- Les délais entre requêtes sont importants pour ne pas surcharger le serveur
- En cas d'interruption, utilisez `--from-row` ou `--from-page` pour reprendre
- Le mode `--curl-cffi` est généralement le plus fiable et le plus rapide
