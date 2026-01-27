#!/usr/bin/env bash
# Charge une page de l'annuaire avec curl. Souvent 403/Cloudflare.
# Usage: ./fetch_curl.sh [page]
#   page: numero 0-based (defaut 0)

cd "$(dirname "$0")"
PAGE="${1:-0}"
URL="https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=${PAGE}"

echo "Chargement de la page ${PAGE} avec curl..."
curl -s -o test_page.html \
  -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: fr-FR,fr;q=0.9,en;q=0.8" \
  -H "Referer: https://www.education.gouv.fr/" \
  "$URL"
echo "HTML sauve dans test_page.html"
echo "(Souvent 403/Cloudflare. Sinon: fetch_dom_chrome.bat ou python test_fetch_page.py --cdp)"
