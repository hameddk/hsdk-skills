#!/usr/bin/env bash
# token-playbook-calculation — read-only static-load audit of an AGENT-PLAYBOOK role set:
#   §1 per-role prompt load (base + host overlays)   §2 skill inventory (desc=always-on-if-registered / body=on-invocation, role->skill map)
# Pair with token-calculation (token-audit.sh) for the docs/ corpus + session transcripts.
#
# Usage: playbook-audit.sh --playbooks DIR [--skills DIR] [--policies DIR] [--divisor N]
#   --playbooks DIR  dir holding <role>-agent.md + <role>-agent.claude.md/.codex.md (+ agent-config.conf)
#   --skills DIR     skills dir (default: <playbooks>/skills) — each <name>/SKILL.md
#   --policies DIR   role-policies dir (default: <playbooks>/role-policies) — <role>.policy.json with .skills
#   --divisor N      chars-per-token estimator when count_tokens is unavailable (default 3.8)
#
# Token rule: exact via Anthropic count_tokens IF $ANTHROPIC_API_KEY works (probed); else bytes/divisor "(est)".
set +e
unset -f grep awk wc sort sed head tail cat find ls cut tr basename 2>/dev/null || true

PLAYBOOKS=""; SKILLS=""; POLICIES=""; DIVISOR="3.8"
while [ $# -gt 0 ]; do case "$1" in
  --playbooks) PLAYBOOKS="$2"; shift 2;;
  --skills) SKILLS="$2"; shift 2;;
  --policies) POLICIES="$2"; shift 2;;
  --divisor) DIVISOR="$2"; shift 2;;
  -h|--help) sed -n '2,18p' "$0"; exit 0;;
  *) echo "unknown arg: $1" >&2; exit 2;;
esac; done
[ -n "$PLAYBOOKS" ] || { echo "ERROR: --playbooks DIR required" >&2; exit 2; }
[ -d "$PLAYBOOKS" ] || { echo "ERROR: not a dir: $PLAYBOOKS" >&2; exit 2; }
[ -n "$SKILLS" ] || SKILLS="$PLAYBOOKS/skills"
[ -n "$POLICIES" ] || POLICIES="$PLAYBOOKS/role-policies"
tok(){ awk -v b="${1:-0}" -v d="$DIVISOR" 'BEGIN{printf "%d", b/d}'; }

echo "########## token-playbook-calculation ##########"
echo "playbooks=$PLAYBOOKS  est-tokens = bytes/$DIVISOR (unless count_tokens usable)"

# count_tokens probe
CT=0
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  code=$(curl -s -m 8 -o /dev/null -w '%{http_code}' https://api.anthropic.com/v1/messages/count_tokens \
    -H "content-type: application/json" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" \
    -d '{"model":"claude-opus-4-8","messages":[{"role":"user","content":"x"}]}' 2>/dev/null)
  [ "$code" = "200" ] && CT=1
  echo "count_tokens: $([ "$CT" = 1 ] && echo 'USABLE (exact)' || echo "NOT AVAILABLE (HTTP $code) -> est")"
else
  echo "count_tokens: NOT AVAILABLE (ANTHROPIC_API_KEY unset) -> est"
fi
ftok(){ local f="$1"; [ -f "$f" ] || { echo 0; return; }
  if [ "$CT" = "1" ] && command -v python3 >/dev/null 2>&1; then
    local n; n=$(python3 - "$f" "$ANTHROPIC_API_KEY" <<'PY' 2>/dev/null
import json,sys,urllib.request
f,key=sys.argv[1],sys.argv[2]
body=json.dumps({"model":"claude-opus-4-8","messages":[{"role":"user","content":open(f,encoding="utf-8",errors="replace").read()}]}).encode()
r=urllib.request.Request("https://api.anthropic.com/v1/messages/count_tokens",data=body,
  headers={"content-type":"application/json","x-api-key":key,"anthropic-version":"2023-06-01"})
try: print(json.load(urllib.request.urlopen(r,timeout=20)).get("input_tokens",0))
except Exception: print("")
PY
)
    [ -n "$n" ] && { echo "$n"; return; }
  fi
  tok "$(wc -c "$f" | awk '{print $1}')"
}

# ---------------- §1 STATIC ROLE LOAD ----------------
echo; echo "===== §1 STATIC ROLE LOAD ====="
if [ -f "$PLAYBOOKS/agent-config.conf" ]; then
  echo "-- per-role model/effort (agent-config.conf) --"
  grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$PLAYBOOKS/agent-config.conf"
  echo
fi
m=$([ "$CT" = 1 ] && echo counted || echo est)
printf "%-12s %9s %9s %9s %9s   (%s)\n" role base claude codex role-load "$m"
for base in "$PLAYBOOKS"/*-agent.md; do
  [ -f "$base" ] || continue
  r=$(basename "$base"); r=${r%-agent.md}
  bt=$(ftok "$base"); ot=$(ftok "$PLAYBOOKS/$r-agent.claude.md"); xt=$(ftok "$PLAYBOOKS/$r-agent.codex.md")
  printf "%-12s %9d %9d %9d %9d\n" "$r" "$bt" "$ot" "$xt" "$((bt+ot))"
done
echo "role-load = base + claude-overlay (Codex variant = base + codex-overlay)."
echo "-- shared files the playbooks pull in (size + est tok) --"
for nm in ROLES README metanotes AGENTS; do
  f="$PLAYBOOKS/$nm.md"; [ -f "$f" ] && printf "  %-14s %8d tok(est)\n" "$nm.md" "$(tok "$(wc -c "$f"|awk '{print $1}')")"
done

# ---------------- §2 SKILL INVENTORY ----------------
echo; echo "===== §2 SKILL INVENTORY ====="
if [ ! -d "$SKILLS" ]; then echo "NOT AVAILABLE (no $SKILLS)"; else
  printf "%-34s %9s %9s   %s\n" skill desc_tok body_tok "fm?"
  for d in "$SKILLS"/*/; do
    f="$d/SKILL.md"; [ -f "$f" ] || continue
    # split frontmatter description-block vs body via state machine
    read dc bc fm < <(awk '
      BEGIN{st="pre"; fm="no"}
      st=="pre" && $0=="---"{st="f"; fm="yes"; next}
      st=="f" && $0=="---"{st="b"; next}
      st=="f"{ if($0 ~ /^description:/){de=1; d+=length($0)+1; next}
               if(de && $0 ~ /^[^ \t]/){de=0}
               if(de){d+=length($0)+1} next }
      st=="b"{ b+=length($0)+1 }
      END{printf "%d %d %s", d, b, fm}' "$f")
    printf "%-34s %9d %9d   %s\n" "$(basename "$d")" "$(tok "$dc")" "$(tok "$bc")" "$fm"
  done
  echo "  desc_tok = the always-on cost IF this skill is registered in the host Skill tool; body_tok = on-invocation."
  echo "  CONFIRM registration by hand (the file alone can't tell): ls ~/.claude/skills, the plugin manifest, or the"
  echo "  spawned session's system-prompt skill list. A SKILL.md read on-demand via Read (not the Skill tool) = 0 always-on."
  echo
  echo "-- role -> skills (from $POLICIES/*.policy.json .skills) --"
  if [ -d "$POLICIES" ] && command -v jq >/dev/null 2>&1; then
    for p in "$POLICIES"/*.policy.json; do
      [ -f "$p" ] || continue
      r=$(basename "$p" .policy.json)
      ids=$(jq -rc '[(.skills.allowed // [])[] | "\(.id)(\(.authorization))"] | join(", ")' "$p" 2>/dev/null)
      printf "  %-12s %s\n" "$r" "${ids:-?}"
    done
  else
    echo "  NOT AVAILABLE (no $POLICIES or jq missing)"
  fi
fi

# ---------------- launcher load-mechanism hint ----------------
echo; echo "===== LOAD MECHANISM (confirm by hand) ====="
echo "How role files enter context changes what 'always-on' means:"
echo "  grep -nE -- '--append-system-prompt|BOOTSTRAP|Read these|read your' <launcher, e.g. bin/start-agent.sh>"
echo "  --append-system-prompt => system-prompt floor (always-on);  bootstrap-Read => on-demand (resident after turn ~1)."
echo
echo "########## end — merge §1/§2 with token-calculation (docs/transcripts) into the §0-§7 report ##########"
