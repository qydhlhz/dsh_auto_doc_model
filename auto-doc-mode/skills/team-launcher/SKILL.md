---
name: team-launcher
description: 启动/恢复科研项目的 5 角色团队（lead + lit-agent + analysis-agent + figure-writer + auditor）。当工作目录下存在 team/ 目录、或用户要求"组队/开团队/团队分工"、或按科研模板开展多环节项目时使用。本技能只做启动与调度骨架，角色内容以项目内 team/roles/ 为准。
---

# team-launcher —— 科研团队启动器（薄）

**唯一职责**：把项目里已有的团队装备起来；**本技能不含角色内容**，一切以项目内 `team/` 为准（事实源唯一）。

## 使用前提

- 当前工作目录是科研项目根，且存在 `team/`（缺则提示：从科研模板 `skeleton/` 复制 `team/` 与 `scripts/`，或见模板 §12）。
- 若缺少 `team/`，不要凭记忆编造角色：停下，告知用户先初始化模板。
- **项目根自检（v4.1）**：`scripts/env_check.ps1` 与 `scripts/build_rules.ps1` 都自带「cwd 是否为项目根」检查——若报 `当前工作目录不像项目根`，说明 cwd 不对（**成员的 cwd 常继承 lead 会话，不保证是项目根**），改用项目根绝对路径重新调用；**装配成员时一律在 prompt 中写明项目根绝对路径**。

## 启动步骤（照做）

1. **环境检查**：`powershell -File scripts\env_check.ps1 -OutFile team/env-check.md`；若 shell 不可用或判定为「需降级」，读 `team/env-check.md` 判定区并告知用户当前处于降级模式（模板 §12 降级模式）。
2. **恢复状态**：读 `Claude_memory.md` 的「项目概况 / 文献库状态 / 空白与待办」摘要区 + `team/board.md`；列出本轮待办与未完成卡。
3. **装配成员**：每个 `spawn_teammate` 的 `prompt` = **`team/rules/<role>.md` 全文** + 项目绝对路径 + 本轮范围；
   - `context` 一律 `fresh`（审查官尤其禁止 `fork`）；
   - **明令**：除 `team/rules/<role>.md` 与本轮任务卡外，**不得读取总纲 `CLAUDE.md` 或其它角色的规则文件**（规则已自包含；越权读取视为违规，记入 `review/`）；
   - 固定名：`lit-agent`、`analysis-agent`、`figure-writer`、`auditor`；创建失败才用备名 `-b`。
4. **建卡派活**：按 `team/tasks/task-card.template.md` 建 `team_task_create`（含 `blocked_by` 与 `write_scopes`），然后 **`send_message` 显式唤醒** owner —— 任务就绪不会自动开工。
5. **推进循环**：`wait_agent` → `list_agents` + `team_task_list` → 按卡内路径核对产出物 → 派 `auditor` → 收卡（过不了 `reopen`）→ 唤醒下游。
6. **收尾**：更新 `team/board.md`（本轮归档 + 配额余量）与 `Claude_memory.md`（进展、文献库状态、待办）；未完成卡保留 owner 与状态。

## 七条铁律（违反即流程失效）

1. 交接只认落盘文件 + 任务卡；消息只用于唤醒与提问。
2. `inactive` ≠ 完成；收卡必须实际核对产出物存在。
3. 任务就绪不唤醒 owner，lead 必须显式唤醒。
4. owner 不自动释放（崩溃后卡仍 in_progress）→ `reassign`/`release`。
5. 审查必须 `fresh`，禁止 `fork`；派卡只给路径不给结论。
6. 名字永久不复用：固定 4 名 + 备名 2 个，余量只用于重建。
7. git 操作由 lead 独占；`write_scopes` 只是建议，越界靠 `git diff` + 收卡核对发现。
