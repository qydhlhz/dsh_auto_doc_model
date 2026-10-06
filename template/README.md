# 科研项目模板 — 初始化清单

> **模板版本：v4.4（2026-10-06）**（与 TEMPLATE_CLAUDE.md 头部版本一致，随模板变更同步递增）。
> v4.4 变更（混合模型路由，环境增强）：① 新增可选增强「混合模型路由」——Lead（思考/计划/讨论）走强模型 `deepseek-v4-pro`、一切队员与子代理（检索/执行/干活）走普通模型 `deepseek-flash`，队员执行报错自动升级推理强度、连续正常后回落，带图请求兜底到原生多模态模型；② `env_check.ps1` 新增**提示级**检测（不阻断、不进判定）；③ 规则正文零改动（模型分派是 DSH 环境层机制，与规则正交）。
> v4.3 变更（去机器指纹，具备对外分发条件）：① 清除包内 4 处本机指纹——`skeleton/.dsh/skills/VENDORED.md` 与 `skills/bio-library/SKILL.md` 的本机用户目录路径改为 `$DSH_HOME` / `%USERPROFILE%` 变量表述；② `skeleton/scripts/env_check.ps1` 的 R 探测候选去掉机器专属盘符路径，改为通用安装位置 + 环境变量 `R_HOME` 可指定；③ Auto_Doc 模式随包预检脚本 `tools/precheck.mjs` 的插件解析候选改为按 `APPDATA` 推导，不再写死用户名路径。**包内无任何密钥、无个人身份信息**（2026-10-04 全包扫描：密钥形态 0 命中、真名/手机号/邮箱/内网 IP 0 命中）。
> v4.2 变更（技能分派与随包携带）：① 新增**技能三档携带**——A 档 22 个技能进 `skeleton/.dsh/skills/`（随项目自动携带）、B 档 8 个技能进 `template/skills/`（随包携带、`-Install` 按需安装）、C 档（bio 真库 561 个/15.6 MB）保持环境依赖；② 新增 `scripts/install_skills.ps1`（安装/刷新/漂移检查，**非门禁**）；③ 12 个新技能按职能分派给 5 角色（角色卡 ④ 节重写）；④ §12 技能条重写：**删除写死的"技能根 33 个"**，新增来源优先级、"携带≠授权"、同义技能合并、环境依赖标注四条规则；⑤ **修正 4 处带命名空间前缀的技能名**（`superpowers:brainstorming`、`nature-skills:nature-figure`、`nature-skills:nature-writing` —— 正文曾教人用错的调用方式）；⑥ `lead` 禁用清单由"无"改为生产类硬约束。
> v4.1 变更（据 2026-10-01 v4.0 全链实弹测试的 D1–D13）：① 明确「一图一张」的文件级/面板级边界（多面板图允许，≤3 面板且须在出图规划声明）；② 用户决定点由三处扩为**五处**（补「出图规划确认」「手稿结构确认」，可与计划书批准合并汇报）；③ 新增**工作目录约定**（一律项目根绝对路径；`scripts/` 两脚本自带项目根自检）；④ `env_check.ps1` 关键包分**必需/可选**，可选缺失不再误判「需降级」；⑤ 写作用域补「仓库根配置→lead 独占，且须单独提交」；⑥ 「原始响应/中间凭证的生命周期须声明」；⑦ 铁律 12 由「数值」扩为「数值/计数/条目数」；⑧ skeleton 预建 `assets/`、`data/`、`output/*`；⑨ `.gitignore` 补 `__pycache__/`、`*.pyc`、`Rplots.pdf`；⑩ 交接单落盘位置明确（成员写进自己产物末尾，由 lead 归档）；⑪ 「首次产出即落 `v1/`」。
> 规则分层（v4.0 新增）：执行规则由 `TEMPLATE_CLAUDE.md` 按 `<!--rules:…-->` 标记生成 `team/rules/<角色>.md`（自包含），成员只读自己那份；改动规则后必须重新生成并跑 `-Check`。
> 双文件体系：`CLAUDE.md`（标准化：只写工作规则）+ `Claude_memory.md`（个性化：只记工作进展与内容）。文献由 `literature/` 分级索引管理。
> **团队制（默认总是组队）**：本项目按团队模式运行——开局先装配团队（`lead` + `lit-agent` + `analysis-agent` + `figure-writer` + `auditor`，角色卡见 `team/roles/`），再进入实质工作；详见 `CLAUDE.md` 头部与「团队分工与协作」节。

## 使用方法（8 步）

1. **复制模板**：将 `template/skeleton/` 下所有内容复制到新项目根目录（项目骨架：`literature/`、`team/`、`scripts/`、`.dsh/skills/` 等）；`template/` 整体保留为项目子目录 `<项目根>/template/`——**B 档技能就在 `<项目根>/template/skills/`，步骤 7 的 `-Install` 默认从这里取源**，模板包同时供查目录树与升级对照。若确定不用模板包，删除后装 B 档须用 `-Source` 指定来源。
2. **启用规则**：将 `template/TEMPLATE_CLAUDE.md` **复制**为项目根目录的 `CLAUDE.md`（复制而非移动：模板包内的原件保留，供升级对照）。
3. **装配团队**：**在项目根**跑 `scripts/env_check.ps1` 生成 `team/env-check.md`（脚本含**项目根自检**，cwd 不对会报错退出；`assets/`、`data/`、`output/*` 已由 skeleton 预建，无需手工创建）；按 `team/roles/` 装配 5 角色（固定名、`fresh`，**每个 spawn prompt 须写明项目根绝对路径**——成员 cwd 继承会话、不保证是项目根）；按 `team/board.md` 重建任务卡并显式唤醒负责人。环境不支持执行脚本时按 CLAUDE.md「团队分工与协作」节进入降级模式。
4. **按需调整**：
   - 「语言」节语言要求（默认中文）；
   - 「PubMed 访问方式」节检索工具（默认 paper-search MCP，全局已配置，无需改动；不可用时按该节降级链取用——本地 CLI `paper-search.exe` → NCBI E-utilities 官方 HTTP 接口，降级须在检索策略文件中如实登记）；
   - 「产出与维护规范」节术语表为空表，随项目填充；
   - 若课题涉及临床/受试者数据，确认「产出与维护规范」节伦理合规条款适用；
   - 「团队分工与协作」节角色编制与技能白名单：按课题需要裁剪角色（如纯文献综述可只保留 lead + lit-agent + auditor）与各角色可加载的 skill；
   - 启用 git：新项目 `git init` 后，越界核对用 `git diff`（git 操作由 lead 独占）。
5. **开始第一次检索**：按 CLAUDE.md 流程执行——先读 `INDEX_QUICK.md`（此时为空）→ 多角度检索（≥2 个检索式）→ 归档 CSV + 策略记录 → 同步更新两级索引 → 记录到 `Claude_memory.md`。
6. **持续维护**：规则变更改 CLAUDE.md；每次检索批次、课题进展更新 Claude_memory.md；新术语同步 glossary.md。
7. **按需安装 B 档技能**：`powershell -File scripts\install_skills.ps1 -List` 看清单与状态；`-Install` 装全部 B 档（默认从 `<项目根>\template\skills` 取源，模板包不在项目内时用 `-Source` 指定）；`-Check` 查缺失与漂移（**不阻断**）。A 档技能随 `skeleton/` 已自动就位，无需安装。
8. **改规则后必须重新生成并校验**：任何一次 `CLAUDE.md`（规则）改动之后，先在项目根跑 `scripts\build_rules.ps1` 重新生成 `team/rules/`，再跑 `scripts\build_rules.ps1 -Check`——**必须 `CHECK OK`，未通过不得交卡**（改了规则忘重生成、或有人手改生成物，`-Check` 都会报 `DRIFT` 或 `MISSING`）。

## 目录结构

```
新项目根目录/
├── CLAUDE.md                      ← 复制自 TEMPLATE_CLAUDE.md（规则，标准化）
├── Claude_memory.md               ← 工作目录/进度/内容（个性化）
├── literature/
│   ├── INDEX_QUICK.md             ← 层级 1 快速索引（分类小标题 + 篇数）
│   ├── INDEX.md                   ← 层级 2 全量索引（文献明细）
│   ├── csv/                       ← 批次文献 CSV（UTF-8 + BOM 版）
│   ├── search_strategy/           ← 检索策略记录（含阴性结果）
│   └── glossary.md                ← 中英术语对照表
├── review/                        ← 子 agent 审查记录（按审查对象分子目录，文件名带状态：通过/未修复/已修复）
├── tools/                         ← 工具复用记录（tools.csv 累积表格）
├── team/                          ← 团队分工（roles/ 角色卡、rules/ 各角色自包含规则（生成物）、tasks/ 任务卡模板、board.md 看板、env-check.md）
├── scripts/                       ← 项目脚本（模板自带 env_check.ps1 开局环境探测、build_rules.ps1 规则生成/校验、install_skills.ps1 B 档技能安装/刷新/漂移检查；**均含项目根自检**）
├── assets/figures/vN/             ← 图件（仅 SVG + PNG、一图一文件；v4.1 起预建）
├── data/                          ← 原始数据（只读；data/raw/ 不入库；v4.1 起预建）
├── output/                        ← 产出（v4.1 起预建）：reports/（lead）· analysis/（analysis-agent）· manuscript/（figure-writer）
├── .dsh/skills/                   ← A 档技能（v4.2 起随 skeleton 自动携带；含 VENDORED.md 清单）
└── template/                      ← 本模板包（可保留备用或删除）
    └── skills/                    ← B 档技能（v4.2 起：随包携带、不自动进项目，见 template/skills/README.md）
```

## 文件命名规则

- 批次：`YYYY-MM-DD_序号_主题.csv / .md`，序号随检索次数递增，禁止覆盖或删除历史记录。
- 索引更新：每次新增检索后，INDEX_QUICK.md 追加分类与篇数、INDEX.md 追加批次与明细。

## 与示例项目的差异

- 本模板为空骨架（文献库 0 篇、索引空表、记忆文件空模板）；示例项目 `2026-08-01_xiujue_mianyi` 中已有 3 批 53 篇文献作为参考范例，可对照其 `literature/` 查看归档形态。

## 升级到 v4.0（已建项目）

v4.0 的规则分层**不自动跟随**已建项目；升级按下列 6 步（母版路径：`template/`）：

1. **复制生成物与脚本**：把 `template/skeleton/team/rules/`（`_common` + 5 角色，共 6 份）与 `template/skeleton/scripts/build_rules.ps1` 复制到项目对应位置（`team/rules/`、`scripts/`）。
2. **换总纲头部**：项目 `CLAUDE.md` 头部换成 v4.0 头部——版本行改 v4.0（2026-10-01），并在「运行模式」行之后补「规则文件（v4.0）」说明行（写明生成与校验命令）。
3. **裁剪 `CLAUDE.md`**：把母版 `TEMPLATE_CLAUDE.md` 的 v4.0 正文（含 `<!--rules:…-->` 标记）同步进项目 `CLAUDE.md`；项目自有的补充条款须落在某个标记之后并被其覆盖——标记之前只允许总纲专用头部（`-Check` 的覆盖门禁要求首个 `## N.` 规则节出现在首个标记之后）。**规则正文以母版为准**。
4. **生成**：在项目根跑 `scripts\build_rules.ps1`（默认 `CLAUDE.md` → `team\roles` → `team\rules`）。
5. **校验**：跑 `scripts\build_rules.ps1 -Check`，必须 `CHECK OK`（`DRIFT` = 生成物与源不一致、`MISSING` = 缺文件；未通过不得交卡）。
6. **装配同步**：确认 `team-launcher` 技能的装配步骤已改为"prompt = `team/rules/<role>.md` 全文 + 项目绝对路径 + 本轮范围"，并明令成员不得读总纲或其它角色的规则文件。

## 升级到 v4.1（已建项目）

v4.1 是**措辞澄清 + 骨架补齐**类改动（无结构性重排），母版路径 `template/`。已建项目按需取用：

1. **换总纲**：把项目 `CLAUDE.md` 同步为母版 v4.1 正文（头部版本行改 v4.1、补「工作目录」提示行；正文改动集中在 §5、§9、§12、§12.1，其余节未动）。**项目自有的补充条款须落在某个标记之后**。
2. **换脚本**：把 `template/skeleton/scripts/{env_check,build_rules}.ps1` 复制到项目 `scripts/`（两者新增**项目根自检**；`env_check.ps1` 另把关键包分必需/可选）。**注意 `.ps1` 必须是 UTF-8 with BOM + CRLF**，从母版复制即可，不要用会剥 BOM 的编辑器改写。
3. **重新生成规则**：在项目根跑 `scripts\build_rules.ps1`，再跑 `-Check` → 必须 `CHECK OK`。
4. **补目录与忽略**：建 `assets/`、`data/`、`output/{reports,analysis,manuscript}`；`.gitignore` 补 `__pycache__/`、`*.pyc`、`Rplots.pdf`。
5. **同步角色卡与看板**：`team/roles/lead.md` 的「用户三个决定点」改成五处；5 张角色卡的「环境事实」节补「工作目录」条；`team/README.md` 的写作用域表补「仓库根配置 → lead 独占（须单独提交）」。
6. **行为变更（无需改文件，但要知道）**：① 多面板图（≤3）合规，但须在出图规划中声明面板构成；② 出图规划确认与手稿结构确认纳入用户决定点；③ 成员一律用项目根绝对路径；④ 交接单写进自己产物末尾，由 `lead` 归档到 `team/`；⑤ 首次产出即落 `v1/`。

## 升级到 v4.2（已建项目）

v4.2 是**能力扩展 + 措辞修正**类改动（无结构性重排）。已建项目按需取用（母版路径 `template/`）：

1. **补 A 档技能**：把 `template/skeleton/.dsh/skills/`（22 个技能 + `VENDORED.md`；**不含** `team-launcher` 已存在项时保留原样）整体复制到项目 `<项目根>/.dsh/skills/`。A 档进项目 git（本设计选定：克隆即完整）。
2. **加安装脚本**：把 `template/skeleton/scripts/install_skills.ps1` 复制到项目 `scripts/`（**必须 UTF-8 with BOM + CRLF**，从母版复制即可）。
3. **换总纲**：项目 `CLAUDE.md` 同步母版 v4.2 正文；头部版本行改 v4.2 并补「技能携带（v4.2 起）」行；§12 技能条按 3.4 替换；§8/§9/§10 的 4 处技能名去前缀。
4. **换角色卡**：5 张 `team/roles/*.md` 的 ④ 节按分派表重写。
5. **重新生成规则**：项目根跑 `scripts\build_rules.ps1`，再跑 `-Check` → 必须 `CHECK OK`。
6. **按需装 B 档**：`install_skills.ps1 -Install -Source <模板包>\skills`（`nature-*` + `bio-library`，约 29.8 MB）。
7. **行为变更**：`lead` 禁用清单不再是"无"；`tdd` 取代 `test-driven-development`；`code-review` 在 `analysis-agent` 处只作自审，**不得替代** `auditor`。

## 混合模型路由（可选增强，v4.4 起）

把「思考/计划/讨论」与「检索/执行/干活」分派到不同模型：**Lead 会话走强模型，一切队员/子代理走普通模型**——机制层强制，不靠模型自觉。

### 机制

- 判定：主会话（root）= planner 路由；`origin:"subagent"` 或 `subagentDepth ≥ 1` 的会话（含 Agent Teams 队员）= executor 路由。
- 改写：挂 DSH 官方 `agent/request` 请求管线最外层（`{ prepend: true }`），强制改写每次请求的 provider/model/推理强度。
- **escalateOnError**：队员某步工具执行失败（`isError` 或文本 `[exit code: N]`，N≥1）→ 下一请求推理强度自动升到 `escalateTo`，连续 `recoverySteps` 步正常后回落基线。
- **vision 兜底**：会话出现图片后粘性路由到原生多模态模型（防止 planner 模型无 image 模态时拒收图片）。

### 配置（profile 的 `cordis.patch.yml`）

```yaml
- id: model-router
  config:
    planner:
      provider: deepseek-official
      model: deepseek-v4-pro
      reasoningEffort: max
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
    vision:
      enabled: true
      provider: deepseek-official
      model: deepseek-flash
```

实现为本地 bundle `@local/dsh-model-router-local`（母版工作区 `output/dsh-model-router-local/`，适配 DSH 0.2.0-rc.2；上游 `dsh-model-router` 0.7.1 与本版本 DSH 不兼容：其依赖的 `foldPlanMode`/`installSettingsSection` 在 0.2.0-rc.2 不存在）。安装：把 bundle link 进 profile 的 `dsh.profile.bundles`（`@local/dsh-model-router-local`，dependencies 用 `link:<bundle 目录>`，与 `@local/dsh-auto-doc` 同形态），重启 App 生效。

### 验收

```bash
# 1) 队员侧：统计队员会话 assistant/message 的 model（应全 deepseek-flash）
zstd -d -c "$DSH_HOME"/sessions/<workspace>/<session>/session.v4.jsonl.zstd \
  | grep '"type":"assistant/message"' | grep -o '"model":"deepseek-[a-z-]*"' | sort | uniq -c
# 2) escalate：队员执行失败步后，下一请求 request/header 的 reasoningEffort 应变 max、回落 high
```

### 已知瑕疵与回退

- **模型切换提示误导**：会话重启后 DSH 的模型选择层可能注入「model changed → flash」提示，而实际请求仍被 planner 路由改写为强模型——以 `request/header` 日志为准，该提示是选项层噪音。
- **回退**：从 profile 的 bundles 与 dependencies 中移除 `@local/dsh-model-router-local`、删除 `cordis.patch.yml` 的 `- id: model-router` 覆盖行、重启，即回到「全员继承会话模型」。
