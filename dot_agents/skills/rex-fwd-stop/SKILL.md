---
name: rex-fwd-stop
description: Stop the Rex port forwards started by rex-fwd. With no argument, stops the forwards in the current Rex tab; with "all", stops every forward on this machine and on every Rex host it knows, viewer and server alike. Use for "/rex-fwd-stop", "/rex-fwd-stop all", "stop the forward", "kill all rex forwards".
allowed-tools: Bash(~/.agents/skills/rex-fwd-stop/stop.sh:*), Bash(rex:*)
---

# Stop rex-fwd forwards

Companion to the `rex-fwd` skill, which runs each forward in a
`fwd <host> <ports>` pane below the dev server and listens on the viewer's
machine.

## Steps

1. Run the bundled script. Pass `all` only if the user asked for all (e.g.
   `/rex-fwd-stop all`):

   ```sh
   ~/.agents/skills/rex-fwd-stop/stop.sh        # this tab
   ~/.agents/skills/rex-fwd-stop/stop.sh all    # everything, everywhere
   ```

   The script accesses the Rex sockets; run it outside the sandbox when needed.

   - **This tab** (default): for each `fwd ...` pane in the caller's tab, it
     closes the tunnels for those ports on the host named in the pane label,
     then closes the pane. Forwards started from other tabs are left alone.
   - **all**: on this machine's Rex server and every reachable host from
     `rex hosts`, it closes every forward in every session (active, away or
     orphaned, either direction) and every `fwd ...` helper pane. Unreachable
     hosts are skipped with a warning.

2. Report what was stopped in a line or two (ports and hosts), or that there
   was nothing to stop. Mention any host the script skipped.

## Don't

- Don't kill `rex` processes or restart Rex servers.
- Don't stop dev servers or close panes other than the `fwd ...` helpers.
