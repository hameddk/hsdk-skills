# hsdk-skills

Agent skills for **auditing and explaining software repos** — for Claude Code, Cursor, and any
harness that speaks the open [Agent Skills](https://agentskills.io) format (OpenAI Codex,
Gemini CLI, GitHub Copilot CLI, and others).

Agents are good at reading code and bad at leaving durable evidence behind. A great audit that
lives in terminal scrollback is worth nothing next month. These skills make agents produce
**artifacts**: committed, self-contained HTML reports and explainers you can open by
double-click, email to a board, or attach to a compliance review — all in one shared design
system, so everything generated across your repos reads as one product.

## What's inside

Every skill is slash-invoked — type its name in any repo you want it to work on.

### Audits — reports that survive

| Skill | What it does |
|---|---|
| `/security-audit` | Monthly whole-repo security audit: secrets (working tree **and** git history), dependencies, auth, OWASP Top 10, personal-data handling, infra/CI-CD, STRIDE threat model. Every finding must carry a concrete exploit scenario — "weak crypto" is not a finding. Writes `docs/SECURITY-AUDIT.html`. |
| `/architecture-audit` | Pre-merge architecture audit: overview, layering and convention violations, service-boundary check ("does this belong in *this* service?"). Applies your private company rubric on top when installed. Writes `docs/ARCHITECTURE-AUDIT.html`. |

Both reports are **latest-only and committed** into the audited repo: each run overwrites the
file and computes a New / Fixed / Persisting delta against the last committed version, so the
trend lives in git, not in a folder of dated files. Both open with a skippable three-question
context interview that steers priority but can never suppress a finding. **Reruns are
incremental**: each report stamps the commit it audited, so the next run re-examines only what
changed (plus one hop of dependents), carries forward untouched findings labeled as such, and
falls back to a full audit when the diff is large, the ruleset changed, or three months have
passed. They share one
[presentation contract](docs/audit-report-presentation.md): verdict above the fold, one diagram
that has to earn its place, findings by severity — each answering *what it is, why it matters,
how it actually works, what surprises people, what to do*.

### Explaining & docs — pages people actually open

| Skill | What it does |
|---|---|
| `/explainer` | Understand a system you own. Interviews you, inventories the repo, then generates a multi-page HTML explainer: a timeline of the product's life plus one page per subsystem — optionally fronted by an interactive knowledge map. Every claim cited to `path:line`. Reruns refresh incrementally — only pages whose cited files changed get rebuilt. |
| `/make-readme-html` | Render Markdown docs you already wrote into themed, self-contained HTML — a doc page, a hub with a navigator grid, or an animated teaser landing page. |
| `/make-agents-md` | Write or audit agent-instruction files (AGENTS.md, CLAUDE.md, role overlays, nested per-package guidance) for any repository. |

`/make-readme-html` themes docs that exist; `/explainer` reads *source* and explains
*mechanism* when the docs don't exist or don't say how the thing really works.

### Token & cost analysis — see what your agent setup costs

| Skill | What it does |
|---|---|
| `/token-calculation` | Measure a repo's context footprint: docs corpus size and growth, giant-doc tail, onboarding read-amplification, context-vs-latency. Read-only. |
| `/token-playbook-calculation` | Measure an agent-playbook framework's per-role static load: base+overlay floor, skill inventory, role→skill map. Read-only. |

## Install

**As a Claude Code plugin** (skills namespaced as `hsdk:security-audit` etc.):

```
/plugin marketplace add hameddk/hsdk-skills
/plugin install hsdk@hsdk-skills
```

**Or via symlinks** (bare skill names, plus Cursor and Agent Skills harnesses):

```bash
git clone https://github.com/hameddk/hsdk-skills.git ~/hsdk-skills
cd ~/hsdk-skills
./bin/install
# Restart Claude Code (and Cursor if running)
```

The installer symlinks the skills into every harness it detects:

- `~/.claude/skills/` — Claude Code (always)
- `~/.cursor/skills/` — Cursor (when `~/.cursor` exists)
- `~/.agents/skills/` — the [Agent Skills](https://agentskills.io) cross-runtime alias read by
  OpenAI Codex, Gemini CLI, GitHub Copilot CLI and other compatible harnesses (when any of
  `~/.agents`, `~/.codex`, `~/.gemini`, `~/.copilot` exists)

The script is idempotent: safe to run again after every `git pull`. Skills are **symlinked,
never copied**, so a pull updates every harness in place.

## One design system

`templates/` holds the shared page skeletons every HTML-emitting skill builds from:

- `template-artifact.html` — **slate**, the default: cool neutrals, one teal accent, system
  fonts, three-state theme switch (light / auto / dark), copy-to-clipboard, print styles.
- `template-cto.html` — **cto**, an indigo doc-hub look, used only when you ask for it.
- `template-map.html` — the knowledge-map front door `/explainer` can add to an explainer.

Every generated page is one self-contained file: no CDN, no build step, opens from `file://`
on an air-gapped machine, and renders correctly in light and dark. See
[templates/README.md](templates/README.md) for the token contract and component catalogs.

## Private company overlays

Your organization's context belongs in `private-docs/` — **gitignored except its README and
the starter templates**, so it never reaches a public tree, a commit, or a PR:

- `architecture-reference.md` — your architecture rubric. When present,
  `/architecture-audit` audits matching repos against it on top of the universal checks.
  Start from `private-docs/architecture-reference.template.md` and fill in the placeholders.
- `logo.svg` — your logo, inlined into generated pages. Without it, pages carry a neutral
  "HSDK" placeholder mark.

See [private-docs/README.md](private-docs/README.md).

**Plugin installs and the overlay:** installing via the plugin marketplace does not create the
`hsdk-private-docs` symlink, so the audits run generic (by design — graceful degradation). To
use your private rubric and logo alongside the plugin, clone the repo and add one symlink:

```bash
ln -s ~/hsdk-skills/private-docs ~/.claude/skills/hsdk-private-docs
```

(Or run `./bin/install`, which sets it up along with the symlinked skills.)

## Output styles

`output-styles/` ships Claude Code output styles (Cursor has no equivalent). Installing does not
activate one — pick with `/output-style`. Currently: **Clear Technical**, plain jargon-free
explanations for competent engineers.

## Updating

```bash
cd ~/hsdk-skills && git pull   # symlinks resolve automatically; restart Claude Code
```

## Uninstall

```bash
./bin/uninstall   # removes symlinks only
```

## Contributing

Skills are Markdown — read one, edit it, test it by using it. See
[CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome.

## License

[MIT](LICENSE)
