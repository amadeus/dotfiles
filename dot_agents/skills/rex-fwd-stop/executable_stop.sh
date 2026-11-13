#!/usr/bin/env bash
# Stop Rex port forwards started by the rex-fwd skill.
#
# Usage: stop.sh [all]
#   No argument: stops the forwards whose "fwd ..." panes are in the caller's
#   Rex tab. Closes the matching tunnels on the viewer host, then the panes.
#   all: stops every forward on this machine's Rex server and on every
#   reachable Rex host it knows (viewer and server sides), in every session,
#   and closes every "fwd ..." helper pane on those servers.
# macOS ships Bash 3, which cannot run the associative arrays below.
if ((BASH_VERSINFO[0] < 4)); then
  for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    if [[ -x "$candidate" ]] && "$candidate" -c '((BASH_VERSINFO[0] >= 4))'; then
      exec "$candidate" "$0" "$@"
    fi
  done
  echo "error: Bash 4+ is required; no compatible Homebrew Bash found" >&2
  exit 1
fi
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq is required"

# shellcheck source=../rex-fwd/lib.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../rex-fwd/lib.sh"

# Labels of rex-fwd helper panes: "fwd <host> <ports>" (or the older "fwd <ports>").
FWD_LABEL='^fwd (.*? )?[0-9]+( [0-9]+)*$'

mode=${1:-tab}
case "$mode" in
  tab | all) ;;
  *) die "usage: stop.sh [all]" ;;
esac

# Closes every forward, in all sessions, on the server named $1 and selected by
# the rex options in the remaining arguments (none = this machine).
close_all_forwards() {
  local name=$1 listing
  shift
  listing=$(rex "$@" fwd ls -A --json 2>/dev/null) || return 1
  while IFS=$'\t' read -r session block listen connect; do
    [[ -n "$block" ]] || continue
    rex "$@" fwd close -s "$session" "$block" >/dev/null
    echo "closed: forward on $name listening on $listen -> $connect"
  done < <(jq -r '.forwards[] | [.session_id, .block_id, .listen, .connect] | @tsv' <<<"$listing")
}

# Closes every rex-fwd helper pane in every session on server "$@".
close_all_fwd_panes() {
  local session pane label
  for session in $(rex "$@" ls --json | jq -r '.sessions[].session_id'); do
    while IFS=$'\t' read -r pane label; do
      [[ -n "$pane" ]] || continue
      rex "$@" block close -s "$session" "$pane" >/dev/null 2>&1 || true
      echo "closed: pane \"$label\""
    done < <(rex "$@" block ls -s "$session" --json |
      jq -r --arg re "$FWD_LABEL" '.blocks[] | select((.label // "") | test($re)) | [.block_id, .label] | @tsv')
  done
}

if [[ "$mode" == all ]]; then
  servers=("")
  while IFS= read -r host; do [[ -n "$host" ]] && servers+=("$host"); done < <(rex hosts --json | jq -r '.hosts[].host.label')
  for server in "${servers[@]}"; do
    if [[ -z "$server" ]]; then args=(); name="this machine"; else args=(--timeout 5s -S "$server"); name="$server"; fi
    if ! rex "${args[@]}" whoami --json >/dev/null 2>&1; then
      echo "warning: $name isn't reachable; skipped" >&2
      continue
    fi
    close_all_forwards "$name" "${args[@]}" || echo "warning: couldn't list forwards on $name" >&2
    close_all_fwd_panes "${args[@]}"
  done
  echo "done: stopped all forwards"
  exit 0
fi

# Tab mode: the helper panes in the caller's tab say which host and ports they
# carry. Close those tunnels on that host first (closing only the pane can
# leave an orphaned forward still holding the port), then the pane.
resolve_caller_pane
window_id=$(rex block inspect -s "$REX_SESSION" "$REX_BLOCK" --json | jq -er '.block.window_id')
panes=$(rex block ls -s "$REX_SESSION" --json | jq -r --arg w "$window_id" --arg re "$FWD_LABEL" '
  .blocks[] | select(.window_id == $w and ((.label // "") | test($re))) | [.block_id, .label] | @tsv')
[[ -n "$panes" ]] || { echo "nothing to stop: no fwd panes in this tab"; exit 0; }

while IFS=$'\t' read -r pane label; do
  rest=${label#fwd }
  ports=$(grep -oE '( [0-9]+)+$' <<<" $rest" | xargs)
  host=$(sed -E 's/ ?[0-9]+( [0-9]+)*$//' <<<"$rest")
  if [[ -n "$host" ]]; then
    ports_json=$(tr ' ' '\n' <<<"$ports" | jq -R . | jq -s .)
    while IFS=$'\t' read -r session block port; do
      [[ -n "$block" ]] || continue
      rex -S "$host" fwd close -s "$session" "$block" >/dev/null
      echo "closed: forward on $host port $port"
    done < <(rex -S "$host" fwd ls -A --json 2>/dev/null | jq -r --argjson ports "$ports_json" '
      .forwards[] | select(.direction == "remote") | (.listen | sub(".*:"; "")) as $port
      | select($ports | index($port)) | [.session_id, .block_id, $port] | @tsv')
  fi
  rex block close -s "$REX_SESSION" "$pane" >/dev/null 2>&1 || true
  echo "stopped: $label"
done <<<"$panes"
