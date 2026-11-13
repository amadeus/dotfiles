# Shared helpers for the rex-fwd and rex-fwd-stop scripts. Source it after
# `set -euo pipefail` and a die() function are defined.

# Prints pid $1 and each of its ancestors, one per line.
ancestors_of() {
  local p=$1
  while [[ -n "$p" && "$p" != 0 && "$p" != 1 ]]; do
    echo "$p"
    p=$(ps -o ppid= -p "$p" | tr -d ' ')
  done
}

# True when process $1 really runs inside Rex pane $3 of session $2, i.e. the
# pane's child process is one of its ancestors.
runs_in_pane() {
  local child
  child=$(rex block call -s "$2" -b "$3" process 2>/dev/null | jq -r '.child.pid // empty') || true
  [[ -n "$child" ]] || return 1
  # Read the whole list first: grep -q under pipefail would SIGPIPE ancestors_of.
  local chain
  chain=$(ancestors_of "$1")
  grep -qx "$child" <<<"$chain"
}

# Codex runs commands through a long-lived app-server daemon whose environment
# was captured when the daemon first started, so the inherited
# REX_SESSION/REX_BLOCK can name some unrelated pane from days ago. If the
# inherited pane isn't actually an ancestor of this script, take the Rex IDs
# from the Codex CLI process that is running in this directory inside a real
# Rex pane instead.
resolve_caller_pane() {
  runs_in_pane $$ "$REX_SESSION" "$REX_BLOCK" && return 0
  local pid cwd env s b found=()
  for pid in $(pgrep -x codex || true); do
    cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
    [[ "$cwd" == "$PWD" ]] || continue
    # Only keep the two Rex variables; the rest of the environment holds secrets.
    env=$(ps eww -o command= -p "$pid" | tr ' ' '\n' | grep -E '^REX_(SESSION|BLOCK)=' || true)
    s=$(sed -n 's/^REX_SESSION=//p' <<<"$env" | sed -n 1p)
    b=$(sed -n 's/^REX_BLOCK=//p' <<<"$env" | sed -n 1p)
    [[ -n "$s" && -n "$b" ]] && runs_in_pane "$pid" "$s" "$b" && found+=("$s $b")
  done
  local unique
  unique=$(printf "%s\n" "${found[@]}" | grep . | sort -u || true)
  case $(grep -c . <<<"$unique" || true) in
    1) read -r REX_SESSION REX_BLOCK <<<"$unique"
       echo "note: inherited Rex pane was stale; using $REX_BLOCK (from the Codex CLI in $PWD)" ;;
    0) die "can't tell which Rex pane this was run from (inherited $REX_BLOCK is not this process's pane)" ;;
    *) die "several Codex sessions in $PWD; can't tell which Rex pane this was run from" ;;
  esac
}

