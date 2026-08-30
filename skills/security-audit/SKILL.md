---
name: security-audit
description: Comprehensive security audit for any software git repo — secrets (working tree + git history), dependencies, auth, OWASP Top 10, personal data handling, infra/CI-CD, STRIDE threat model. Every finding requires a concrete exploit scenario. Writes a committed self-contained HTML report to docs/SECURITY-AUDIT.html (latest only). Run monthly per product repo, or on demand before compliance-relevant releases. Heavy — expect 15–30 min.
---

# /security-audit — Security audit

**Role**: You are acting as a **Chief Security Officer** (strategic lens: what would actually hurt us? what would a regulator ask?) and a **senior security engineer** (tactical lens: is this door actually unlocked? show me the path). The goal is to find doors that are actually unlocked — not to perform security theater. Every finding must carry a concrete exploit scenario; findings that survive only as "best practice says" get dropped or downgraded to LOW hygiene notes.

The audit is **read-only**: static analysis, standard read-only tooling (`git`, `grep`, `npm audit` and ecosystem equivalents), and code reading. Never exploit anything, never send requests to production systems, never modify code. The only file this skill writes is the report.

---

## Before the audit — context interview (three questions, skippable)

Ask as **one batched set** (AskUserQuestion where available), before reading anything:

1. **Exposure.** Is this deployed internet-facing, internal-only, or not yet deployed? Severity
   is assessed against the stated exposure; with no answer, assume internet-facing.
2. **Areas of concern.** Recent changes or areas that deserve extra attention (a new integration,
   an auth refactor)? These get priority — like seed topics, never the whole scope.
3. **Accepted risks.** Known, deliberately accepted risks? These still get verified and reported,
   labeled **accepted, because X** — so the monthly report shows them without re-arguing them.

Every question is optional; skipping any or all runs the full audit unchanged. **Answers steer
priority, severity context, and labeling — they never shrink scope or suppress a finding.** An
audit that lets the owner pre-clear findings is not an audit.

---

## Run mode — full or incremental

Decide before Phase 0. The last committed report is the memory: read it with
`git show HEAD:docs/SECURITY-AUDIT.html` and parse its `<meta name="audit-base">` stamp.

**Run FULL when any of these hold** (name the reason in the Scope line):

- no committed report, or no parseable base stamp
- the base commit is not an ancestor of `HEAD` (history was rewritten)
- `git diff --name-only <base>..HEAD` touches more than ~1/3 of tracked files
- the last **full** run is older than 3 months (the Scope line of each report records its
  mode, so walk `git log` on the report to find the last full one), or the user asked
  for `--full`

**Otherwise run INCREMENTAL against `<base>`:**

- **Scope** = changed files **plus their direct importers/callers** (one hop — a change in
  one file can make untouched code newly reachable). Phases 3, 4, 5 and 7 apply to this
  scope instead of the whole repo.
- **Always rerun in full, in every mode:** Phase 2 (new advisories publish against unchanged
  lockfiles); Phase 1's history scan on the new commits only (`git log <base>..HEAD -p` —
  naturally incremental) with the working-tree scan covering changed files; and Phase 0
  recon whenever entry points, routes, or infra/CI configs changed.
- **Carry-forward:** a prior finding whose cited file is untouched since `<base>` carries
  forward, labeled **"carried forward — anchor unchanged"**. A finding whose cited file
  changed is re-verified from scratch. **CRITICAL findings are never carried forward —
  re-verify every one, even with an untouched anchor.**

State the mode in the report's Scope line, e.g.:
`Scope: incremental vs abc1234 (14 files changed; carried 9, re-verified 4, new 2) — last full 2026-06`

---

## Phase 0 — Recon & trust boundaries

Works on any software git repo. Build the mental model before hunting:

1. **Stack**: read the package manifest(s) — `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, `Gemfile`, `composer.json` — plus lockfiles, entry points, and directory structure. Classify: API service, frontend/SPA, monorepo, CLI, library, worker, infra.
2. **Entry points**: HTTP routes, message consumers, scheduled jobs, CLI arguments, file uploads, webhooks.
3. **Trust boundaries**: where does untrusted input cross into the system? Internet → API, user → file parser, third-party webhook → handler, CI → deploy.
4. **Assets**: what is worth stealing or breaking here? Credentials, personal data, business records, money-moving operations, the infrastructure itself.

Print a short block:
```
▶ Security audit — [repo-name] ([type]) on branch [branch]
  Entry points:     [list]
  Trust boundaries: [list]
  Crown jewels:     [list]
```

The remaining phases are scoped by what Phase 0 found — skip what does not exist (no CI configs → skip the CI part of Phase 6, and say so in the report), never skip what does.

## Phase 1 — Secrets

- **Working tree**: API keys, tokens, passwords, private keys, connection strings, cloud credentials, committed `.env` files. Check source, config, docs, test fixtures, CI files.
- **Git history**: a secret deleted from the tree is still leaked. Search history for the same patterns (`git log -p` on suspicious paths, `git grep` across revisions of config/env files). Report the commit that introduced it.
- Distinguish live secrets (CRITICAL, needs rotation, not just removal) from obvious placeholders/test dummies (ignore).

## Phase 2 — Dependencies & supply chain

- Lockfile present and consistent with the manifest.
- Known vulnerabilities: run the ecosystem audit tool if available (`npm audit`, `pip-audit`, `cargo audit`, ...); otherwise flag notable outdated security-critical packages.
- Abandoned or suspiciously-named packages (typosquats), packages with install scripts, dependencies pulled from git URLs or HTTP.

## Phase 3 — Auth & access control

- How is authentication implemented? Trace it, don't assume from the framework name.
- Every endpoint/entry point: is authorization enforced, and at which layer? List public endpoints and verify each is intentionally public.
- IDOR: do handlers verify the caller owns the resource, or only that the caller is logged in?
- Token/session hygiene: JWT algorithm and expiry, session invalidation, token storage on the client, password hashing.

## Phase 4 — OWASP Top 10 pass

Walk the code with the current OWASP Top 10 as the checklist: injection (SQL/NoSQL/command/template), broken access control (beyond Phase 3), XSS, SSRF, path traversal, insecure deserialization, security misconfiguration (permissive CORS, missing security headers, debug endpoints in production, default credentials), cryptographic failures, insufficient logging of security events.

**Verify by tracing.** A `dangerouslySetInnerHTML` or string-concatenated query is a *candidate* until you trace whether attacker-controlled input reaches it. Report the traced path, not the grep hit.

## Phase 5 — Personal & regulated data

- Inventory: what personal or regulated data does this repo collect, store, or process? (GDPR is the canonical lens; apply whatever regime the data implies.)
- Where does it flow — databases, logs, third parties, exports, analytics?
- PII in logs or error messages, unencrypted transport or storage of sensitive fields, missing retention/deletion paths, personal data in test fixtures.

## Phase 6 — Infrastructure & CI/CD

- Dockerfiles: running as root, secrets baked into layers, unpinned base images.
- Compose/K8s/Terraform/serverless configs: exposed ports, permissive security groups, plaintext secrets, over-broad IAM.
- CI workflows: secrets exposed to forked-PR triggers (`pull_request_target`), unpinned third-party actions, credentials echoed to logs, deploy jobs without protection.

## Phase 7 — STRIDE threat model

For each trust boundary from Phase 0, one row per applicable threat:

```
| Boundary | Threat (S/T/R/I/D/E) | Scenario | Mitigated? | Where |
|---|---|---|---|---|
| Internet → API | Spoofing | Attacker replays stolen JWT after logout | ✗ | no token revocation |
```

Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Unmitigated rows with a realistic scenario become findings; mitigated rows stay in the table as evidence of coverage.

## Phase 8 — False-positive gate

Before reporting, every candidate finding must pass:

1. **Exploit scenario**: "An attacker who [precondition] does [steps] and gets [impact]." No scenario → drop, or keep as a LOW hygiene note if it is a real but unexploitable gap.
2. **Verified in code**: you read the actual handler/config/path, not just a file name or grep match.
3. **Reachable**: dead code and disabled features are noted as such, not reported as live findings.

Severity:

| Severity | Meaning |
|---|---|
| **CRITICAL** | Exploitable now with no special access: leaked live secret, auth bypass, injection reachable from untrusted input |
| **HIGH** | Exploitable with realistic preconditions (a valid account, an internal foothold), or personal-data exposure |
| **MEDIUM** | Defense-in-depth gap: works today only because another layer happens to hold |
| **LOW** | Hygiene: hardening, headers, best practice with no current path to impact |

## Phase 9 — Committed report

Write the audit to **`docs/SECURITY-AUDIT.html`** in the audited repo — **one self-contained HTML
file, latest only.** Each run overwrites it; there is no dated history.

**The presentation contract is `docs/audit-report-presentation.md` in the hsdk-skills repo. Read it
before writing the report.** It defines the file mechanics (charset, no fetch, no CDN, no sibling
assets, never print a secret), the structure (verdict above the fold → one diagram that earns its
place → findings by severity in collapsible `<details>`), and the five-section shape every finding
uses. It is shared with `/architecture-audit` so the two reports read as one family.

The five sections, applied to a security finding: **what it is → why it matters (the concrete
exploit scenario: who does what, and what they get) → how it actually works (`path:line`) → what
surprises people (often why the obvious fix is wrong) → what to do (the fix and its cost)**.

**Trend note, state it once in the run summary:** the delta baseline is the last *committed*
version of the report (`git show HEAD:docs/SECURITY-AUDIT.html`); the full dated history is
`git log -p` on the same path. There are no dated report files — say so, so nobody looks for them.

The Markdown skeleton below is the *content* the HTML carries — the same sections, rendered per the
presentation contract rather than emitted as `.md`.

```
# Security Audit — [repo-name] — YYYY-MM

Date:    [ISO 8601 UTC]    Branch: [branch]    Commit: [short sha]
Scope:   [phases run; anything skipped and why]
Context: [exposure as stated, or "assumed internet-facing"; focus areas; accepted risks — or "interview skipped"]

## Executive summary
[3–6 sentences in plain language for CTO/compliance readers: overall posture,
the findings that matter, what changed since last month, what to do first.]

## Findings
[Ordered by severity. Each finding:]

### [SEVERITY] N. [short title]
**File**: path/to/file.ts:42
**Exploit scenario**: An attacker who [precondition] does [steps] → [impact].
**Evidence**: [the traced path — where input enters, where it lands]
**Fix**: [concrete change, exact location]

## STRIDE coverage
[Phase 7 table]

## Delta vs previous audit
[Baseline = the last committed version of this report:
`git show HEAD:docs/SECURITY-AUDIT.html`. Match findings by title + file
(tolerate line drift). Three lists: New / Fixed / Persisting — note how long
each persisting finding has been open. Persisting CRITICAL/HIGH findings get
called out in the executive summary.
If the report has never been committed: "First audit — no baseline."]

## Recommended next steps
[Ordered by priority, one line each.]
```

**Redaction rule**: never reproduce a discovered secret's value in the report — name the file, line, and kind (`AWS access key`, `Stripe live key`), first/last 4 characters at most.

Then print a terse chat summary:

```
## Summary

Repo:     [name]   Branch: [branch]
Findings: N  (X critical, Y high, Z medium, W low)
Delta:    +N new / -M fixed / K persisting
Report:   docs/SECURITY-AUDIT.html
```

If there are CRITICAL findings, end with: `⚠ N critical finding(s) — rotate/fix before anything else.`
A clean audit still gets a report — the monthly record of "nothing found, here's what was checked" is itself the compliance artifact.

Finally, offer to commit the report with message `docs: security audit YYYY-MM`. Never push.

---

## Hard rules

- Read-only audit. The report file is the only write. Never fix findings during the audit; never run intrusive or destructive commands.
- Interview answers steer priority and labeling, never scope. A finding covered by a stated accepted risk is reported and labeled, not dropped.
- Every reported finding above LOW carries a concrete exploit scenario and a verified file:line. No scenario, no finding.
- Never say "in some files" — name every location.
- Never include secret values in the report or the chat output.
- Always write the report file, even on a clean audit.
- Skipped phases (nothing to scan) are declared in the report's Scope line, never silently omitted.
