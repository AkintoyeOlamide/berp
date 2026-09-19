from pathlib import Path
import re

text = Path("lib/core/data/catering_menu.dart").read_text(encoding="utf-8")
have = set(
    re.findall(
        r"'([^']+)': '\$_dir/[a-z0-9_]+\.(?:jpeg|jpg|png)'",
        text,
    )
)
names = []
for m in re.finditer(r"_build\('([^']+)', \[(.*?)\]\)", text, re.S):
    body = m.group(2)
    names.extend(re.findall(r"'([^']+)'", body))

unique = list(dict.fromkeys(names))
missing = [n for n in unique if n not in have]
print(f"total_listings={len(names)}")
print(f"unique={len(unique)}")
print(f"mapped={len(have)}")
print(f"missing={len(missing)}")
Path("tools/missing_meals.txt").parent.mkdir(parents=True, exist_ok=True)
Path("tools/missing_meals.txt").write_text("\n".join(missing), encoding="utf-8")
print("wrote tools/missing_meals.txt")
