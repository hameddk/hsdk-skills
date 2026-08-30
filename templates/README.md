# hsdk HTML templates

Self-contained page skeletons for every skill that emits HTML: audit
reports, explainers, runbooks, doc hubs. Two looks plus a knowledge-map
front door, one contract — every page ships a three-state theme switch;
the page templates add copy-to-clipboard and annotated `SLOT` / `COMPONENT`
blocks; the map is a DATA block plus an engine you never edit. Extracted from the house
operator-doc artifacts and proven on a live runbook page and a 17-page
explainer.

## Files

| File | What it is |
|---|---|
| `template-artifact.html` | **slate** — the default artifact look. Cool slate neutrals, one teal accent, status hues, sticky top bar, masthead header, at-a-glance tiles, timeline spine. Fully self-contained, system fonts only. |
| `template-cto.html` | **cto** — the indigo doc-hub look. Indigo palette, Poppins body + Playfair Display numerals, sticky contents **rail** (mobile top bar under 1080px), fixed top-right theme switch, masthead with indigo thesis panel, swatch status cards, numbered stage list with squared pills, dual-theme SVG figures. Needs network for Google Fonts (falls back to system fonts offline). |
| `template-map.html` | **map** — the knowledge-map front door for multi-page explainers (the explainer skill's Phase 4): a pannable node graph over the site's topic pages with hover peeks, a reader panel, a guided journey and group dimming. Slate tokens; a DATA block you fill plus an engine you never edit; validates its own data at load. |
| `check-map` | Shell validator for a built map: runs the template's own DATA checks and verifies every node's `topics/<id>.html` exists. `templates/check-map knowledge-map.html` — a clean map prints nothing. |
| `README.md` | This guide: the token contract, the theme mechanism, navigation, copy buttons, and the component catalogs. |

Pick one look per site; don't mix them. The map is not a third look — it
uses the slate tokens and always pairs with slate pages — a **cto** site
gets no map. Everything below
applies to both unless marked **slate**, **cto** or **map**.

## Quick start

1. Copy the template next to your output and rename it.
2. Fill every `<!-- SLOT: ... -->`: title, brand, header, nav anchors, footer, and the theme storage key.
3. Delete every `<!-- COMPONENT: ... -->` block (HTML *and* its CSS rules) that the page does not use.
4. Write content into the remaining structure. Add `class="copyhost"` to blocks worth copying.
5. Run the checklist at the bottom of this file.

## Hard rules — the template is only valid with all of these

- `<meta charset="utf-8">` is **line 1**. Over `file://` browsers otherwise fall back to Windows-1252 and every em dash renders as `â€"`.
- **No external resources** — no CDN, no `fetch`, no XHR, no build step; icons are inline SVG; the file must open by double-click with no server. **One sanctioned exception:** cto's Google Fonts links (Poppins, Playfair Display) — offline it degrades to the system stack and must still read fine.
- **Relative links only**, so a folder of pages can be moved or zipped.
- Keep each file **under ~800 lines**; split into multiple pages and link them rather than growing one page. (The templates themselves are catalogs and run longer; a built map is one file by design — its engine is not hand-written prose.)
- The page must read correctly in **both themes** — check both before shipping (see Theme below).

## Design tokens

All color and type flows through CSS custom properties on `:root`. Never
hard-code a color in a component; never define a token *only* inside the dark
blocks — every token gets its light value on bare `:root` first.

### slate tokens

| Token | Role |
|---|---|
| `--ground` | page background (tinted, sits behind cards) |
| `--surface` / `--surface-2` | card background / inset background (code, thead, hover) |
| `--ink` / `--ink-soft` / `--ink-faint` | primary / body / de-emphasized text |
| `--line` / `--line-strong` | hairline / emphasized borders |
| `--accent` / `--accent-ink` / `--accent-soft` | the one accent (teal): borders & spines / text on ground / tinted fills |
| `--ok`, `--warn`, `--danger` + `-soft` | status text + tinted fills; `warn` doubles as "blocked/pending" |
| `--shadow` | card elevation (both themes define their own) |
| `--mono`, `--sans` | system font stacks; no web fonts |

### cto tokens

| Token | Role |
|---|---|
| `--white` / `--card` | page background / card background |
| `--black` / `--grey` / `--g1` | primary / body / de-emphasized text |
| `--g2` / `--g3` / `--g4` | strong border / hairline / inset fill |
| `--dark-indigo` / `--medium-indigo` / `--light-indigo` | headings / accents & eyebrows / dashed borders |
| `--panel-indigo` | solid indigo fills (thesis panel, firm pills) |
| `--tint` / `--tint2` | indigo-tinted fills (callouts, hovers, number chips) |
| `--cta-blue` | links and focus rings — links are never indigo |
| `--ok`, `--warn`(+`-d`), `--err`(+`-d`) | status swatches and pills |
| `--font-body` / `--font-display` | Poppins / Playfair Display (numerals only) |

One accent color (slate: teal; cto: indigo, with CTA blue reserved for
links). Status hues are for status, not decoration. If you need a second
accent, you are building a different template.

## Theme selector

Three states, CSS-first, JS only sets one attribute:

1. **Light** is the default: tokens on bare `:root`.
2. **System dark**: the same tokens redefined under
   `@media (prefers-color-scheme: dark)` guarded as
   `:root:not([data-theme="light"])` — so an explicit light choice beats a
   dark OS.
3. **Forced dark**: the tokens repeated under `:root[data-theme="dark"]` — so
   an explicit dark choice beats a light OS.

The switch is three icon buttons (sun / half-filled circle / moon) that set
`data-theme="light"`, remove the attribute (auto), or set
`data-theme="dark"`, and persist the choice in `localStorage`.

Rules:

- Change the storage `KEY` once per site (the `SLOT` in the script) so two
  sites served from the same origin don't fight. All pages of one site share
  one key — on the map it is `SITE.themeKey` in the DATA block.
- Keep the two dark blocks **byte-identical**. If you touch a dark value,
  change it in both.
- `localStorage` access stays inside `try/catch` — private windows and some
  `file://` configurations throw on the accessor.
- Never express theme with a class on `body` or with inline styles; the
  attribute-on-`:root` contract is what makes the CSS guards compose.
- Switch placement: **slate** — in the top bar; **cto** — a fixed pill at the
  top right of the viewport on desktop, in the mobile top bar under 1080px.

## Navigation

### slate: top bar

Sticky, same surface language as the cards. Contract:

- **Brand** (left): a 16 px inline SVG in `currentColor` + the site name.
  Links to `#top` on a single page, to `index.html` on inner pages.
- **Anchors**: at most 2–3 same-page section anchors. Sections carry
  `scroll-margin-top: 66px` so anchored headings clear the bar.
- **Pages dropdown**: a native `<details class="menu">` listing every page,
  grouped under `mp-group` labels — the site map in one control. Delete it on
  single-page sites. The script closes it on outside click, Escape, and link
  click; keep that script whenever you keep the menu.
- **Current page**: on multi-page sites, mark the open page's nav link with
  `aria-current="page"` (styled automatically).
- **Theme switch** (right): as above. It lives in the bar; don't float it
  elsewhere.

### cto: contents rail

A sticky left `nav.rail` (260px): brand, kicker, a numbered **Contents**
`<ol>` of on-page sections (`decimal-leading-zero` counters are automatic),
an optional plain **Pages** list of sub-pages, and an `.other` footer line.
Under 1080px the rail hides and the mobile **top bar** appears — same brand,
a `details.menu` panel mirroring the rail's links, and the theme switch.
Keep both in sync when you edit nav links; both use the same menu-close
script as slate.

## Logo

Pages may carry a logo — cto's `footer.end .logo` (132px), or the brand icon slot in either
template. The rule, for every skill that builds from these templates:

- If `~/.claude/skills/hsdk-private-docs/logo.svg` exists, **inline its contents** at the logo
  slot (self-contained rule: embed, never link).
- Otherwise use the built-in **HSDK placeholder mark** that ships in the template (a
  `currentColor` rounded-rect wordmark — it themes automatically).

Drop your organization's logo at `private-docs/logo.svg` in the hsdk-skills repo (gitignored) to
brand every generated page without committing the logo anywhere public.

## Copy buttons

Add `class="copyhost"` to any block a reader may want to paste somewhere: a
command `pre` (wrap it: `<div class="copyhost"><pre>…</pre></div>`), a stage
card, a trap, a callout carrying a decision. The script injects a hover-shown
clipboard button that copies the block's visible text (button excluded,
blank runs collapsed) and flips to a check for 1.4 s. Clipboard API first,
hidden-textarea `execCommand` fallback.

Don't put it on navigation, headings, or one-line labels — a copy button on
everything is a copy button on nothing.

## Component catalog

### slate

| Component | Use for | Variants |
|---|---|---|
| `.badge` | pinned commits, proof counts, one-word caveats in the header | `ok`, `warn`, `danger`, `accent`, `.mono` spans; squared corners, leading status dot |
| `.thesis` | the one-paragraph claim the page defends, right under the header | accent left border; bold the load-bearing sentence |
| `.stats > .stat` | 3–5 headline numbers (stat ledger) | `dd.ok/.danger/.accent` colors the number; `small` for context |
| `.verdicts > .verdict` | questions asked, each with a short colored answer + basis | `.a.yes/.no/.part` |
| `.correction` | earlier wrong claims, replaced up front — put it FIRST when it exists | — |
| `.tiles > .tile` | at-a-glance status board near the top of a page | `band-ok`, `band-warn`, `band-danger`, `band-accent` left spine; no class = neutral |
| `header.masthead` | page header: eyebrow with dash, big h1 (optional `.h1-sub` accent line), lede, mono `.meta-row`, badge legend | — |
| `.callout` | the paragraph the reader must not miss | `ok`, `warn`, `danger` |
| `h2` + `.phase-no` + `.when` | numbered runbook phases / guide steps | — |
| `pre` (+ `.c`, `.out` spans) | commands with inline comments and expected output | `danger` left border for destructive commands |
| `.tablewrap > table` | short enumerable facts; first column is the key | `td.k` bold key col, `td .sub` sub-lines, `.num-col` right-aligned tabular numerals |
| `.timeline > li` + `.stage-card` | a life-cycle spine: what the actor does vs what the system does | `li.blocked` for pending/gated stages; optional `band-*` left spine on the card |
| `.milestones > li` | dated-dot history timeline | `li.cut` (red dot) for removals/regressions; `.d` date, `.sha` ref |
| `.compare-cols > .ccol` | the same list reconstructed side by side | `li.only` + `.flag`/`.flag.warn` per-item markers |
| `.decision` | numbered rulings someone must make | `.id` badge; `.lean` for the recommendation |
| `.opts > .opt` | option compare with pro/con lists | top bar `rec`/`warn`/`no`; `li.pro`/`li.con` |
| `.chain > .chain-lane` | hop-sequence diagrams (pipelines, signal chains) | `works`/`broken` spine; `.hop.good`/`.hop.dead` |
| `.register > .item` | work items with file:line `.cite` + status chips | `.rchip blocked/open/done/unver/size`; close with `.chip-legend` |
| `ul.arrows` | next-step lists (→) | `.ask` variant (?) for open questions |
| `.ev` | dense file:line evidence lists, usually inside `details.fold` | — |
| `.rows > .row` | key/value rubrics (candidates / middle tier / excluded) | `.swatch s-ok/s-warn/s-danger/s-neutral/s-accent` in the key |
| `ol.qs` | simple numbered lists: questions, decisions, prerequisites | — |
| `figure` + `figcaption` | inline SVG diagrams: Gantt bars, boundary maps, comparisons | hexes hard-coded in SVG — check both themes |
| `.topic-grid > .node` | page indexes, topology maps, card grids | `edge` (accent), `data` (dashed) |
| `.trap` | a gotcha that fails quietly — "you would expect X, actually Y" | — |
| `details.fold` | long material most readers skip | — |
| `nav.switch` (top bar) | the Map ⇄ Field-guide view switcher — only on sites that ship a knowledge map; the map carries the mirrored control | `a.cur` + `aria-current="page"` marks the open view |

### cto

| Component | Use for | Variants |
|---|---|---|
| `header.mast` | page header: eyebrow, big h1, `.sub`, `.thesis` indigo panel (the one takeaway, copyable), `.meta` provenance line | — |
| `.snum` | Playfair section numeral above each `h2` | — |
| `.grid.g3 > .card` | status boards and link-card indexes | grids `g2`/`g3`/`g4`; `.swatchline` + `.swatch s-ok/s-warn/s-err/s-neutral/s-indigo`; swatch in `h4` for risk cards; `card ul` for enumerations; `card.tinted` for the highlighted one; linked `h4` for index cards |
| `.callout` | the paragraph the reader must not miss | default indigo tint; `plain` (grey aside), `dark` (solid indigo — the decision, once per page); `.tag` uppercase label |
| `figure` + `.fig-light`/`.fig-dark` | inline SVG diagrams (comparisons, boundary maps, Gantt charts, phase strips) | provide BOTH theme variants; CSS picks one. Indigo ramp #2D297C→#6C63F1→#897EF7; green #1AA785 for the payoff bar |
| `.rows > .row` | key/value rubrics with status-swatch keys | `.k` / `.v`; `em` for the italic why-note |
| `table` | numeric/fact tables: underlined indigo header, zebra rows | `td.num` for tabular numerals; `td.k` bold key col; `td .sub` sub-lines |
| `h3` + `.pill` | phase headings: pill grades commitment | `firm`/`cond`/`stop` |
| `dl.stats > .stat` | 3–5 headline numbers (stat ledger) | `dd.ok/.err/.ind` colors the number |
| `.verdicts > .verdict` | questions asked, each with a short colored answer + basis | `.a.yes/.no/.part` |
| `.correction` | earlier wrong claims, replaced up front | — |
| `ul.milestones` | dated-dot history timeline | `li.cut` (red dot) for removals; `.d` date, `.sha` ref |
| `.compare-cols > .ccol` | the same list reconstructed side by side | `li.only` + `.flag`/`.flag.warn` |
| `.decision` | numbered rulings someone must make | Playfair `.id`; `.lean` for the recommendation |
| `.opts > .opt` | option compare with pro/con lists | top bar `rec`/`warn`/`no`; `li.pro`/`li.con` |
| `.chain > .chain-lane` | hop-sequence diagrams | `works`/`broken` spine; `.hop.good`/`.hop.dead` |
| `.register > .item` | work items with `.cite` file:line + status chips | `.rchip blocked/open/done/unver/size`; close with `.chip-legend` |
| `ul.arrows` | next-step lists (→) | `.ask` variant (?) for open questions |
| `details.fold` + `.ev` | dense file:line evidence inside a fold | — |
| `ol.qs > li` | numbered stage list (timeline / lifecycle / runbook): `.qt` title, `.qop` actor, `.qd` detail, `.qlinks` | `li.blocked` turns the number red; right-side `.qpill`; bare `li` text = simple question list |
| `.pill` | status pills (squared, 6px radius) | `firm` (solid indigo), `cond` (dashed outline), `stop` (red) |
| `footer.end` | provenance + related links; optional brand logo via `.logo` | — |

Both templates ship print styles: rails/topbars hidden, page-break avoidance
on figures, cards, callouts and tables. Printing to PDF works out of the box.

Both templates also carry a **flow-diagram example** establishing the basic SVG
vocabulary: neutral box → accent-tinted box → solid accent box, arrows in the
accent color, dashed line for a boundary. Compose bigger diagrams from only
those primitives.

If a component only restates nearby prose, delete it. The design survives
subtraction; it does not survive decoration.

## One file or many

- **Single-file deliverables** (audit reports, artifacts): everything stays
  embedded, exactly as `template-artifact.html` ships. This is the default.
- **Multi-page sites** (explainers, doc hubs — cto's home turf): either embed the CSS in every
  page (robust — any page can be mailed alone), or extract the `<style>` body
  to `assets/style.css` and link it relatively from each page. If you
  extract, every page still keeps charset first and its own copies of the
  three scripts, and all pages share one theme storage key. Give every page
  the same top bar with the same Pages dropdown, and persistent prev/next
  links in a footer nav.

## Knowledge map (`template-map.html`)

The front door the explainer skill can add to a multi-page explainer: one
self-contained `knowledge-map.html` next to `index.html`, a pannable graph
whose nodes are the site's topic pages. It is a second door onto the SAME
pages, never a parallel content store.

- **Two halves.** Everything between the `DATA START` / `DATA END` markers
  is yours: `SITE` (title, journey label + hint, field-guide href, theme
  key), `GROUPS`, `NODES`, `JOURNEY`, `EDGES`, `ZONES`. Everything after
  `DATA END` is the engine — do not edit it. The ONE edit outside DATA is
  the `<title>` tag (what shows before scripts run); the bar, the journey
  strip, the switcher and the theme key are written from `SITE` at load.
- **It checks itself.** At load the engine validates DATA (ids, zones,
  overlaps, fact arrays with bold lead-ins, edge labels, edges with no clear
  orthogonal route, journey order, leftover placeholders)
  and shows a red banner plus console warnings while problems remain.
  `templates/check-map knowledge-map.html` runs the same validator from the
  shell and additionally verifies that every node's `topics/<id>.html` and
  the field-guide href exist. A clean run prints nothing. `bin/check-map-selftest`
  (in this repo) proves the clean path and every negative check against a
  generated fixture package.
- **Ids and links.** Node ids are slugs (lowercase letters, digits, single
  hyphens) — each names `topics/<id>.html`; `SITE.fieldGuideHref` is a
  relative path inside the package.
- **Layout rules.** Node box 176 × 84 centred on `x,y`, fully inside its
  group's zone; zones and nodes never overlap; a node carrying a journey
  stage needs 12px extra clearance on its top and right — zone edge,
  neighbouring cards, and passing edges (the stage badge and its ring stick
  out); place nodes to minimise edge crossings (edges route orthogonally —
  no diagonals). Mark a relation that would cross most of the map
  `panelOnly` (4th edge element `1`) instead of drawing it.
- **Both doors carry the switcher.** The map's top bar has Map ⇄ Field
  guide; `index.html` gets the mirrored `nav.switch` COMPONENT from
  `template-artifact.html`. Both share one theme key.
- No print form — it is an interactive surface. Hue tokens `--g-1` … `--g-6`
  are defined in all three theme blocks; add `--g-7` in all three if you need
  a seventh group.

## Checklist before shipping

- [ ] `<meta charset="utf-8">` is the first line of every page
- [ ] no `http(s)://` in any `src`/`href` except genuine outbound content links (and cto's Google Fonts links)
- [ ] every relative link resolves, both directions
- [ ] unused `COMPONENT` blocks removed, HTML and CSS both
- [ ] theme storage `KEY` renamed; switch cycles Light / Auto / Dark and persists
- [ ] both themes checked — no unreadable pair, no color defined only in a dark block
- [ ] `copyhost` only on blocks worth pasting; copy works from `file://`
- [ ] cto: rail links and mobile menu panel list the same targets
- [ ] map: `templates/check-map knowledge-map.html` prints nothing; `nav.switch` present on both the map and `index.html`
- [ ] every page under ~800 lines (a built `knowledge-map.html` is exempt — its engine is a template, not prose)
- [ ] page opens by double-click from the filesystem and looks right
