# 医学科研项目模板 v4.4 + Auto_Doc 模式 + 模型路由组件

面向 DSH（DeepSeek Harness）的科研项目工作体系，三件套：

| 目录 | 是什么 | 作用 |
|---|---|---|
| `template/` | **科研项目模板包**（v4.4） | 规则正文、项目骨架、脚本、技能三档携带；新项目从这里实例化 |
| `auto-doc-mode/` | **Auto_Doc 模式**（DSH Agent preset bundle，v1.2） | 把「开局组队 + 定位规则事实源」变成选模式即生效；随包携带 22 个通用技能与 v4.4 规则快照 |
| `model-router/` | **混合模型路由组件**（独立插件 bundle，v1.0.2，MIT） | 可选环境增强：主对话跟随会话选择，队员/子代理绑死普通模型，报错自动升级推理强度 |

## 一、三件套的职责边界（重要）

| 层 | 归属 | 说明 |
|---|---|---|
| 常驻执行体（persona 规程 + 22 个 A 档技能 + 规则基线快照） | `auto-doc-mode/` | 省去「每个项目重复携带技能、每个会话重读总纲」 |
| 母版与门禁（规则唯一事实源、版本、`build_rules.ps1 -Check`） | `template/TEMPLATE_CLAUDE.md` | 改规则改这里，并重新生成 `team/rules/` |
| 项目骨架与实例化（`team/`、`scripts/`、目录、记忆与审查契约） | `template/skeleton/` → 项目根 | 模式**不携带**骨架；项目未实例化则 `env_check.ps1` 等开局步骤无处可跑 |
| 模型分派（环境层，与规则正交） | `model-router/` | **独立可选**：profile 级生效，不依赖模板实例化；模板仅文档化并提供 `env_check.ps1` 提示级检测 |

## 二、快速开始

### A. 实例化一个科研项目（必需）

按 `template/README.md` 的 **8 步**执行，要点：

1. 把 `template/skeleton/` 下**所有内容**复制到新项目根目录（含 `.dsh/skills/`、`team/`、`scripts/`）；
2. 把 `template/TEMPLATE_CLAUDE.md` **复制**为项目根 `CLAUDE.md`（复制而非移动）；`template/` 整体保留为项目子目录 `<项目根>/template/`，供 B 档技能安装与升级对照；
3. 在项目根跑 `scripts\env_check.ps1` 生成 `team/env-check.md`（脚本含项目根自检）；
4. 按 `team/roles/` 装配 5 角色团队（`lead` / `lit-agent` / `analysis-agent` / `figure-writer` / `auditor`），**每个成员的 prompt 须写明项目根绝对路径**，角色规则读 `team/rules/<角色>.md`；
5. 改过 `CLAUDE.md` 后必须跑 `scripts\build_rules.ps1` 重新生成、再用 `-Check` 校验，**必须 `CHECK OK`**。

### B. 装 Auto_Doc 模式（可选，需 DSH）

用 DSH 的 `plugin_manager` → `action: install_bundle`，`target` 指向本仓库的 `auto-doc-mode/` 绝对路径；装完在新建会话的模式选择器里选 **Auto_Doc**。改后用 `node auto-doc-mode/tools/precheck.mjs` 做只读预检（应输出 `PASS`）。

### C. 装混合模型路由（可选，需 DSH 0.2.0-rc.2 实测线）

按 `model-router/README.md` 安装：把 `model-router/` 目录 link 进目标 profile 的 `dsh.profile.bundles`（`@local/dsh-model-router-local`），在 profile 的 `cordis.patch.yml` 加 `- id: model-router` 覆盖行，重启 profile。生效后：**主对话跟随会话选择**（GUI 选 `deepseek-v4-pro` 或 `deepseek-v4.1-flash` 都生效，随时可切）；一切子代理与 Agent Teams 队员**绑死** `deepseek-flash`（队员执行报错自动升级推理强度、连续正常回落）；带图请求兜底到多模态模型。**已知瑕疵**：会话重启后可能看到「model changed」提示与实际路由不符——以会话日志 `request/header` 为准（详见组件 README）。

## 三、环境依赖

| 依赖 | 必需性 | 说明 |
|---|---|---|
| Windows + PowerShell 7（pwsh） | 必需 | 所有脚本为 `.ps1`；`env_check.ps1` 含项目根自检 |
| R + `ggplot2`/`svglite` 等 | 出图必需 | 出图语言固定为 R；未在 PATH 时按 `R_HOME` 或通用安装位置探测，结果写入 `team/env-check.md` |
| Python 3（`python-docx`/`Pillow`） | 交付与像素验证需要 | Word 手稿与图件像素级验证 |
| Git | 推荐 | 越界核对用 `git diff`；每收一张任务卡提交一次 |
| DSH | 仅模式/路由需要 | 团队工具（`spawn_teammate` 等）、模式加载与模型路由依赖 DSH |
| 文献检索通道（PubMed MCP / 本地 CLI / NCBI E-utilities） | 按需 | 三者按优先级降级，降级须在检索策略文件如实登记 |
| 生信技能真库（`bio-*` 561 个 / 约 15.6 MB） | **不随包** | 属环境依赖（C 档），缺失时按总纲降级模式处理并记录 |

## 四、技能三档携带

| 档 | 位置 | 数量/体积 | 行为 |
|---|---|---|---|
| A | `template/skeleton/.dsh/skills/` | 22 个 / 约 0.24 MB | 实例化时随项目自动就位，可直接引用（仍须角色卡白名单授权） |
| B | `template/skills/` | 8 个 / 237 文件 / 约 29.83 MB | 随包携带、不自动进项目；用 `scripts/install_skills.ps1 -Install` 按需安装 |
| C | 环境依赖（`$DSH_HOME/skill-library/bio/`） | 561 个 / 约 15.6 MB | 不随包；先读 `bio-library` 导航技能再用 `read` 取正文 |

## 五、第三方技能与许可声明（务必阅读）

- `template/skills/` 与 `template/skeleton/.dsh/skills/` 内的技能是**第三方原样快照**，目录内（含子目录）**未随附 LICENSE / COPYING / NOTICE 文件**；「无许可文件」≠「无授权条款」。
- 来源根、快照日期、文件数、字节数与「许可文件」列如实登记在 `template/skeleton/.dsh/skills/VENDORED.md`；该表只登记本机来源根，**不足以判定对外分发的授权**。
- 本仓库为**私有仓库**，定位为作者自用与内部协作。**对外公开发布或再分发前，须先逐项确认上游授权**，或改为「包内不含第三方技能、由 `install_skills.ps1` 从本机全局技能根复制」的形态。
- 模板自身与模式配置文件（`TEMPLATE_CLAUDE.md`、`README.md`、`team/`、`scripts/`、`cordis.patch.yml` 等）的授权方式**尚未指定 LICENSE**，默认保留所有权利。
- `model-router/` 为 **MIT**（fork 自 `dsh-model-router`，版权声明见组件内 `LICENSE`），可独立使用与分发。

## 六、目录结构

```
med-research-template-v4.4/
├── README.md                    本文件
├── template/                    模板包（v4.4）
│   ├── README.md                初始化清单（8 步 + 混合模型路由一节）
│   ├── TEMPLATE_CLAUDE.md       规则正文（唯一权威，v4.4）
│   ├── skeleton/                项目骨架（实例化时复制到项目根）
│   │   ├── Claude_memory.md     工作记忆模板
│   │   ├── literature/          分级索引 + CSV + 检索策略 + 术语表
│   │   ├── review/              审查记录（三态：通过/未修复/已修复）
│   │   ├── tools/               工具复用登记（tools.csv）
│   │   ├── team/                5 角色卡 + 6 份自包含角色规则（生成物）+ 任务卡 + 看板
│   │   ├── scripts/             env_check / build_rules / install_skills
│   │   └── .dsh/skills/         A 档技能 + VENDORED.md 清单
│   └── skills/                  B 档技能（随包携带，按需安装）
├── auto-doc-mode/               DSH Agent preset bundle（v1.2）
│   ├── package.json / cordis.patch.yml
│   ├── rules/                   persona 规程 + v4.4 总纲快照 + 角色卡 + 角色规则
│   ├── skills/                  22 个 A 档技能快照
│   ├── tools/precheck.mjs       只读预检
│   ├── README.md                装/卸/更新与边界说明
│   └── PROVENANCE.md            快照来源、母版提交号、SHA256 校验
└── model-router/                混合模型路由组件（v1.0.2，MIT，独立分发）
    ├── package.json / cordis.patch.yml
    ├── lib/index.js             路由逻辑（DSH agent/request 管线改写）
    ├── README.md                安装 / 配置 / 验收 / 已知瑕疵 / 回退
    └── LICENSE                  MIT（上游 dsh-model-router + fork 修改）
```

## 七、版本与变更

- **模板 v4.4（2026-10-06）**：混合模型路由（环境增强）。规则正文零改动；README 新增「混合模型路由」一节、`env_check.ps1` 新增提示级检测、`TEMPLATE_CLAUDE.md` 头部加说明行；6 份角色规则重新生成并通过 `-Check`。
- **模板 v4.3（2026-10-04）**：去机器指纹，具备对外分发条件。清除包内 5 类本机指纹（本机用户目录路径、角色卡中的 R/Python 绝对路径、模式预检里的写死用户名路径等，统一改为通用安装位置探测与变量表述）；`env_check.ps1` 的 R/Python 探测改为通用安装位置 + `R_HOME`；重新生成 6 份角色规则并通过 `-Check`。包内身份/机器指纹扫描全 0。
- **模板 v4.2**：技能三档携带（A 随项目、B 随包、C 环境依赖）、`install_skills.ps1`、技能按角色分派、修正带命名空间前缀的技能名。
- **模板 v4.1**：据全链实弹测试回填 11 项（一图一张边界、用户决定点五处、工作目录约定、凭证生命周期、预建目录等）。
- **模板 v4.0**：规则分层——总纲按 `<!--rules:…-->` 标记切片，生成成员只读的自包含 `team/rules/<角色>.md`。
- **Auto_Doc 模式 v1.2**：对应模板 v4.4，快照与母版逐字节一致（见 `auto-doc-mode/PROVENANCE.md`）。
- **model-router v1.0.2**：主对话改为**跟随会话选择**（`plannerFollowSession: true` 默认，GUI 选 v4-pro / v4.1-flash 均可，插件不改写主对话）；队员/子代理维持绑死 flash。v1.0.1：首个随包版本，本地 fork（适配 DSH 0.2.0-rc.2，上游 0.7.1 不兼容），已在本机四轮真实会话实测通过（核心路由 + escalate 升级/回落）。

## 八、已知限制

1. Auto_Doc 模式的**端到端效果尚未在真实会话验证**：profile 层与预检均已确认，但「新建会话选 Auto_Doc 后 persona 与随包技能确实生效」需在新会话实测。
2. 规则/技能快照**不会自动跟随母版**：母版改动后须按 `PROVENANCE.md` 重取快照并重装模式（目前为人工流程，未脚本化）。
3. 模式安装形态依赖 bundle 目录可访问；若以链接方式装入 profile，移动/删除该目录会使模式失效。
4. 出图与手稿交付链在模板 v4.0/v4.1 阶段做过全链实弹测试；v4.2/v4.3 的改动为内容扩展与清洗，未重跑全链。
5. **model-router 已实测与本机 DSH 0.2.0-rc.2 兼容**（核心路由 + escalate 四轮实测通过）；其他 DSH 版本未经测试。vision 粘性路由与「model changed」提示瑕疵见组件 README「已知瑕疵」。
