@echo off
cd /d "%~dp0"
set PAGE=0
if not "%~1"=="" set PAGE=%~1
set "URL=https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=%PAGE%"

echo Chargement de la page %PAGE% avec curl ...
curl.exe -s -o test_page.html -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: fr-FR,fr;q=0.9,en;q=0.8" -H "Referer: https://www.education.gouv.fr/" "%URL%"
if errorlevel 1 (
    echo curl a echoue. Verifiez que curl est installe (Windows 10+ ou Git pour Windows).
    exit /b 1
)
echo HTML sauve dans test_page.html
echo (Souvent 403/Cloudflare avec curl. Si oui : fetch_dom_chrome.bat ou test_fetch_page.py --cdp)
