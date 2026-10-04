# PROVENANCE — Auto_Doc 模式随包快照的来源

> 本文件说明 bundle 内 `rules/` 与 `skills/` 两份**快照**来自哪里、何时取的、如何核对，
> 以及它们与母版（模板包）的关系。规则正文的唯一事实源始终是模板母版，本 bundle 只带副本。

## 快照来源

| 项 | 值 |
|---|---|
| 母版工作区 | `D:\deepseek_work\2026-09-20_template` |
| 模板版本 | **v4.3（2026-10-04）** |
| 母版 git 提交 | `2508ddfd7311c4dad935ee409211407bad0582c1`（2026-10-04 `feat(template): v4.2 -> v4.3 去机器指纹（可对外分发）+ Auto_Doc 快照刷新`） |
| 快照生成时间 | 2026-10-04 14:05（v4.3 刷新） |

## rules/（规则快照）

| bundle 内路径 | 母版来源 | 校验 |
|---|---|---|
| `rules/CLAUDE_v4.3.md` | `template/TEMPLATE_CLAUDE.md` | SHA256 `D36D91EAE5EE11B959D2F7728F041F18EF9F636B2BD0A8EDDEF2E6623D681854`（与母版逐字节一致） |
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
  工作区根 `CLAUDE.md` 标注 v4.3 时以**工作区**为唯一事实源，本快照只在工作区无规则时使用。
