#!/usr/bin/env bash
# sync-skills.sh
# Fetches the latest skills from upstream (npx skills@latest add mattpocock/skills),
# rebuilds the skill category folders from .agents/skills/, and regenerates the
# data-driven parts of README.md (skill count + inventory).
#
# Category metadata lives here (CATEGORY_META + the add lines below) and is the
# single source of truth for both the symlinks and the README. The metadata is
# verified against https://www.aihero.dev/skills by check-categories.sh.
#
# Requires network access (fetches from upstream).
#
# Usage:
#   ./sync-skills.sh

set -euo pipefail
cd "$(dirname "$0")"

ROOT="$(pwd)"
SKILLS_DIR="$ROOT/.agents/skills"

# Fetch/update skills from upstream (requires network)
npx --yes skills@latest add mattpocock/skills -y

# Category folders, in display order.
CATEGORIES=(01-getting-started 02-the-main-flow 03-shaping 04-upkeep 05-productivity-skills 06-reference-skills 07-uncategorized)

# Category metadata used to regenerate README.md:  folder|Display name|Description|Start-with skill
# Descriptions and start-with hints mirror https://www.aihero.dev/skills.
CATEGORY_META=(
  "01-getting-started|01 Getting Started|Set up once, then find your way around.|setup-matt-pocock-skills"
  "02-the-main-flow|02 The Main Flow|The idea→ship spine, in order.|grill-with-docs"
  "03-shaping|03 Shaping|Explore an open question and produce a decision/answer that feeds the flow.|wayfinder"
  "04-upkeep|04 Upkeep|Keep the codebase and issue list healthy; generates work for the flow.|improve-codebase-architecture"
  "05-productivity-skills|05 Productivity Skills|Human-facing workflows you run, not about code.|grill-me"
  "06-reference-skills|06 Reference Skills|The reusable layer other skills invoke or cite.|codebase-design"
  "07-uncategorized|07 Uncategorized|Not listed on the site — default for unmapped skills.|"
)

MAPPED=""

add() {
  local category="$1"; shift
  mkdir -p "$category"
  for skill in "$@"; do
    if [ ! -d "$SKILLS_DIR/$skill" ]; then
      echo "WARN: '$skill' not found in $SKILLS_DIR — skipped" >&2
      continue
    fi
    ln -sfn "../.agents/skills/$skill" "$category/$skill"
    MAPPED="$MAPPED $skill"
  done
}

# Rebuild cleanly (category folders only contain symlinks, so this is safe)
rm -rf "${CATEGORIES[@]}"

add 01-getting-started setup-matt-pocock-skills ask-matt
add 02-the-main-flow grill-with-docs to-spec to-tickets implement code-review
add 03-shaping wayfinder prototype research
add 04-upkeep improve-codebase-architecture diagnosing-bugs resolving-merge-conflicts triage wizard
add 05-productivity-skills grill-me handoff to-questionnaire teach wait-what writing-for-agents
add 06-reference-skills codebase-design domain-modeling grilling tdd

# Every remaining skill goes to 07-uncategorized (default for unmapped skills)
mkdir -p 07-uncategorized
for skill in "$SKILLS_DIR"/*/; do
  name="$(basename "$skill")"
  case " $MAPPED " in
    *" $name "*) ;;
    *) ln -sfn "../.agents/skills/$name" "07-uncategorized/$name" ;;
  esac
done

# (AGENTS.md / CLAUDE.md live only at the repo root — agents find them via upward lookup)

# Regenerate the data-driven parts of README.md (skill count + inventory)
python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
readme = root / "README.md"
src = (root / "sync-skills.sh").read_text(encoding="utf-8")

meta = []
for m in re.finditer(r'^\s*"([\w-]+)\|([^|\n]*)\|([^|\n]*)\|([^|\n]*)"[ \t]*$', src, re.M):
    meta.append((m.group(1), m.group(2).strip(), m.group(3).strip(), m.group(4).strip()))

mapping = {}
for m in re.finditer(r'^add\s+([\w-]+)\s+(.+)$', src, re.M):
    mapping[m.group(1)] = m.group(2).split()

# Skills not pinned by an `add` line land in 07-uncategorized (same rule as above)
skills_dir = root / ".agents" / "skills"
mapped = set(s for skills in mapping.values() for s in skills)
mapping["07-uncategorized"] = sorted(
    p.name for p in skills_dir.iterdir() if p.is_dir() and p.name not in mapped
)
total = sum(len(v) for v in mapping.values())

rows = []
for folder, name, desc, start in meta:
    skills = mapping.get(folder, [])
    desc_part = desc + (f" Start with `/{start}`." if start else "")
    skills_cell = "<br>".join(f"- `{s}`" for s in skills)
    rows.append(f"| {name} | {desc_part} | {skills_cell} |")
inventory = "\n".join([
    "| Category | Description | Skills |",
    "|---|---|---|",
] + rows)

text = readme.read_text(encoding="utf-8")
count_re = re.compile(r"<!-- SKILL-COUNT:START -->.*?<!-- SKILL-COUNT:END -->", re.S)
text, n1 = count_re.subn(f"<!-- SKILL-COUNT:START -->{total}<!-- SKILL-COUNT:END -->", text)
inv_re = re.compile(r"<!-- SKILL-INVENTORY:START -->.*?<!-- SKILL-INVENTORY:END -->", re.S)
block = f"<!-- SKILL-INVENTORY:START -->\n\n{inventory}\n\n<!-- SKILL-INVENTORY:END -->"
text, n2 = inv_re.subn(lambda m: block, text)

if not n1 or not n2:
    print("WARN: README.md markers not found — add <!-- SKILL-COUNT:START/END --> and "
          "<!-- SKILL-INVENTORY:START/END -->", file=sys.stderr)
    sys.exit(0)

readme.write_text(text, encoding="utf-8")
print(f"README.md updated: {len(meta)} categories, {total} skills")
PY

echo "Done. Skills linked into: ${CATEGORIES[*]}"
