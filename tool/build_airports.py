"""Build a compact world-airport JSON from OurAirports open data."""

from __future__ import annotations

import csv
import io
import json
import urllib.request
from pathlib import Path

AIRPORTS_URL = (
    "https://davidmegginson.github.io/ourairports-data/airports.csv"
)
COUNTRIES_URL = (
    "https://davidmegginson.github.io/ourairports-data/countries.csv"
)
OUT = Path(__file__).resolve().parents[1] / "assets" / "data" / "airports.json"


def download(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "vmo-aero/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read().decode("utf-8", errors="replace")


def keep(row: dict[str, str]) -> bool:
    kind = (row.get("type") or "").strip()
    iata = (row.get("iata_code") or "").strip().upper()
    if kind == "closed":
        return False
    if kind in {"large_airport", "medium_airport"}:
        return True
    if iata and kind in {"small_airport", "seaplane_base"}:
        return True
    return False


def main() -> None:
    countries_csv = download(COUNTRIES_URL)
    countries: dict[str, str] = {}
    reader = csv.DictReader(io.StringIO(countries_csv))
    for row in reader:
        code = (row.get("code") or "").strip().upper()
        name = (row.get("name") or "").strip()
        if code and name:
            countries[code] = name

    airports_csv = download(AIRPORTS_URL)
    rows = csv.DictReader(io.StringIO(airports_csv))
    out: list[dict[str, str]] = []
    seen: set[str] = set()
    for row in rows:
        if not keep(row):
            continue
        ident = (row.get("ident") or row.get("gps_code") or "").strip().upper()
        icao = (row.get("icao_code") or row.get("gps_code") or ident).strip().upper()
        iata = (row.get("iata_code") or "").strip().upper()
        name = (row.get("name") or "").strip()
        city = (row.get("municipality") or "").strip()
        iso = (row.get("iso_country") or "").strip().upper()
        if not name or not ident:
            continue
        key = iata or icao or ident
        if key in seen:
            continue
        seen.add(key)
        kind = (row.get("type") or "").strip()
        out.append(
            {
                "iata": iata,
                "icao": icao if len(icao) <= 6 else ident,
                "name": name,
                "city": city,
                "country": countries.get(iso, iso),
                "iso": iso,
                "type": kind.replace("_airport", "").replace("_base", ""),
            }
        )

    rank = {"large": 0, "medium": 1, "small": 2, "seaplane": 3}
    out.sort(
        key=lambda a: (
            rank.get(a["type"], 9),
            a["country"],
            a["city"],
            a["name"],
        )
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(out)} airports to {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
