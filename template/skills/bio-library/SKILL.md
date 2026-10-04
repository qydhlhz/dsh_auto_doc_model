---
name: bio-library
description: 生信技能库导航。**本机存在 561 个生信/组学分析技能**（ATAC-seq、ChIP-seq、CRISPR 筛选、单细胞、空间转录组、变异注释、甲基化、宏基因组、群体遗传、临床生统等），为节省常驻 token 已移出默认技能根——因此它们**不在技能目录中、`skill` 工具调不到**，但**绝不等于不存在**。凡任务涉及生信或组学数据分析、或需要生信工具/流程/参数，必须先调用本技能，再按其指引用 `read` 读取对应 `SKILL.md`；**不得因为技能目录里没有生信条目就忽略其存在、凭记忆自行发挥**。
---

# 生信技能库导航

> ⚠️ **首先记住**：本机**存在 561 个生信技能**，它们只是**不在技能目录里**。
> 技能目录中没有生信条目，**绝不代表没有生信技能可用**。
> 遇到生信/组学任务却不查本库、直接凭记忆写代码或选参数，属于违规。

## 为什么不在目录里

技能目录会作为一条 user message 注入每个会话历史，并在**每一步**重发。
561 个 bio 技能常驻约 72,417 tokens/步，迁出后整份目录降至约 2,524。
省下的是常驻开销，**能力一个没少**——全部仍在磁盘上，按需读取。

## 它们是「读」出来的，不是「调」出来的

这些技能**不在任何已注册技能根中**，`skill` 工具**不认识它们**，
调用 `skill` 只会得到「找不到技能」。必须用 `read` 工具直接读取 `SKILL.md` 全文，
然后严格按该技能正文执行。

## 库位置

```
$DSH_HOME\skill-library\bio\
├── INDEX.md            总览：全部 71 组 + 每组技能数（权威清单）
├── groups\<组名>.md     单组成员清单（技能名、目录名、一句话说明）
└── <技能目录>\SKILL.md   技能本体
```

## 取用步骤

1. **定位组** — 读 `$DSH_HOME\skill-library\bio\INDEX.md`（约 1,200 tokens），在分组表里找到相关组；
2. **择技** — 读 `groups\<组名>.md`（约 400 tokens），挑出技能及其**目录名**；
3. **加载** — 用 `read` 读 `$DSH_HOME\skill-library\bio\<目录名>\SKILL.md` 全文，然后严格按该技能正文执行。

只有第 1、2 步按需产生成本；技能本体常驻开销为零。

## 分组（按规模，完整表见 INDEX.md）

| 组 | 技能数 |
|---|---|
| `bio-workflows` | 41 |
| `bio-data-visualization` | 20 |
| `bio-single-cell` | 18 |
| `bio-crispr-screens` | 15 |
| `bio-comparative-genomics` | 13 |
| `bio-alignment` | 12 |
| `bio-atac-seq` | 12 |
| `bio-chipseq` | 12 |
| `bio-clinical-biostatistics` | 12 |
| `bio-clinical-databases` | 12 |
| `bio-causal-genomics` | 11 |
| `bio-copy-number` | 11 |
| `bio-methylation` | 11 |
| `bio-spatial-transcriptomics-spatial` | 10 |
| `bio-genome-assembly` | 9 |
| `bio-long-read-sequencing` | 9 |
| `bio-metabolomics` | 9 |
| `bio-proteomics` | 9 |
| `bio-flow-cytometry` | 8 |
| `bio-genome-intervals` | 8 |
| …（余下 51 组） | |

## 注意

- 技能正文里引用的相对路径、脚本、参考文件，都相对**该技能自己的目录**解析。
- 库内技能互相引用时按名字回本索引重新定位，不要自行拼接路径。
- 不要凭记忆复述技能内容——必须先读 `SKILL.md` 原文。
