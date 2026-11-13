---
name: rex-fwd
description: Forward the dev server(s) running in the current Rex tab to whichever other machine is viewing this Rex session, on the same port, in a split pane below the server. Use for "/rex-fwd", "rex fwd the server", "forward the dev server to my laptop", or any request to expose a local dev server port on the viewing machine via Rex.
allowed-tools: Bash(~/.agents/skills/rex-fwd/forward.sh:*), Bash(rex:*)
---

# Restart this tab's dev-server forwards to the viewing machine

The dev server runs here, on the machine hosting this Rex session. The user
browses it from another machine whose Rex app is attached to the session. The
script works out that viewer and its Rex host automatically, then creates
reverse forwards (`-R`) that listen on the viewer's machine and connect to
`localhost` here, with the same port on both ends.

Every invocation means restart the requested ports. Close existing Rex reverse
forwards listening on those ports on the viewer host, across sessions and
regardless of state, then create fresh forwards. Leave other ports alone.

## Steps

1. Run the bundled script, appending any port numbers the user gave (none is
   the normal case):

   ```sh
   ~/.agents/skills/rex-fwd/forward.sh [PORT...]
   ```

   The script accesses the local Rex socket and runs `lsof`; run it outside
   the sandbox when needed. It selects Homebrew Bash if macOS Bash is too old.

   What it does:
   - **Ports**: with none given, scans the other panes in the caller's tab for
     localhost URLs and keeps the ports actually listening.
   - **Viewer**: finds the Rex apps attached to this session from another
     machine, and matches each to the Rex host (from `rex hosts`) whose own
     local app reports the same machine label. If only apps on this machine
     are viewing, it prints the local URLs and does nothing.
   - **Tunnel session** on the viewer host: `$REX_FWD_SESSION` if set, else a
     session labeled `Forwards`, else the host's single `... Misc` session,
     else a new `Forwards` session.
   - **Restart**: closes matching forwards on the viewer host, splits a
     `fwd <host> <ports>` pane below each server pane (`--focus=false
     --keep-open`), waits for Rex to report them `active`, and removes exited
     old `fwd` panes for those ports in this tab.

   Set `REX_FWD_VIEWER=<host label>` to skip detection and force a host.

2. Report which ports were restarted, on which host, and their localhost URLs
   there, plus that Ctrl+C in the `fwd` pane stops them. Use the script's
   `active:` lines as confirmation that Rex started the tunnels. Do not perform
   HTTP/browser checks by default or claim application connectivity was tested.

## If the script fails

- **No ports found**: capture the server pane with
  `rex capture -s "$REX_SESSION" -b <block> --trim --unwrap | tail -60`, find
  its port, and rerun the script with it.
- **Viewer isn't a reachable Rex host**: report it (`rex hosts check`); the
  viewing machine needs its own Rex server to listen on. Don't fall back to
  forwarding on this machine.
- **A forward didn't become active**: capture the new `fwd` pane and inspect
  `rex -S <host> fwd ls -A`. Report the error; do not repeatedly restart
  tunnels or choose a different port to hide the failure.
- **Port occupied by something other than a Rex reverse forward**: report
  the conflict; do not kill an unrelated process.

## Don't

- Don't use `rex fwd open` — it loops this machine back to itself on a random
  port.
- Don't use `-L` or run the forward from the viewer's side.
- Don't change ports or ask before restarting the matching forwards.
