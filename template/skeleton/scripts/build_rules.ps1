<#
  build_rules.ps1 —— 规则分层切片器 / 校验器
  用法：
    母版生成（工作目录 = template\skeleton\scripts）：
      .\build_rules.ps1 -Template ..\..\TEMPLATE_CLAUDE.md -RolesDir ..\team\roles -OutDir ..\team\rules
    项目内重新生成（工作目录 = 项目根）：
      .\scripts\build_rules.ps1
    校验（不写盘；exit 1 = 漂移）：
      .\scripts\build_rules.ps1 -Check
#>
[CmdletBinding()]
param(
  [string]$Template = 'CLAUDE.md',
  [string]$RolesDir = 'team\roles',
  [string]$OutDir   = 'team\rules',
  [string]$LauncherA = '',
  [string]$LauncherB = '',
  [switch]$Check
)
$ErrorActionPreference = 'Stop'
$Valid = @('common','lead','lit-agent','analysis-agent','figure-writer','auditor')
$GenTimePattern = '^     生成时间：.*$'

# 失败出口：不要用 Write-Error —— $ErrorActionPreference='Stop' 下它会抛终止异常，
# 其后的 exit 1 永不执行，调用方既看不到原因也拿不到 $LASTEXITCODE=1（2026-09-29 实测）。
function Fail([string]$msg) { [Console]::Error.WriteLine("ERROR: $msg"); exit 1 }

# 相对路径必须先按「PowerShell 当前位置」解析成绝对路径：Push-Location 只改 PS 位置，
# 不改 .NET 进程工作目录，[System.IO.File]::* 直接吃相对路径会解析到别处（2026-09-29 实测失败）。
function Get-FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
function Read-Utf8([string]$p) { [System.IO.File]::ReadAllText((Get-FullPath $p), [System.Text.Encoding]::UTF8) }
function Write-Lf([string]$p, [string]$text) {
  $full = Get-FullPath $p
  $dir = Split-Path $full -Parent
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($full, $text, (New-Object System.Text.UTF8Encoding($false)))
}
function Get-Sha12([string]$p) { (Get-FileHash (Get-FullPath $p) -Algorithm SHA256).Hash.Substring(0,12) }

# ---------- 0. 项目根自检（v4.1） ----------
# 默认路径（CLAUDE.md / team\roles / team\rules）均相对 cwd 解析；cwd 不是项目根时会静默读错、写错位置
# （团队成员的 cwd 常继承 lead 会话、可能落在别的项目），故先自检并给出可诊断的报错。
if (-not (Test-Path $Template)) { Fail "源文件不存在：$Template —— cwd 是否为项目根？请 cd 到项目根，或用 -Template 指定绝对路径（v4.1 项目根自检）" }
if (-not (Test-Path $RolesDir)) { Fail "角色卡目录不存在：$RolesDir —— cwd 是否为项目根？请 cd 到项目根，或用 -RolesDir 指定绝对路径（v4.1 项目根自检）" }

# ---------- 1. 读取与切块 ----------
$raw = (Read-Utf8 $Template) -replace "`r`n", "`n"
$lines = $raw -split "`n"
$markerRe = '^<!--rules:([a-z0-9,\-]+)-->$'
$blocks = @()          # @{ targets=@(...); lines=@(...) }
$cur = $null
$firstMarkerLine = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
  $m = [regex]::Match($lines[$i], $markerRe)
  if ($m.Success) {
    $targets = $m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($tg in $targets) {
      if ($Valid -notcontains $tg) { Fail "非法标记目标：'$tg'（第 $($i+1) 行）" }
    }
    if ($firstMarkerLine -lt 0) { $firstMarkerLine = $i }
    $cur = @{ targets = $targets; lines = @() }
    $blocks += $cur
    continue
  }
  if ($cur) { $cur.lines += $lines[$i] }
}
if ($blocks.Count -eq 0) { Fail "源文件中没有任何 <!--rules:...--> 标记" }

# 覆盖门禁：首个「编号规则节标题」必须在首个标记之后。
# 标记之前的区域只允许总纲专用头部（# 标题、版本/运行模式提示、## 目录、交叉引用说明）；
# 现行总纲的规则节一律写成 "## N. 标题"，故判据取编号标题（未编号的 "## 目录" 不算规则节，
# 否则本门禁在源文件上恒假阳性）。逐行循环取首个命中，避免 Select-String 的行号语义歧义。
$firstHeading = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^## \d+\.') { $firstHeading = $i + 1; break }
}
if ($firstHeading -and ($firstHeading - 1) -lt $firstMarkerLine) {
  Fail "覆盖门禁不通过：'## N.' 规则节标题出现在首个标记之前（第 $firstHeading 行）——规则正文必须被标记覆盖"
}
# 覆盖门禁：存在无标记的“孤立正文块”（仅在标记之间才会发生，故此处检查每个块非空即通过）

function Get-Slice([string]$target) {
  $out = @()
  foreach ($b in $blocks) { if ($b.targets -contains $target) { $out += $b.lines } }
  ($out -join "`n").Trim("`n") + "`n"
}

# ---------- 2. 拼装 ----------
$tplSha = Get-Sha12 $Template
function New-Header([string[]]$sources) {
  $s = ($sources | ForEach-Object { $_ }) -join ' + '
  @(
    "<!-- 自动生成，勿手改。源：$s",
    "     生成命令：powershell -File scripts\build_rules.ps1",
    "     校验命令：powershell -File scripts\build_rules.ps1 -Check",
    "     生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -->",
    ""
  ) -join "`n"
}
function New-RoleDoc([string]$role) {
  $cardPath = Join-Path $RolesDir "$role.md"
  # 角色卡同样归一化行尾：生成物硬约束是「无 BOM + LF」，卡若为 CRLF 会污染生成物
  $card = if (Test-Path $cardPath) { ((Read-Utf8 $cardPath) -replace "`r`n", "`n").Trim("`n") } else { "（未找到角色卡 $cardPath）" }
  $cardSha = if (Test-Path $cardPath) { Get-Sha12 $cardPath } else { 'missing' }
  $head = New-Header @("CLAUDE.md@$tplSha", "team/roles/$role.md@$cardSha")
  $commonPart = Get-Slice 'common'
  $rolePart = Get-Slice $role
  @(
    $head,
    "# $role 执行规则（自包含，本文件即该角色的全部规则）",
    "",
    "## A. 角色卡（身份 / 职责 / 写作用域 / 技能白名单 / DoD / 升级条件）",
    "",
    $card,
    "",
    "## B. 通用规则（全体遵守）",
    "",
    $commonPart,
    "## C. $role 专属规则",
    "",
    $rolePart
  ) -join "`n" | ForEach-Object { $_ -replace "`n{3,}", "`n`n" }
}
function New-CommonDoc {
  $head = New-Header @("CLAUDE.md@$tplSha")
  (@($head, "# 通用规则（全体遵守）", "", (Get-Slice 'common')) -join "`n") -replace "`n{3,}", "`n`n"
}

$targets = @('common') + @(Get-ChildItem $RolesDir -Filter *.md -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName })
$targets = $targets | Select-Object -Unique

# ---------- 3. 写出或校验 ----------
$strip = { param($t) ($t -split "`n" | Where-Object { $_ -notmatch $GenTimePattern }) -join "`n" }

if (-not $Check) {
  Write-Lf (Join-Path $OutDir '_common.md') (New-CommonDoc)
  foreach ($r in ($targets | Where-Object { $_ -ne 'common' })) {
    Write-Lf (Join-Path $OutDir "$r.md") (New-RoleDoc $r)
  }
  Write-Host "generated -> $OutDir（$($targets.Count) 份）"
  exit 0
} else {
  # 校验用的临时目录优先落在工作区 .cache/（约定：临时文件不散落到 %TEMP%），无 .cache/ 时退回 %TEMP%
  $tmpRoot = if (Test-Path '.cache') { (Resolve-Path '.cache').Path } else { $env:TEMP }
  $tmp = Join-Path $tmpRoot ("rules_check_" + [guid]::NewGuid().ToString('N').Substring(0,8))
  $script:CheckExit = 0
  $prevOut = $OutDir; $OutDir = $tmp
  Write-Lf (Join-Path $OutDir '_common.md') (New-CommonDoc)
  foreach ($r in ($targets | Where-Object { $_ -ne 'common' })) { Write-Lf (Join-Path $OutDir "$r.md") (New-RoleDoc $r) }
  $OutDir = $prevOut
  foreach ($f in (Get-ChildItem $tmp -File)) {
    $disk = Join-Path $prevOut $f.Name
    if (-not (Test-Path $disk)) { Write-Host "MISSING: $($f.Name)"; $script:CheckExit = 1; continue }
    if ((& $strip (Read-Utf8 $disk)) -ne (& $strip (Read-Utf8 $f.FullName))) { Write-Host "DRIFT: $($f.Name)"; $script:CheckExit = 1 }
  }
  Remove-Item $tmp -Recurse -Force
  # launcher 两处一致性
  if ($LauncherA -and $LauncherB -and (Test-Path $LauncherA) -and (Test-Path $LauncherB)) {
    if ((Get-Sha12 $LauncherA) -ne (Get-Sha12 $LauncherB)) { Write-Host "DRIFT: team-launcher 两处副本不一致"; $script:CheckExit = 1 }
  }
  # 成功路径也显式 exit 0：脚本不显式退出时 $LASTEXITCODE 保留上一次的值，
  # 调用方（尤其 CI）会读到陈旧退出码，把「CHECK OK」误判为失败（2026-09-29 实测）。
  if ($script:CheckExit -eq 0) { Write-Host "CHECK OK"; exit 0 } else { Write-Host "CHECK FAILED"; exit 1 }
}
