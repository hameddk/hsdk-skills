#!/usr/bin/env bash
# token-calculation — read-only context-size & latency audit of ANY repo's docs/ corpus
# and that repo's Claude Code session transcripts. Repo-agnostic; no playbook/role knowledge.
# (For agent-playbook role/skill static load, use token-playbook-calculation.)
#
# Usage: token-audit.sh [--repo DIR] [--docs DIR] [--divisor N] [--topn N] [--sessions N]
#   --repo DIR     repo root to audit (default: cwd). Sizes <repo>/docs/**.md
#   --docs DIR     override the docs dir (default: <repo>/docs)
#   --divisor N    chars-per-token estimator (default 3.8)
#   --topn N       giant-tail / top-N concentration (default 10)
#   --sessions N   transcripts to deep-analyse for growth+latency (default 2)
#
# Read-only: never writes inside the audited repo (scratch goes to mktemp).
# Token rule: every number here is "(est)" = bytes/divisor. (Exact count_tokens is used
# only by the per-file static-load audit in token-playbook-calculation.)
set +e
# RTK / token-optimizer wraps coreutils as shell functions; drop any inherited wrappers.
unset -f grep awk wc sort sed head tail cat find ls cut tr basename 2>/dev/null || true

REPO="$(pwd)"; DOCS=""; DIVISOR="3.8"; TOPN="10"; SESS="2"
while [ $# -gt 0 ]; do case "$1" in
  --repo) REPO="$2"; shift 2;;
  --docs) DOCS="$2"; shift 2;;
  --divisor) DIVISOR="$2"; shift 2;;
  --topn) TOPN="$2"; shift 2;;
  --sessions) SESS="$2"; shift 2;;
  -h|--help) sed -n '2,16p' "$0"; exit 0;;
  *) echo "unknown arg: $1" >&2; exit 2;;
esac; done
[ -n "$DOCS" ] || DOCS="$REPO/docs"
tok(){ awk -v b="${1:-0}" -v d="$DIVISOR" 'BEGIN{printf "%d", b/d}'; }

echo "################ token-calculation ################"
echo "repo=$REPO   docs=$DOCS   est-tokens = bytes/$DIVISOR"
date -u +"run_utc=%Y-%m-%dT%H:%M:%SZ" 2>/dev/null

# ---------------- ENVIRONMENT ----------------
echo; echo "===== ENVIRONMENT ====="
uname -sr 2>/dev/null
sw_vers 2>/dev/null | tr '\n' ' '; echo
echo "claude: $(claude --version 2>/dev/null || echo n/a)   codex: $(codex --version 2>/dev/null || echo n/a)"

# ---------------- corpus index (lines<TAB>bytes<TAB>abspath) ----------------
IDX=$(mktemp); : > "$IDX"
[ -d "$DOCS" ] && find "$DOCS" -type f -name '*.md' -exec wc -lc {} + 2>/dev/null \
  | grep -vE ' total$' | awk '{l=$1;b=$2;$1="";$2="";sub(/^ +/,"");print l"\t"b"\t"$0}' > "$IDX"
NF=$(awk 'END{print NR+0}' "$IDX")

# ---------------- CORPUS SHAPE ----------------
echo; echo "===== CORPUS SHAPE (docs=$DOCS) ====="
if [ "$NF" -eq 0 ]; then echo "NOT AVAILABLE (no $DOCS/*.md)"; else
  TOTB=$(awk '{s+=$2}END{print s}' "$IDX")
  echo "files=$NF  total_bytes=$TOTB  total_tok(est)=$(tok "$TOTB")"
  printf "%-18s %5s %10s %9s %9s %9s\n" subdir files tok_est median p90 max
  SUBS=$(awk -v d="$DOCS/" '{p=$3; sub("^"d,"",p); n=split(p,a,"/"); if(n>1)print a[1]}' "$IDX" | sort -u)
  haveroot=$(awk -v d="$DOCS/" '{p=$3; sub("^"d,"",p); if(p !~ /\//)c++} END{print c+0}' "$IDX")
  for sd in $SUBS; do
    TBI=$(mktemp)
    awk -v d="$DOCS/$sd/" 'index($3,d)==1{print $2}' "$IDX" | sort -n > "$TBI"
    awk -v sd="$sd" -v D="$DIVISOR" '{v[NR]=$1;s+=$1} END{n=NR; if(n==0){printf "%-18s (none)\n",sd} else {mi=int((n+1)/2); pi=int(n*0.9); if(pi<1)pi=1; printf "%-18s %5d %10d %9d %9d %9d\n", sd, n, s/D, v[mi]/D, v[pi]/D, v[n]/D}}' "$TBI"
    rm -f "$TBI"
  done
  [ "$haveroot" -gt 0 ] && echo "(+ $haveroot file(s) at docs/ root)"
  echo "-- giant docs (>200 lines) --"
  awk -v D="$DIVISOR" '$1>200{printf "%5d lines  %8d tok  %s\n",$1,$2/D,$3}' "$IDX" | sort -rn | head -20
  TOPB=$(awk '{print $2}' "$IDX" | sort -rn | head -"$TOPN" | awk '{s+=$1}END{print s+0}')
  awk -v t="$TOPB" -v T="$TOTB" -v n="$TOPN" 'BEGIN{printf "top-%d files = %.1f%% of corpus\n", n, (T?100*t/T:0)}'
fi

# ---------------- ONBOARDING (only if dispatch-style dirs exist) ----------------
echo; echo "===== ONBOARDING = artefact + cited docs/*.md (est) ====="
if [ "$NF" -eq 0 ]; then echo "NOT AVAILABLE (no corpus)"; else
  any=0
  for kind in tasks handoffs; do
    d="$DOCS/$kind"; [ -d "$d" ] || continue
    any=1; TBO=$(mktemp)
    for bf in $(ls -1 "$d"/*.md 2>/dev/null | sort -r); do
      ob=$(awk -v f="$bf" '$3==f{print $2}' "$IDX"); sum=${ob:-0}
      for c in $(grep -oE 'docs/[A-Za-z0-9/._-]+\.md' "$bf" 2>/dev/null | sort -u); do
        cp="$REPO/$c"; [ "$cp" = "$bf" ] && continue
        cb=$(awk -v f="$cp" '$3==f{print $2}' "$IDX"); sum=$((sum+${cb:-0}))
      done
      printf "%d\t%s\n" "$(tok "$sum")" "$(basename "$bf")" >> "$TBO"
    done
    sort -n "$TBO" | awk -v k="$kind" '{a[NR]=$1} END{n=NR; if(n==0){print k": (none)"; exit} mi=int((n+1)/2); pi=int(n*0.9); if(pi<1)pi=1; printf "%-9s n=%d  median=%d  p90=%d  max=%d  (onboarding tok, est)\n", k, n, a[mi], a[pi], a[n]}'
    echo "  largest $kind onboarding (tok | file):"; sort -rn "$TBO" | head -3
    rm -f "$TBO"
  done
  [ "$any" = 0 ] && echo "skipped (no docs/tasks or docs/handoffs — onboarding analysis needs dispatch-style artefacts that cite docs/*.md)"
  [ "$any" = 1 ] && echo "CAVEAT: counts cited docs/*.md only (excludes source-code reads) -> understates true cold-start."
fi

# ---------------- CONTEXT GROWTH + LATENCY ----------------
echo; echo "===== CONTEXT GROWTH + LATENCY (this repo's Claude Code transcripts) ====="
enc=$(printf '%s' "$REPO" | sed 's#/#-#g')
TDIR="$HOME/.claude/projects/$enc"
if [ ! -d "$TDIR" ]; then echo "NOT AVAILABLE (no transcripts at $TDIR)";
elif ! command -v jq >/dev/null 2>&1; then echo "NOT AVAILABLE (jq missing — needed to parse usage)";
else
  nfiles=$(ls -1 "$TDIR"/*.jsonl 2>/dev/null | wc -l | awk '{print $1}')
  cm=$(grep -lc 'isCompactSummary\|"subtype":"compact"\|compactMetadata\|"type":"summary"' "$TDIR"/*.jsonl 2>/dev/null | wc -l | awk '{print $1}')
  echo "transcripts=$nfiles   with-compaction/summary-marker=$cm"
  echo "deep-analysing the $SESS richest session(s) (ctx = input+cache_create+cache_read; latency = inter-turn wall-clock incl. tool time):"
  for j in $(for f in "$TDIR"/*.jsonl; do t=$(grep -c '"usage"' "$f" 2>/dev/null); echo "$t $f"; done | sort -rn | head -"$SESS" | awk '{print $2}'); do
    nm=$(grep -m1 -oE '"(agentName|customTitle)":"[^"]+"' "$j" 2>/dev/null | head -1 | sed 's/.*:"//;s/"$//')
    [ -n "$nm" ] || nm=$(basename "$j")
    SER=$(mktemp)
    jq -r 'select(.type=="assistant" and (.message.usage!=null)) | [ (.timestamp|sub("\\.[0-9]+Z$";"Z")|fromdateiso8601), ((.message.usage.input_tokens//0)+(.message.usage.cache_creation_input_tokens//0)+(.message.usage.cache_read_input_tokens//0)) ] | @tsv' "$j" > "$SER" 2>/dev/null
    awk -v nm="$nm" '{n++;ctx[n]=$2;ts[n]=$1; if(n>1&&$2<prev)dec++; prev=$2}
      END{ if(n==0){print "  "nm" (no usage rows)"; exit}
        for(i=1;i<=n;i++)s[i]=ctx[i];
        for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(s[j]<s[i]){t=s[i];s[i]=s[j];s[j]=t}
        printf "  %s  turns=%d  ctx first=%d med=%d p90=%d max=%d  monotonic_decreases=%d\n", nm, n, ctx[1], s[int((n+1)/2)], s[int(n*0.9)], s[n], dec
        for(i=2;i<=n;i++){dt=ts[i]-ts[i-1]; if(dt<0||dt>600)continue; c=ctx[i]; if(c<50000){lo+=dt;loN++}else if(c<120000){md+=dt;mdN++}else{hi+=dt;hiN++}}
        printf "    inter-turn s  <50k:%s  50-120k:%s  >120k:%s\n",
          (loN?sprintf("%.1f(n=%d)",lo/loN,loN):"-"), (mdN?sprintf("%.1f(n=%d)",md/mdN,mdN):"-"), (hiN?sprintf("%.1f(n=%d)",hi/hiN,hiN):"-") }' "$SER"
    rm -f "$SER"
  done
  echo "NOTE: TTFT / pure model latency NOT in transcripts -> NOT AVAILABLE without OTEL (CLAUDE_CODE_ENABLE_TELEMETRY)."
fi

rm -f "$IDX"
echo; echo "################ end — assemble into the report (see SKILL.md) ################"
