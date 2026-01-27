#!/usr/bin/env bash
# Charge une page avec Chrome --headless --dump-dom.
# Usage: ./fetch_dom_chrome.sh [page]
#   page: numero 0-based (defaut 0)
# Si Cloudflare bloque en headless: run_chrome_cdp.bat + python test_fetch_page.py --cdp

cd "$(dirname "$0")"
PAGE="${1:-0}"
URL="https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=${PAGE}"

CHROME=""
[ -f "/c/Program Files/Google/Chrome/Application/chrome.exe" ] && CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
[ -z "$CHROME" ] && [ -f "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" ] && CHROME="/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
[ -z "$CHROME" ] && command -v google-chrome >/dev/null 2>&1 && CHROME="google-chrome"
[ -z "$CHROME" ] && command -v chromium >/dev/null 2>&1 && CHROME="chromium"
[ -z "$CHROME" ] && command -v chromium-browser >/dev/null 2>&1 && CHROME="chromium-browser"

if [ -z "$CHROME" ]; then
  echo "Chrome/Chromium introuvable."
  exit 1
fi

echo "Chargement de la page ${PAGE} avec Chrome (--headless --dump-dom)..."
"$CHROME" --headless=new --disable-gpu --no-sandbox --dump-dom "$URL" > test_page.html 2>/dev/null
echo "HTML sauve dans test_page.html"
