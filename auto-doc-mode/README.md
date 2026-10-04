# Auto_Doc 模式（bundle 源）

> 这是一个 **DSH Agent preset（模式）bundle**：把科研模板 v4.3 从「每个项目各自抄一份规则」
> 变成「在 GUI 选模式即生效」。装进 profile 后，新建会话的模式选择器里会出现 **Auto_Doc**。

## 一、装 / 卸 / 更新

| 动作 | 做法 |
|---|---|
| 安装 | 用 `plugin_manager` → `action: install_bundle`，`target` = 本目录绝对路径（不要手工改 profile 的 `package.json` / `cordis.patch.yml`，也不要自己跑 pnpm） |
| 改后预检 | `node tools/precheck.mjs`（只读）：① 两个 `!!js` 块按加载器上下文求值 → 安装目录与 22 个技能；② skills 根不得有平铺 `.md`；③ patch 引用的 27 个插件名全部可解析 |
| 验证 | `plugin_manager` `list_plugins` 里出现 `preset-auto-doc`（`@deepseek-ai/dsh-agent-preset`）；`cordis_inspect_query` Host `Config.listConfigs` 里 `include:preset-auto-doc` 状态为 `schema`；新建会话的模式选择器出现 Auto_Doc |
| 更新规则/技能快照 | 改本目录文件后重装（或按 `PROVENANCE.md` 重取快照）；**已开的会话保持它启动时的组合**，改动只对新会话生效 |
| 卸载 | `plugin_manager` 的删除 bundle 操作（桌面 profile 的 bundle 选择页 / 工具） |

已装 profile：**desktop**（本机 GUI 就是 desktop profile 起的）。`web` profile 未装（如需，另行 `dsh plugin --profile web add <本目录>`）。

## 二、这个模式里有什么

```
auto-doc-mode/
├── package.json            # bundle 清单：dsh.bundle.patch → cordis.patch.yml
├── cordis.patch.yml        # preset 声明：id=auto-doc、name=Auto_Doc、order=5 + 插件组成
├── rules/                  # 规则快照（会话读它，或读工作区自己的 CLAUDE.md）
│   ├── AUTO_DOC_persona.md # 本模式规程（persona 正文源，@@RULES@@/@@SKILLS@@ 占位符）
│   ├── CLAUDE_v4.3.md      # v4.3 总纲全文快照（与 template/TEMPLATE_CLAUDE.md 逐字节一致）
│   └── team/{roles,rules}/*.md + README.md   # 5 张角色卡 + 6 份自包含角色规则
├── skills/                 # 22 个 A 档技能快照（含 team-launcher），挂到技能根 rank 300
├── tools/precheck.mjs      # 只读预检（!!js 求值 / 技能形态 / 插件名解析），改完重装前跑
└── PROVENANCE.md           # 快照来源、母版提交号、校验方式
```

**persona 只放规程，不放总纲正文**：总纲正文若既嵌 persona 又被工作区 `CLAUDE.md` 注入，
等于每步重复付费。规程「一、规则事实源」条决定：工作区有 v4.3 的 `CLAUDE.md` 就以它为准，
没有才读本 bundle 的 `rules/CLAUDE_v4.3.md` 快照。

**插件组成**（沿随包 `standard`/`cordis` 两个 preset 的既有写法）：

- 身份：`dsh-persona`（规程）+ `dsh-agent-instructions`（注入工作区 `CLAUDE.md`/`AGENTS.md`）
- 工具：pwsh/bash、fs、fs-search、jobs、skill、goal、todo、ask-user、web、present、jobs；
  计划模式、压缩、委派（subagent / subagent_fork / workflow）三组；
  **不含**创造模式的 `tool-cordis` 与 `tool-plugin-manager`（显式 `disabled: true`）
- 技能：`dsh-skill-filesystem` + `customSkillDirs` 指向本 bundle 的 `skills/`
  （项目根 rank 100 / 用户根 rank 400 照常保留，本根为 rank 300）
- 团队工具（`spawn_teammate` / 任务卡 / `wait_agent` …）来自 profile 的
  `@deepseek-ai/dsh-experimental-agent-team-profile`，preset 不重复声明

## 三、选 Auto_Doc 之后会发生什么

persona 规程要求（也是本模式的价值所在）：

1. **定位规则**：工作区是 v4.3 模板实例 → 以工作区 `CLAUDE.md` 为准；否则读本 bundle 快照。
2. **开局硬要求**：跑 `scripts\env_check.ps1` → 读 `Claude_memory.md` 摘要与 `team/board.md`
   → 调 `team-launcher` 装配 5 角色（lead / lit-agent / analysis-agent / figure-writer / auditor）
   → 建卡并**显式唤醒**负责人。**未装配不得开始检索/分析/出图/写作。**
3. **行为红线**：绝对路径、真实性、落盘交接、审查 `fresh`、活跃成员上限 3、
   一域一写者、五处用户决定点、收尾更新记忆。
4. **降级**：用户说「轻量/不组队」或环境不满足（无 shell、配额耗尽）→ 按总纲「降级模式」，
   并在 `Claude_memory.md` 记录原因与未覆盖项。

## 四、边界与已知限制

- 本 bundle **不携带** `skeleton/`（目录骨架、`scripts/*.ps1`、`team/` 模板）——项目落地仍按模板
  `README.md` 的实例化步骤；工作区未实例化时，规程会提示/代为实例化，但 `env_check.ps1`
  之类脚本要项目内有才有得跑。
- **不携带** B 档 `nature-*`（29.8 MB）与 C 档 `bio-*`（561 个，在 `$DSH_HOME/skill-library/bio/`）；
  按总纲「技能来源与优先级」在会话中按需取用，缺装按降级模式记录。
- 规则/技能是**快照**：模板母版改动不会自动流到本 bundle，需按 `PROVENANCE.md` 刷新并重装。
- 安装依赖本目录可访问；若安装器把本目录以链接方式装入 profile，删除/移动本目录会让模式失效。
- **与科研分区规则的关系（2026-10-04 定，层次重组 A 案）**：科研分区规则文件（`<科研分区工作根>\AGENTS.md`）
  已由「模板正文 v4.2 全文副本（225 行）」改为**薄壳**（48 行）：只留分区定位、规则事实源三级指向
  （项目 `CLAUDE.md` → 本模式快照 → 模板母版）、团队制、分区专属事项与变更追溯；正文不再重复。
  **本模式是叠加层，不取代模板系统**——项目骨架（`team/`、`scripts/`、目录、记忆与审查契约）仍按
  `template/README.md` 实例化：`team-launcher` 硬依赖项目内 `team/`（缺则停下要求先实例化），
  persona 开局硬要求第①步的 `scripts\env_check.ps1` 也要项目内有才跑得动。模式省下的是
  「每个项目重复携带 A 档技能 + 每个会话重读总纲」。
- **快照一致性复核（2026-10-04）**：`rules/CLAUDE_v4.3.md` 与 `template/TEMPLATE_CLAUDE.md` SHA256
  一致（`D36D91EA…`）；6 份角色规则、5 张角色卡、22 个 A 档技能与 `template/skeleton/` 逐文件比对
  **0 不一致**；`team-launcher` 三处副本（本 bundle / `template/skeleton/.dsh/skills/` / `$DSH_HOME\skills\`）
  SHA256 一致（`66098C73…`）；唯一差异是母版 `.dsh/skills/VENDORED.md` 按 `PROVENANCE.md` 说明有意未复制。
