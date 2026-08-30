---
name: explainer
description: Use when someone wants to UNDERSTAND a system they own — "explain what we built", "walk me through the product", "I need to see how this fits together", "document this for a CTO". Interviews the reader, inventories the codebase, then generates a multi-page HTML explainer: a timeline of the product's life plus one deep-dive page per subsystem, written as plain mechanism with no jargon — optionally fronted by an interactive knowledge map (pannable node graph with a guided journey). Derives every claim from code and cites it. NOT for rendering existing Markdown docs (that is make-readme-html) and NOT a README generator.
---

# /explainer — Explain a system to the person who owns it

Generates a browsable HTML explainer of a real codebase: a **timeline spine** of the product's
life, and **one page per subsystem** answering what it is, why it exists, how it actually works,
what surprises people, and what breaks it.

**Distinct from `make-readme-html`**, which themes existing Markdown. This one reads
*source* and explains *mechanism*. If the docs already say it and you just want it pretty, use
that skill instead.

## The reader

One person: **someone who owns this system but has not been in the code day to day.** A CTO, a
returning founder, a new principal engineer. Technical and fluent — do not explain what a process
or an HTTP request is. But they do not know *your* subsystem names, *your* invariants, or *why*
that odd thing is the way it is.

They are usually a visual thinker. The spine is a **timeline**, not a layer diagram.

---

## Phase 0 — Interview. Ask before reading anything.

Ask these as **one batched set** (use AskUserQuestion where available). Do not proceed on
assumptions; the answers change the whole shape.

1. **The journey.** What is the product's life, start to finish, in one line? (e.g. "download →
   install → one project → many projects → connect to the platform → sync memory"). This becomes
   the timeline spine.
2. **The reader's floor.** What does the reader already know cold, and what are they fuzzy on?
   Anything they know cold gets one sentence, not a page. Anything fuzzy becomes a priority topic.
3. **Scope.** Whole workspace, one repo, or one subsystem? For multi-repo workspaces, prefer the
   **umbrella** — the interesting mechanisms usually span repos, and a submodule-scoped run misses
   exactly the parts worth explaining.
4. **Seed topics.** Anything specific they want explained, or any question they have been unable
   to answer themselves? These are the highest-value pages — start the topic list with them.
5. **Front door.** Timeline index only, index **plus knowledge map** (default — an interactive
   node-graph front door over the same pages; see Phase 4), or map as the landing page. The map
   costs one extra file and needs no extra research — it is derived from the build. The map is
   slate-only: an explainer built on the CTO template gets no map — skip this question and Phase 4
   when the prompt explicitly requests CTO.

Optional if unclear: where the output should live, and whether anything is deliberately out of
scope.

**Then read the repo and come back with a proposal — do not start writing HTML.**

---

## Incremental refresh — when an explainer already exists

If `{{OUTPUT_DIR}}/index.html` exists and carries a
`<meta name="explainer-base" content="<sha>">` stamp, refresh instead of rebuilding. **Skip the
Phase 0 interview** — the existing explainer already encodes the reader, journey and scope —
unless the user says those changed.

Fall back to a full rebuild (through the normal phases) when the base commit is not an ancestor
of `HEAD`, or `git diff --name-only <base>..HEAD` touches more than ~1/3 of tracked files.
Otherwise:

1. **Map the diff onto the pages.** Each topic page's own `path:line` citations are its
   dependency set. A topic page is *affected* when the diff touches a file it cites.
2. **Rebuild only affected topic pages**, re-deriving their content from the current code.
3. **Verify kept pages cheaply**: every citation must still resolve (file exists, cited line
   within reasonable drift). A kept page with broken citations is affected after all — rebuild
   it.
4. **Append to the timeline** from `git log <base>..HEAD` if the product's life moved
   (releases, new capabilities, removals). Do not rewrite existing stages.
5. **New subsystems** (new top-level dirs, new services, new manifests) → propose NEW topic
   pages through the normal Phase 1 gate — the proposal lists only the additions, and waits
   for approval like any topic list.
6. **Update the map** (when one exists): touch only the DATA entries for rebuilt/added/removed
   nodes, never the engine; re-run `check-map`.
7. **Re-stamp** `index.html` with the new `HEAD` sha.

Report at the end: pages rebuilt / kept / added, and any kept-page citations that drifted.

---

## Phase 1 — Inventory, then a gate

**Derive the topic list from the repository. Never from a generic architecture template.** The
topics must be the things *this* system actually has.

Read, roughly in this order:
- orientation files: `README.md`, `AGENTS.md`, `CLAUDE.md`
- `docs/` — plans, **ADRs**, design reviews, runbooks. ADRs are the richest source: they record a
  decision *and the problem that forced it*, which is exactly the "why it exists" section.
- manifests and scripts (`package.json`, `Cargo.toml`, `go.mod`), `Dockerfile`, compose, CI
  workflows — these encode the real runtime and the real gates
- the source tree: top-level directories are usually the true subsystem boundaries
- test names — they state intended behaviour more honestly than comments

Come back with, **for approval**:
- proposed **timeline stages**
- proposed **topic list**, 10–25 items, each with a one-line scope
- anything that looked important but could not be verified

**Stop and wait.** A wrong topic list wastes the entire build.

---

## Phase 2 — `index.html`, the timeline

**What happens, in order, across the product's life.** Not a layer diagram.

Each stage carries:
- **what the user does** — a command, a click, a wait
- **what the system does** — the real mechanism, named
- **links to the topics it touches**

Make the timeline visually primary: a spine with stages as nodes and a clear reading direction.
Inline SVG or CSS only. Below it, the topic index, grouped (runtime, storage, security, tooling,
integration…), each with its one-line scope.

---

## Phase 3 — One page per topic, five fixed sections

1. **What it is** — two or three sentences, the way you would tell a colleague.
2. **Why it exists** — what breaks or is worse without it. If an ADR or design doc records the
   original problem, **quote the decisive line and cite it**.
3. **How it actually works** — the real mechanism. Name files, functions, syscalls, tables, env
   vars, ports, limits. This section earns the page.
4. **What surprises people** — the counter-intuitive part; the assumption you would correct before
   someone acts on it. **If a topic has no such section, you have not understood it yet — go back
   to the code.**
5. **What breaks it** — failure modes, sharp edges, accepted residuals, known gaps. "Accepted,
   because X" is a valid and valuable answer; a documented tradeoff is not a flaw.

Then where they exist: **Numbers that matter** (limits, ranges, timeouts, pool sizes, versions)
and **Where to look** (3–6 `path/to/file.ts:123` pointers, most useful first).

**While writing each page, collect map data as you go** (if the map was chosen): every time one
page's mechanism depends on another's, note the pair and a one-line "why these connect" — that
sentence becomes an edge label in Phase 4, and writing time is the cheapest moment to capture it.

---

## Phase 4 — The knowledge map (when chosen in Phase 0)

One extra file, `knowledge-map.html`, in the package root next to `index.html`: a pannable,
zoomable graph of the topic pages, for readers who navigate spatially rather than by list. It is
a second front door onto the SAME topic pages — never a parallel content store. Slate-only: a
CTO-template explainer has no map.

**Build it from `~/.claude/skills/hsdk-templates/template-map.html`.** The file is two halves:
a DATA block (between the `DATA START` / `DATA END` markers) and an ENGINE below it. Replace the
data; **do not edit the engine** — it implements the interaction contract below, and hand-edits
break it in ways that are hard to see until a user hits them. The ONE edit outside DATA is the
`<title>` tag (it is what shows before scripts run); the bar, the journey strip, the switcher and
the theme key are written from `SITE` at load.

### Data you fill in

- **SITE** — the per-site strings: `title` (also the `<title>`), `journeyLabel`, `journeyHint`,
  `fieldGuideHref`, `themeKey` — the ONE storage key every page of the site shares.
- **GROUPS** — 4–6 semantic clusters, each with a name and one of the hue tokens `--g-1` … `--g-6`.
  Names are plain text, at most 24 characters — they render on one-line labels.
- **NODES** — one per topic page. `id` MUST equal the topic slug — lowercase letters, digits, single hyphens — (`topics/<id>.html` is where
  "Read the full page" points). Each carries `x,y` (map coordinates), a one-line `teaser` (the
  hover peek), and `what`: an ARRAY of 2–3 fact bullets, each opening with a bolded lead-in
  (`"<b>Lead:</b> rest"` — the validator checks it) — **never a prose paragraph**; paragraphs are
  what the topic pages are for. Titles and teasers are plain text; titles at most 44 characters.
- **EDGES** — `[a, b, why, panelOnly?]`. Every edge carries a one-line *why these connect* — an
  unlabeled line is decoration, delete it. Mark an edge `panelOnly` (1) when drawing it would
  cross most of the map: it then appears in the reader panel's connection list (tagged "related ·
  not drawn") but not as a line. Prefer a handful of panelOnly edges over a hairball.
- **ZONES** — one dashed rectangle per group. **Every node box (176×84 centred on x,y) must sit
  fully inside its group's zone.** Zones may not overlap. A node carrying a journey stage needs
  12px extra clearance on its top and right — zone edge, neighbouring cards, and passing edges —
  the stage badge and its ground ring stick out.
- **JOURNEY** — the Phase 2 timeline stages mapped onto nodes, numbered 1..n in narrative order,
  each with a stage title and a one-sentence "what happens". This is the guided tour.

Place nodes to MINIMIZE edge crossings first, then compactness. The engine routes edges
orthogonally (horizontal/vertical only — no diagonals, no curves) with rounded bends, picks
routes that dodge node boxes, and draws a small bridge arc where one line must cross another —
but it cannot fix a layout that forces many crossings. Iterate on coordinates until the map
reads calmly. You cannot see the render — iterate against `check-map` (below), which names every
node that leaves its zone and every overlap with exact coordinates.

### The interaction contract (what the engine provides — verify, don't reinvent)

- **Hover peek**: pointing at a node or edge shows a small over-card — node teaser or edge
  "why" — so the reader can preview where a link leads before committing.
- **Click → reader panel**: a slide-in panel (right side) with the topic's group tag, title,
  bold one-line lead, the 2–3 fact bullets, a **"Read the full page"** link to
  `topics/<slug>.html`, and the connected-topics list (each with its why-line; clicking one
  selects it and flies the map there). Escape or ✕ closes and returns to the map — getting back
  is always one action.
- **Journey mode**: toggled from the top bar; lives INSIDE the reader panel as a strip above the
  facts — "stage n of N", a fixed-width numbered segment stepper (jump anywhere; prev/next
  buttons never move), the stage's one-sentence description, ←/→ keyboard stepping, and a gold
  path drawn on the map through the journey nodes. Closing the panel exits journey mode.
- **Legend**: fixed top-LEFT on the map itself (not in the bar), stacked vertically; each chip
  toggles dimming of its group.
- **Top bar, left to right**: brand/title · usage hint · spacer · Journey toggle · the
  **view switcher** · theme switch at the far right. The switcher is a two-segment control with
  icons — graph icon + "Map", document icon + "Field guide" — linking `knowledge-map.html` ⇄
  `index.html`; give `index.html`'s top bar the mirrored control — the `nav.switch` COMPONENT that
  `template-artifact.html`'s top bar carries for exactly this, not a hand-rolled one. No
  breadcrumb trail on the map.
- Pan by drag, zoom by scroll/buttons, fit-to-view; light/auto/dark theme sharing the site's
  storage key.

### Map self-check

- [ ] `~/.claude/skills/hsdk-templates/check-map knowledge-map.html` prints nothing — it runs the
      map's own validator (the one that paints a red banner on the map while problems remain) and
      checks that every node's page and the field-guide href exist
- [ ] every node id has a matching `topics/<id>.html`; every topic page has a node (or a stated
      reason it is off-map)
- [ ] every node inside its zone; zones don't overlap; no diagonal lines anywhere
- [ ] every drawn edge labeled and with a clear orthogonal route (`check-map` names the edges that
      have none); long-haul relations are panelOnly, not hairball lines
- [ ] journey stages all resolve to nodes and read in order 1..n
- [ ] node facts are bullets (array), not paragraphs
- [ ] switcher present in BOTH directions (map ↔ index) via the `nav.switch` COMPONENT, icons
      included, one theme key shared (`SITE.themeKey` = the pages' `KEY`)
- [ ] engine untouched below the DATA END marker

---

## The ELI5 principles — technique from ELI5, altitude from the reader

"Explain like I'm 5" never meant *childish*. Its own rule is **"layman-accessible, not for actual
five-year-olds."** The technique is what transfers; the altitude is set by the reader above. Keep
the floor high — never explain what a variable is — and keep the technique intact:

- **Purpose before mechanism.** People cannot retain a mechanism they have no slot for. Always
  answer "why does this exist" before "how does it work".
- **Anchor to the familiar, then say where the anchor breaks.** A structural analogy earns its
  place; a decorative one does not. **Always state where it stops holding** — an unflagged leaky
  analogy is worse than none, because the reader extends it and is silently wrong.
- **Name the misconception outright.** "You would expect X. Actually Y, because Z." This is the
  single highest-value move in the whole document, and it is what section 4 is for.
- **Concrete instance before general rule.** One real example — a command, a path, a number — then
  the generalisation. Never the reverse.
- **One causal chain at a time.** A causes B causes C. If you need a web, you need more pages.
- **Say what it is *not*.** Half of understanding a boundary is knowing what falls outside it.
- **Beat the curse of knowledge.** The writer cannot remember not knowing. Antidote: before
  publishing a page, state what the reader must already know for it to land — then confirm the
  page assumes nothing beyond that.
- **Feynman's test.** If a section cannot be written plainly, that is a gap in *your*
  understanding, not a licence to reach for jargon. Go back and read the code.

---

## Writing rules

**Explain mechanisms, not vibes.** "The uid pool holds 99 pre-created accounts, 61001–61099, and a
released uid is re-vended to a later session" beats "robust session identity management."

**Banned — these carry no information:** leverage, robust, seamless, powerful, comprehensive,
cutting-edge, best-in-class, enterprise-grade, simply, just, easily, of course.

**Also banned:** describing what a file *contains* rather than what it *does*. "`spawn.ts` handles
spawning" is not an explanation.

- Concrete number over adjective: "~9 minutes", not "slow".
- Short sentences, one idea each. Active voice — the system does things.
- Define a term at first use in a half-sentence, then use it freely.
- Saying "this is subtle" is fine, if what follows is precise about *why*.

---

## Evidence rules — what separates this from a plausible-sounding site

**Never state a mechanism you have not verified.** The failure mode of this document is fluent,
confident, and wrong.

- Prefer **running a command** to recalling. Read the file, grep the symbol, check the version.
- Cite `path:line` for every non-obvious claim.
- If something important cannot be verified, write **"not verified"** and say what you would need
  to check. That sentence is worth more than a guess.
- When a README and the code disagree, **the code wins — and say so on the page.** The stale doc
  is itself useful information about the system.
- Quote decisive lines from ADRs rather than paraphrasing them away.

---

## Output contract

    {{OUTPUT_DIR}}/index.html          timeline spine + topic index
    {{OUTPUT_DIR}}/knowledge-map.html  the map front door (when chosen in Phase 0)
    {{OUTPUT_DIR}}/topics/<slug>.html  ONE FILE PER TOPIC
    {{OUTPUT_DIR}}/assets/style.css    shared styling
    {{OUTPUT_DIR}}/assets/app.js       only if genuinely needed

**Rules with specific reasons — do not "improve" them:**

1. **One topic per file; never a single self-contained page.** A 6000-line HTML file cannot be
   edited reliably by a model later. Keep each file **under ~800 lines**; split and link if
   longer. (Exception: `knowledge-map.html` is one self-contained file by design — its engine is
   a template, not hand-written prose.)
2. **`<meta charset="utf-8">` first inside every `<head>`.** Over `file://` browsers fall back to
   Windows-1252 and every em dash renders as `â€"`.
   `index.html` additionally carries `<meta name="explainer-base" content="<full commit sha>">`
   — the commit the explainer was built from; the next run parses it to refresh incrementally.
3. **No `fetch`, no XHR, no JSON loading.** Over `file://` these are CORS-blocked. Content is
   inline; navigation is plain `<a href>`. Double-clicking `index.html` must work with no server.
4. **No CDN, no external fonts, no build step.** System font stack, inline SVG. (One sanctioned
   exception: the cto template's Google Fonts links, when cto was explicitly requested.)
5. Relative links only, so the folder can be moved or zipped.

**Design — build from the shared hsdk template.** Default is
`~/.claude/skills/hsdk-templates/template-artifact.html` (slate); use `template-cto.html` only
when the prompt explicitly asks for the CTO template; the knowledge map builds from
`template-map.html` per Phase 4. Follow the multi-page guidance in
`~/.claude/skills/hsdk-templates/README.md`: extract the template's `<style>` body into
`assets/style.css`, keep charset first and the template's scripts in every page, and share one
theme storage key across the site. If the template directory is missing, halt and say to re-run
`./bin/install` from the hsdk-skills repo. (Installed as a plugin, the symlink does not exist —
use the `templates/` directory at the plugin root, two levels up from this SKILL.md, wherever a
`hsdk-templates` path is named, `check-map` included.)

The prose rules stand regardless of template: restrained and readable — a reference someone
returns to, not a landing page. 65–75 characters per line. Monospace for code and paths.
Persistent back-link plus prev/next on every page. Diagrams as inline SVG with a text
alternative; if a diagram only restates the prose, leave it out.

---

## Self-check before reporting done

- [ ] built from the shared template — slate, unless the prompt asked for cto
- [ ] `<meta charset="utf-8">` first in every `<head>`
- [ ] `index.html` carries `<meta name="explainer-base">` with the built commit's full sha
- [ ] no page over ~800 lines (`knowledge-map.html` is exempt — its engine is a template, not prose)
- [ ] no fetch, no CDN, no external font, no build step
- [ ] every link resolves, both directions
- [ ] every topic page has all five sections
- [ ] every non-obvious claim carries a `path:line`
- [ ] every "not verified" is deliberate and names what is missing
- [ ] no banned word appears
- [ ] opening `index.html` from the filesystem works with no server
- [ ] if the map was chosen: the Phase 4 map self-check passes too

**Retrofit:** if an explainer package already exists and only the map is wanted, run Phase 4 alone —
derive nodes from the index topic grid, teasers and facts from each page's "What it is", edges
from in-content cross-links and timeline stage links, the journey from the index timeline.
Slate packages only — a CTO-template package gets no map; decline the retrofit and say why.

Then report, terse: what was built, what could not be verified, and the three topics worth
deepening first.
