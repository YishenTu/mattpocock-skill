#!/usr/bin/env bash
# check-categories.sh
# Fetches https://www.aihero.dev/skills, parses the site's skill categories
# (names, descriptions, start-with hints, skills), and compares them against
# the metadata in sync-skills.sh — which is also what sync-skills.sh uses to
# regenerate README.md. So this catches stale READMEs before they happen.
#
# Read-only — never modifies files.
#
# Exit codes:
#   0  no drift (informational notes are OK)
#   1  drift found — update the metadata in sync-skills.sh, then run ./sync-skills.sh
#   2  network/fetch error
#   3  parse error (site structure changed)

set -euo pipefail
cd "$(dirname "$0")"

URL="https://www.aihero.dev/skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching $URL ..."
if ! curl -fsSL --max-time 30 "$URL" -o "$TMP/skills.html"; then
  echo "ERROR: could not fetch $URL" >&2
  exit 2
fi

# 1) Parse the site: per category, the number, name, description, start-with
#    skill, and the skills listed in it.
python3 - "$TMP/skills.html" > "$TMP/site.tsv" <<'PY'
import re, sys

html = open(sys.argv[1], encoding="utf-8").read()
start = html.find(">Skills<")
end = html.find("What changed recently", start)
if start == -1 or end == -1:
    print("ERROR: could not locate the skills section on the page", file=sys.stderr)
    sys.exit(3)
region = html[start:end]

heads = [(m.start(), m.group(1), m.group(2).strip()) for m in re.finditer(
    r'<h3[^>]*><span[^>]*>(\d+)</span>([^<]+)</h3>', region)]
if not heads:
    print("ERROR: no category headings found — site structure may have changed", file=sys.stderr)
    sys.exit(3)

for i, (pos, num, name) in enumerate(heads):
    chunk_end = heads[i + 1][0] if i + 1 < len(heads) else len(region)
    chunk = region[pos:chunk_end]
    m = re.search(r'</h3><p[^>]*>([^<]+)</p>', chunk)
    desc = m.group(1).strip() if m else ""
    m = re.search(r'Start with<!-- -->\s*<a[^>]*href="/skills-([\w-]+)"', chunk)
    startwith = m.group(1) if m else ""
    skills = []
    for slug in re.findall(r'href="/skills-([\w-]+)"', chunk):
        if slug not in skills:
            skills.append(slug)
    print(f"{num}\t{name}\t{desc}\t{startwith}\t{','.join(skills)}")
PY

# 2) Parse the local metadata out of sync-skills.sh (CATEGORY_META + add lines).
python3 - sync-skills.sh > "$TMP/local.tsv" <<'PY'
import re, sys

src = open(sys.argv[1], encoding="utf-8").read()
cats = re.findall(r'^CATEGORIES=\(([^)]*)\)', src, re.M)
folders = cats[0].split() if cats else []

meta = {}
for m in re.finditer(r'^\s*"([\w-]+)\|([^|\n]*)\|([^|\n]*)\|([^|\n]*)"[ \t]*$', src, re.M):
    folder, name, desc, startwith = (g.strip() for g in m.groups())
    meta[folder] = (name, desc, startwith)

mapping = {}
for m in re.finditer(r'^add\s+([\w-]+)\s+(.+)$', src, re.M):
    folder, skills = m.group(1), m.group(2).split()
    for s in skills:
        mapping[s] = folder

print(",".join(folders))
for f, (n, d, s) in sorted(meta.items()):
    print(f"META\t{f}\t{n}\t{d}\t{s}")
for s, f in sorted(mapping.items()):
    print(f"{s}\t{f}")
PY

# 3) Compare site vs local metadata.
python3 - "$TMP/site.tsv" "$TMP/local.tsv" <<'PY'
import sys

def read_tsv(path):
    with open(path) as f:
        return [line.rstrip("\n").split("\t") for line in f if line.strip()]

site = read_tsv(sys.argv[1])
local_lines = read_tsv(sys.argv[2])

folders = set(local_lines[0][0].split(","))
local = {}
local_meta = {}
for parts in local_lines[1:]:
    if parts[0] == "META":
        local_meta[parts[1]] = (parts[2], parts[3], parts[4])
    elif len(parts) == 2:
        local[parts[0]] = parts[1]

def slug(name):
    return name.strip().lower().replace(" ", "-")

site_skills = {}
site_meta = {}
for num, name, desc, startwith, skills in site:
    folder = f"{num}-{slug(name)}"
    site_meta[folder] = (name, desc, startwith)
    for s in skills.split(","):
        site_skills[s] = (num, name)

issues, info = [], []

# Skill placement drift
for skill, (num, name) in sorted(site_skills.items()):
    expected = f"{num}-{slug(name)}"
    if skill not in local:
        issues.append(f"UNMAPPED       '{skill}' is listed under '{name}' ({num}) on the site "
                      f"but has no mapping in sync-skills.sh — it would land in 07-uncategorized. "
                      f"Add it to the 'add {expected} ...' line.")
    elif local[skill] != expected:
        issues.append(f"MOVED          '{skill}' is listed under '{name}' ({expected}) on the site "
                      f"but sync-skills.sh maps it to '{local[skill]}'.")

for skill, folder in sorted(local.items()):
    if skill not in site_skills:
        info.append(f"NOT ON SITE    '{skill}' is mapped to '{folder}' but not listed on "
                    f"aihero.dev/skills (may be intentional).")

for num, name, _, _, _ in site:
    folder = f"{num}-{slug(name)}"
    if folder not in folders:
        issues.append(f"NEW CATEGORY   the site lists '{num} {name}' -> folder '{folder}' "
                      f"but sync-skills.sh has no such folder. Add it to CATEGORIES, "
                      f"CATEGORY_META, and an 'add' line.")

# Description / start-with drift (these feed README.md via sync-skills.sh)
for folder, (name, desc, startwith) in sorted(site_meta.items()):
    if folder not in local_meta:
        continue
    l_name, l_desc, l_start = local_meta[folder]
    if l_desc != desc:
        issues.append(f"DESCRIPTION    '{name}' ({folder}): the site says \"{desc}\" "
                      f"but sync-skills.sh has \"{l_desc}\". Update CATEGORY_META, "
                      f"then run ./sync-skills.sh to refresh README.md.")
    if l_start != startwith:
        site_hint = f"/{startwith}" if startwith else "(none)"
        local_hint = f"/{l_start}" if l_start else "(none)"
        issues.append(f"START WITH     '{name}' ({folder}): the site says \"Start with {site_hint}\" "
                      f"but sync-skills.sh has \"{local_hint}\". Update CATEGORY_META.")

print(f"\nParsed {len(site)} categories / {len(site_skills)} skills from the site; "
      f"{len(local)} skills mapped, {len(local_meta)} categories in sync-skills.sh.\n")

if issues:
    print("Drift found (update sync-skills.sh, then run ./sync-skills.sh):")
    for i in issues:
        print(f"  ✗ {i}")
if info:
    print("Informational:")
    for i in info:
        print(f"  ℹ {i}")
if not issues:
    print("✓ Site categories, descriptions, and start-with hints match sync-skills.sh.")
print(f"\nSummary: {len(issues)} drift issue(s), {len(info)} informational note(s)")
sys.exit(1 if issues else 0)
PY
