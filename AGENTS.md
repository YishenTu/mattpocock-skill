# AGENTS.md

This repo contains Matt Pocock's agent skills (https://github.com/mattpocock/skills), installed locally and organized into category folders.

## Updating skills

Run from the repo root:

```
./sync-skills.sh
```

This runs `npx skills@latest add mattpocock/skills` (installs/updates all skills into `.agents/skills/` and refreshes `skills-lock.json`), then rebuilds the category folders and regenerates the README skill inventory from the metadata in `sync-skills.sh`.

To verify the category metadata (names, descriptions, start-with hints, skills) in `sync-skills.sh` still matches the site, run `./check-categories.sh` (fetches https://www.aihero.dev/skills, read-only, exit 1 when drift is found).

## Skill organization

- `.agents/skills/<name>/` is the canonical copy of each skill (contains `SKILL.md`). Never edit files inside category folders — they are symlinks into `.agents/skills/`.
- Category folders at the repo root are views over `.agents/skills/`, named after the categories on https://www.aihero.dev/skills:

| Folder | Website category |
|---|---|
| `01-getting-started` | Getting Started |
| `02-the-main-flow` | The Main Flow |
| `03-shaping` | Shaping |
| `04-upkeep` | Upkeep |
| `05-productivity-skills` | Productivity Skills |
| `06-reference-skills` | Reference Skills |
| `07-uncategorized` | not listed on the site — default for unmapped skills |

- Each category folder contains relative symlinks `<skill> -> ../.agents/skills/<skill>`.
- `AGENTS.md`/`CLAUDE.md` live only at the repo root.

### Adding a new skill

1. Install it under `.agents/skills/<name>/`.
2. Determine its category from https://www.aihero.dev/skills. If the site doesn't list a category for it (or none is specified), use `07-uncategorized`.
3. Run `./sync-skills.sh` — it links the skill into the right category folder automatically (unmapped skills land in `07-uncategorized`) and refreshes the README inventory. To pin a skill to a category permanently, add it to the matching `add <category> ...` line in `sync-skills.sh`.
