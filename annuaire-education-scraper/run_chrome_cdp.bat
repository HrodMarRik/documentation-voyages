@echo off
echo Fermez toutes les fenetres Chrome, puis appuyez sur une touche.
pause >nul
echo Demarrage de Chrome avec --remote-debugging-port=9222 ...
echo Gardez cette fenetre ouverte. Dans un autre terminal : python test_fetch_page.py --cdp
echo.
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
) else (
    echo Chrome introuvable. Lancez manuellement : chrome.exe --remote-debugging-port=9222
    pause
)
