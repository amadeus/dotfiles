import { execFile } from "node:child_process";

export default {
  id: "gents-ready.cli",
  setup(context) {
    const server = process.env.NVIM;
    const id = process.env.GENTS_SESSION;
    if (!server || !/^\d+$/.test(id ?? "")) return;

    return context.data.on("session.execution.succeeded", (event) => {
      const sessionID = event.data.sessionID;
      const current = context.ui.router.current();
      const visible = current.type === "session" && current.sessionID === sessionID;
      const openTab = context.ui.tabs.enabled() && context.ui.tabs.list().some((tab) => tab.sessionID === sessionID);
      if (!visible && !openTab) return;

      execFile(
        "nvim",
        ["--server", server, "--remote-expr", `v:lua.require'gents'.ready(${id})`],
        { timeout: 2000 },
        () => {}, // The Neovim session may have closed while OpenCode was working.
      );
    });
  },
};
