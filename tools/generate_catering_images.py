#!/usr/bin/env python3
"""Generate catering meal images via xAI Grok Imagine and wire them into the app.

Usage:
  set XAI_API_KEY=...
  python tools/generate_catering_images.py

Optional:
  python tools/generate_catering_images.py --limit 10
  python tools/generate_catering_images.py --model grok-imagine-image
  python tools/generate_catering_images.py --force
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "lib" / "core" / "data" / "catering_menu.dart"
OUT_DIR = ROOT / "assets" / "images" / "catering"
API_URL = "https://api.x.ai/v1/images/generations"


def slugify(name: str) -> str:
    s = name.lower()
    s = s.replace("&", " and ")
    s = s.replace("/", " ")
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")[:72] or "meal"


def parse_menu(text: str) -> tuple[dict[str, str], list[str]]:
    mapped = dict(
        re.findall(
            r"'([^']+)': '(\$_dir/[a-z0-9_]+\.(?:jpeg|jpg|png))'",
            text,
        )
    )
    names: list[str] = []
    for m in re.finditer(r"_build\('([^']+)', \[(.*?)\]\)", text, re.S):
        names.extend(re.findall(r"'([^']+)'", m.group(2)))
    unique = list(dict.fromkeys(names))
    return mapped, unique


def prompt_for(name: str) -> str:
    return (
        f"Premium in-flight private jet catering photo of {name}, "
        "served on a dark ceramic plate or elegant cabin tray, "
        "soft studio lighting, appetizing food photography, "
        "shallow depth of field, realistic textures, no text, no logo, "
        "no watermark, square composition, high detail"
    )


def generate_one(
    api_key: str,
    prompt: str,
    model: str,
    aspect_ratio: str = "1:1",
) -> bytes:
    body = {
        "model": model,
        "prompt": prompt,
        "n": 1,
        "aspect_ratio": aspect_ratio,
        "response_format": "b64_json",
    }
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        payload = json.loads(resp.read().decode("utf-8"))

    data = payload.get("data") or []
    if not data:
        raise RuntimeError(f"Empty image response: {payload}")

    item = data[0]
    if item.get("b64_json"):
        import base64

        return base64.b64decode(item["b64_json"])

    url = item.get("url")
    if not url:
        raise RuntimeError(f"No image payload: {item}")
    with urllib.request.urlopen(url, timeout=180) as img_resp:
        return img_resp.read()


def rewrite_map(text: str, mapping: dict[str, str]) -> str:
    lines = [
        "  static const Map<String, String> _imagesByName = {",
        *[f"    '{name}': '{path}'," for name, path in sorted(mapping.items())],
        "  };",
    ]
    new_map = "\n".join(lines)
    pattern = r"  static const Map<String, String> _imagesByName = \{.*?\n  \};"
    updated, n = re.subn(pattern, new_map, text, count=1, flags=re.S)
    if n != 1:
        raise RuntimeError("Could not rewrite _imagesByName in catering_menu.dart")
    return updated


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0, help="Max meals to generate")
    parser.add_argument(
        "--model",
        default="grok-imagine-image",
        help="xAI image model id",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate even if a mapped file already exists",
    )
    parser.add_argument("--sleep", type=float, default=0.4)
    args = parser.parse_args()

    api_key = os.environ.get("XAI_API_KEY") or os.environ.get("GROK_API_KEY")
    if not api_key:
        # Optional local .env (XAI_API_KEY=...)
        env_path = ROOT / ".env"
        if env_path.exists():
            for line in env_path.read_text(encoding="utf-8").splitlines():
                if line.startswith("XAI_API_KEY="):
                    api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break
    if not api_key:
        print(
            "Missing XAI_API_KEY. Set it in the environment or .env, then re-run.",
            file=sys.stderr,
        )
        return 2

    text = MENU.read_text(encoding="utf-8")
    mapped, unique = parse_menu(text)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    todo: list[str] = []
    for name in unique:
        slug = slugify(name)
        rel = f"$_dir/{slug}.jpeg"
        path = OUT_DIR / f"{slug}.jpeg"
        if name in mapped and path.exists() and not args.force:
            continue
        if path.exists() and not args.force:
            mapped[name] = rel
            continue
        todo.append(name)

    if args.limit > 0:
        todo = todo[: args.limit]

    print(f"Unique meals: {len(unique)}")
    print(f"Already mapped: {len(mapped)}")
    print(f"To generate: {len(todo)} with model={args.model}")

    ok = 0
    failed: list[tuple[str, str]] = []
    for i, name in enumerate(todo, 1):
        slug = slugify(name)
        out = OUT_DIR / f"{slug}.jpeg"
        print(f"[{i}/{len(todo)}] {name} -> {out.name}")
        try:
            raw = generate_one(api_key, prompt_for(name), args.model)
            out.write_bytes(raw)
            mapped[name] = f"$_dir/{slug}.jpeg"
            ok += 1
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", errors="replace")
            failed.append((name, f"HTTP {e.code}: {detail[:240]}"))
            print(f"  FAILED: HTTP {e.code}")
        except Exception as e:  # noqa: BLE001
            failed.append((name, str(e)))
            print(f"  FAILED: {e}")
        time.sleep(args.sleep)

    MENU.write_text(rewrite_map(text, mapped), encoding="utf-8")
    print(f"Updated {MENU.relative_to(ROOT)}")
    print(f"Generated OK: {ok}")
    if failed:
        print(f"Failed: {len(failed)}")
        for name, err in failed[:20]:
            print(f"  - {name}: {err}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
