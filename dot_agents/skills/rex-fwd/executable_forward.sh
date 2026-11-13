#!/usr/bin/env bash
# Reverse-forward dev server ports from this machine to whichever other
# machine(s) are viewing this Rex session, keeping the same port on both ends,
# so http://localhost:PORT works in the viewer's browser.
#
# Usage: forward.sh [PORT...]
#   With no ports, scans the other panes in the caller's Rex tab for
#   localhost URLs and forwards every one that is actually listening.
#   With ports, forwards exactly those.
#
# The viewer is any Rex app attached to this session from another machine. It
# is matched to a Rex host this server knows by the app's machine label, and
# each server pane gets a "fwd <host> <ports>" pane split below it running
# `rex -S <host> fwd new -R port:localhost:port ...`.
#
# Environment overrides:
#   REX_FWD_VIEWER   host label to forward to, skipping viewer detection
#   REX_FWD_SESSION  session label on the viewer host to hold the tunnels
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

[[ -n "${REX_SESSION:-}" && -n "${REX_BLOCK:-}" ]] ||
  die "REX_SESSION/REX_BLOCK not set; run this from a Rex terminal"
command -v jq >/dev/null || die "jq is required"

for p in "$@"; do
  [[ "$p" =~ ^[0-9]+$ ]] || die "not a port: $p"
done

# True when something on this machine is listening on TCP port $1.
is_listening() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

# Localhost ports mentioned in the recent output of pane $1.
ports_in_block() {
  rex capture -s "$REX_SESSION" -b "$1" --trim --unwrap 2>/dev/null |
    tail -n 400 |
    grep -oE '(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1?\]):[0-9]{2,5}' |
    sed -E 's/.*:([0-9]+)$/\1/' | sort -un || true
}

# shellcheck source=lib.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"

resolve_caller_pane

window_id=$(rex block inspect -s "$REX_SESSION" "$REX_BLOCK" --json | jq -er '.block.window_id')

# Candidate server panes: every pane in this tab except the caller's own pane
# and any existing fwd panes.
blocks=$(rex block ls -s "$REX_SESSION" --json | jq -r --arg w "$window_id" --arg me "$REX_BLOCK" '
  .blocks[] | select(.window_id == $w and .block_id != $me and ((.label // "") | startswith("fwd") | not)) | .block_id')

# Map port -> pane that printed it (first pane wins).
declare -A port_block=()
for b in $blocks; do
  for p in $(ports_in_block "$b"); do
    [[ -n "${port_block[$p]:-}" ]] || port_block[$p]=$b
  done
done

if (($# > 0)); then
  ports=("$@")
else
  ports=()
  for p in "${!port_block[@]}"; do
    is_listening "$p" && ports+=("$p")
  done
  ((${#ports[@]} > 0)) || die "no listening localhost ports found in this tab's other panes (pass a port explicitly)"
fi

# Machine labels of Rex apps attached to this session from another machine.
# Apps on this machine connect over the unix socket and need no forward.
remote_viewer_labels() {
  rex client ls -s "$REX_SESSION" --json | jq -r '
    .clients[] | select(.connection_state == "connected" and .info.kind == "app"
      and .principal.transport != "unix") | .info.label // empty' | sort -u
}

# Prints the label of the Rex host whose own local app (unix socket) reports
# machine label $1, i.e. the host running on the viewer's machine.
host_for_machine() {
  local host labels
  while IFS= read -r host; do
    [[ -n "$host" ]] || continue
    labels=$(rex --timeout 3s -S "$host" client ls --json 2>/dev/null | jq -r '
      .clients[] | select(.principal.transport == "unix") | .info.label // empty') || continue
    if grep -qxF "$1" <<<"$labels"; then echo "$host"; return 0; fi
  done < <(rex hosts --json | jq -r '.hosts[].host.label')
  return 1
}

# Session on viewer host $1 that holds the tunnel blocks: $REX_FWD_SESSION if
# set, else "Forwards", else the host's single "... Misc" session, else a new
# "Forwards" session.
viewer_session() {
  local host=$1 sessions id want=${REX_FWD_SESSION:-Forwards}
  sessions=$(rex -S "$host" ls --json)
  id=$(jq -r --arg l "$want" '[.sessions[] | select(.label == $l)][0].session_id // empty' <<<"$sessions")
  if [[ -z "$id" && -z "${REX_FWD_SESSION:-}" ]]; then
    id=$(jq -r '[.sessions[] | select(.label | test(" Misc$"))] | if length == 1 then .[0].session_id else empty end' <<<"$sessions")
  fi
  if [[ -z "$id" ]]; then
    id=$(rex -S "$host" new "$want" --json | jq -er '.session_id') || return 1
  fi
  echo "$id"
}

viewer_hosts=()
if [[ -n "${REX_FWD_VIEWER:-}" ]]; then
  viewer_hosts=("$REX_FWD_VIEWER")
else
  viewers=$(remote_viewer_labels)
  [[ -n "$viewers" ]] || {
    echo "nothing to forward: every Rex app viewing this session runs on this machine"
    for p in "${ports[@]}"; do echo "local: http://localhost:$p"; done
    exit 0
  }
  while IFS= read -r machine; do
    if host=$(host_for_machine "$machine"); then
      viewer_hosts+=("$host")
    else
      echo "warning: \"$machine\" is viewing this session but isn't a reachable Rex host here; can't forward to it" >&2
    fi
  done <<<"$viewers"
  ((${#viewer_hosts[@]} > 0)) || die "no viewing machine is a reachable Rex host (see rex hosts check); set REX_FWD_VIEWER to force one"
fi

declare -A requested=()
for p in "${ports[@]}"; do requested[$p]=1; done
ports=("${!requested[@]}")
requested_json=$(printf '%s\n' "${ports[@]}" | jq -R . | jq -s .)

# Group ports by the server pane they belong to, so each server gets one fwd
# pane per viewer host below it.
declare -A block_ports=()
for p in "${ports[@]}"; do
  is_listening "$p" || echo "warning: nothing is listening on $p here yet; forwarding anyway"
  b=${port_block[$p]:-$REX_BLOCK}
  block_ports[$b]="${block_ports[$b]:-} $p"
done

status=0
for host in "${viewer_hosts[@]}"; do
  target_session=$(viewer_session "$host") || die "couldn't find or create a session on \"$host\""

  # A call means restart these ports: close every reverse forward on the
  # viewer host listening on them, regardless of session or state.
  while IFS=$'\t' read -r old_session old_block port; do
    [[ -n "$old_block" ]] || continue
    rex -S "$host" fwd close -s "$old_session" "$old_block"
    echo "closed: previous forward on $host port $port"
  done < <(rex -S "$host" fwd ls -A --json | jq -r --argjson ports "$requested_json" '
    .forwards[] | select(.direction == "remote") | (.listen | sub(".*:"; "")) as $port
    | select($ports | index($port)) | [.session_id, .block_id, $port] | @tsv')

  # Old helper panes in this tab for this host (or from the older unlabeled
  # format) whose ports are all being restarted; removed once they've exited.
  old_panes=$(rex block ls -s "$REX_SESSION" --json | jq -r \
    --arg w "$window_id" --arg host "$host" --argjson ports "$requested_json" '
    .blocks[] | select(.window_id == $w and ((.label // "") | startswith("fwd ")))
    | (.label | capture("^fwd (?<h>.*?) ?(?<p>[0-9]+( [0-9]+)*)$")) as $m
    | select(($m.h == "" or $m.h == $host) and (($m.p | split(" ")) - $ports | length) == 0)
    | .block_id')

  for b in "${!block_ports[@]}"; do
    args=()
    for p in ${block_ports[$b]}; do args+=(-R "$p:localhost:$p"); done
    label="fwd $host${block_ports[$b]}"
    pane=$(rex split -s "$REX_SESSION" -b "$b" --split=below --ratio 20 --label "$label" \
      --focus=false --keep-open --json -- rex -S "$host" fwd new -v -s "$target_session" "${args[@]}" |
      jq -r '.block_ids[0]')
    echo "started: $label (pane $pane, below $b)"
  done

  # Wait up to ~10s for each new forward to show up as active on the viewer.
  for _ in $(seq 20); do
    active=$(rex -S "$host" fwd ls -A --json | jq -r --arg session "$target_session" '
      .forwards[] | select(.session_id == $session and .direction == "remote"
        and .state == "active" and (.client // "") != "")
      | (.listen | sub(".*:"; "")) as $port
      | select(.connect == ("localhost:" + $port)) | $port')
    missing=0
    for p in "${ports[@]}"; do grep -qx "$p" <<<"$active" || missing=1; done
    ((missing == 0)) && break
    sleep 0.5
  done

  for p in "${ports[@]}"; do
    if grep -qx "$p" <<<"$active"; then
      echo "active: http://localhost:$p on $host -> localhost:$p here"
    else
      echo "FAILED: $p did not become active on $host; check the fwd pane output"
      status=1
    fi
  done

  for old_pane in $old_panes; do
    process=$(rex block call -s "$REX_SESSION" -b "$old_pane" process 2>/dev/null) || continue
    if jq -e '.child == null and .last_exit != null' <<<"$process" >/dev/null; then
      rex block close -s "$REX_SESSION" "$old_pane"
    fi
  done
done
exit "$status"
