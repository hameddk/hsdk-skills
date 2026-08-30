---
name: token-calculation
description: Use when auditing the context-size, token-budget, or latency of ANY repository from its docs/ folder and its Claude Code session transcripts — questions like "how big is our docs corpus", "why are sessions on this repo getting slow or expensive", corpus growth, giant-doc tail, onboarding read-amplification, or context-vs-latency. Read-only; produces a measured report. For an agent-playbook role/skill static-load audit, pair with token-playbook-calculation.
---

# /token-calculation — docs/ context-size & latency audit (any repo)

**Role**: You are a performance auditor measuring where context (and therefore money and latency) goes in a repository's `docs/` corpus and in the Claude Code sessions run against it. **Read-only — never edit, commit, or change the audited repo.** Your report is the deliverable, not your process. Numbers, not adjectives. Distributions (median / p90 / max), never just means — the tail is what matters.

This skill is **repo-agnostic**: it analyses any `docs/` tree + that repo's transcripts. It knows nothing about agent roles. To audit an agent-playbook framework's per-role prompt floor and skill inventory, **also run the companion skill `token-playbook-calculation`** and merge the sections.

## When to use
- "How many tokens is our `docs/` corpus? Where's the bulk / the giant-doc tail?"
- "Why are Claude Code sessions on this repo getting slow or expensive over time?"
- Establishing a baseline before restructuring docs or prompts.
- NOT for: a single file's token count (just count it); live production latency SLOs (needs OTEL — see latency note).

## Iron rules
1. **Never `cat` the whole corpus into context** (can be ~1M+ tokens). The bundled script sizes in-shell and surfaces only aggregates.
2. **Label every number** `(measured)`, `(est)`, or `NOT AVAILABLE`. Never fabricate or infer a number you did not measure.
3. **Token estimate** = bytes ÷ 3.8 — state the divisor. (Exact `count_tokens` lives in the playbook companion skill, for per-file static load.)
4. **Distributions**: median, p90, max per group.

## Procedure
```bash
SKILL=~/.claude/skills/token-calculation
bash "$SKILL/token-audit.sh" --repo /path/to/repo --sessions 2
# --docs DIR (if not <repo>/docs)   --divisor 3.8   --topn 10
```
The script emits, each labelled:
- **Environment** — OS, Claude Code + Codex versions.
- **Corpus shape** — per `docs/` subdir: files, est tokens, median/p90/max; giant-doc tail (>200 lines); top-N concentration; total tree size.
- **Onboarding** (auto-skips if no `docs/tasks` or `docs/handoffs`) — per dispatch-style artefact: itself + every `docs/*.md` it cites; median/p90/max + largest worked examples.
- **Context growth + latency** — for the richest N session transcripts (resolved from `~/.claude/projects/<encoded-repo-path>/`): per-turn context (input+cache_create+cache_read) first/median/p90/max, monotonic-decrease count (≈ compaction events), inter-turn wall-clock bucketed by context size, and how many transcripts carry a compaction/summary marker.

### Do by hand (the script can't)
- **Worst onboarding example** — itemise the single largest brief line-by-line (itself + each cited artefact + tokens).
- **Latency caveat** — inter-turn seconds include tool-execution time (upper bound). True TTFT / per-request latency is **NOT AVAILABLE** without OTEL (`CLAUDE_CODE_ENABLE_TELEMETRY=1` + an exporter). Say so.

## Gotchas the script already handles (know them for debugging)
- **RTK / token-optimizer wraps `grep`/`awk`/`wc`/etc. as shell functions** that can abort loops — the script `unset -f`s them; if running commands yourself, prefix with `command `.
- **`set -e` in the host profile** kills bare `[ -z x ] && y` lines — the script runs `set +e`.
- **`wc -l < file` returns 0 under RTK** (lost redirect) — use `wc -l file`.
- **The `Grep` tool's `count` mode caps the total at `head_limit`** — the script uses `find`, no cap.
- **A fenced repo may block the `Write` tool** (fail-closed PreToolUse guard) — write the final report via a shell heredoc (`cat > file`) to a path the user names, **outside** any protected dir, and send them the path.

## Report assembly
ONE markdown report, tables + short narrative: **Environment · Corpus shape · Onboarding · Context growth & compaction · Latency · What I could not measure**. End with a 5-line TL;DR: (1) total corpus size, (2) where the bulk/tail is, (3) typical vs worst onboarding, (4) the one number characterising latency-vs-context, (5) the biggest unmeasured unknown. Write the file outside the audited repo's protected dirs; give the user the path.
