# VENDORED —— 随模板携带的技能清单（A/B 两档表格由生成脚本产出，勿手改表格）

> 生成时间：2026-10-04 11:09:27 ｜ 生成源：随包快照目录（与全局根同源时逐项一致） ｜ 档位说明见项目内 `CLAUDE.md` 的「团队分工与协作」节（v4.2 技能条）
> 来源根变量展开：`$DSH_HOME` = 用户级 DSH 根（本机默认 `%USERPROFILE%\.dsh`）；`$DSH_AGENTS_HOME` = agent 级根（本机默认 `%USERPROFILE%\.agents`，该变量未导出到 shell，此处为约定路径；两处磁盘实测存在）。下表"来源根"列即这两处根下的 `skills\` 子目录。
> **上游来源未知**：30 份 `SKILL.md` 的 front-matter 以 name/description 为主，另有 author×2、version×2（`nature-polishing` v6.0.0、`nature-writing` v1.0.0）及 disable-model-invocation / argument-hint 等字段；**无上游仓库 URL、无授权条款**。本表只登记**本机来源根**，**不足以判定对外分发的授权**（对外分发前须另行确认上游授权）。
> A 档 = 随 `skeleton/` 自动就位、**可直接引用**（仍须角色卡白名单授权）；B 档 = 随 `template/skills/` 携带，需 `scripts/install_skills.ps1 -Install`。
> **技能内容为第三方原样快照**：技能目录内（**含子目录**）**未随附 LICENSE / COPYING / NOTICE 文件**（下方"许可文件"列如实登记）；"无许可文件"≠"无授权条款"。
> **档位即下方两节标题（A 档 / B 档）**：按节分表，故不单列"档位"列。

## A 档（随项目自动携带，可直接引用——授权仍见角色卡白名单）

| 技能 | 来源根 | 快照日期 | 文件数 | 字节 | 许可文件 |
|---|---|---|---|---|---|
| `team-launcher` | $DSH_HOME/skills | 2026-10-04 | 1 | 3376 | **无** |
| `brainstorming` | $DSH_HOME/skills | 2026-10-04 | 8 | 52545 | **无** |
| `writing-plans` | $DSH_HOME/skills | 2026-10-04 | 2 | 7814 | **无** |
| `systematic-debugging` | $DSH_HOME/skills | 2026-10-04 | 11 | 40733 | **无** |
| `verification-before-completion` | $DSH_HOME/skills | 2026-10-04 | 1 | 4201 | **无** |
| `triage` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 4 | 19731 | **无** |
| `writing-for-agents` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 3 | 13723 | **无** |
| `wizard` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 3 | 13037 | **无** |
| `diagnosing-bugs` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 3 | 10134 | **无** |
| `domain-modeling` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 4 | 8664 | **无** |
| `tdd` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 4 | 7509 | **无** |
| `code-review` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 6779 | **无** |
| `retro` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 4564 | **无** |
| `to-spec` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 3258 | **无** |
| `grilling` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 2131 | **无** |
| `handoff` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 1056 | **无** |
| `research` | $DSH_AGENTS_HOME/skills | 2026-10-04 | 2 | 903 | **无** |
| `subagent-driven-development` | $DSH_HOME/skills | 2026-10-04 | 4 | 19883 | **无** |
| `executing-plans` | $DSH_HOME/skills | 2026-10-04 | 1 | 2469 | **无** |
| `using-git-worktrees` | $DSH_HOME/skills | 2026-10-04 | 1 | 7983 | **无** |
| `requesting-code-review` | $DSH_HOME/skills | 2026-10-04 | 2 | 7610 | **无** |
| `finishing-a-development-branch` | $DSH_HOME/skills | 2026-10-04 | 1 | 7061 | **无** |

## B 档（随 template/skills/ 携带，需安装）

| 技能 | 来源根 | 快照日期 | 文件数 | 字节 | 许可文件 |
|---|---|---|---|---|---|
| `nature-figure` | $DSH_HOME/skills | 2026-10-04 | 93 | 30750411 | **无** |
| `nature-academic-search` | $DSH_HOME/skills | 2026-10-04 | 36 | 168844 | **无** |
| `nature-writing` | $DSH_HOME/skills | 2026-10-04 | 64 | 140433 | **无** |
| `nature-citation` | $DSH_HOME/skills | 2026-10-04 | 7 | 100599 | **无** |
| `nature-polishing` | $DSH_HOME/skills | 2026-10-04 | 28 | 50692 | **无** |
| `nature-paper2ppt` | $DSH_HOME/skills | 2026-10-04 | 2 | 43195 | **无** |
| `nature-reader` | $DSH_HOME/skills | 2026-10-04 | 5 | 20453 | **无** |
| `bio-library` | $DSH_HOME/skills | 2026-10-04 | 1 | 3359 | **无** |

## 同义技能与优先名

- `tdd`（A 档）与 `test-driven-development`（全局）同义 → **以 `tdd` 为准**；`analysis-agent` 角色卡**白名单只写 `tdd`**（同义说明中提及旧名）。
- 新增同义技能时，由 `lead` 裁定唯一正式名并登记到**本节**。

## 悬空引用（指向未随包技能，2026-10-04 实测登记）

随包技能正文含 21 处 superpowers:<技能名> 前缀的跨技能引用（8 个不同名字）。全树核对后 **7 个已随包**（executing-plans / finishing-a-development-branch / requesting-code-review / subagent-driven-development / using-git-worktrees / writing-plans / verification-before-completion），**唯一悬空的是 test-driven-development（3 处）**：

- subagent-driven-development/SKILL.md:276
- systematic-debugging/SKILL.md:179
- systematic-debugging/SKILL.md:287

处置：**不补 test-driven-development**——v4.2 §12 已定「tdd 与 test-driven-development 同义，以随包的 tdd 为准」；遇到这三处引用改用 tdd。

另注（裸名映射）：上述引用均带 superpowers: 前缀，而本机规则明确「带前缀会报找不到」。技能正文属第三方原样快照、不得改动；调用时一律去前缀、用裸名——**其余 7 个已随包**的名字去前缀即可用；`test-driven-development` 未随包，改用 `tdd`。

## 维护

- 本文 A/B 两档**表格由生成脚本产出**：**项目内**台账由 `scripts\install_skills.ps1 -Refresh` 重写（**在项目根执行**，脚本自带项目根自检；手改表格会被下次覆盖）。
- **母版**台账（本文件所在处）由 v4.2 实施计划 `## Task 3` 的 Step 1 生成脚本产出；**不要在 `template\skeleton\` 下执行 `-Install`/`-Refresh`**（会被护栏拒绝：模板包内快照另有维护流程），也不要把 B 档写进 `skeleton/`。
- 查缺失与漂移：`powershell -File scripts\install_skills.ps1 -Check`（**在项目根执行**；不阻断，exit 0）。
