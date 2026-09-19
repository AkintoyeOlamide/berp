from __future__ import annotations

import re
import shutil
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "lib" / "core" / "data" / "catering_menu.dart"
SRC = Path(r"C:\Users\USER\.cursor\projects\c-Users-USER-Documents-vmo-aero\assets")
DST = ROOT / "assets" / "images" / "catering"

ALIASES = {
    "Ham & Cheese Sandwich": "ham_cheese_sandwich",
    "Cheese & Olive Tartlets": "cheese_olive_tartlets",
    "Greek Yogurt & Granola": "greek_yogurt_granola",
    "Smoked Salmon & Cream Cheese": "smoked_salmon_cream_cheese",
    "Omelette (Custom)": "omelette_custom",
    "Niçoise Salad": "nicoise_salad",
    "Crisps / Chips": "crisps_chips",
    "Egg Sauce / Egg Stew": "egg_sauce_egg_stew",
    "Vanilla Crème Brûlée": "vanilla_creme_brulee",
    "Assorted Canapés": "assorted_canapes",
    "Crudités with Dips": "crudites_with_dips",
    "Vegetable Consommé": "vegetable_consomme",
    "Sushi & Sashimi Platter": "sushi_and_sashimi_platter",
    "Couscous & Vegetables": "couscous_and_vegetables",
    "T-Bone Steak": "t_bone_steak",
    "Chicken Stir-Fry": "chicken_stir_fry",
    "Stir-Fry Noodles": "stir_fry_noodles",
    "Stir-Fry Shrimp & Vegetables": "stir_fry_shrimp_and_vegetables",
    "Sweet & Sour Fish": "sweet_and_sour_fish",
    "Sweet & Sour Prawns": "sweet_and_sour_prawns",
    "Sweet & Sour Salmon": "sweet_and_sour_salmon",
    "Coca-Cola": "coca_cola",
    "Coca-Cola Zero": "coca_cola_zero",
    "Oatmeal / Porridge": "oatmeal_porridge",
    "Sautéed Potatoes": "sauteed_potatoes",
    "Sautéed Mushrooms": "sauteed_mushrooms",
    "Sautéed Greens": "sauteed_greens",
    "Sautéed Spinach": "sauteed_spinach",
    "Sautéed Ugu": "sauteed_ugu",
    "Biscuits & Cookies": "biscuits_and_cookies",
    "American Pancakes": "pancakes",
    "Seasonal Fruit Platter": "fresh_fruit_platter",
    "Fruit Platter": "fresh_fruit_platter",
    "Mini Sliders (Beef / Chicken / Fish)": "mini_sliders",
    "Fresh Garden Salad": "garden_salad",
}


def slugify(name: str) -> str:
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode("ascii")
    s = s.lower().replace("&", " and ").replace("/", " ")
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")[:80] or "meal"


def parse_names(text: str) -> list[str]:
    names: list[str] = []
    for m in re.finditer(r"_build\('([^']+)', \[(.*?)\]\)", text, re.S):
        names.extend(re.findall(r"'([^']+)'", m.group(2)))
    return list(dict.fromkeys(names))


def find_file(name: str, files: dict[str, str]) -> str | None:
    candidates = [
        slugify(name),
        slugify(name).replace("_and_", "_"),
    ]
    if name in ALIASES:
        candidates.insert(0, ALIASES[name])
    for c in candidates:
        if c in files:
            return files[c]
    return None


def rewrite_map(text: str, mapping: dict[str, str]) -> str:
    lines = [
        "  static const Map<String, String> _imagesByName = {",
        *[f"    '{name}': '{path}'," for name, path in mapping.items()],
        "  };",
    ]
    new_map = "\n".join(lines)
    pattern = r"  static const Map<String, String> _imagesByName = \{.*?\n  \};"
    updated, n = re.subn(pattern, new_map, text, count=1, flags=re.S)
    if n != 1:
        raise SystemExit("Could not rewrite _imagesByName")
    return updated


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    copied = 0
    if SRC.exists():
        for p in SRC.glob("*.png"):
            shutil.copy2(p, DST / p.name)
            copied += 1

    files: dict[str, str] = {}
    for p in DST.iterdir():
        if p.suffix.lower() in {".png", ".jpeg", ".jpg"}:
            files[p.stem] = p.name

    text = MENU.read_text(encoding="utf-8")
    names = parse_names(text)
    mapping: dict[str, str] = {}
    missing: list[str] = []
    for name in names:
        found = find_file(name, files)
        if found:
            mapping[name] = f"$_dir/{found}"
        else:
            missing.append(name)

    MENU.write_text(rewrite_map(text, mapping), encoding="utf-8")
    print(f"copied_png={copied}")
    print(f"unique={len(names)}")
    print(f"mapped={len(mapping)}")
    print(f"missing={len(missing)}")
    if missing:
        print("MISSING:")
        for m in missing:
            print(f"  {m} -> {slugify(m)}")


if __name__ == "__main__":
    main()
