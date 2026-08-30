# CLAUDE.md

Guidance for Claude Code (and other agents) when working in this repository.

## What this repo is

Claude Code / Cursor skills for auditing and explaining software repos. Skill source-of-truth lives at `skills/<name>/SKILL.md`. `bin/install` symlinks these into `~/.claude/skills/<name>/` and `~/.cursor/skills/<name>/`.

## Design decisions (non-negotiable)

Don't "improve" these. They were resolved in design and exist for reasons:

1. **Each skill has a distinct purpose.** `architecture-audit` (pre-merge audit) and `security-audit` (monthly security audit) are the audit pair; the rest are focused repo-authoring helpers.
2. **No `/qa` skill.** Manual browser QA needs a staging URL and a human driving it — not a skill.
3. **No `/review` skill.** Coding agents already review code well on demand, and the audit pair covers the structured part. A review skill would be duplicate coverage.
4. **Symlinks, not copies.** Single source of truth in this repo.

## Conventions

- All code in English. Comments, variable names, commit messages — English regardless of conversation language.
- Commit messages describe behavioral change, not file change.
- New skills: add `skills/<name>/SKILL.md`, update `bin/install` and `bin/uninstall`, update README.
- New output styles: add `output-styles/<name>.md`, update README. `bin/install` globs the directory, so no script change is needed.
- Symlinks, never copies — for output styles too. A copy drifts from the repo silently and there is no signal when it does.

## Out of scope

Don't propose or implement any of these:

- CI pipelines. Personal skill repo, not a product.
- Tests. Skills are markdown — test them by using them.
- Node.js package wrapper. No `package.json`. No `npm install`.
- Emojis in commit messages or filenames.
- Reformatting SKILL.md files. They are pasted verbatim from agreed design.
- Configuration files. Hard-coded paths are fine.
- "Smart router" that picks skills based on diff analysis. Explicitly rejected.
- Cross-platform support beyond macOS/Linux. Windows users are on their own.
- Telemetry, analytics, auto-update. None of this. Ever.

## Pre-commit checklist

Before committing changes that affect skills or install scripts:

- [ ] All SKILL.md files have correct frontmatter (`name:` matching `<dir>`)
- [ ] `bin/install` is executable, idempotent, and runs without errors
- [ ] `bin/install` correctly skips Cursor when `~/.cursor` doesn't exist
- [ ] `bin/uninstall` removes only symlinks
- [ ] No `node_modules/`, `.DS_Store`, or editor cruft committed
- [ ] README stays under 200 lines, free of marketing fluff
- [ ] `git log --oneline` reads as a coherent narrative

## File locations

- Skills: `skills/<name>/SKILL.md` (source of truth)
- Install: `bin/install`, `bin/uninstall`
- Shared HTML templates: `templates/` — symlinked to `~/.claude/skills/hsdk-templates/` by `bin/install`. `template-artifact.html` (slate) is the default; `template-cto.html` only when the prompt explicitly asks for the CTO template; `template-map.html` is the knowledge-map front door the explainer skill builds (a DATA block plus an engine that is never edited; `templates/check-map` validates a built map).
- Docs: `docs/audit-report-presentation.md`
- Private overlays: `private-docs/` — gitignored except its README, symlinked to `~/.claude/skills/hsdk-private-docs/` by `bin/install`. `/architecture-audit` applies `private-docs/architecture-reference.md` when present. Company-specific content lives ONLY here, never in tracked files.
- Audit reports (written into the *audited* repo, not this one): `docs/ARCHITECTURE-AUDIT.html` and `docs/SECURITY-AUDIT.html` — one self-contained HTML file each, latest run only. Shared presentation contract: `docs/audit-report-presentation.md`. Both skills link to it; neither restates it, so the two reports cannot drift apart.
- `AGENTS.md` is a symlink to this file — the same guidance under the filename Codex and other agents read. Never turn it into a copy.
