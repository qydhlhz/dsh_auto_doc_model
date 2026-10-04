# template/skills —— B 档技能（随模板包携带，不自动进项目）

本目录是模板**自带的科学写作/制图技能快照**，用于保证「模板封装后换机器也能跑」——目标机器不必预装全局技能库。

## 为什么不在 skeleton/ 里

这 8 个技能合计约 **29.8 MB**（按 1 MB = 1024² B 计；其中 `nature-figure` 一个就占约 29.3 MB，是绝大部分）。若放进 `skeleton/`，**每个新项目**都会复制一份，代价不成比例。所以它们随 `template/` 包携带，需要时按项目安装。

## 清单

| 技能 | 用途 | 归属角色 |
|---|---|---|
| `nature-figure` | R 出图（§9 固定） | figure-writer |
| `nature-writing` | 手稿起草与改写（§10 固定） | figure-writer |
| `nature-polishing` | 学术英文润色 | figure-writer |
| `nature-paper2ppt` | 论文转中文 PPT | figure-writer |
| `nature-citation` | 严格 CNS 引用 | lit-agent |
| `nature-academic-search` | 多源文献检索与引用管理 | lit-agent |
| `nature-reader` | 中英对照全文阅读器 | lit-agent |
| `bio-library` | 生信技能库**导航器**（真库 561 个仍在 `$DSH_HOME/skill-library/bio/`，不随包） | analysis-agent |

## 怎么装

在项目根执行（脚本自带项目根自检）：

```powershell
# 看清单与安装状态
powershell -File scripts\install_skills.ps1 -List

# 安装全部 B 档（默认从 <项目根>\template\skills 取源；模板包不在项目内时用 -Source 指定）
powershell -File scripts\install_skills.ps1 -Install
powershell -File scripts\install_skills.ps1 -Install -Source D:\path\to\template\skills

# 用全局最新版刷新项目内快照（VENDORED.md 的 A/B 两档表格会自动重写，无需手工同步）
powershell -File scripts\install_skills.ps1 -Refresh

# 检查缺失与漂移（不阻断，exit 0）
powershell -File scripts\install_skills.ps1 -Check
```

装完后技能落在 `<项目根>\.dsh\skills\`，优先级**高于**任何全局技能根。

## 许可与来源

本目录内容为**第三方技能原样快照**，技能目录内**未随附 LICENSE / COPYING / NOTICE 文件**。定位为**个人/内部使用**的科研模板。

若要对外分发本模板包，须先确认各技能的上游授权，或改为「包内不含第三方技能，由 `install_skills.ps1` 从本机全局技能根复制」。来源与快照日期见 `.dsh/skills/VENDORED.md`（模板包内为 `skeleton/.dsh/skills/VENDORED.md`）。
