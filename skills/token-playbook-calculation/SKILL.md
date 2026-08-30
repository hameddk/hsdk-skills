---
name: token-playbook-calculation
description: Use when auditing the per-role static prompt load and skill inventory of an agent-playbook / multi-agent framework (role playbooks + host overlays + skills + role-policies, e.g. a mythical-style start-agent.sh setup) — questions like "what does each role pay before any work", "how big is the always-on floor per role", "which skills cost what", or "Claude vs Codex overlay asymmetry". Read-only. Pairs with token-calculation (which covers docs/ corpus + session transcripts) to produce the full report.
---

# /token-playbook-calculation — agent-playbook static-load audit

**Role**: You are a performance auditor measuring the fixed per-role context floor of an agent-playbook framework: the base playbook + host overlay each role loads, and the skill files it can pull in. **Read-only.** Numbers, not adjectives. Distributions where there's a population.

**REQUIRED COMPANION:** this skill covers ONLY §1 (static role load) and §2 (skill inventory). For §0 environment, §3 onboarding, §4 docs corpus, and §5/§6 growth+latency, run **token-calculation** and merge both into one §0–§7 report.

## When to use
- "What's the fixed token floor each role pays before doing any work?"
- "Which role is heaviest? How much do the skills add? Claude vs Codex overlay cost?"
- Auditing a `start-agent.sh`-style framework: `<role>-agent.md` + `<role>-agent.claude.md`/`.codex.md` + `skills/<name>/SKILL.md` + `role-policies/<role>.policy.json` + `agent-config.conf`.
- NOT for plain repos with no role playbooks — use token-calculation alone.

## Iron rules
1. **Label every number** `(measured)`, `(est)`, or `NOT AVAILABLE`. Never fabricate.
2. **Token rule**: exact via Anthropic `count_tokens` IF an API key works (the script probes it); else **bytes ÷ 3.8 (est)** — state the divisor. An OAuth (claude.ai Max/Team) session returns **401** on `count_tokens` → est; record it.
3. The "always-on" cost of a skill is its **description block** — and only if the skill is **registered** in the host Skill tool. The **body** is on-invocation. A SKILL.md the playbook reads on-demand via `Read` (not the Skill tool) has **0 always-on** cost.

## Procedure
```bash
SKILL=~/.claude/skills/token-playbook-calculation
bash "$SKILL/playbook-audit.sh" --playbooks /path/to/playbooks/dir
# --skills DIR (default <playbooks>/skills)   --policies DIR (default <playbooks>/role-policies)   --divisor 3.8
```
The script emits:
- **§1 Static role load** — `agent-config.conf` model/effort per role; per role base + claude-overlay + codex-overlay + role-load total (exact if `count_tokens` works, else est); plus shared files (ROLES/README/metanotes/AGENTS) the playbooks pull in.
- **§2 Skill inventory** — per `SKILL.md`: `desc_tok` (always-on **if registered**) and `body_tok` (on-invocation), frontmatter present?; plus the role→skill map parsed from `role-policies/*.policy.json` `.skills` (with each skill's authorization: `triggered` / `read-reference`).

### Do by hand (decisive, the script only hints)
- **Load mechanism** — read the launcher (`bin/start-agent.sh` or equivalent). `--append-system-prompt` ⇒ the role files are a true system-prompt floor (always-on). A **bootstrap that tells the agent to *Read* its files** ⇒ on-demand load (resident only after ~turn 1); the real always-on floor is then the ambient host system-prompt + tool schemas + registered-skill descriptions, which you can anchor empirically from the **first transcript turn's context** (via token-calculation).
- **Skill registration** — confirm which skills are actually in the host Skill tool (`ls ~/.claude/skills`, plugin manifest, or the session's injected skill list). Only those contribute `desc_tok` as always-on; the rest are `Read`-on-demand (0 floor).
- **Claude vs Codex asymmetry** — compare claude-overlay vs codex-overlay sizes per role, and note any host-only ambient registry (plugins) one host carries and the other doesn't.

## Gotchas the script handles (same host traps as the companion)
- RTK wraps `grep`/`awk`/`wc` as shell functions → script `unset -f`s them (else use `command `).
- `set -e` profile kills bare `A && B` → script uses `set +e`.
- `wc -l < file` returns 0 under RTK → use `wc -l file`.
- `count_tokens` 401 on OAuth sessions → script probes and falls back to est.
- A fenced repo may block the `Write` tool → write the report via a shell heredoc to a user-named path outside protected dirs.

## Report assembly
Merge §1/§2 here with §0/§3/§4/§5/§6 from token-calculation into ONE §0–§7 report (§7 = what you could not measure + why). End with a 5-line TL;DR: (1) heaviest static floor + role, (2) typical vs worst onboarding, (3) corpus tail concentration, (4) the one number characterising latency-vs-context, (5) the biggest unmeasured unknown. Write the file outside protected dirs; give the user the path.
