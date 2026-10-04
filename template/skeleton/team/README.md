# team/ —— 团队分工记录（模板 skeleton）

本目录是**团队执行模型的状态与规则载体**。角色卡在 `roles/`，任务卡模板在 `tasks/`，
看板是 `board.md`，开局检查结果写 `env-check.md`。

## 唯一写者（机制上 write_scopes 只是建议，必须靠纪律）

| 目录 / 文件 | 唯一写者 |
|---|---|
| `team/`（含本目录全部文件） | lead |
| `literature/` | lit-agent |
| `scripts/`、`tools/`、`output/analysis/` | analysis-agent |
| `assets/`、`output/manuscript/` | figure-writer |
| `review/` | auditor |
| 仓库根配置（`.gitignore`、`.gitattributes`、`README.md`、`.dsh/`） | lead（**杂项整理须单独成一次提交**，不得与任务卡产物混提，v4.1） |
| `data/`（原始数据） | 无人可写（只读） |

跨域写入：先发消息给 lead 申请 → lead 改任务卡授权 → 才动手。

**交接单落盘位置（v4.1）**：`team/handoff.template.md` 只是**模板**，而 `team/` 属 lead 独占写域——成员**不要**把交接单写进 `team/`。成员在自己的**产物文件末尾**附「交接摘要」小节并发消息给 lead，由 lead 抽取后落盘 `team/`。

## 与另外两个记录文件的关系（不重复记）

- `board.md`（本目录）：**任务级**看板 —— 哪张卡、谁在做、什么状态、产出在哪、审查结论在哪。
- `Claude_memory.md`（项目根）：**项目级**记忆 —— 课题进展、文献库状态、空白与待办。

## 跨会话恢复（teammate 不跨会话存活）

新会话开局固定五步：① 跑 `scripts/env_check.ps1` → `env-check.md`；
② 读 `Claude_memory.md` 摘要区 + 本目录 `board.md`；③ 按 `roles/` 装配成员（**固定名、`fresh`**）；
④ 按 `board.md` 重建任务卡并**显式唤醒** owner（任务就绪不会自动开工）；
⑤ 循环推进直至全部卡终态。

## 铁律

13 条铁律的正文已迁入总纲 §12.1（避免两处规则），生成物见 `team/rules/_common.md` 同节。**以总纲为准**。
