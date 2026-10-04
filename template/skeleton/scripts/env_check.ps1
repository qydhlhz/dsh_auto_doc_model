<#
  env_check.ps1 — 团队开局前置检查（科研模板 skeleton/scripts/）
  用法： powershell -File scripts/env_check.ps1 [-OutFile team/env-check.md]
  作用： 探测 shell / R / Python / git / 关键包，生成 team/env-check.md，
         并给出「可组队 / 需处理阻断项」判定（对应模板 §12 降级模式）。
   v4.1：① 新增「项目根自检」——cwd 不像项目根即报错退出（团队成员 cwd 常继承 lead 会话）；
         ② 关键包分「必需 / 可选」，仅必需包缺失才阻断，可选包缺失仅提示（原判据会把可组队误报为需降级）。
#>
param([string]$OutFile = "team/env-check.md")
$ErrorActionPreference = 'SilentlyContinue'
$root = (Get-Location).Path

# 0) 项目根自检（v4.1）：模板假定「工作目录 = 项目根」，但团队成员的 cwd 常继承 lead 会话、
#    可能落在别的项目；不匹配即报错退出，避免把产出与环境记录写进错误的项目。
if (-not ((Test-Path 'CLAUDE.md') -or (Test-Path 'TEMPLATE_CLAUDE.md') -or (Test-Path 'team\roles') -or (Test-Path 'team/roles'))) {
  [Console]::Error.WriteLine("ERROR: 当前工作目录不像项目根（缺 CLAUDE.md 与 team\roles）：$root")
  [Console]::Error.WriteLine("       请先 cd 到项目根，或用绝对路径调用本脚本（v4.1 项目根自检）。")
  exit 1
}

$lines = New-Object System.Collections.Generic.List[string]
$blockers = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$lines.Add("# 开局前置检查（env-check.md）")
$lines.Add("")
$lines.Add("> 由 ``scripts/env_check.ps1`` 自动生成，请勿手改；重跑即覆盖。")
$lines.Add("> 生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ｜ 工作目录：``$root``")
$lines.Add("")
$lines.Add("| 项 | 结果 | 判定 |")
$lines.Add("|---|---|---|")

# 1) shell
$psv = $PSVersionTable.PSVersion.ToString()
$lines.Add("| PowerShell | $psv | 可用 |")

# 2) R（不在 PATH，按候选路径探测；可用环境变量 R_HOME 指定，如 R_HOME=C:\Program Files\R\R-4.4.3）
$rCands = @()
if ($env:R_HOME) { $rCands += (Join-Path $env:R_HOME 'bin\Rscript.exe') }
$rGlobs = @('C:\Program Files\R\*\bin\Rscript.exe','C:\Program Files (x86)\R\*\bin\Rscript.exe')
if ($env:LOCALAPPDATA) { $rGlobs += (Join-Path $env:LOCALAPPDATA 'Programs\R\*\bin\Rscript.exe') }
foreach ($g in $rGlobs) { $rCands += (Get-ChildItem $g -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) }
$rscript = $rCands | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $rscript) { $rscript = (Get-Command Rscript).Source }
if ($rscript) {
  $lines.Add("| Rscript | ``$rscript`` | 可用 |")
  $rver = & $rscript -e 'cat(R.version.string)' 2>$null
  $lines.Add("| R 版本 | $rver | — |")
  # 关键包探测（写临时脚本，避免 -e 引号在 PowerShell 下被吞）
  $tmp = Join-Path $env:TEMP 'env_check_pkgs.R'
  # 注意：PowerShell 5.1 的 Set-Content -Encoding UTF8 会写入 BOM，
  # Rscript 遇 BOM 报 "unexpected invalid token"，故用无 BOM 的 UTF-8 写入
  $rSrc = @'
p <- c("ggplot2","svglite","dplyr","tidyr","survival","rms","patchwork","readxl","ggforce","ComplexHeatmap")
res <- sapply(p, function(x) requireNamespace(x, quietly = TRUE))
cat(paste(names(res), res, sep="=", collapse=";"), "\n")
'@
  [System.IO.File]::WriteAllText($tmp, $rSrc, (New-Object System.Text.UTF8Encoding($false)))
  $pkgs = & $rscript $tmp 2>$null
  $lines.Add("| R 关键包 | $pkgs | 见下 |")
  $rRequired = @('ggplot2','svglite')   # 出图基础：绘图 + SVG 矢量导出（§9 固定 SVG/PNG）
  foreach ($kv in ($pkgs -split ';')) {
    # R 的 cat(paste(...), "`n") 会在末项后留一个空格，故用 \s*$ 容错（否则末项漏判）
    if ($kv -match '=FALSE\s*$') {
      $pkg = $kv -replace '=FALSE\s*$',''
      if ($rRequired -contains $pkg) { $blockers.Add("R **必需**包缺失：$pkg（按模板 §7 申请安装，不得改语言）") }
      else { $warnings.Add("R 可选包缺失：$pkg（**不阻断**，按本轮是否用到核对）") }
    }
  }
  Remove-Item $tmp -Force
} else {
  $lines.Add("| Rscript | 未找到 | **阻断**（§9 固定 R） |")
  $blockers.Add("R 未安装或路径变更：§9 出图无法执行")
}

# 3) Python 与关键包
$py = (Get-Command python).Source
if ($py) {
  $pyv = & python -V 2>&1
  $lines.Add("| Python | ``$py``（$pyv） | 可用 |")
  $pyChk = & python -c "import importlib,sys;mods=['PIL','docx','pandas','matplotlib','numpy','openpyxl'];print(';'.join(m+'='+str(bool(importlib.util.find_spec(m))) for m in mods))" 2>$null
  $lines.Add("| Python 关键包 | $pyChk | 见下 |")
  $pyRequired = @('PIL','docx','pandas')   # 像素级验证 / Word 交付 / 数据处理
  foreach ($kv in ($pyChk -split ';')) {
    if ($kv -match '=False$') {
      $m = $kv -replace '=False$',''
      if ($pyRequired -contains $m) { $blockers.Add("Python **必需**包缺失：$m（按模板 §7 申请安装）") }
      else { $warnings.Add("Python 可选包缺失：$m（**不阻断**，按本轮是否用到核对）") }
    }
  }
} else {
  $lines.Add("| Python | 未找到 | **阻断**（§10 docx 交付） |")
  $blockers.Add("Python 未安装：Word 交付与像素级校验无法执行")
}

# 4) git
$gitv = (& git --version 2>$null)
if ($gitv) { $lines.Add("| git | $gitv | 可用 |") } else { $lines.Add("| git | 未找到 | 降级：改用时间戳核对越界 |"); $blockers.Add("git 不可用：越界检测降级为产出清单 + 时间戳") }

# 5) 判定
$lines.Add("")
$lines.Add("## 判定")
if ($blockers.Count -eq 0) {
  $lines.Add("- **可组队**：无必需依赖缺失，团队可自行跑验证脚本。")
  if ($warnings.Count -gt 0) {
    $lines.Add("- 以下为**可选依赖缺失，不构成降级**（v4.1 起不再据此判「需降级」；请按本轮实际用途核对）：")
    foreach ($w in $warnings) { $lines.Add("  - $w") }
  }
} else {
  $lines.Add("- **需先处理阻断项**（模板 §12 降级模式仅在这些阻断项无法解决时启用）：")
  foreach ($b in $blockers) { $lines.Add("  - $b") }
  if ($warnings.Count -gt 0) {
    $lines.Add("- 另，可选依赖缺失（不阻断）：")
    foreach ($w in $warnings) { $lines.Add("  - $w") }
  }
}
$lines.Add("")
$lines.Add("## 配额余量")
$lines.Add("- 本机 maxMembers=8（含失败成员、名字永不复用）；固定 4 名 teammate + 2 个备名。")

$OutFile = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path (Get-Location).Path $OutFile }
$OutFile = [System.IO.Path]::GetFullPath($OutFile)
New-Item -ItemType Directory -Force (Split-Path $OutFile) | Out-Null
[System.IO.File]::WriteAllText($OutFile, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
if (-not (Test-Path $OutFile)) { throw "写入失败：$OutFile" }
Write-Host "written: $OutFile"
