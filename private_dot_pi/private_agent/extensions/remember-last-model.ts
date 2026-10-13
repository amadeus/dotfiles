/**
 * Remember the last interactive model and thinking level as startup defaults.
 * Auto-loaded from ~/.pi/agent/extensions; enable with /reload or restart Pi.
 * Headless/RPC runs (including subagents) must not overwrite personal defaults.
 */
import {
  getAgentDir,
  SettingsManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let pending = Promise.resolve();

  function remember(ctx: ExtensionContext) {
    if (ctx.mode !== "tui" || !ctx.model) return;

    // Snapshot before awaiting: rapid model/thinking changes can overlap.
    const { provider, id } = ctx.model;
    const level = ctx.thinkingLevel ?? pi.getThinkingLevel();
    const cwd = ctx.cwd;
    const agentDir = getAgentDir();

    pending = pending.then(async () => {
      // Use Pi's locked, merge-on-write settings API rather than replacing JSON.
      // A fresh manager also picks up settings changed by another Pi instance.
      const settings = SettingsManager.create(cwd, agentDir, { projectTrusted: false });
      const loadErrors = settings.drainErrors();
      if (loadErrors.length) throw loadErrors[0].error;

      if (settings.getDefaultProvider() !== provider || settings.getDefaultModel() !== id) {
        settings.setDefaultModelAndProvider(provider, id);
      }
      if (settings.getDefaultThinkingLevel() !== level) {
        settings.setDefaultThinkingLevel(level);
      }
      // An existing per-model override would otherwise win at the next startup.
      const override = settings.getModelThinkingLevel(provider, id);
      if (override !== undefined && override !== level) {
        settings.setModelThinkingLevel(provider, id, level);
      }

      await settings.flush();
      const writeErrors = settings.drainErrors();
      if (writeErrors.length) throw writeErrors[0].error;
    }).catch((error: unknown) => {
      ctx.ui.notify(`Could not remember Pi defaults: ${String(error)}`, "warning");
    });
    return pending;
  }

  pi.on("session_start", (_event, ctx) => remember(ctx));
  pi.on("model_select", (_event, ctx) => remember(ctx));
  pi.on("thinking_level_select", (_event, ctx) => remember(ctx));
  // Also capture the actual selection when using a restored session/branch.
  pi.on("before_agent_start", (_event, ctx) => remember(ctx));
  pi.on("session_shutdown", async () => { await pending; });
}
