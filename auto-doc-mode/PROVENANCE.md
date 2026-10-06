# PROVENANCE — Auto_Doc 模式随包快照的来源

> 本文件说明 bundle 内 `rules/` 与 `skills/` 两份**快照**来自哪里、何时取的、如何核对，
> 以及它们与母版（模板包）的关系。规则正文的唯一事实源始终是模板母版，本 bundle 只带副本。

## 快照来源

| 项 | 值 |
|---|---|
| 母版工作区 | 源仓库（模板母版工作区，路径见源仓库；本包为分发副本） |
| 模板版本 | **v4.4（2026-10-06）** |
| 母版 git 提交 | `2026-10-06 v4.3 -> v4.4 混合模型路由（环境增强）`（本次刷新提交，见母版 `Claude_memory.md` 变更记录） |
| 快照生成时间 | 2026-10-06（v4.4 刷新） |

## rules/（规则快照）

| bundle 内路径 | 母版来源 | 校验 |
|---|---|---|
| `rules/CLAUDE_v4.4.md` | `template/TEMPLATE_CLAUDE.md` | SHA256 `09538E48C1A6600BEC69A19804B43EBD6BF1806B82F66F0067CD2668263D7166`（与母版逐字节一致） |
| `rules/team/roles/*.md`（5 份） | `template/skeleton/team/roles/` | 逐字节复制 |
| `rules/team/rules/*.md`（6 份） | `template/skeleton/team/rules/` | 逐字节复制（由 `build_rules.ps1` 生成的自包含角色规则） |
| `rules/team/README.md` | `template/skeleton/team/README.md` | 逐字节复制 |

## skills/（技能快照，A 档）

`skills/` 是 `template/skeleton/.dsh/skills/` 的逐字节副本：**22 个技能**（含 `team-launcher`、
`brainstorming`、`writing-plans`、`executing-plans`、`tdd`、`code-review`、`systematic-debugging`、
`research`、`handoff`、`triage` 等），约 245 KB / 65 个文件。

- 母版自带的来源与许可登记见 `template/skeleton/.dsh/skills/VENDORED.md`（未复制进 bundle，
  以免被技能发现器当作技能条目）；需要时回母版查。
- 本 bundle **不含** B 档（`template/skills/` 的 `nature-*`，29.8 MB）与 C 档（`$DSH_HOME/skill-library/bio/`
  的 561 个 `bio-*`）；它们按模板总纲「技能来源与优先级」在会话中按需取用。

## 刷新与一致性

- 母版改了规则或 A 档技能 → 本 bundle 的快照即过期。重取方式：重跑本目录生成时的同一组复制命令
  （见母版 `Claude_memory.md` 的相应变更记录），或按上表逐项复核 SHA256。
- 会话中判定「读工作区规则还是读本快照」的规则写在 persona 规程「一、规则事实源」：
  工作区根 `CLAUDE.md` 标注 v4.4 时以**工作区**为唯一事实源，本快照只在工作区无规则时使用。
