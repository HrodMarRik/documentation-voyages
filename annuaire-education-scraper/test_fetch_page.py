#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test : recupere le HTML d'une page de l'annuaire education.gouv.fr,
le sauvegarde et l'analyse (blocs, selecteurs).

  --uc       : undetected-chromedriver (Chrome anti-detection, contourne souvent Cloudflare).
  --uc-version N : avec --uc, force ChromeDriver pour Chrome majeur N (ex. 143 si Chrome 143.x).
  --selenium : Selenium + Chrome (JS, cookies, navigateur reel). ChromeDriver via Selenium 4.
  --flaresolverr [URL]: envoie l'URL a FlareSolverr (Docker ou binaire). Pip: inutile. FlareSolverr a installer a part.
  --browser  : Playwright lance Chrome/Chromium (souvent bloque Cloudflare).
  --cdp [URL]: Playwright se connecte a un Chrome existant (--remote-debugging-port=9222).
  --curl-cffi : empreinte TLS Chrome, sans navigateur (pip install curl_cffi).
  Sans option: requete requests (souvent bloque 403/Cloudflare).

Le navigateur Cursor (MCP) charge bien l'annuaire mais n'expose pas d'API pour
exporter le HTML ; --cdp permet de reutiliser un Chrome ou vous avez deja charge la page.
"""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scraper_annuaire import BASE_URL, USER_AGENT, TIMEOUT, extract_block
import requests
from bs4 import BeautifulSoup

PAGE_TEST = 0
OUT_HTML = Path(__file__).resolve().parent / "test_page.html"
SEL_BLOCS = "div.etablissement.etablissement--search__item"


def fetch_with_requests(url: str) -> tuple[str, bytes, int]:
    session = requests.Session()
    session.headers.update({
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
        "Referer": "https://www.education.gouv.fr/",
    })
    r = session.get(url, timeout=TIMEOUT)
    return r.text, r.content, r.status_code


def fetch_with_curl_cffi(url: str) -> tuple[str, bytes]:
    """
    curl_cffi : requete HTTP avec empreinte TLS Chrome. Contourne souvent la detection.
    pip install curl_cffi. Pas de navigateur.
    """
    from curl_cffi import requests as cf_requests

    r = cf_requests.get(url, impersonate="chrome", timeout=TIMEOUT)
    r.raise_for_status()
    html = r.text
    return html, html.encode("utf-8")


def fetch_with_playwright(url: str, headless: bool = True) -> tuple[str, bytes]:
    import time
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(headless=headless, channel="chrome")
        except Exception:
            browser = p.chromium.launch(headless=headless)
        try:
            ctx = browser.new_context(
                locale="fr-FR",
                extra_http_headers={"Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8"},
            )
            page = ctx.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=60_000)
            try:
                page.wait_for_selector(SEL_BLOCS, timeout=12_000)
            except Exception:
                time.sleep(5)
            html = page.content()
        finally:
            browser.close()
    return html, html.encode("utf-8")


def fetch_with_cdp(url: str, cdp_url: str = "http://127.0.0.1:9222") -> tuple[str, bytes]:
    """
    Se connecte a un Chrome lance avec --remote-debugging-port=9222, reutilise
    une page sur l'annuaire ou en ouvre une (meme profil = memes cookies).
    NE FERME PAS le navigateur (c'est le Chrome de l'utilisateur).
    """
    import time
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(cdp_url)
        try:
            ctx = browser.contexts[0] if browser.contexts else None
            if not ctx:
                raise RuntimeError("Aucun contexte. Lancez Chrome avec: chrome --remote-debugging-port=9222")
            pages = ctx.pages
            page = None
            for pg in pages:
                if "education.gouv.fr/annuaire" in pg.url:
                    page = pg
                    break
            if not page:
                page = pages[0] if pages else ctx.new_page()
            if url != page.url:
                page.goto(url, wait_until="domcontentloaded", timeout=60_000)
                try:
                    page.wait_for_selector(SEL_BLOCS, timeout=12_000)
                except Exception:
                    time.sleep(5)
            html = page.content()
        finally:
            pass  # ne pas browser.close() : c'est le Chrome de l'utilisateur
    return html, html.encode("utf-8")


def fetch_with_selenium(url: str, headless: bool = True) -> tuple[str, bytes]:
    """
    Selenium + Chrome : navigateur reel, JS et cookies actives. ChromeDriver gere par Selenium 4.
    pip install selenium. Chrome doit etre installe.
    """
    import time
    from selenium import webdriver
    from selenium.webdriver.chrome.options import Options
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support import expected_conditions as EC
    from selenium.webdriver.support.ui import WebDriverWait

    opts = Options()
    if headless:
        opts.add_argument("--headless=new")
    opts.add_argument("--disable-blink-features=AutomationControlled")
    opts.add_experimental_option("excludeSwitches", ["enable-automation"])
    opts.add_argument("--window-size=1920,1080")
    opts.add_argument("--lang=fr-FR")
    opts.add_experimental_option("prefs", {"intl.accept_languages": "fr-FR,fr,en"})
    driver = None
    try:
        driver = webdriver.Chrome(options=opts)
        driver.get(url)
        time.sleep(3)
        try:
            WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, SEL_BLOCS))
            )
        except Exception:
            time.sleep(5)
        html = driver.page_source
    finally:
        if driver is not None:
            try:
                driver.quit()
            except OSError:
                pass
    return html, html.encode("utf-8")


def fetch_with_uc(url: str, headless: bool = True, version_main: int | None = None) -> tuple[str, bytes]:
    """
    undetected-chromedriver : Chrome patche pour eviter la detection (Cloudflare, etc.).
    pip install undetected-chromedriver. Chrome doit etre installe.
    version_main: numero majeur de Chrome (ex. 143) pour forcer le ChromeDriver correspondant.
    """
    import time
    import undetected_chromedriver as uc
    from selenium.webdriver.chrome.options import Options

    opts = Options()
    if headless:
        opts.add_argument("--headless=new")
    kwargs = {"options": opts}
    if version_main is not None:
        kwargs["version_main"] = int(version_main)
    driver = None
    try:
        driver = uc.Chrome(**kwargs)
        driver.get(url)
        time.sleep(3)
        try:
            from selenium.webdriver.support.ui import WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            from selenium.webdriver.common.by import By
            WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, SEL_BLOCS))
            )
        except Exception:
            time.sleep(5)
        html = driver.page_source
    finally:
        if driver is not None:
            try:
                driver.quit()
            except OSError:
                pass
    return html, html.encode("utf-8")


def fetch_with_flaresolverr(url: str, base_url: str = "http://127.0.0.1:8191") -> tuple[str, bytes]:
    """
    Envoie l'URL a FlareSolverr (request.get). FlareSolverr doit tourner (Docker ou binaire).
    pip install : rien de plus (requests suffit). FlareSolverr : docker ou release GitHub.
    """
    import json

    api = f"{base_url.rstrip('/')}/v1"
    payload = {"cmd": "request.get", "url": url, "maxTimeout": 60000}
    r = requests.post(api, json=payload, headers={"Content-Type": "application/json"}, timeout=90)
    r.raise_for_status()
    data = r.json()
    if data.get("status") != "ok":
        raise RuntimeError("FlareSolverr: %s" % data.get("message", data))
    sol = data.get("solution") or {}
    html = sol.get("response") or ""
    if not html:
        raise RuntimeError("FlareSolverr: pas de 'response' dans solution")
    return html, html.encode("utf-8")


def analyze(html: str, raw: bytes, out_path: Path, page: int = PAGE_TEST) -> int:
    out_path.write_bytes(raw)
    print(f"\n3. HTML sauvegarde : {out_path}")

    if "Cloudflare" in html or "Attention Required" in html or "you have been blocked" in html.lower():
        print("   >>> Page de blocage detectee (Cloudflare).")

    print("\n4. Parse BeautifulSoup(html, 'lxml')...")
    try:
        soup = BeautifulSoup(html, "lxml")
    except Exception as e:
        print(f"   Erreur lxml, fallback 'html.parser': {e}")
        soup = BeautifulSoup(html, "html.parser")

    blocks = soup.select(SEL_BLOCS)
    print(f"   select('{SEL_BLOCS}') -> {len(blocks)} blocs")

    for alt in ["div.etablissement", "div[role='article']", "div.etablissement--search__item", "a.btn-cta"]:
        print(f"   select('{alt}') -> {len(soup.select(alt))}")

    print("\n5. Extraction (extract_block) sur les blocs...")
    rows = []
    for i, blk in enumerate(blocks[:5]):
        row = extract_block(blk, page)
        if row:
            rows.append(row)
            print(f"   Bloc {i}: nom={row.get('nom','')[:40]!r} | academie={row.get('academie','')!r} | url={row.get('url_fiche','')[:50]}...")
    for blk in blocks[5:]:
        row = extract_block(blk, page)
        if row:
            rows.append(row)
    print(f"   Total lignes extraites: {len(rows)} (blocs trouves: {len(blocks)})")

    print("\n6. Verif structure (1er bloc)...")
    if blocks:
        b = blocks[0]
        about = b.get("about")
        h2 = b.find("h2")
        a_cta = b.select_one("a.btn-cta")
        acad = b.select_one("div.establishment-info-item.academy p.establishment__header__info")
        print(f"   about={about!r}")
        print(f"   h2={h2.get_text(strip=True)[:50] if h2 else None!r}")
        print(f"   a.btn-cta href={a_cta.get('href') if a_cta else None!r}")
        print(f"   academie p={acad.get_text(strip=True) if acad else None!r}")

    print("\n7. Extrait HTML brut...")
    tit = soup.find("title")
    print(f"   <title>: {tit.get_text(strip=True) if tit else '(aucun)'}")
    if blocks:
        print("   1er bloc (800 car.):")
        print(str(blocks[0])[:800])
        print("   ...")
    else:
        body = soup.find("body") or soup
        print(f"   (0 blocs) debut body: {(body.get_text(separator=' ', strip=True) or '')[:400]}...")

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Test fetch + analyse 1 page annuaire education.gouv.fr")
    ap.add_argument("--uc", action="store_true", help="undetected-chromedriver (contourne souvent Cloudflare, pip install)")
    ap.add_argument("--uc-version", type=int, metavar="N", default=None,
                    help="Avec --uc: forcer ChromeDriver pour Chrome majeur N (ex. 143). Utile si Chrome/ChromeDriver en decalage.")
    ap.add_argument("--selenium", action="store_true", help="Selenium + Chrome (JS, cookies, navigateur reel). pip install selenium.")
    ap.add_argument("--flaresolverr", nargs="?", const="http://127.0.0.1:8191", metavar="URL", default=None,
                    help="FlareSolverr (Docker/binaire a lancer a part). Defaut: http://127.0.0.1:8191")
    ap.add_argument("--browser", action="store_true", help="Playwright lance Chrome (souvent bloque Cloudflare)")
    ap.add_argument("--cdp", nargs="?", const="http://127.0.0.1:9222", metavar="URL", default=None,
                    help="Se connecter a un Chrome avec --remote-debugging-port=9222 (defaut: 127.0.0.1:9222)")
    ap.add_argument("--curl-cffi", action="store_true", help="curl_cffi : empreinte TLS Chrome (sans navigateur). pip install curl_cffi")
    ap.add_argument("--headed", action="store_true", help="Avec --uc, --selenium ou --browser: Chrome visible")
    ap.add_argument("--page", type=int, default=PAGE_TEST, help="Index page (0-based, defaut 0)")
    args = ap.parse_args()

    url = f"{BASE_URL}&page={args.page}"
    print("=" * 60)
    print("Test fetch + analyse — annuaire education.gouv.fr")
    if args.uc:
        print("   Mode: undetected-chromedriver (anti-detection Cloudflare)")
    elif args.selenium:
        print("   Mode: Selenium + Chrome (JS, cookies)")
    elif args.curl_cffi:
        print("   Mode: curl_cffi (empreinte TLS Chrome)")
    elif args.flaresolverr is not None:
        print("   Mode: FlareSolverr (serveur Docker/binaire)")
    elif args.cdp is not None:
        print("   Mode: Playwright (connexion CDP a Chrome existant)")
    elif args.browser:
        print("   Mode: Playwright (navigateur lance par le script)")
    else:
        print("   Mode: requests (souvent bloque par Cloudflare)")
    print("=" * 60)
    print(f"\n1. URL : {url}\n")

    if args.uc:
        print("2. undetected-chromedriver: Chrome, goto, wait...")
        try:
            html, raw = fetch_with_uc(url, headless=not args.headed, version_main=args.uc_version)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            err = str(e)
            if "distutils" in err.lower():
                print("   >>> Python 3.12+ : pip install setuptools (distutils a ete supprime).")
            if "Current browser version is" in err:
                m = re.search(r"Current browser version is (\d+)", err)
                if m:
                    print(f"   >>> Chrome/ChromeDriver en decalage. Essayez: --uc-version {m.group(1)}  ou mettez a jour Chrome.")
            print("   >>> pip install undetected-chromedriver. Chrome doit etre installe.")
            return 1
    elif args.selenium:
        print("2. Selenium: Chrome, goto, wait...")
        try:
            html, raw = fetch_with_selenium(url, headless=not args.headed)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            print("   >>> pip install selenium. Chrome doit etre installe. ChromeDriver : Selenium 4 le gere.")
            return 1
    elif args.curl_cffi:
        print("2. curl_cffi: GET (impersonate=chrome)...")
        try:
            html, raw = fetch_with_curl_cffi(url)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            print("   >>> pip install curl_cffi")
            return 1
    elif args.flaresolverr is not None:
        fs = args.flaresolverr or "http://127.0.0.1:8191"
        print("2. FlareSolverr %s/v1, request.get..." % fs)
        try:
            html, raw = fetch_with_flaresolverr(url, base_url=fs)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            print("   >>> Lancez FlareSolverr : docker run -p 8191:8191 ghcr.io/flaresolverr/flaresolverr:latest")
            return 1
    elif args.cdp is not None:
        cdp = args.cdp or "http://127.0.0.1:9222"
        print("2. Playwright: connexion CDP a %s, page.content()..." % cdp)
        try:
            html, raw = fetch_with_cdp(url, cdp_url=cdp)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            if "ECONNREFUSED" in str(e) or "9222" in str(e):
                print("   >>> Aucun Chrome sur le port 9222. Fermez TOUT Chrome, puis dans un autre terminal :")
                print('        "C:/Program Files/Google/Chrome/Application/chrome.exe" --remote-debugging-port=9222')
                print("       Ou Edge : \"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe\" --remote-debugging-port=9222")
            return 1
    elif args.browser:
        print("2. Playwright: lancement Chromium, goto, wait_for_selector('%s')..." % SEL_BLOCS)
        try:
            html, raw = fetch_with_playwright(url, headless=not args.headed)
            print(f"   OK. Content-Length: {len(raw)} octets")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            return 1
    else:
        print("2. Requete GET (timeout=%s s)..." % TIMEOUT)
        try:
            html, raw, status = fetch_with_requests(url)
            print(f"   Status: {status}")
            print(f"   Content-Length: {len(raw)} octets")
            if status == 403 or (raw[:500].decode("utf-8", errors="ignore").find("Cloudflare") >= 0):
                print("   >>> 403/Cloudflare. Utilisez --cdp ou --browser.")
        except Exception as e:
            print(f"   ERREUR: {type(e).__name__}: {e}")
            return 1

    analyze(html, raw, OUT_HTML, args.page)
    print("\n" + "=" * 60)
    print("Fin du test.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
