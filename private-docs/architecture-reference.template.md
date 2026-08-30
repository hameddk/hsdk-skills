# [Your Organization] Architecture Reference

> **This is a starter template.** Copy it to `private-docs/architecture-reference.md` and
> replace every bracketed placeholder with your organization's real rules. Everything in
> `private-docs/` except the README and `*.template.md` files is gitignored — your rules
> never leave your machine. When the copy exists, `/architecture-audit` applies it on top
> of its universal checks.

> **Applies to (detection)** — apply this rubric when the audited repo matches:
> - `[file or dir pattern, e.g. openapi.yaml + src/services/]` → backend ([framework])
> - `[file or dir pattern, e.g. src/pages/ + src/app-router/]` → frontend ([framework])
> - Both → monorepo; audit each side separately
>
> Delete this block to apply the rubric to every audited repo.

---

## Part 1 — Backend checks

State each rule with an ID, the rule itself, and what a violation looks like — the auditor
cites rule IDs in findings.

- **B-1 [rule name]**: [the rule, one sentence]. Violation: [what to flag, concretely].
- **B-2 [e.g. "Config through one mechanism"]**: [e.g. "All configuration is read via the
  config layer; no direct env reads in src/"]. Violation: [e.g. "any process.env outside
  config/"].

## Part 2 — Frontend checks

- **F-1 [rule name]**: [the rule]. Violation: [what to flag].
- **F-2 [e.g. "i18n coverage"]**: [e.g. "every user-visible string goes through the i18n
  API; locales X, Y, Z are required"]. Violation: [hardcoded strings, missing locale files].

## Part 3 — Service-boundary rules

Which capabilities must live in their own service, and how services talk to each other.

- **S-1 [e.g. "Email is its own service"]**: [e.g. "no mail-sending libraries in product
  repos; emit an event / call the notification service instead"].
- **S-2 [approved inter-service mechanism]**: [e.g. "REST between services; queues for
  async; no shared databases"].

## Anti-patterns — highest signal

The mistakes newcomers most commonly make in your stack. Always at least **HIGH** severity.

- [e.g. "Business logic in the frontend — validation, pricing, authorization"]
- [e.g. "A second ORM / query layer alongside the sanctioned one"]

## Hard contracts — always CRITICAL when broken

- [e.g. "No secrets in any repo, ever — config comes from the secret store"]
- [e.g. "Every endpoint requires auth unless listed in the public-endpoint allowlist below"]
