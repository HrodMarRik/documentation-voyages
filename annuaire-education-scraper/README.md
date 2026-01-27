# Scraper Annuaire Education.gouv.fr

Parcourt les 3110 pages de l’annuaire [education.gouv.fr/annuaire](https://www.education.gouv.fr/annuaire), extrait les blocs « Accéder à la fiche » (nom, type, statut, académie, zone, adresse, etc.) et écrit un CSV.

- **Délai** : 11 à 20 secondes (aléatoire) entre chaque requête pour respecter les limites du site.
- **Temps estimé** : 9 h à 17 h pour l’intégralité des pages.

## Installation

```bash
cd annuaire-education-scraper
pip install -r requirements.txt
# Pour --browser ou --cdp : playwright install chromium
```

## Usage

**Avec fenêtre de progression (Tkinter) :**
```bash
python scraper_annuaire.py
```

**Sans interface graphique (console + `progress.json`) :**
```bash
python scraper_annuaire.py --no-gui
```

**Reprise (ex. à partir de la page 500, jusqu’à la 1000) :**
```bash
python scraper_annuaire.py --from-page 500 --to-page 1000 --no-gui
```

**Options :**
- `--from-page N` : page de début (0-based, défaut : 0)
- `--to-page N` : page de fin exclusive (défaut : 3110)
- `--no-gui` : désactive la fenêtre Tkinter
- `--csv FICHIER` : fichier CSV de sortie (défaut : `annuaire_etablissements.csv`)

**Modes de récupération (le site est protégé par Cloudflare ; `requests` seul donne souvent 403) :**
- `--selenium` : Selenium + Chrome (JS, cookies, navigateur réel). ChromeDriver géré par Selenium 4. Cloudflare peut encore bloquer ; si oui, utiliser `--uc` ou `--cdp`.
- `--uc` : undetected-chromedriver (Chrome, anti-détection). Souvent efficace contre Cloudflare.
- `--uc-version N` : avec `--uc`, forcer ChromeDriver pour Chrome majeur N (ex. `143` si Chrome 143.x).
- `--flaresolverr [URL]` : FlareSolverr (Docker ou binaire). Défaut : `http://127.0.0.1:8191`.
- `--browser` : Playwright lance Chrome/Chromium.
- `--cdp [URL]` : Playwright se connecte à un Chrome déjà lancé avec `--remote-debugging-port=9222` (ex. via `run_chrome_cdp.bat`). **Recommandé si bloqué.**
- `--curl-cffi` : curl_cffi, empreinte TLS Chrome (sans navigateur). `pip install curl_cffi`.
- `--headed` : avec `--selenium`, `--uc` ou `--browser`, navigateur visible (peut aider à passer Cloudflare en headless).

Exemples :
```bash
python scraper_annuaire.py --no-gui --selenium
python scraper_annuaire.py --no-gui --uc --uc-version 143
python scraper_annuaire.py --no-gui --flaresolverr
python scraper_annuaire.py --no-gui --cdp
python scraper_annuaire.py --no-gui --curl-cffi
```

### Vous êtes bloqué (Cloudflare) ? — Ordre recommandé

1. **`--cdp`** (le plus fiable)  
   Vous utilisez **votre** Chrome. Aucune détection possible.  
   - Fermez tout Chrome/Edge, lancez `run_chrome_cdp.bat` (ou `chrome --remote-debugging-port=9222`).  
   - Dans ce navigateur : ouvrez https://www.education.gouv.fr/annuaire, passez la vérification Cloudflare si demandé (captcha, attente).  
   - Dans un autre terminal : `python scraper_annuaire.py --no-gui --cdp`

2. **`--flaresolverr`**  
   FlareSolverr est fait pour résoudre les défis Cloudflare.  
   - `docker run -d -p 8191:8191 ghcr.io/flaresolverr/flaresolverr`  
   - `python scraper_annuaire.py --no-gui --flaresolverr`

3. **`--uc --headed --uc-version N`**  
   undetected-chromedriver avec fenêtre visible. Si votre Chrome est en 143 :  
   `python scraper_annuaire.py --no-gui --uc --uc-version 143 --headed`

4. **`--curl-cffi`**  
   Empreinte TLS type Chrome, **sans navigateur**. Peut suffire si le blocage est surtout sur la fingerprint.  
   - `pip install curl_cffi`  
   - `python scraper_annuaire.py --no-gui --curl-cffi`

## Fichiers générés

- **annuaire_etablissements.csv** : établissements extraits (url_fiche, nom, type_etablissement, statut, academie, zone, adresse, code_postal, commune, id_etablissement, nom_slug, page, **telephone** — ce dernier depuis la carte de la liste).
- **progress.json** : progression (page, etablissements, started_at, last_update, eta_seconds, status).

## Phase 2 : Email et téléphone de chaque fiche (`scraper_fiches.py`)

Après avoir généré **annuaire_etablissements.csv** avec `scraper_annuaire.py`, lancez **scraper_fiches.py** pour ouvrir chaque `url_fiche`, extraire **email** et **téléphone**, et produire un CSV enrichi.

**Mêmes modes de fetch** : `--curl-cffi`, `--uc`, `--flaresolverr`, `--cdp`, `--selenium`, `--browser`, `--headed`, `--uc-version`.

```bash
# 1) Phase 1 : lister toutes les écoles (ex. 2 pages pour test)
python scraper_annuaire.py --no-gui --from-page 0 --to-page 2 --curl-cffi

# 2) Phase 2 : enrichir avec email et téléphone depuis chaque fiche
python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_etablissements_complet.csv --curl-cffi
```

**Options de scraper_fiches.py :**
- `--input` : CSV produit par scraper_annuaire (défaut : annuaire_etablissements.csv)
- `--output` : CSV enrichi (défaut : annuaire_etablissements_complet.csv)
- `--from-row`, `--to-row` : traiter uniquement les lignes N à M (pour reprendre ou tester)
- `--delay-min`, `--delay-max` : délai entre 2 fiches en secondes (défaut : 3–8 s)

Le CSV de sortie reprend toutes les colonnes du CSV d’entrée et ajoute **email** et **telephone**. Si la fiche ne contient pas d’email/tel, la valeur de la carte (phase 1) est conservée pour le téléphone lorsqu’elle existe. Mis à jour à chaque page.

## Test d’une page (`test_fetch_page.py`)

Récupère le HTML d’une page, le sauvegarde dans `test_page.html` et l’analyse (blocs, extraction).

```bash
# Requête HTTP (souvent 403 / Cloudflare)
python test_fetch_page.py

# Playwright lance Chrome (souvent bloqué aussi)
python test_fetch_page.py --browser

# Se connecter à un Chrome existant (contourne Cloudflare en réutilisant votre session)
# 1) Fermez Chrome/Edge, puis lancez-le avec le port de debug (gardez-le ouvert) :
#    Windows : run_chrome_cdp.bat  OU  "C:\...\chrome.exe" --remote-debugging-port=9222
#    Edge : "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222
#    Linux/macOS : chrome --remote-debugging-port=9222
# 2) Dans ce navigateur : ouvrez l’annuaire, passez Cloudflare si besoin
# 3) Dans un autre terminal : python test_fetch_page.py --cdp

# curl_cffi (empreinte TLS Chrome, sans navigateur) : souvent non détecté
python test_fetch_page.py --curl-cffi

# Selenium (JS, cookies) : pip install selenium
python test_fetch_page.py --selenium

# Outils a installer : --uc (pip install undetected-chromedriver) et --flaresolverr (Docker/binaire)
python test_fetch_page.py --uc
python test_fetch_page.py --flaresolverr
```

**Outils :** `--curl-cffi` : `pip install curl_cffi` (souvent non détecté, sans navigateur). `--selenium` : `pip install selenium` (Chrome requis). `--uc` : `pip install undetected-chromedriver` (Chrome requis). `--flaresolverr` : lancer FlareSolverr (`docker run -d -p 8191:8191 ghcr.io/flaresolverr/flaresolverr:latest` ou [binaire](https://github.com/FlareSolverr/FlareSolverr/releases)).

**Navigateur Cursor (MCP)** : le navigateur intégré à Cursor charge correctement l’annuaire (pas de blocage Cloudflare), mais il n’expose pas d’API pour exporter le HTML. Il est utile pour vérifier manuellement que la page s’affiche.

## Charger une page en ligne de commande

Sans Python : **curl** ou **Chrome --dump-dom**. Le HTML est écrit dans `test_page.html`.

| Script | Commande | Remarque |
|--------|----------|----------|
| **curl** | `fetch_curl.bat` ou `./fetch_curl.sh [page]` | Souvent 403/Cloudflare. Essai rapide. |
| **Chrome** | `fetch_dom_chrome.bat [page]` ou `./fetch_dom_chrome.sh [page]` | Chrome headless `--dump-dom`. Peut être bloqué aussi. |

`[page]` = numéro de page 0-based (défaut 0). Ex. `fetch_curl.bat 5` ou `./fetch_dom_chrome.sh 5`.

**curl seul (Windows, Git Bash) :**
```bash
curl -s -o test_page.html -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml" -H "Accept-Language: fr-FR,fr;q=0.9" -H "Referer: https://www.education.gouv.fr/" "https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=0"
```

**Chrome --dump-dom seul :**
```batch
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox --dump-dom "https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=0" > test_page.html
```

Si Cloudflare bloque curl et Chrome headless : `run_chrome_cdp.bat` puis `python test_fetch_page.py --cdp`.

## Alternative

Une [API officielle](https://www.data.gouv.fr/fr/dataservices/annuaire-de-leducation-nationale/) (data.education.gouv.fr, jeu `fr-en-annuaire-education`) fournit ~66 000 établissements sans limite de requêtes.
