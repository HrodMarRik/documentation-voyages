#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scraper de l'annuaire education.gouv.fr.
Parcourt les pages, extrait les blocs établissement et écrit un CSV.
Délai aléatoire 11–20 s entre chaque requête.
"""

import argparse
import csv
import inspect
import json
import random
import re
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------
BASE_URL = "https://www.education.gouv.fr/annuaire?keywords=&department=&academy=&status=All&establishment=All&geo_point="
SEL_BLOCS = "div.etablissement.etablissement--search__item"
PAGE_START = 0
PAGE_END = 3110  # exclusive: pages 0..3109
DELAY_MIN = 11
DELAY_MAX = 20
TIMEOUT = 45
MAX_RETRIES = 3
RETRY_BACKOFF = 5
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_CSV = SCRIPT_DIR / "annuaire_etablissements.csv"
PROGRESS_JSON = SCRIPT_DIR / "progress.json"

CSV_FIELDS = [
    "url_fiche", "nom", "type_etablissement", "statut", "academie", "zone",
    "adresse", "code_postal", "commune", "id_etablissement", "nom_slug", "page",
    "telephone",
]


def _trace(verbose: bool, msg: str, *args) -> None:
    """Affiche la ligne en cours et un message si --verbose."""
    if not verbose:
        return
    frame = inspect.currentframe()
    if frame and frame.f_back:
        lineno = frame.f_back.f_lineno
        fname = Path(frame.f_back.f_code.co_filename).name
    else:
        lineno, fname = 0, "?"
    text = (msg % args) if args else msg
    print(f"  [{fname}:L{lineno}] {text}", flush=True)


def _text(el):
    return el.get_text(strip=True) if el else ""


def parse_fiche_path(href: str, base: str = "https://www.education.gouv.fr") -> dict:
    path = urlparse(urljoin(base, href)).path
    parts = path.strip("/").split("/")
    if len(parts) >= 6 and parts[0] == "annuaire":
        nom_slug = parts[5].replace(".html", "") if parts[5].endswith(".html") else parts[5]
        return {
            "code_postal": parts[1],
            "commune": parts[2],
            "type_etablissement": parts[3],
            "id_etablissement": parts[4],
            "nom_slug": nom_slug,
        }
    return {"code_postal": "", "commune": "", "type_etablissement": "", "id_etablissement": "", "nom_slug": ""}


def extract_block(block, page: int) -> dict | None:
    href = block.get("about") or (block.select_one("a.btn-cta") and block.select_one("a.btn-cta").get("href"))
    if not href:
        return None
    url_fiche = urljoin("https://www.education.gouv.fr", href)
    parsed = parse_fiche_path(href, "https://www.education.gouv.fr")

    # Téléphone depuis la carte (a[href^="tel:"])
    tel = ""
    a_tel = block.select_one('a[href^="tel:"]')
    if a_tel and a_tel.get("href"):
        t = a_tel["href"].replace("tel:", "").strip()
        if t and len(t) >= 8:
            tel = re.sub(r"[\s.]", "", t)

    return {
        "url_fiche": url_fiche,
        "nom": _text(block.find("h2")),
        "type_etablissement": _text(block.select_one("p.establishment-type")) or parsed.get("type_etablissement", ""),
        "statut": _text(block.select_one("p.establishment-public")),
        "academie": _text(block.select_one("div.establishment-info-item.academy p.establishment__header__info")),
        "zone": _text(block.select_one("div.establishment-info-item.zone p.establishment__header__info")),
        "adresse": _text(block.select_one("p.establishment--address-line")),
        "code_postal": parsed.get("code_postal", ""),
        "commune": parsed.get("commune", ""),
        "id_etablissement": parsed.get("id_etablissement", ""),
        "nom_slug": parsed.get("nom_slug", ""),
        "page": page,
        "telephone": tel,
    }


def fetch_page(session: requests.Session, page: int) -> str | None:
    url = f"{BASE_URL}&page={page}"
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


def fetch_page_curl_cffi(session, page: int) -> str | None:
    """Requête avec curl_cffi : empreinte TLS type Chrome (contourne souvent la détection)."""
    url = f"{BASE_URL}&page={page}"
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


def fetch_page_flaresolverr(url: str, base_url: str = "http://127.0.0.1:8191") -> str | None:
    """Envoie l'URL à FlareSolverr (request.get). Retourne le HTML ou None."""
    try:
        api = f"{base_url.rstrip('/')}/v1"
        payload = {"cmd": "request.get", "url": url, "maxTimeout": 60000}
        r = requests.post(api, json=payload, headers={"Content-Type": "application/json"}, timeout=90)
        r.raise_for_status()
        data = r.json()
        if data.get("status") != "ok":
            return None
        return (data.get("solution") or {}).get("response") or None
    except Exception:
        return None


def write_progress(path: Path, data: dict) -> None:
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def _process_html(
    html: str, page: int, from_page: int, to_page: int, total_etablissements: int,
    started_at: str, csv_path: Path, progress_path: Path, csv_needs_header: bool,
    use_tqdm: bool, it,
) -> tuple[int, bool]:
    try:
        soup = BeautifulSoup(html, "lxml")
    except Exception:
        soup = BeautifulSoup(html, "html.parser")
    blocks = soup.select(SEL_BLOCS)
    rows = [extract_block(blk, page) for blk in blocks]
    rows = [r for r in rows if r]
    total_etablissements += len(rows)
    try:
        with open(csv_path, "a", newline="", encoding="utf-8-sig") as f:
            w = csv.DictWriter(f, fieldnames=CSV_FIELDS, restval="", quoting=csv.QUOTE_MINIMAL)
            if csv_needs_header:
                w.writeheader()
                csv_needs_header = False
            w.writerows(rows)
    except Exception:
        pass
    elapsed = (datetime.now(timezone.utc) - datetime.fromisoformat(started_at.replace("Z", "+00:00"))).total_seconds()
    pages_done = page - from_page + 1
    eta_seconds = int((to_page - page - 1) * (elapsed / pages_done)) if pages_done > 0 and page < to_page - 1 else None
    write_progress(progress_path, {
        "page": page,
        "total_pages": PAGE_END,
        "etablissements": total_etablissements,
        "started_at": started_at,
        "last_update": datetime.now(timezone.utc).isoformat(),
        "eta_seconds": eta_seconds,
        "status": "running",
    })
    if use_tqdm:
        it.set_postfix(etabl=total_etablissements, refresh=True)
    return total_etablissements, csv_needs_header


def _scraper_loop(
    fetcher, from_page: int, to_page: int, csv_path: Path, progress_path: Path,
    stop_event: threading.Event | None, use_tqdm: bool, verbose: bool,
) -> str:
    """Boucle principale : fetcher(page, url) -> html|None. Parse, CSV, progress, délai."""
    _trace(verbose, "_scraper_loop(from_page=%s, to_page=%s)", from_page, to_page)
    started_at = datetime.now(timezone.utc).isoformat()
    total_etablissements = 0
    csv_needs_header = not csv_path.exists() or csv_path.stat().st_size == 0

    it = range(from_page, to_page)
    if use_tqdm:
        it = tqdm(it, unit="page", desc="Pages", dynamic_ncols=True)

    for page in it:
        _trace(verbose, "Boucle page=%s", page)
        if stop_event and stop_event.is_set():
            _trace(verbose, "stop_event: arrêt demandé, write_progress status=stopped")
            write_progress(progress_path, {
                "page": page - 1 if page > from_page else from_page - 1,
                "total_pages": PAGE_END,
                "etablissements": total_etablissements,
                "started_at": started_at,
                "last_update": datetime.now(timezone.utc).isoformat(),
                "eta_seconds": None,
                "status": "stopped",
            })
            return "stopped"

        url = f"{BASE_URL}&page={page}"
        _trace(verbose, "fetch page=%s", page)
        html = fetcher(page, url)
        if html is None:
            _trace(verbose, "fetch → None (échec), continue + sleep(RETRY_BACKOFF)")
            if use_tqdm:
                it.set_postfix_str("erreur fetch", refresh=True)
            if page < to_page - 1:
                time.sleep(RETRY_BACKOFF)
            continue

        _trace(verbose, "BeautifulSoup + select + _process_html")
        total_etablissements, csv_needs_header = _process_html(
            html, page, from_page, to_page, total_etablissements, started_at,
            csv_path, progress_path, csv_needs_header, use_tqdm, it,
        )

        if page < to_page - 1:
            delay = random.uniform(DELAY_MIN, DELAY_MAX)
            _trace(verbose, "time.sleep(%.1f) [DELAY_MIN..DELAY_MAX]", delay)
            time.sleep(delay)

    if use_tqdm:
        it.close()

    _trace(verbose, "write_progress(progress_path, status='done') + return 'done'")
    write_progress(progress_path, {
        "page": to_page - 1,
        "total_pages": PAGE_END,
        "etablissements": total_etablissements,
        "started_at": started_at,
        "last_update": datetime.now(timezone.utc).isoformat(),
        "eta_seconds": 0,
        "status": "done",
    })
    return "done"


def run_scraper(
    from_page: int,
    to_page: int,
    csv_path: Path,
    progress_path: Path,
    stop_event: threading.Event | None,
    use_tqdm: bool = True,
    verbose: bool = False,
    fetch_mode: str = "requests",
    fetch_opts: dict | None = None,
) -> str:
    fetch_opts = fetch_opts or {}
    _trace(verbose, "run_scraper(from_page=%s, to_page=%s, fetch_mode=%s)", from_page, to_page, fetch_mode)

    # --- Mode browser (Playwright, navigateur lancé par le script) ---
    if fetch_mode == "browser":
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            try:
                browser = p.chromium.launch(headless=not fetch_opts.get("headed", False), channel="chrome")
            except Exception:
                browser = p.chromium.launch(headless=not fetch_opts.get("headed", False))
            ctx = browser.new_context(
                locale="fr-FR",
                extra_http_headers={"Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8"},
            )
            pl_page = ctx.new_page()

            def fetcher(pg, u):
                try:
                    pl_page.goto(u, wait_until="domcontentloaded", timeout=60_000)
                    try:
                        pl_page.wait_for_selector(SEL_BLOCS, timeout=12_000)
                    except Exception:
                        time.sleep(5)
                    return pl_page.content()
                except Exception:
                    return None

            try:
                return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)
            finally:
                browser.close()

    # --- Mode CDP (Playwright, connexion à un Chrome --remote-debugging-port=9222) ---
    if fetch_mode == "cdp":
        from playwright.sync_api import sync_playwright

        cdp_url = fetch_opts.get("cdp_url", "http://127.0.0.1:9222")
        with sync_playwright() as p:
            browser = p.chromium.connect_over_cdp(cdp_url)
            ctx = browser.contexts[0] if browser.contexts else None
            if not ctx:
                raise RuntimeError("Aucun contexte. Lancez Chrome avec: chrome --remote-debugging-port=9222")
            pages = ctx.pages
            pl_page = next((pg for pg in pages if "education.gouv.fr/annuaire" in pg.url), None)
            if pl_page is None:
                pl_page = pages[0] if pages else ctx.new_page()

            def fetcher(pg, u):
                try:
                    if u != pl_page.url:
                        pl_page.goto(u, wait_until="domcontentloaded", timeout=60_000)
                        try:
                            pl_page.wait_for_selector(SEL_BLOCS, timeout=12_000)
                        except Exception:
                            time.sleep(5)
                    return pl_page.content()
                except Exception:
                    return None

            return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)

    # --- Mode Selenium (Chrome standard : JS, cookies, exécution réelle) ---
    if fetch_mode == "selenium":
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.support.ui import WebDriverWait

        opts = Options()
        if not fetch_opts.get("headed", False):
            opts.add_argument("--headless=new")
        opts.add_argument("--disable-blink-features=AutomationControlled")
        opts.add_experimental_option("excludeSwitches", ["enable-automation"])
        opts.add_argument("--window-size=1920,1080")
        opts.add_argument("--lang=fr-FR")
        # JS et cookies : activés par défaut dans Chrome. On s'assure que le profil les accepte.
        prefs = {"intl.accept_languages": "fr-FR,fr,en"}
        opts.add_experimental_option("prefs", prefs)
        driver = webdriver.Chrome(options=opts)
        try:
            def fetcher(pg, u):
                try:
                    driver.get(u)
                    time.sleep(3)
                    try:
                        WebDriverWait(driver, 15).until(
                            EC.presence_of_element_located((By.CSS_SELECTOR, SEL_BLOCS))
                        )
                    except Exception:
                        time.sleep(5)
                    return driver.page_source
                except Exception:
                    return None

            return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)
        finally:
            if driver is not None:
                try:
                    driver.quit()
                except OSError:
                    pass

    # --- Mode UC (undetected-chromedriver) ---
    if fetch_mode == "uc":
        import undetected_chromedriver as uc
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.support.ui import WebDriverWait

        opts = Options()
        if not fetch_opts.get("headed", False):
            opts.add_argument("--headless=new")
        kwargs = {"options": opts}
        if fetch_opts.get("uc_version") is not None:
            kwargs["version_main"] = int(fetch_opts["uc_version"])
        driver = uc.Chrome(**kwargs)
        try:
            def fetcher(pg, u):
                try:
                    driver.get(u)
                    time.sleep(3)
                    try:
                        WebDriverWait(driver, 15).until(
                            EC.presence_of_element_located((By.CSS_SELECTOR, SEL_BLOCS))
                        )
                    except Exception:
                        time.sleep(5)
                    return driver.page_source
                except Exception:
                    return None

            return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)
        finally:
            if driver is not None:
                try:
                    driver.quit()
                except OSError:
                    pass

    # --- Mode curl_cffi (empreinte TLS Chrome, sans navigateur) ---
    if fetch_mode == "curl_cffi":
        from curl_cffi import requests as cf_requests

        session = cf_requests.Session()
        session.headers.update({
            "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
            "Referer": "https://www.education.gouv.fr/",
        })
        _trace(verbose, "Session curl_cffi (impersonate=chrome)")

        def fetcher(pg, u):
            return fetch_page_curl_cffi(session, pg)

        return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)

    # --- Mode requests ou flaresolverr ---
    session = requests.Session() if fetch_mode == "requests" else None
    if session:
        session.headers.update({
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
            "Referer": "https://www.education.gouv.fr/",
        })
        _trace(verbose, "Session requests créée")
    flaresolverr_base = fetch_opts.get("flaresolverr_url", "http://127.0.0.1:8191")

    def fetcher(pg, u):
        if fetch_mode == "requests":
            return fetch_page(session, pg)
        return fetch_page_flaresolverr(u, flaresolverr_base)

    return _scraper_loop(fetcher, from_page, to_page, csv_path, progress_path, stop_event, use_tqdm, verbose)


def run_gui(progress_path: Path, from_page: int, to_page: int, stop_event: threading.Event) -> None:
    try:
        import tkinter as tk
        from tkinter import ttk
    except ImportError:
        return

    root = tk.Tk()
    root.title("Scraper Annuaire Education — Progression")
    root.geometry("420x200")
    root.resizable(True, True)

    # Barre de progression
    lb_page = ttk.Label(root, text="Page: — / —")
    lb_page.pack(pady=(8, 2))
    progress = ttk.Progressbar(root, length=360, maximum=max(1, to_page - from_page))
    progress.pack(pady=4, padx=20, fill=tk.X)

    lb_etabl = ttk.Label(root, text="Établissements: 0")
    lb_etabl.pack(pady=2)
    lb_elapsed = ttk.Label(root, text="Temps écoulé: —")
    lb_elapsed.pack(pady=2)
    lb_eta = ttk.Label(root, text="Temps restant (estimé): —")
    lb_eta.pack(pady=2)

    def format_durée(s: float | None) -> str:
        if s is None or s < 0:
            return "—"
        h = int(s) // 3600
        m = (int(s) % 3600) // 60
        return f"{h}h {m}min" if h else f"{m}min"

    def update_ui() -> None:
        try:
            if progress_path.exists():
                with open(progress_path, "r", encoding="utf-8") as f:
                    d = json.load(f)
            else:
                d = {}
        except Exception:
            d = {}
        p = d.get("page", from_page - 1)
        total = d.get("total_pages", PAGE_END)
        etabl = d.get("etablissements", 0)
        status = d.get("status", "?")

        lb_page.config(text=f"Page: {p + 1} / {total}")
        lb_etabl.config(text=f"Établissements: {etabl}")

        done = max(0, p - from_page + 1)
        progress["value"] = done

        started = d.get("started_at")
        if started:
            try:
                dt0 = datetime.fromisoformat(started.replace("Z", "+00:00"))
                elapsed = (datetime.now(timezone.utc) - dt0).total_seconds()
                lb_elapsed.config(text=f"Temps écoulé: {format_durée(elapsed)}")
            except Exception:
                lb_elapsed.config(text="Temps écoulé: —")
        else:
            lb_elapsed.config(text="Temps écoulé: —")

        eta = d.get("eta_seconds")
        lb_eta.config(text=f"Temps restant (estimé): {format_durée(eta)}")

        if status in ("done", "stopped"):
            lb_eta.config(text=f"Statut: {status}")
            return

        root.after(1000, update_ui)

    def on_stop() -> None:
        stop_event.set()
        lb_eta.config(text="Arrêt demandé…")

    btn = ttk.Button(root, text="Arrêter", command=on_stop)
    btn.pack(pady=8)

    def on_close() -> None:
        stop_event.set()
        root.destroy()

    root.protocol("WM_DELETE_WINDOW", on_close)

    update_ui()
    root.mainloop()


def main() -> int:
    ap = argparse.ArgumentParser(description="Scraper annuaire education.gouv.fr")
    ap.add_argument("--from-page", type=int, default=PAGE_START, help=f"Page de début (0-based, défaut: {PAGE_START})")
    ap.add_argument("--to-page", type=int, default=PAGE_END, help=f"Page de fin exclusive (défaut: {PAGE_END})")
    ap.add_argument("--no-gui", action="store_true", help="Désactiver la fenêtre de progression")
    ap.add_argument("--csv", type=Path, default=OUTPUT_CSV, help="Fichier CSV de sortie")
    ap.add_argument("-v", "--verbose", action="store_true", help="Afficher la ligne exécutée et les étapes (fichier:Ligne)")
    # Modes de récupération (contournent Cloudflare)
    ap.add_argument("--uc", action="store_true", help="undetected-chromedriver (Chrome, contourne souvent Cloudflare)")
    ap.add_argument("--uc-version", type=int, metavar="N", default=None,
                    help="Avec --uc: forcer ChromeDriver pour Chrome majeur N (ex. 143)")
    ap.add_argument("--flaresolverr", nargs="?", const="http://127.0.0.1:8191", metavar="URL", default=None,
                    help="FlareSolverr (Docker/binaire). Défaut: http://127.0.0.1:8191")
    ap.add_argument("--selenium", action="store_true",
                    help="Selenium + Chrome (JS, cookies, navigateur réel). ChromeDriver géré par Selenium 4.")
    ap.add_argument("--browser", action="store_true", help="Playwright lance Chrome/Chromium")
    ap.add_argument("--cdp", nargs="?", const="http://127.0.0.1:9222", metavar="URL", default=None,
                    help="Playwright se connecte à un Chrome --remote-debugging-port=9222")
    ap.add_argument("--curl-cffi", action="store_true",
                    help="curl_cffi : empreinte TLS Chrome (sans navigateur). pip install curl_cffi")
    ap.add_argument("--headed", action="store_true", help="Avec --uc, --selenium ou --browser: navigateur visible")
    args = ap.parse_args()

    from_page = max(0, args.from_page)
    to_page = min(PAGE_END, max(from_page + 1, args.to_page))
    progress_path = PROGRESS_JSON
    csv_path = args.csv

    # fetch_mode et fetch_opts
    if args.uc:
        fetch_mode = "uc"
        fetch_opts = {"headed": args.headed, "uc_version": args.uc_version}
    elif args.selenium:
        fetch_mode = "selenium"
        fetch_opts = {"headed": args.headed}
    elif args.flaresolverr is not None:
        fetch_mode = "flaresolverr"
        fetch_opts = {"flaresolverr_url": args.flaresolverr or "http://127.0.0.1:8191"}
    elif args.cdp is not None:
        fetch_mode = "cdp"
        fetch_opts = {"cdp_url": args.cdp or "http://127.0.0.1:9222"}
    elif args.browser:
        fetch_mode = "browser"
        fetch_opts = {"headed": args.headed}
    elif args.curl_cffi:
        fetch_mode = "curl_cffi"
        fetch_opts = {}
    else:
        fetch_mode = "requests"
        fetch_opts = {}

    if args.no_gui:
        run_scraper(
            from_page, to_page, csv_path, progress_path, stop_event=None,
            use_tqdm=True, verbose=args.verbose, fetch_mode=fetch_mode, fetch_opts=fetch_opts,
        )
        return 0

    stop_event = threading.Event()
    scr = threading.Thread(
        target=run_scraper,
        args=(from_page, to_page, csv_path, progress_path, stop_event),
        kwargs={"use_tqdm": False, "verbose": args.verbose, "fetch_mode": fetch_mode, "fetch_opts": fetch_opts},
        daemon=False,
    )
    scr.start()
    run_gui(progress_path, from_page, to_page, stop_event)
    scr.join(timeout=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
