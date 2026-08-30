# private-docs — your organization's private overlays

Everything in this folder **except this README and the `*.template.md` starters** is
gitignored. Keep company-specific reference material here; it never gets committed,
pushed, or included in a PR.

`bin/install` symlinks this folder to `~/.claude/skills/hsdk-private-docs/` (and the
Cursor equivalent) so the skills can read it at runtime.

## Architecture rubric

Start from the shipped template:

    cp private-docs/architecture-reference.template.md private-docs/architecture-reference.md

Then replace every bracketed placeholder with your organization's real rules.

When present, `/architecture-audit` audits repos against it **on top of** its
universal checks. Optionally open the file with an **"Applies to (detection)"** block
listing file/dir patterns that identify your repos — the overlay then activates only
for matching repos. With no detection block, the rubric applies to every audited repo.

No rubric file means the audit runs its universal checks only. Nothing else changes.

## Logo

Put your organization's logo at:

    private-docs/logo.svg

Skills that build HTML from the shared templates inline it at the page's logo slot. Without it,
pages carry a neutral "HSDK" placeholder mark. Keep the SVG self-contained (no external
references) — it gets embedded directly into generated pages.
