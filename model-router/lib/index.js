// dsh-model-router-local — local fork of dsh-model-router, adapted for DSH 0.2.0-rc.2.
//
// Upstream 0.7.1 imports `foldPlanMode` from @deepseek-ai/dsh-plan-mode and
// `installSettingsSection`/`settingsNamespace` from @deepseek-ai/dsh-settings;
// neither export exists in DSH 0.2.0-rc.2's bundled versions, so upstream fails
// to load. This fork drops those surfaces and re-implements vision detection and
// error escalation by scanning the Session event log directly. In DSH 0.2.0-rc.2
// the Session exposes `session.log` (the ordered event array; upstream's
// `session.events` does not exist here). The `agent/pre-step` waterfall only
// carries inbox user messages (no tool results), so it cannot see failures —
// `agent/request` scans the log tail instead. DSH 0.2.0 also reports failed tool
// steps with `isError: false` and a `[exit code: N]` text marker (verified
// against real session logs), so both signals are checked.
//
// Kept from upstream: roleFor/routeFor policy, per-route provider/model/
// reasoningEffort/maxTokens stamping on the `agent/request` waterfall with
// { prepend: true }, sticky image detection, and escalateOnError semantics.
// Removed from upstream: plan-mode folding (mode:plan behaves like strict),
// prompt-section and skill registration, and the settings GUI panel. Config is
// patch-only.

import { Service } from "@deepseek-ai/cordis";
import z from "@deepseek-ai/schemastery";

const name = "model-router";

const ModelRouteSchema = z.object({
  provider: z.string().min(1),
  model: z.string().min(1),
  reasoningEffort: z.union(["off", "low", "high", "max"]),
  maxTokens: z.number().min(1),
  escalateOnError: z.boolean(),
  escalateTo: z.union(["off", "low", "high", "max"]),
  recoverySteps: z.number().min(1),
});

const VisionRouteSchema = z.object({
  enabled: z.boolean().default(false),
  provider: z.string().min(1).default("deepseek-official"),
  model: z.string().min(1).default("deepseek-flash"),
  reasoningEffort: z.union(["off", "low", "high", "max"]),
  maxTokens: z.number().min(1),
});

const Config = z.object({
  planner: ModelRouteSchema.default({
    provider: "deepseek-official",
    model: "deepseek-v4-pro",
    reasoningEffort: "max",
  }),
  executor: ModelRouteSchema.default({
    provider: "deepseek-official",
    model: "deepseek-flash",
    reasoningEffort: "high",
    escalateOnError: true,
    escalateTo: "max",
    recoverySteps: 2,
  }),
  mode: z.union(["strict", "plan"]).default("strict"),
  enabled: z.boolean().default(true),
  promptSection: z.boolean().default(false), // accepted for upstream config compat; unused in this fork
  skill: z.boolean().default(false),         // accepted for upstream config compat; unused in this fork
  vision: VisionRouteSchema.default({}),
});

function roleFor(agent) {
  const options = agent?.options;
  const depth = options?.subagentDepth;
  if (typeof depth === "number" && depth >= 1) return "executor";
  const session = agent?.session;
  if (session?.header?.origin === "subagent") return "executor";
  return "planner";
}

function routeFor(agent, config) {
  // This fork supports only strict semantics: the root agent always takes the
  // planner route. `mode: "plan"` is accepted for config compat and behaves
  // identically (no plan-mode folding API exists in DSH 0.2.0-rc.2).
  return roleFor(agent) === "executor" ? config.executor : config.planner;
}

function effortFor(route, state) {
  if (route.escalateOnError === true && state.failStreak > 0) {
    return route.escalateTo ?? route.reasoningEffort;
  }
  return route.reasoningEffort;
}

const EXIT_CODE_MARKER = /\[exit code: ([1-9]\d*)\]/;

function contentHasImage(content) {
  if (!Array.isArray(content)) return false;
  for (const block of content) {
    if (!block || typeof block !== "object") continue;
    if (block.type === "image") return true;
    if (block.type === "tool-result" && contentHasImage(block.content)) return true;
  }
  return false;
}

function toolResultFailed(message) {
  if (!message || typeof message !== "object") return false;
  if (message.isError === true) return true;
  const content = message.content;
  if (!Array.isArray(content)) return false;
  for (const block of content) {
    if (!block || typeof block !== "object") continue;
    if (block.type === "text" && typeof block.text === "string" && EXIT_CODE_MARKER.test(block.text)) return true;
    if (block.type === "tool-result" && toolResultFailed({ content: block.content, isError: false })) return true;
  }
  return false;
}

function compareStepKey(left, right) {
  const [lt, ls] = left.split(":").map(Number);
  const [rt, rs] = right.split(":").map(Number);
  return lt !== rt ? lt - rt : ls - rs;
}

/**
 * Scan the tail of a session event log for image blocks and for the most recent
 * step's failed tool results. Events mirror the persisted session JSON: a
 * tool/result carries `data.turn`, `data.step` and `data.message` (role:"tool",
 * content blocks, optional isError).
 */
function scanRecentLog(log, lookback = 40) {
  let sawImage = false;
  const resultsByStep = new Map();
  if (Array.isArray(log)) {
    for (const event of log.slice(-lookback)) {
      if (!event || typeof event !== "object") continue;
      const data = event.data;
      if (!data || typeof data !== "object") continue;
      if (event.type === "user/message" && contentHasImage(data.content)) sawImage = true;
      if (event.type === "assistant/message" && data.message && contentHasImage(data.message.content)) sawImage = true;
      if (event.type === "tool/result" && data.message) {
        if (contentHasImage(data.message.content)) sawImage = true;
        const key = `${data.turn}:${data.step}`;
        const list = resultsByStep.get(key) ?? [];
        list.push(data.message);
        resultsByStep.set(key, list);
      }
    }
  }
  let lastStepFailed = false;
  const hadToolResult = resultsByStep.size > 0;
  if (hadToolResult) {
    let lastKey = null;
    for (const key of resultsByStep.keys()) {
      if (lastKey === null || compareStepKey(key, lastKey) > 0) lastKey = key;
    }
    lastStepFailed = (resultsByStep.get(lastKey) ?? []).some(toolResultFailed);
  }
  return { sawImage, lastStepFailed, hadToolResult };
}

const DEFAULT_STATE = () => ({ sawImage: false, failStreak: 0, cleanStreak: 0 });

const ModelRouter = class extends Service {
  static inject = [];

  constructor(ctx, rawConfig = {}) {
    super(ctx, "modelRouter");
    this.config = Config(rawConfig ?? {});
    this.states = new WeakMap();
    this.harness = ctx;

    const disposers = new Map();
    this.harness.on("agent/disposed", (disposedAgent) => {
      const dispose = disposers.get(disposedAgent);
      if (dispose !== undefined) {
        dispose();
        disposers.delete(disposedAgent);
      }
    });

    this.harness.on("agent/created", ({ agent }) => {
      const state = () => {
        const existing = this.states.get(agent);
        if (existing !== undefined) return existing;
        const created = DEFAULT_STATE();
        this.states.set(agent, created);
        return created;
      };

      const disposeRequest = agent.ctx.on(
        "agent/request",
        async (_payload, next) => {
          const resolved = await next();
          const cfg = this.config;
          if (!cfg.enabled) return resolved;
          const st = state();

          // Observe the session log tail once per request: sticky image
          // detection and per-step failure accounting for escalateOnError.
          if (!st.sawImage) {
            const scan = scanRecentLog(agent.session?.log);
            if (scan.sawImage) st.sawImage = true; // sticky until compaction drops the image
            if (scan.hadToolResult) {
              if (scan.lastStepFailed) {
                st.failStreak += 1;
                st.cleanStreak = 0;
              } else {
                st.cleanStreak += 1;
                const recovery = cfg.executor.recoverySteps ?? 2;
                if (st.cleanStreak >= recovery) st.failStreak = 0;
              }
            }
          }

          if (cfg.vision.enabled && st.sawImage) {
            const stamped = {
              ...resolved,
              provider: cfg.vision.provider,
              model: cfg.vision.model,
            };
            if (cfg.vision.maxTokens !== undefined) stamped.maxTokens = cfg.vision.maxTokens;
            const effort = effortFor(cfg.vision, st);
            if (effort !== undefined) stamped.reasoningEffort = effort;
            return stamped;
          }

          const route = routeFor(agent, cfg);
          if (route === undefined) return resolved;
          const stamped = { ...resolved, provider: route.provider, model: route.model };
          if (route.maxTokens !== undefined) stamped.maxTokens = route.maxTokens;
          const effort = effortFor(route, st);
          if (effort !== undefined) stamped.reasoningEffort = effort;
          return stamped;
        },
        { prepend: true },
      );

      disposers.set(agent, () => {
        disposeRequest();
      });
    });
  }
};

export { Config, ModelRouter, name, roleFor, routeFor, scanRecentLog, toolResultFailed, contentHasImage, effortFor };
export default ModelRouter;
