@echo off
cd /d "%~dp0"
set PAGE=0
if not "%~1"=="" set PAGE=%~1
set "URL=https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point=&page=%PAGE%"

echo Chargement de la page %PAGE% avec Chrome (--headless --dump-dom) ...
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox --dump-dom "%URL%" > test_page.html 2>nul
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox --dump-dom "%URL%" > test_page.html 2>nul
) else (
    echo Chrome introuvable.
    exit /b 1
)
echo HTML sauve dans test_page.html
echo (Si Cloudflare bloque en headless, utilisez run_chrome_cdp.bat + python test_fetch_page.py --cdp)
