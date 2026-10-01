# Matt Pocock Skills (organized)

> **Purpose:** this repo is a categorized index of [Matt Pocock's agent skills](https://github.com/mattpocock/skills) for quickly browsing them by area. It contains no original skill content — **all credit belongs to Matt Pocock** ([aihero.dev](https://www.aihero.dev), [github.com/mattpocock/skills](https://github.com/mattpocock/skills)).

The <!-- SKILL-COUNT:START -->38<!-- SKILL-COUNT:END --> skills are installed once into `.agents/skills/` (canonical copies) and surfaced through category folders via relative symlinks, so the repo stays consistent across machines.

## Skill inventory

<!-- SKILL-INVENTORY:START -->

| Category | Description | Skills |
|---|---|---|
| 01 Getting Started | Set up once, then find your way around. Start with `/setup-matt-pocock-skills`. | - `setup-matt-pocock-skills`<br>- `ask-matt` |
| 02 The Main Flow | The idea→ship spine, in order. Start with `/grill-with-docs`. | - `grill-with-docs`<br>- `to-spec`<br>- `to-tickets`<br>- `implement`<br>- `code-review` |
| 03 Shaping | Explore an open question and produce a decision/answer that feeds the flow. Start with `/wayfinder`. | - `wayfinder`<br>- `prototype`<br>- `research` |
| 04 Upkeep | Keep the codebase and issue list healthy; generates work for the flow. Start with `/improve-codebase-architecture`. | - `improve-codebase-architecture`<br>- `diagnosing-bugs`<br>- `resolving-merge-conflicts`<br>- `triage`<br>- `wizard` |
| 05 Productivity Skills | Human-facing workflows you run, not about code. Start with `/grill-me`. | - `grill-me`<br>- `handoff`<br>- `to-questionnaire`<br>- `teach`<br>- `wait-what`<br>- `writing-for-agents` |
| 06 Reference Skills | The reusable layer other skills invoke or cite. Start with `/codebase-design`. | - `codebase-design`<br>- `domain-modeling`<br>- `grilling`<br>- `tdd` |
| 07 Uncategorized | Not listed on the site — default for unmapped skills. | - `claude-handoff`<br>- `git-guardrails-claude-code`<br>- `implement-spec`<br>- `loop-me`<br>- `migrate-to-shoehorn`<br>- `pr`<br>- `retro`<br>- `scaffold-exercises`<br>- `setup-pre-commit`<br>- `setup-ts-deep-modules`<br>- `writing-beats`<br>- `writing-fragments`<br>- `writing-shape` |

<!-- SKILL-INVENTORY:END -->

## Quick start

```bash
git clone https://github.com/YishenTu/mattpocock-skill.git mattpocock-skill   # new machine
cd mattpocock-skill
./sync-skills.sh
```

That's it — one command fetches the latest skills and rebuilds everything. On an existing checkout, just run `./sync-skills.sh` (that's the fetch + categorize step of the workflow below).

## Workflow

1. **Fetch**: `./sync-skills.sh` — downloads the latest skills (`npx skills@latest add mattpocock/skills`)
2. **Categorize**: the same command links each skill into its category folder; skills not listed on aihero.dev/skills go to `07-uncategorized`
3. **Read** them: browse the category folders (they're just symlink views of `.agents/skills/`)

## Commands

| Command | What it does |
|---|---|
| `./sync-skills.sh` | Fetches the latest skills (`npx skills@latest add mattpocock/skills`), rebuilds the 7 category folders from `.agents/skills/`, and regenerates the README inventory. |
| `./check-categories.sh` | Fetches aihero.dev/skills and reports drift vs the metadata in `sync-skills.sh` (read-only; exit 1 = drift). |

To pin a skill to a category permanently, add it to the matching `add <folder> ...` line in `sync-skills.sh`. Unmapped skills automatically land in `07-uncategorized`.

## Notes

- **Symlinks are relative** — keep them that way; absolute symlinks break on other machines.
- **Windows**: cloning requires Developer Mode + `git config core.symlinks true`, otherwise symlinks materialize as text files.
- **Never use "Download ZIP"** from GitHub/GitLab — symlinks aren't preserved. Always `git clone`.
- Skills run with full agent permissions — review new skills before use.
