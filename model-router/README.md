# dsh-model-router-local（独立组件）

> **DeepSeek Harness 混合模型路由插件**（本地 fork，v1.0.2，MIT）。
> 把「思考/计划/讨论」与「检索/执行/干活」分派到不同模型：主会话（Lead）走强模型，一切子代理/Agent Teams 队员走普通模型——机制层强制，不靠模型自觉。

## 与上游的关系

本组件 fork 自 [dsh-model-router](https://www.npmjs.com/package/dsh-model-router) 0.7.1（MIT）。
上游与本机 DSH 0.2.0-rc.2 **不兼容**（两层，均经源码实证）：

1. 上游声明 `@deepseek-ai/dsh-plan-mode: ^0.1.0-rc.8` / `@deepseek-ai/dsh-settings: ^0.1.0-rc.8` 两个 peer，DSH 启动兼容检查将范围与**运行时版本 0.2.0-rc.2** 比较，`^0.1.0-rc.8` 不含 0.2.x → 拒绝安装；
2. 即便豁免强装，上游 import 的 `foldPlanMode`（dsh-plan-mode）与 `installSettingsSection`/`settingsNamespace`（dsh-settings）在 0.2.0-rc.2 的捆绑版本中**不存在**，运行时必崩；其 vision/escalate 检测依赖的 `agent.session.events` 在本机也不存在。

本 fork 的适配：删除上述两个 API 依赖与 settings GUI；vision 检测与错误升级改为扫描 `agent.session.log`（本机 Session 的事件数组）尾部事件；失败判据同时认 `isError: true` 与文本标记 `[exit code: N]`（N≥1，DSH 0.2.0 的 pwsh 失败 `isError` 恒 false）；`mode: plan` 与 `strict` 等价；不注册 prompt 段落与技能（配置纯走 patch）。

## 路由规则

| 谁 | 判定 | 默认路由 |
|---|---|---|
| planner（主会话：思考/计划/讨论/审阅） | root 会话（无 subagent 标记） | **跟随会话选择**（GUI 选 v4-pro / v4.1-flash 均可，插件不改写）；`plannerFollowSession: false` 时固定 `deepseek-v4-pro` / `max` |
| executor（子代理/队员：检索/执行/干活） | `origin:"subagent"` 或 `subagentDepth ≥ 1` | **绑死** `deepseek-flash` / `high` + 报错自动升级 `max`、连续 2 步正常回落 |
| vision（带图请求，粘性） | 会话日志出现图片 | `deepseek-flash`（原生多模态） |

改写发生在 DSH `agent/request` 管线最外层（`{ prepend: true }`），对 Agent Teams 队员同样生效（队员会话即 `origin:"subagent"` 的子会话）；主对话在 `plannerFollowSession: true`（默认）下**不改写**，用户随时在会话里切换模型。

## 安装（profile 级，全会话生效）

1. 把本目录放到一个固定位置，在目标 profile 的 `package.json` 里注册为本地 bundle：
   ```json
   "dependencies": { "@local/dsh-model-router-local": "link:<本目录绝对路径>" },
   "dsh": { "profile": { "bundles": [ "…", "@local/dsh-model-router-local" ] } }
   ```
   （与 `@local/dsh-auto-doc` 同形态；Electron 独占的 desktop profile 用 GUI 插件页或 `plugin_manager` `install_bundle`。）
2. 在本目录跑一次 `pnpm install` 生成依赖（或手工把 `node_modules` 链接到该 profile 的依赖树，保证 `@deepseek-ai/cordis` / `@deepseek-ai/schemastery` 可解析）。
3. profile 的 `cordis.patch.yml` 加覆盖行：
   ```yaml
   - id: model-router
     config:
       plannerFollowSession: true   # 主对话跟随会话选择（默认）；false 才用 planner 固定路由
       planner:   { provider: deepseek-official, model: deepseek-v4-pro, reasoningEffort: max }
       executor:
         provider: deepseek-official
         model: deepseek-flash
         reasoningEffort: high
         escalateOnError: true
         escalateTo: max
         recoverySteps: 2
       mode: strict
       promptSection: false
       skill: false
       vision: { enabled: true, provider: deepseek-official, model: deepseek-flash }
   ```
4. 重启 profile（插件在启动时加载）。

## 验收

```bash
# 队员侧：统计队员会话 assistant/message 的 model（应全 deepseek-flash）
zstd -d -c "$DSH_HOME"/sessions/<workspace>/<session>/session.v4.jsonl.zstd \
  | grep '"type":"assistant/message"' | grep -o '"model":"deepseek-[a-z-]*"' | sort | uniq -c
# escalate：队员执行失败步后，下一请求 request/header 的 reasoningEffort 应变 max、回落 high
```

## 已知瑕疵

- 会话重启后 DSH 模型选择层可能注入「model changed → flash」提示，而实际请求仍被 planner 路由改写为强模型——以 `request/header` 日志为准，该提示是选项层噪音。
- vision 粘性路由生效后整个会话持续走 vision 模型，直至图片被压缩/裁剪移除（无运行时回退开关）。

## 回退

从 profile 的 bundles 与 dependencies 移除 `@local/dsh-model-router-local`、删除 `cordis.patch.yml` 的 `- id: model-router` 覆盖行、重启，即回到「全员继承会话模型」。

## 测试

本组件不带测试框架；核心逻辑（角色判定/路由/日志扫描/升级回落）在母版工作区以单测覆盖（27 项，2026-10-06 全过，随源仓库维护、不随本包分发），并在 DSH 0.2.0-rc.2 上经四轮真实会话实测（核心路由 + escalate 升级/回落）。
