<#
  install_skills.ps1 —— 随包技能（B 档）安装 / 快照刷新 / 漂移检查（科研模板 skeleton/scripts/）
  用法（在项目根执行）：
    powershell -File scripts\install_skills.ps1 -List
    powershell -File scripts\install_skills.ps1 -Install [-Source <模板包 skills 路径>]
    powershell -File scripts\install_skills.ps1 -Refresh
    powershell -File scripts\install_skills.ps1 -Check
  约定（v4.2）：
    A 档 22 个技能随 skeleton/ 自动进项目；B 档 8 个随 template/skills/ 携带、需 -Install。
    -Refresh 刷新项目内快照，并**同步重写 .dsh\skills\VENDORED.md 的 A/B 两档表格**（文件数/字节/快照日期）。
    -Check 恒 exit 0（**不是门禁**，只报缺失与漂移）。
    本脚本自带项目根自检（同 v4.1 约定）。
#>
[CmdletBinding()]
param(
  [switch]$List,
  [switch]$Install,
  [switch]$Refresh,
  [switch]$Check,
  [string]$Source = ''
)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path

function Fail([string]$msg) { [Console]::Error.WriteLine("ERROR: $msg"); exit 1 }

function Assert-WritableProjectRoot {
  # v4.2 护栏：模板包的 skeleton/ 与包根都满足下方项目根自检，但它们不是项目——写入会把 B 档（约 30 MB）灌进模板包
  $parent = Split-Path $root -Parent
  $isSkeleton = Test-Path (Join-Path $parent 'TEMPLATE_CLAUDE.md')
  $isPackage = (Test-Path (Join-Path $root 'TEMPLATE_CLAUDE.md')) -and ((Test-Path (Join-Path $root 'skeleton')) -or (Test-Path (Join-Path $root 'skills')))
  if ($isSkeleton -or $isPackage) {
    Fail "当前目录是模板包（$root），不是项目根；-Install/-Refresh 会把技能写进模板包。请在项目根执行（模板包内的快照由母版维护流程 T1/T2/T3 更新）。只读的 -List / -Check 仍可用。"
  }
}

if (-not ((Test-Path 'CLAUDE.md') -or (Test-Path 'TEMPLATE_CLAUDE.md') -or (Test-Path 'team\roles') -or (Test-Path 'team/roles'))) {
  Fail "当前工作目录不像项目根（缺 CLAUDE.md 与 team\roles）：$root —— 请 cd 到项目根，或用绝对路径调用（v4.1 项目根自检）"
}

$destRoot = Join-Path $root '.dsh\skills'
$A = @('team-launcher','brainstorming','writing-plans','systematic-debugging','verification-before-completion',
       'triage','writing-for-agents','wizard','diagnosing-bugs','domain-modeling','tdd','code-review',
       'retro','to-spec','grilling','handoff','research','subagent-driven-development','executing-plans','using-git-worktrees','requesting-code-review','finishing-a-development-branch')
$B = @('nature-figure','nature-academic-search','nature-writing','nature-citation','nature-polishing',
       'nature-paper2ppt','nature-reader','bio-library')
$globalRoots = @(
  [pscustomobject]@{ Path = (Join-Path $env:USERPROFILE '.dsh\skills');    Label = '$DSH_HOME/skills' },
  [pscustomobject]@{ Path = (Join-Path $env:USERPROFILE '.agents\skills'); Label = '$DSH_AGENTS_HOME/skills' }
)
$vendored = Join-Path $destRoot 'VENDORED.md'

function Get-Stat([string]$p) {
  if (-not (Test-Path $p)) { return $null }
  $f = Get-ChildItem -Recurse -File $p -ErrorAction SilentlyContinue
  [pscustomobject]@{ Files = $f.Count; Bytes = ($f | Measure-Object Length -Sum).Sum }
}
function Find-Global([string]$name) {
  foreach ($r in $globalRoots) { $p = Join-Path $r.Path $name; if (Test-Path $p) { return $p } }
  return $null
}
function Get-SourceLabel([string]$name) {
  foreach ($r in $globalRoots) { if (Test-Path (Join-Path $r.Path $name)) { return $r.Label } }
  return '（全局未找到，来源为本机快照）'
}
function Get-LicenseName([string]$p) {
  $lic = (Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(LICENSE|COPYING|NOTICE)' } | Select-Object -First 1).Name
  if (-not $lic) { return '**无**' }
  return $lic
}
function New-VendoredRows([string[]]$names) {
  $date = Get-Date -Format 'yyyy-MM-dd'
  foreach ($n in $names) {
    $p = Join-Path $destRoot $n
    $st = Get-Stat $p
    $files = if ($st) { $st.Files } else { 0 }
    $bytes = if ($st) { $st.Bytes } else { 0 }
    $lic = if (Test-Path $p) { Get-LicenseName $p } else { '**无**' }
    "| ``{0}`` | {1} | {2} | {3} | {4} | {5} |" -f $n, (Get-SourceLabel $n), $date, $files, $bytes, $lic
  }
}
function Update-Vendored([string]$path) {
  if (-not (Test-Path $path)) { Write-Host "SKIP（未找到 VENDORED.md，无法重写表格）: $path"; return $false }
  $all = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
  $out = New-Object System.Collections.Generic.List[string]
  $i = 0; $changed = $false
  while ($i -lt $all.Count) {
    $line = $all[$i]
    if ($line -match '^>\s*生成时间：') {
      $out.Add("> 生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ｜ 生成源：随包快照目录（与全局根同源时逐项一致） ｜ 档位说明见项目内 ``CLAUDE.md`` 的「团队分工与协作」节（v4.2 技能条）")
      $changed = $true; $i++; continue
    }
    if ($line -match '^##\s*A 档' -or $line -match '^##\s*B 档') {
      $names = if ($line -match '^##\s*A 档') { $A } else { $B }
      $out.Add($line); $i++
      while ($i -lt $all.Count -and $all[$i] -notmatch '^\|') { $out.Add($all[$i]); $i++ }
      $h = 0
      while ($i -lt $all.Count -and $all[$i] -match '^\|' -and $h -lt 2) { $out.Add($all[$i]); $i++; $h++ }
      while ($i -lt $all.Count -and $all[$i] -match '^\|') { $i++ }
      foreach ($r in (New-VendoredRows $names)) { $out.Add($r) }
      $changed = $true; continue
    }
    $out.Add($line); $i++
  }
  if ($changed) {
    [System.IO.File]::WriteAllText($path, ($out -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "VENDORED 已重写: $path"
  }
  return $changed
}
function Resolve-Source {
  if ($Source -ne '') { if (-not (Test-Path $Source)) { Fail "-Source 指定路径不存在：$Source" }; return $Source }
  $d = Join-Path $root 'template\skills'
  if (Test-Path $d) { return $d }
  return $null
}

if ($List -or (-not ($Install -or $Refresh -or $Check))) {
  Write-Host "B 档技能（随 template/skills/ 携带，需 -Install）—— 目标：$destRoot"
  foreach ($s in $B) {
    $st = Get-Stat (Join-Path $destRoot $s)
    $g = Find-Global $s
    $state = if ($st) { "已安装（$($st.Files) 文件 / $($st.Bytes) 字节）" }
             elseif ($g) { "未安装（全局有：$g）" }
             else { "未安装（全局也没有）" }
    Write-Host ("  {0,-24} {1}" -f $s, $state)
  }
  Write-Host "`nA 档技能（随 skeleton/ 自动携带）—— 共 $($A.Count) 个"
  foreach ($s in $A) {
    $st = Get-Stat (Join-Path $destRoot $s)
    Write-Host ("  {0,-24} {1}" -f $s, $(if ($st) { "在位（$($st.Files) 文件）" } else { "**缺失**" }))
  }
  exit 0
}

if ($Install) {
  Assert-WritableProjectRoot
  $src = Resolve-Source
  if (-not $src) {
    Fail "找不到模板包内的 skills 目录。请用 -Source 指定，例如：-Source D:\path\to\template\skills"
  }
  New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
  foreach ($s in $B) {
    $from = Join-Path $src $s
    if (-not (Test-Path $from)) { Write-Host "SKIP（源缺失）: $s"; continue }
    $to = Join-Path $destRoot $s
    if (Test-Path $to) { Write-Host "SKIP（目标已存在，未覆盖）: $s —— 如需刷新请用 -Refresh"; continue }
    Copy-Item -LiteralPath $from -Destination $to -Recurse -Force
    Write-Host "INSTALLED: $s"
  }
  exit 0
}

if ($Refresh) {
  Assert-WritableProjectRoot
  New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
  $n = 0
  foreach ($s in ($A + $B)) {
    $g = Find-Global $s
    if (-not $g) { Write-Host "SKIP（全局无此技能，无法刷新）: $s"; continue }
    $to = Join-Path $destRoot $s
    if (Test-Path $to) { Remove-Item -LiteralPath $to -Recurse -Force }
    Copy-Item -LiteralPath $g -Destination $to -Recurse -Force
    $n++
    Write-Host "REFRESHED: $s  <- $g"
  }
  Update-Vendored $vendored | Out-Null
  Write-Host "`n已刷新 $n 个技能；VENDORED.md 两档表格已同步重写（若该文件缺失，请从模板包 skeleton 恢复）。"
  exit 0
}

if ($Check) {
  $missing = 0; $drift = 0
  foreach ($s in ($A + $B)) {
    $to = Get-Stat (Join-Path $destRoot $s)
    if (-not $to) { Write-Host "MISSING: $s"; $missing++; continue }
    $g = Find-Global $s
    if (-not $g) { continue }
    $gst = Get-Stat $g
    if ($gst -and ($gst.Files -ne $to.Files -or $gst.Bytes -ne $to.Bytes)) {
      Write-Host ("DRIFT: {0}  项目内 {1} 文件/{2} 字节  vs  全局 {3} 文件/{4} 字节" -f $s, $to.Files, $to.Bytes, $gst.Files, $gst.Bytes)
      $drift++
    }
  }
  Write-Host "`n检查完成：缺失 $missing 个，漂移 $drift 个。**本检查不阻断**（exit 0）；漂移可用 -Refresh 消除。"
  exit 0
}