---
name: make-readme-html
description: Use when asked to create, generate, or refresh a themed, self-contained HTML version of a project's docs — a rendered README/ROLES page, a hub/index landing page with a navigator grid, or an animated "teaser" landing page. Turns Markdown docs into beautiful, consistent, dependency-free HTML built from the shared hsdk slate template (cto template on explicit request). Works for any repo; scales from one page to a linked set across submodules.
---

# /make-readme-html — Themed HTML pages from your docs

You turn a project's Markdown (README.md, ROLES.md, sub-package docs) into **self-contained, single-file HTML pages** in one cohesive design system, and optionally a navigator hub and an animated teaser landing page. Output is portable: open the `.html` directly, no server, no build, no dependencies — system fonts, everything inline (the cto template's Google Fonts links are the one exception, and only when cto was explicitly requested).

The goal is **fidelity + consistency**: render the real doc content faithfully (never paraphrase), and make every page share the same identity so a set of repos reads as one product.

## When to use / not use

Use when the ask is "make an HTML version of the README", "a landing page for the repo", "render the docs as a styled site", "a teaser / elevator-pitch page", or "do the same for the other submodules".

Don't use for: editing the Markdown itself (that's normal editing), a full multi-page app/site framework, or content you'd need to invent — this renders docs that already exist (the teaser mode is the one exception, where you compose a short pitch).

## The design system (one source of truth)

Build every page from the shared hsdk template. Default is
`~/.claude/skills/hsdk-templates/template-artifact.html` (**slate** — cool neutrals, one teal
accent, sticky top bar, three-state theme switch, copy buttons); use `template-cto.html` only when
the prompt explicitly asks for the CTO template. Follow the guide next to the templates
(`~/.claude/skills/hsdk-templates/README.md`) — token contract, theme mechanism, navigation,
component catalog. Never re-derive or fork the stylesheet. If the template directory is missing,
halt and say to re-run `./bin/install` from the hsdk-skills repo.

**Bundled asset** (this skill's own directory, `~/.claude/skills/make-readme-html/assets/`):

- `template-teaser.html` — the Mode C canvas engine, with `{{PLACEHOLDER}}` copy and an EXAMPLE
  network to replace. Modes A and B need only the shared template.

## Modes

- **A — Doc page.** Render one Markdown doc (`README.md` → `README.html`, `ROLES.md` → `README-ROLES.html`). The default.
- **B — Hub / index.** A root landing page: the README content **plus** a "Project map" navigator grid linking the other HTML pages and key docs.
- **C — Teaser.** A cinematic single-screen elevator-pitch landing page with a live `<canvas>` animation. Bespoke; compose a short why/what/how.

For a multi-repo set: build a doc page (A) in each repo/submodule, one hub (B) at the root, and optionally one teaser (C) as `index.html`.

---

## Mode A — Doc page (faithful Markdown → themed HTML)

Start from the shared template: copy `template-artifact.html`, fill every `SLOT`, delete every
`COMPONENT` block the page does not use (HTML *and* its CSS), keep the `KEEP` blocks intact. Then
place the doc content:

- **Title-band hoist into the masthead.** The doc's `# H1` → the masthead `<h1>`; a short mono
  kicker (e.g. `DOCS · OVERVIEW`) → the eyebrow; the first paragraph after the H1 → the lede.
  If the H1 is immediately followed by a non-paragraph (list/code/blockquote), omit the lede and
  start the body there.
- **Everything else** becomes the page body, converted with the rules below.
- **Top bar:** brand = repo/project name, a `View README.md ↗` link, plus cross-links when
  rendering a set. On a multi-page set use the Pages dropdown and one shared theme storage key
  for the whole site.

### Conversion rules (the engine — follow exactly)

1. **Faithful 1:1.** Never paraphrase, summarize, reorder, or omit. Every heading, paragraph, list item, table cell, code block, and blockquote in the source appears in the output.
2. **Title-band hoist.** The doc's `# H1` → `<h1>` in `.head`; the first paragraph after it → `<p class="sub">`. `.prose` begins with everything else. Don't duplicate them in `.prose`. If the H1 is immediately followed by a non-paragraph (list/code/blockquote), omit `<p class="sub">` and start `.prose` there.
3. **★ Escape angle-bracket placeholders.** Literal `<...>` tokens (`<repo>`, `<host>`, `<port>`, `<your-token>`, `<base>`, `<recipient>`, …) and any literal `<`, `>`, `&` MUST become `&lt;`/`&gt;`/`&amp;` — inside text **and** inside `<code>`/`<pre>`. A bare `<repo>` left unescaped renders as an unknown tag and **disappears**. This is the #1 failure to prevent. (If the source has intentional raw HTML, preserve genuine tags but still escape placeholder-style tokens.)
4. **Inline:** `**bold**`→`<strong>`, `*italic*`/`_x_`→`<em>`, `` `code` ``→`<code>` (escaped; never linkify code spans), `[t](u)`→`<a href="u">t</a>`.
5. **Headings:** `##`→`<h2>`, `###`→`<h3>`, `####`→`<h4>`. Give each a GitHub-style slug `id` (lowercase; spaces/underscores→`-`; strip non-`[a-z0-9-]`; collapse repeats) and rewrite intra-doc `[t](#anchor)` links to match, so any TOC works.
6. **Tables** (GFM pipe) → `<div class="tablewrap"><table><thead>…</thead><tbody>…</tbody></table></div>`; drop the `|---|` separator row; convert inline Markdown inside every cell.
7. **Fenced code** ```` ```lang … ``` ```` → `<pre><code>…</code></pre>`, contents escaped (rule 3), line breaks preserved; drop the fence/lang markers. ASCII diagrams go in `<pre>` verbatim (escaped).
8. **Blockquotes** `> ` → `<blockquote><p>…</p></blockquote>`; **lists** → `<ul>`/`<ol><li>` (preserve nesting); `---` → `<hr>`.
9. **Generated blocks.** If the source wraps a region in `<!-- BEGIN GENERATED: … -->` … `<!-- END GENERATED -->`, render the inner content normally but wrap the whole region in `<div class="generated">…</div>` (the theme adds a "generated" badge). Never print the raw comment.
10. **Link rewrite for a themed set.** When other docs in the set are also being rendered, rewrite real Markdown links: `README.md`→`README.html`, `ROLES.md`→`README-ROLES.html`, etc. Leave all other relative paths as-is. Never linkify filenames that appear only inside `` `code` ``.

---

## Mode B — Hub / index (navigator)

Render the root README (Mode A rules) **and** add a "Project map" navigator near the top, using
the template's `.topic-grid > .node` component (its purpose: page indexes and card grids) — one
card per page: title + one-line description. Mark the most important card with the `edge`
(accent) variant. Tables (architecture, roadmap) render per Mode A; for a status column, use
small mono spans colored with the template's status tokens (`--ok` done / `--warn` in progress /
`--ink-faint` planned) — never invent new hues.

## Mode C — Animated teaser (`index.html`)

A cinematic, single-screen elevator pitch with a live `<canvas>` network animation. **Start from `assets/template-teaser.html`** (copy it, fill every `{{PLACEHOLDER}}`, then adapt) — the canvas engine has no equivalent in the shared template, so this asset stays. **Re-theme it to the shared template's slate tokens** (ground / surface / ink / accent) so the teaser and the doc pages read as one product. It already implements: DPR-crisp canvas, a scripted message loop with comet trails + receive-ripples + a status ticker, a `prefers-reduced-motion` static fallback, tab-hidden pause, and a responsive two-column → stacked layout.

Adapt: the headline / sub / CTAs (the pitch), the nav + footer links, and — if the project's "network" differs — the `NODES`, `EDGES`, and `SCRIPT` arrays in the inline script (nodes = the entities, edges = who talks to whom, SCRIPT = an ordered story of messages that "finishes a task"). Keep the elevator-pitch discipline: provoke curiosity about **why / what / how**, then link into the deeper pages (the hub + a "why" page).

---

## Verify before declaring done

1. **Render it.** Open in a headless browser, confirm **no console errors**.
2. **No placeholder leaks** (the critical risk): grep the output for bare angle-bracket tokens, e.g. `grep -nE '<(repo|host|url|port|token|path|base|recipient|name|project)[-a-z0-9]*>' out.html` — any hit is a bug (should be `&lt;…&gt;`).
3. **Faithfulness:** every source table/code block/section is present; the title-band hoist didn't drop content; generated regions became `.generated` divs.
4. **Responsive:** check a narrow viewport (≤480px) — content stacks, no horizontal overflow. For the teaser, confirm the reduced-motion fallback renders a static lit network.
5. **Both themes:** check light and dark; the switch cycles Light / Auto / Dark and persists; all pages of a set share one storage key.

## Conventions

- **Self-contained:** one `.html` file, CSS + JS inline, graphics inline (SVG/canvas). No external resources; system fonts (the cto template's Google Fonts links are the one sanctioned exception, only when cto was explicitly requested). Don't add libraries.
- **English** for all code/markup/comments regardless of conversation language.
- A doc page is a *rendering* of its Markdown — keep them in sync: if you change a `.md`, re-render its `.html`.

## Registration

This skill is installed by `bin/install` (symlinked to `~/.claude/skills/make-readme-html/`). It's in the install/uninstall `SKILLS` arrays and the README. After install, invoke as `/make-readme-html`.
