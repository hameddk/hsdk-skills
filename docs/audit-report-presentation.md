# Audit report presentation — shared spec

Both `/security-audit` and `/architecture-audit` render their report as **one
self-contained HTML file**, using the explanation technique from `skills/explainer/SKILL.md`.

This file is the single source for that contract. Neither skill restates it; both link here.

---

## Output

    docs/SECURITY-AUDIT.html        (security-audit)
    docs/ARCHITECTURE-AUDIT.html    (architecture-audit)

**Latest only.** Each run overwrites its file. There is no dated history and no
`docs/<kind>-audit/YYYY-MM.md`.

**Trend, state it in the run summary once:** the file is committed, so history is not lost —
each skill's report carries a New / Fixed / Persisting delta computed against the last committed
version (`git show HEAD:<file>`), and `git log -p` on the file is the full dated history. Say so,
so nobody goes looking for dated report files.

**One file, deliberately.** Unlike an explainer, an audit gets emailed, attached to a compliance
review, or dropped into a ticket. It is regenerated wholesale each run rather than edited, so the
"a model cannot edit a huge file" rule that governs `explainer` does not apply here.

---

## Template

Build the report from the shared hsdk template:

    ~/.claude/skills/hsdk-templates/template-artifact.html   (slate — the DEFAULT)
    ~/.claude/skills/hsdk-templates/template-cto.html        (cto — only on request)

**Slate is the default.** Use the cto template only when the prompt explicitly asks for it
("use the CTO template", "cto look") — never infer it from the audience or
the repo. Follow the guide next to the templates
(`~/.claude/skills/hsdk-templates/README.md`): fill every `SLOT`, delete every unused
`COMPONENT` block (HTML *and* its CSS), keep the `KEEP` blocks intact.

**Plugin installs have no symlinks** — there the templates ship inside the plugin itself: use
the `templates/` directory at the plugin root (two levels up from the invoking skill's
SKILL.md). Wherever this contract or a skill says `~/.claude/skills/hsdk-templates/`, that
plugin-root `templates/` directory is the equivalent fallback.

If neither location exists, halt and print:

    ✗ hsdk templates not found.
      Expected: ~/.claude/skills/hsdk-templates/ (symlink install)
      or the templates/ directory at the plugin root (plugin install).
      Re-run ./bin/install from the hsdk-skills repo, or reinstall the plugin.

Two audit-specific overrides of the template guide:

- The report stays **one file** regardless of length — the guide's ~800-line split rule yields
  to "One file, deliberately" above.
- cto's Google Fonts links are the one sanctioned exception to "no external resources" — allowed
  only because cto was explicitly requested, and the file must still read fine offline on the
  system-font fallback.

---

## Mechanics — these have specific reasons, do not "improve" them

1. **`<meta charset="utf-8">` first inside `<head>`.** Over `file://` browsers fall back to
   Windows-1252 and every em dash renders as `â€"`. An audit gets opened from disk and emailed as
   an attachment — both are `file://`.
2. **No `fetch`, no XHR, no JSON.** CORS-blocked over `file://`. Everything inline.
3. **No CDN, no external font, no build step.** System font stack, inline SVG. An audit must
   render on a machine with no network — including a reviewer's laptop and an air-gapped host.
   (One sanctioned exception: the cto template's Google Fonts links, when cto was explicitly
   requested — see Template above.)
4. **Self-contained.** No sibling files, no `assets/`. One file that survives being moved,
   zipped, or attached to an email.
5. **Colours as CSS custom properties on `:root`**, redefined under
   `@media (prefers-color-scheme: dark)`. Never define a colour only inside the media query.
6. **Never print a secret value.** Not in the report, not in the chat summary. Path, line, and
   kind only — `.env:14 — AWS key`, never the key. This rule outranks completeness.
7. **Machine-readable base stamp**: `<meta name="audit-base" content="<full commit sha>">` in
   `<head>` — the commit the audit ran against, exactly this attribute shape. The next run
   parses it to decide between a full and an incremental audit (each skill defines its own
   run-mode rules). The human-readable sha in the verdict block does not replace this.

---

## Structure

**Top: the verdict, above the fold.** Counts by severity, the single most urgent item, and the
date + commit SHA the audit ran against. A reader who stops here must still know whether to worry.

**Then: a visual.** The one diagram that carries the audit's shape — for security, where findings
cluster across the attack surface; for architecture, the module/dependency map with violations
marked. Inline SVG, with a text alternative underneath. **If the diagram only restates the
table, leave it out** — a decorative diagram costs trust.

**Then: findings, ordered by severity.** Each finding is collapsible (`<details>`, no JavaScript),
collapsed by default except Critical and High, which start open.

---

## Each finding uses the explainer five-section shape

Adapted from `skills/explainer/SKILL.md` Phase 3. The section names change; the discipline does not.

1. **What it is** — two or three sentences, the way you would tell a colleague.
2. **Why it matters** — the concrete consequence. For security this is the **exploit scenario**:
   who does what, and what they get. "Weak crypto" is not a finding; "an attacker with read access
   to the backup bucket recovers session tokens because they are encrypted with a key committed at
   `config/keys.ts:8`" is.
3. **How it actually works** — the real mechanism, with `path/to/file.ts:123`. This section earns
   the finding. A reader must be able to reach the same conclusion from the citation alone.
4. **What surprises people** — the counter-intuitive part, the assumption you would correct before
   someone acts. Often *why the obvious fix is wrong*. **If a finding has no such section, look
   again — you may have found a symptom rather than the defect.**
5. **What to do** — the concrete fix, and its cost. Where a tradeoff was deliberately accepted,
   say **"accepted, because X"** rather than reporting it as a flaw.

Where they exist, add **Numbers that matter** (versions, limits, counts, CVE ids) and **Where to
look** (3–6 citations, most useful first).

---

## Writing rules

**Explain mechanisms, not vibes.** "Session cookies are set without `HttpOnly` at
`api/session.ts:44`, so any XSS reads them" beats "weak session security."

**Banned:** leverage, robust, seamless, powerful, comprehensive, cutting-edge, best-in-class,
enterprise-grade, simply, just, easily, of course.

**Also banned:** severity without a reason. Every Critical and High states what an attacker or a
maintainer actually gets.

- Concrete number over adjective. Active voice. Short sentences, one idea each.
- Define a term at first use in a half-sentence, then use it freely.
- Name the misconception outright: "You would expect X. Actually Y, because Z."
- Say where an analogy stops holding. An unflagged leaky analogy is worse than none.
- If a section cannot be written plainly, that is a gap in your understanding, not a licence for
  jargon. Go back and read the code.

---

## Evidence rules

**Never state a finding you have not verified.** A false High costs more than a missed Medium: it
burns the reader's trust in the whole report.

- Read the file. Run the command. Check the version. Do not infer from a filename.
- Cite `path:line` for every finding.
- If something looks wrong but cannot be confirmed, report it as **"suspected — not verified"**
  and say exactly what would confirm it. That is a useful finding; a guess dressed as a fact is not.
- When a doc and the code disagree, **the code wins — and say so**, because the stale doc is
  itself a finding.

---

## Self-check before reporting done

- [ ] built from the shared template — slate, unless the prompt asked for cto
- [ ] `<meta charset="utf-8">` is the first line in `<head>`
- [ ] no fetch, no CDN, no external font, no sibling files
- [ ] opening the file directly from disk works, with no network
- [ ] every finding has all five sections
- [ ] every finding cites `path:line`
- [ ] every Critical and High states a concrete exploit or breakage scenario
- [ ] no secret value appears anywhere, including the chat summary
- [ ] every "suspected — not verified" says what would confirm it
- [ ] no banned word appears
- [ ] the verdict block names the commit SHA the audit ran against
- [ ] `<meta name="audit-base">` carries the audited commit's full sha
