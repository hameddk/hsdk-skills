---
name: architecture-audit
description: Full architecture audit for any software git repo. Generates an architecture overview (stack, modules, routes, endpoints, config, secrets), audits layering and conventions, and flags components that belong in separate services. When a private company rubric is installed (private-docs/architecture-reference.md), matching repos are additionally audited against it. Writes a committed self-contained HTML report to docs/ARCHITECTURE-AUDIT.html (latest only). Run before merging any feature branch.
---

# /architecture-audit — Architecture audit

**Role**: You are acting simultaneously as a **senior software architect** (strategic lens: is this the right design? does this belong here?) and a **senior lead developer** (tactical lens: is this implemented correctly? does it follow the established conventions?). Apply both lenses throughout. Be direct. Name specific files and line numbers. Recommend concrete fixes, not vague principles. Vibe-coders need unambiguous direction — "consider moving X" is insufficient; "move X to Y, here's exactly why, here's exactly how" is the standard.

---

## Before the audit — context interview (three questions, skippable)

Ask as **one batched set** (AskUserQuestion where available), before reading anything:

1. **Areas of concern.** What is this branch/merge about, and are there areas that deserve extra
   attention? These get priority — never the whole scope.
2. **Deliberate deviations.** Known deviations from convention or the reference — tradeoffs
   already made on purpose? These still get verified and reported, labeled
   **accepted, because X** — recorded, not re-argued.
3. **Planned work.** Components already scheduled for extraction or rewrite? Findings there are
   still reported, labeled **already planned** — so the report reflects reality without nagging.

Every question is optional; skipping any or all runs the full audit unchanged. **Answers steer
priority and labeling — they never shrink scope or suppress a finding.**

---

## Run mode — full or incremental

Decide before Phase 0. The last committed report is the memory: read it with
`git show HEAD:docs/ARCHITECTURE-AUDIT.html` and parse its `<meta name="audit-base">` stamp.

**Run FULL when any of these hold** (name the reason in the report's Context line):

- no committed report, or no parseable base stamp
- the base commit is not an ancestor of `HEAD` (history was rewritten)
- `git diff --name-only <base>..HEAD` touches more than ~1/3 of tracked files
- the private rubric changed since the last run (compare the rubric file's sha256 against the
  report's `<meta name="rubric-sha256">` stamp — a changed ruleset invalidates carried
  findings), the last **full** run is older than 3 months, or the user asked for `--full`

**Otherwise run INCREMENTAL against `<base>`:**

- **Scope** = changed files **plus their direct importers** (one hop). Phase 2 and Phase 3B/3C
  apply to this scope; Phase 1's overview is carried forward with only the changed areas
  refreshed (routes, endpoints, models that moved).
- **Always rerun in every mode:** Phase 3A whenever a package manifest or lockfile changed
  (new dependencies are exactly where boundary violations enter), and stack/rubric detection
  (it is one file read).
- **Carry-forward:** a prior finding whose cited file is untouched since `<base>` carries
  forward, labeled **"carried forward — anchor unchanged"**. A finding whose cited file
  changed is re-verified. **CRITICAL findings are never carried forward — re-verify every
  one.**

When the overlay is ON, also stamp `<meta name="rubric-sha256" content="<sha256 of the rubric
file>">` in the report so the next run can detect rubric changes. State the mode in the
report's Context line, e.g.:
`Context: incremental vs abc1234 (8 files changed; carried 5, re-verified 2, new 1)`

---

## Phase 0 — Stack detection

This skill works on any software git repo. Detect, in order:

1. **Language, framework, shape.** Read the package manifest(s) — `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`/`build.gradle`, `*.csproj`, `Gemfile`, `composer.json` — plus lockfiles, top-level directory structure, and entry points. Classify the repo: API service, frontend/SPA, monorepo, CLI tool, library, background worker, infra-as-code.

2. **Private rubric check.** Read the organization's rubric if one is installed:

   ```
   ~/.claude/skills/hsdk-private-docs/architecture-reference.md
   ```

   - File exists and opens with an **"Applies to (detection)"** block → overlay ON only for
     repos matching those criteria; a monorepo matching several gets each side audited
     separately, in sequence.
   - File exists with no detection block → overlay ON for every repo.
   - No file (or the `hsdk-private-docs` symlink is missing) → **generic audit**, overlay OFF.

3. Print: `▶ Auditing [repo-name] ([detected type], [private rubric|generic]) on branch [branch]`

If the repo shape is genuinely ambiguous (no manifest, contradictory signals), ask the user to confirm before continuing.

### Private rubric overlay

The rubric lives in the hsdk-skills repo's gitignored `private-docs/` folder (see its README) so
company rules never reach a public tree. When the overlay is ON, the rubric is the source of
truth — never audit an overlay repo from memory. Generic repos do not need a rubric; universal
checks apply from this skill alone.

---

## Phase 1 — Architecture Overview

Produce a factual map of what exists. This is not an audit — reserve judgement for Phase 2. Pick the closest template below and keep its shape; adapt labels and paths to the detected stack (the paths shown are examples, not requirements — except on overlay repos, where the rubric defines the expected layout).

### 1A — Frontend overview (any frontend/SPA)

Walk the source tree, locale files, static assets, and the package manifest.

```
## Architecture Overview — [repo-name] (Frontend)

### Pages & Routes
| Route path      | Component                                   |
|-----------------|---------------------------------------------|
| /               | src/pages/home/home.tsx                     |
| /control/:id    | src/pages/control/control.tsx               |
(Inferred from the router config — e.g. src/components/app-router/app-router.tsx)

### Navigation / Menu items
(Walk nav, sidebar, menu components — list every link target and its label)
| Label           | Route        |
|-----------------|--------------|
| Home            | /            |

### i18n (if present)
- Provider:        [library / platform]
- Locale files:    [list files found]
- String coverage: all user-visible strings via the i18n API ✓ / ✗ (N hardcoded strings found)
(If the private rubric sets locale requirements, check them.)

### PWA (if configured)
- Service worker:  ✓ / ✗
- Web app manifest:✓ / ✗

### Inline styles
- Inline style props in markup: ✓ clean / ✗ (N occurrences — files listed below)

### Secrets
- Hardcoded API keys / tokens in source: ✓ clean / ✗ (found at: ...)
```

### 1B — Backend / API overview (any API service)

Parse the API spec if one exists (`openapi.yaml`, swagger, GraphQL schema) and walk the service/handler layer.

```
## Architecture Overview — [repo-name] (Backend)

### API Endpoints
| Method | Path                 | Auth          | In spec | Notes              |
|--------|----------------------|---------------|---------|--------------------|
| POST   | /authentication      | PUBLIC        | ✓       | JWT issue          |
| GET    | /users               | JWT ✓         | ✓       |                    |

Public endpoints (no auth required):
  [list — if none, state "None. All endpoints require auth."]

Endpoints in code but NOT in the spec / in the spec but NOT in code:
  [list both directions — if none, state "None"]
  (If no API spec exists at all, state that here — it becomes a Phase 2 finding.)

### Persistence
- ORM / data layer:        [name, or "raw queries"]
- Models/tables found:     [list]
- Inline raw SQL:          ✓ clean / ✗ (found in: ...)
- Migrations present:      ✓ / ✗ (models without migration: ...)

### Secrets & Config
- Config read through one mechanism: ✓ / ✗ (mechanism: ...)
- Scattered env reads in source:     ✓ clean / ✗ (found in: ...)
- Secrets in config files:           ✓ clean / ✗
```

### 1C — Other repo shapes (CLI, library, worker, infra)

```
## Architecture Overview — [repo-name] ([type])

### Entry points
[binaries, exported API, handlers, scheduled jobs]

### Public surface
[commands / exported functions / consumed events — what users or callers depend on]

### External services & persistence
[databases, queues, third-party APIs touched]

### Secrets & Config
[same checks as 1B]
```

---

## Phase 2 — Architecture Audit

**Universal checks — every repo:**

- **Layering & dependency direction**: lower layers must not import upper layers; no circular module dependencies; entry points thin, logic in modules.
- **Separation of concerns**: each module has one describable purpose. Files that have grown past the point of holding in one read are a finding.
- **Config & secrets**: no secrets in the repo; configuration flows through one mechanism, not scattered env reads.
- **Contract drift**: if an API spec, schema, or public type surface exists, code and contract must match in both directions.
- **Error handling**: one consistent strategy, not a mix of swallowed errors, ad-hoc throws, and bare logging.
- **Dead weight**: unused modules, duplicated logic, copy-pasted variants of the same function.

**Overlay checks — rubric repos only.** Check every item from the loaded private rubric. If the
rubric organizes its checks by repo type (backend / frontend / boundary sections), apply the
sections matching the detected type; boundary/service checks apply always.

For every violation, determine severity:

| Severity | Meaning |
|---|---|
| **CRITICAL** | Security hole, data integrity risk, hard contract broken (secret in repo, auth bypassed, migration data loss) |
| **HIGH** | Architectural boundary violation, breaks extensibility, will cause failures at scale |
| **MEDIUM** | Convention drift, tech debt, reduced maintainability |
| **LOW** | Style, naming, minor cleanup |

Output:

```
## Audit Results

| # | Severity | File | Rule | Issue |
|---|----------|------|------|-------|
| 1 | CRITICAL  | src/services/users/users.service.ts:42 | B-AP-6 | Direct process.env read |
...

---

### CRITICAL

#### 1. [Rule ID or check name] — [short title]
**File**: src/services/users/users.service.ts:42
**Found**: `process.env.ADMIN_SECRET`
**Rule**: B-AP-6 — no direct process.env reads in src/  (generic repos: name the universal check)
**Fix**: Add `adminSecret` to the config layer, read via `app.get('adminSecret')`.
```

Every violation must name the exact file and line. Never write "in some service files" or similar. If a check passes cleanly, do not list it — only report violations.

---

## Phase 3 — Service Boundary Check

**Architectural context**: In a service-oriented codebase, each deployable has one purpose and communicates with the rest over explicit APIs or events. **Your role here is senior architect.** The question for every dependency and every module is: *"Does this belong in THIS service, or does it belong in its own?"*

For repos that are deliberately not services — a CLI, a library, a single-purpose tool — do not demand microservices. Instead, apply 3A as *"does this dependency match the repo's stated purpose?"* and evaluate module boundaries rather than service extraction.

### 3A — Out-of-scope component detection

Scan the package manifest (dependencies + dev dependencies) AND all import statements in source files. Signal packages below are npm examples — map to ecosystem equivalents (Python: celery → jobs, weasyprint → PDF, boto3-S3-as-primary-store → storage; Go/Java/etc. likewise).

| Category | Signal packages / imports | Where it should live |
|---|---|---|
| Email sending | nodemailer, @sendgrid/mail, mailgun-js, @aws-sdk/client-ses | Dedicated notification service |
| SMS | twilio, vonage, @aws-sdk/client-sns | Dedicated notification/SMS service |
| AI / RAG / LLM | langchain, openai, @anthropic-ai/sdk, chromadb, weaviate, qdrant, pinecone | Dedicated AI/RAG service |
| PDF generation | pdfkit, puppeteer†, playwright†, jspdf, html-pdf | Dedicated document service |
| Image processing | sharp, jimp, imagemagick, gm, canvas | Dedicated media service |
| Background jobs / queues | bull, bullmq, agenda, bee-queue, @aws-sdk/client-sqs (as scheduler) | Dedicated worker service |
| WebSocket / real-time push | socket.io, ws, uws (unless the API framework's own transport) | Dedicated real-time service |
| Payments | stripe, braintree, mollie, paypal-rest-sdk | Dedicated payment service |
| Full-text search engine | elasticsearch, opensearch-client, meilisearch | Dedicated search service |
| File/object storage (primary feature) | multer beyond temp parsing, @aws-sdk/client-s3 as primary store | Dedicated media/storage service |
| Auth provider (replacing the platform's auth) | auth0, keycloak-connect, passport | External IdP, not bundled |
| Web scraping / browser automation | puppeteer†, playwright† (for scraping) | Dedicated worker service |
| Reporting / analytics | metabase-embed, cube, tableau | Dedicated reporting service |

† puppeteer/playwright flagged only when used for PDF generation or scraping, not for testing.

For each detected out-of-scope component, output:

```
### ⚠ OUT-OF-SCOPE COMPONENT: [Category]

Detected: [package name or import]
Found in: [file:line]

Architect's assessment:
[package] does not belong in [repo-name]. Embedding it here:
  - [Specific reason 1: e.g., couples this service's release cycle to email delivery uptime]
  - [Specific reason 2: e.g., cannot be scaled independently from the API tier]
  - [Specific reason 3: e.g., makes this service responsible for two distinct failure domains]

Recommendation:
  Extract to a dedicated [category] service. [repo-name] should instead emit an
  event to a message queue or call the [category] service's API. The [category]
  service handles delivery, retries, and logging independently.
```

### 3B — Business logic in the wrong tier (repos with a frontend/backend split)

**Frontend**: Any function that enforces a business rule — validation beyond UI feedback, authorization checks, pricing calculations, compliance rules — must move to the backend. List each one with file and line.

**Backend**: Any function that purely formats data for display — locale-dependent strings, date/currency/number formatting for UI rendering — should move to the frontend. List each one.

### 3C — Endpoints without consumers (API repos)

Identify any endpoint that:
- Has no known frontend or client consumer
- Is an admin or maintenance script wrapped as an HTTP route
- Is inter-service communication that should use internal networking instead of the public API

For each, state: what it does, who calls it, and where it should live instead.

---

## Phase 4 — Committed report

Write the audit to **`docs/ARCHITECTURE-AUDIT.html`** in the audited repo — **one self-contained
HTML file, latest only.** Each run overwrites it; there is no dated history.

**The presentation contract is `docs/audit-report-presentation.md` in the hsdk-skills repo. Read it
before writing the report.** It defines the file mechanics (charset, no fetch, no CDN, no sibling
assets), the structure (verdict above the fold → one diagram that earns its place → findings by
severity in collapsible `<details>`), and the five-section shape every finding uses. It is shared
with `/security-audit` so the two reports read as one family.

The five sections, applied to an architecture finding: **what it is → why it matters (what breaks,
or what gets harder to change) → how it actually works (`path:line`) → what surprises people
(often why the structure looks wrong but is deliberate) → what to do (the fix and its cost, or
"accepted, because X")**.

**The diagram here is the module and dependency map with violations marked** — for this audit it
usually does earn its place, because a layering violation is easier to see than to read. Drop it
only if it would restate the table.

**Trend note, state it once in the run summary:** the delta baseline is the last *committed*
version of the report (`git show HEAD:docs/ARCHITECTURE-AUDIT.html`); the full dated history is
`git log -p` on the same path. There are no dated report files — say so, so nobody looks for them.

The Markdown skeleton below is the *content* the HTML carries — the same sections, rendered per the
presentation contract rather than emitted as `.md`.

Report structure:

```
# Architecture Audit — [repo-name] — YYYY-MM

Date:    [ISO 8601 UTC]    Branch: [branch]    Commit: [short sha]
Type:    [detected type]   Rubric: [private rubric | generic]
Context: [focus areas; accepted deviations; planned work — or "interview skipped"]

## Executive summary
[3–6 sentences in plain language for readers who will not read the findings:
overall state, the most important risks, what changed since last month.]

## Architecture overview
[Phase 1 output]

## Findings
[Phase 2 + Phase 3 output, ordered by severity]

## Delta vs previous audit
[Baseline = the last committed version of this report:
`git show HEAD:docs/ARCHITECTURE-AUDIT.html`. Match findings by rule + file
(tolerate line drift). Three lists: New / Fixed / Persisting (note how long
each persisting finding has been open).
If the report has never been committed: "First audit — no baseline."]

## Recommended next steps
[Ordered by priority, one line each.]
```

Then print a terse chat summary:

```
## Summary

Repo:    [name]   Type: [type]   Branch: [branch]
Rule violations:      N  (X critical, Y high, Z medium, W low)
Boundary violations:  N  (list component categories)
Delta:                +N new / -M fixed / K persisting
Report:  docs/ARCHITECTURE-AUDIT.html

Items requiring immediate attention before merge:
  1. [one line each, ordered by severity]
```

If zero violations across all phases, the report still gets written (a clean audit is itself the record):
```
✓ No violations found.
```

Finally, offer to commit the report with message `docs: architecture audit YYYY-MM`. Never push.

---

## Hard rules

- When the private rubric applies, read it before Phase 2. Never audit an overlay repo from memory.
- Name specific files and lines for every finding. Never say "in some files" or "in places".
- If the repo shape is ambiguous, ask before proceeding.
- On overlay repos, never recommend changes that contradict the rubric — its rulings outrank general best practice.
- Service-boundary violations are always at minimum **HIGH** severity — they affect the team's ability to develop, deploy, and scale services independently. (Exception: repos that are deliberately not services, per Phase 3.)
- Hardcoded secrets are always **CRITICAL** regardless of context.
- Always write the report file, even on a clean audit.
- The audit is read-only except for the report file. Never fix findings during the audit.
- Interview answers steer priority and labeling, never scope. A finding covered by a stated deviation or plan is reported and labeled, not dropped.
- When a vibe-coder has built something in the wrong place, be explicit: name the correct service type, explain the separation rationale, and give a migration path. Architectural clarity is the entire point of this skill.
