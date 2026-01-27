#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 : pour chaque établissement du CSV (annuaire_etablissements.csv),
ouvre la fiche (url_fiche), extrait l’email et le téléphone, écrit un CSV enrichi.

Mêmes modes de fetch que scraper_annuaire.py : --curl-cffi, --uc, --flaresolverr,
--cdp, --selenium, --browser, --headed, --uc-version.

Usage :
  1) Lancer d’abord scraper_annuaire.py pour générer annuaire_etablissements.csv
  2) python scraper_fiches.py --input annuaire_etablissements.csv --output annuaire_complet.csv --curl-cffi
"""

import argparse
import csv
import random
import re
import sys
import time
from pathlib import Path

from bs4 import BeautifulSoup
from tqdm import tqdm

# Imports depuis scraper_annuaire
sys.path.insert(0, str(Path(__file__).resolve().parent))
from scraper_annuaire import (
    CSV_FIELDS,
    DELAY_MAX,
    DELAY_MIN,
    fetch_page_flaresolverr,
    MAX_RETRIES,
    RETRY_BACKOFF,
    TIMEOUT,
)
import requests

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_INPUT = SCRIPT_DIR / "annuaire_etablissements.csv"
DEFAULT_OUTPUT = SCRIPT_DIR / "annuaire_etablissements_complet.csv"
DELAY_FICHE_MIN = 3
DELAY_FICHE_MAX = 8

FICHE_FIELDS = list(CSV_FIELDS) + ["email", "telephone"]

# Regex email (complément si pas de mailto)
RE_EMAIL = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")


def extract_email_telephone(html: str) -> tuple[str, str]:
    """
    Extrait email et téléphone depuis le HTML de la fiche.
    - Email : a[href^="mailto:"] ou regex dans le texte.
    - Téléphone : a[href^="tel:"] (priorité) ou zone avec label "Téléphone"/"Tél".
    """
    if not html or not html.strip():
        return "", ""

    try:
        soup = BeautifulSoup(html, "lxml")
    except Exception:
        soup = BeautifulSoup(html, "html.parser")

    email = ""
    telephone = ""

    # --- Email : mailto en priorité
    for a in soup.select('a[href^="mailto:"]'):
        href = a.get("href", "").strip()
        if href:
            e = href.replace("mailto:", "").split("?")[0].strip().lower()
            if e and "@" in e:
                email = e
                break
    if not email:
        for m in RE_EMAIL.findall(html):
            if "example" not in m.lower() and "email" not in m.lower():
                email = m.strip().lower()
                break

    # --- Téléphone : tel: en priorité
    for a in soup.select('a[href^="tel:"]'):
        href = a.get("href", "").strip()
        if href:
            t = href.replace("tel:", "").strip()
            # Nettoyer espaces/points
            t = re.sub(r"[\s.]", "", t)
            if t and len(t) >= 8:
                telephone = t
                break

    return email or "", telephone or ""


def _fetch_url_curl_cffi(session, url: str) -> str | None:
    for attempt in range(MAX_RETRIES):
        try:
            r = session.get(url, impersonate="chrome", timeout=TIMEOUT)
            r.raise_for_status()
            return r.text
        except Exception:
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_BACKOFF)
            else:
                return None
    return None


def _fetch_url_browser_driver(driver, url: str) -> str | None:
    try:
        driver.get(url)
        time.sleep(2)
        return driver.page_source
    except Exception:
        return None


def _fetch_url_playwright(pl_page, url: str) -> str | None:
    try:
        pl_page.goto(url, wait_until="domcontentloaded", timeout=60_000)
        time.sleep(2)
        return pl_page.content()
    except Exception:
        return None


def _run_fiches_loop(fetcher, rows, output_path: Path, out_fields, delay_min: int, delay_max: int) -> None:
    with open(output_path, "w", newline="", encoding="utf-8-sig") as out:
        writer = csv.DictWriter(out, fieldnames=out_fields, restval="", quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        for row in tqdm(rows, unit="fiche", desc="Fiches"):
            # Nettoyer les clés None du row avant écriture
            clean_row = {k: v for k, v in row.items() if k is not None}
            url = clean_row.get("url_fiche", "").strip()
            if not url:
                clean_row["email"] = ""
                clean_row["telephone"] = ""
                writer.writerow(clean_row)
                continue
            html = fetcher(url)
            email, telephone = extract_email_telephone(html) if html else ("", "")
            clean_row["email"] = email or clean_row.get("email", "")
            clean_row["telephone"] = telephone or clean_row.get("telephone", "")
            writer.writerow(clean_row)
            out.flush()
            time.sleep(random.uniform(delay_min, delay_max))


def run_fiches(
    input_path: Path,
    output_path: Path,
    from_row: int,
    to_row: int,
    fetch_mode: str,
    fetch_opts: dict,
    delay_min: int,
    delay_max: int,
) -> int:
    rows = []
    with open(input_path, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames or list(CSV_FIELDS)
        # Filtrer les fieldnames None (colonnes vides)
        if fieldnames:
            fieldnames = [f for f in fieldnames if f is not None]
        for r in reader:
            # Nettoyer les clés None du dictionnaire
            clean_r = {k: v for k, v in dict(r).items() if k is not None}
            rows.append(clean_r)

    if not rows:
        print("Aucune ligne dans le CSV d'entrée.")
        return 1

    # Appliquer from_row / to_row
    total = len(rows)
    rows = rows[from_row:to_row]
    print(f"Lignes à traiter : {from_row} à {to_row} (sur {total}) -> {len(rows)} fiches.")

    # Champs de sortie : ceux du CSV + email, telephone (au cas où l'entrée ne les a pas)
    out_fields = list(fieldnames) if fieldnames else list(CSV_FIELDS)
    # Filtrer None au cas où
    out_fields = [f for f in out_fields if f is not None]
    if "email" not in out_fields:
        out_fields.append("email")
    if "telephone" not in out_fields:
        out_fields.append("telephone")

    # --- Construction du fetcher (url -> html)
    fetcher = None
    teardown = lambda: None

    if fetch_mode == "curl_cffi":
        from curl_cffi import requests as cf_requests

        session = cf_requests.Session()
        session.headers.update({
            "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
            "Referer": "https://www.education.gouv.fr/",
        })
        fetcher = lambda url: _fetch_url_curl_cffi(session, url)
        print("Mode : curl_cffi (empreinte TLS Chrome)")

    elif fetch_mode == "flaresolverr":
        base = fetch_opts.get("flaresolverr_url", "http://127.0.0.1:8191")
        fetcher = lambda url: fetch_page_flaresolverr(url, base)
        print("Mode : FlareSolverr")

    elif fetch_mode == "uc":
        import undetected_chromedriver as uc
        from selenium.webdriver.chrome.options import Options

        opts = Options()
        if not fetch_opts.get("headed", False):
            opts.add_argument("--headless=new")
        kwargs = {"options": opts}
        if fetch_opts.get("uc_version") is not None:
            kwargs["version_main"] = int(fetch_opts["uc_version"])
        driver = uc.Chrome(**kwargs)
        fetcher = lambda url: _fetch_url_browser_driver(driver, url)

        def _teardown():
            if driver:
                try:
                    driver.quit()
                except OSError:
                    pass

        teardown = _teardown
        print("Mode : undetected-chromedriver")

    elif fetch_mode == "selenium":
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options

        opts = Options()
        if not fetch_opts.get("headed", False):
            opts.add_argument("--headless=new")
        opts.add_argument("--disable-blink-features=AutomationControlled")
        opts.add_experimental_option("excludeSwitches", ["enable-automation"])
        opts.add_argument("--lang=fr-FR")
        driver = webdriver.Chrome(options=opts)
        fetcher = lambda url: _fetch_url_browser_driver(driver, url)

        def _teardown():
            if driver:
                try:
                    driver.quit()
                except OSError:
                    pass

        teardown = _teardown
        print("Mode : Selenium")

    elif fetch_mode == "browser":
        from playwright.sync_api import sync_playwright

        print("Mode : Playwright (navigateur)")
        with sync_playwright() as p:
            try:
                browser = p.chromium.launch(headless=not fetch_opts.get("headed", False), channel="chrome")
            except Exception:
                browser = p.chromium.launch(headless=not fetch_opts.get("headed", False))
            ctx = browser.new_context(locale="fr-FR", extra_http_headers={"Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8"})
            pl_page = ctx.new_page()
            fetcher = lambda url: _fetch_url_playwright(pl_page, url)
            _run_fiches_loop(fetcher, rows, output_path, out_fields, delay_min, delay_max)
            browser.close()
        print(f"Écrit : {output_path}")
        return 0

    elif fetch_mode == "cdp":
        from playwright.sync_api import sync_playwright

        print("Mode : CDP (Chrome --remote-debugging-port=9222)")
        cdp_url = fetch_opts.get("cdp_url", "http://127.0.0.1:9222")
        with sync_playwright() as p:
            browser = p.chromium.connect_over_cdp(cdp_url)
            ctx = browser.contexts[0] if browser.contexts else None
            if not ctx:
                raise RuntimeError("Aucun contexte. Lancez Chrome avec: chrome --remote-debugging-port=9222")
            pages = ctx.pages
            pl_page = next((pg for pg in pages if "education.gouv.fr/annuaire" in pg.url), None) or (pages[0] if pages else ctx.new_page())
            fetcher = lambda url: _fetch_url_playwright(pl_page, url)
            _run_fiches_loop(fetcher, rows, output_path, out_fields, delay_min, delay_max)
        print(f"Écrit : {output_path}")
        return 0

    elif fetch_mode == "requests":
        session = requests.Session()
        session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
            "Referer": "https://www.education.gouv.fr/",
        })

        def _fetch_req(url):
            for attempt in range(MAX_RETRIES):
                try:
                    r = session.get(url, timeout=TIMEOUT)
                    r.raise_for_status()
                    return r.text
                except Exception:
                    if attempt < MAX_RETRIES - 1:
                        time.sleep(RETRY_BACKOFF)
                    else:
                        return None
            return None

        fetcher = _fetch_req
        print("Mode : requests (souvent bloqué)")

    if fetcher is None:
        print("Mode inconnu ou non implémenté pour les fiches :", fetch_mode)
        return 1

    _run_fiches_loop(fetcher, rows, output_path, out_fields, delay_min, delay_max)
    try:
        teardown()
    except Exception:
        pass
    print(f"Écrit : {output_path}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase 2 : enrichir le CSV avec email et téléphone depuis chaque fiche")
    ap.add_argument("--input", type=Path, default=DEFAULT_INPUT, help=f"CSV généré par scraper_annuaire (défaut: {DEFAULT_INPUT.name})")
    ap.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help=f"CSV enrichi (défaut: {DEFAULT_OUTPUT.name})")
    ap.add_argument("--from-row", type=int, default=0, help="Index de la première ligne à traiter (défaut: 0)")
    ap.add_argument("--to-row", type=int, default=2**30, help="Index de la dernière ligne à traiter (exclu, défaut: toutes)")
    ap.add_argument("--delay-min", type=int, default=DELAY_FICHE_MIN, help=f"Délai min entre 2 fiches en s (défaut: {DELAY_FICHE_MIN})")
    ap.add_argument("--delay-max", type=int, default=DELAY_FICHE_MAX, help=f"Délai max entre 2 fiches en s (défaut: {DELAY_FICHE_MAX})")
    # Modes de fetch (mêmes que scraper_annuaire)
    ap.add_argument("--curl-cffi", action="store_true", help="curl_cffi (recommandé, souvent non détecté)")
    ap.add_argument("--uc", action="store_true", help="undetected-chromedriver")
    ap.add_argument("--uc-version", type=int, metavar="N", default=None, help="Avec --uc: Chrome majeur N (ex. 143)")
    ap.add_argument("--flaresolverr", nargs="?", const="http://127.0.0.1:8191", metavar="URL", default=None)
    ap.add_argument("--selenium", action="store_true")
    ap.add_argument("--browser", action="store_true")
    ap.add_argument("--cdp", nargs="?", const="http://127.0.0.1:9222", metavar="URL", default=None)
    ap.add_argument("--headed", action="store_true")
    args = ap.parse_args()

    if args.uc:
        fetch_mode = "uc"
        fetch_opts = {"headed": args.headed, "uc_version": args.uc_version}
    elif args.curl_cffi:
        fetch_mode = "curl_cffi"
        fetch_opts = {}
    elif args.flaresolverr is not None:
        fetch_mode = "flaresolverr"
        fetch_opts = {"flaresolverr_url": args.flaresolverr or "http://127.0.0.1:8191"}
    elif args.cdp is not None:
        fetch_mode = "cdp"
        fetch_opts = {"cdp_url": args.cdp or "http://127.0.0.1:9222"}
    elif args.selenium:
        fetch_mode = "selenium"
        fetch_opts = {"headed": args.headed}
    elif args.browser:
        fetch_mode = "browser"
        fetch_opts = {"headed": args.headed}
    else:
        fetch_mode = "requests"
        fetch_opts = {}

    if not args.input.exists():
        print(f"Fichier introuvable : {args.input}")
        print("Lancez d'abord : python scraper_annuaire.py --no-gui --curl-cffi (ou autre mode)")
        return 1

    return run_fiches(
        args.input,
        args.output,
        args.from_row,
        args.to_row,
        fetch_mode,
        fetch_opts,
        args.delay_min,
        args.delay_max,
    )


if __name__ == "__main__":
    sys.exit(main())
