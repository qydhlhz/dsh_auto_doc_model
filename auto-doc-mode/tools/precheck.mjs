// Auto_Doc 模式 bundle 预检：改完 cordis.patch.yml / rules / skills 后、重装前跑一遍。
//   node tools/precheck.mjs [cordis.patch.yml 路径]
// 检查三件事：
//   1) `!!js |` 块表达式按加载器上下文求值 → 目录/正文是否正确（占位符已替换、路径真实存在）；
//   2) 每个技能目录都是 <name>/SKILL.md 形态（skill-filesystem 只认这一层）；
//   3) patch 里引用的每个插件包名都能在 dsh 安装树里解析（名字打错会让 preset 激活失败）。
// 说明：本脚本只读，不改 profile；真正安装仍要走 plugin_manager install_bundle。
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = path.dirname(fileURLToPath(import.meta.url));
const bundleDir = path.resolve(here, '..');
const patchPath = process.argv[2] ? path.resolve(process.argv[2]) : path.join(bundleDir, 'cordis.patch.yml');
const problems = [];

// ---------- 1) !!js 块表达式求值 ----------
const lines = fs.readFileSync(patchPath, 'utf8').split(/\r?\n/);
const blocks = [];
for (let i = 0; i < lines.length; i++) {
  if (!/!!js\s*\|\s*$/.test(lines[i])) continue;
  const indent = lines[i].match(/^\s*/)[0].length;
  const buf = [];
  let j = i + 1;
  for (; j < lines.length; j++) {
    if (lines[j].trim() === '') { buf.push(''); continue; }
    if (lines[j].match(/^\s*/)[0].length <= indent) break;
    buf.push(lines[j]);
  }
  blocks.push({ line: i + 1, code: buf.join('\n') });
  i = j - 1;
}
console.log(`[1] !!js 块表达式: ${blocks.length} 个`);
// 两遍：先求值拿到全部返回值（目录型块给出权威安装目录），再对正文块做路径锚定断言。
const evaluated = blocks.map((blk, k) => {
  try {
    const value = new Function('baseUrl', 'process', 'ctx', `return (${blk.code});`)(
      patchPath, process, { get: () => undefined });
    return { k, line: blk.line, value };
  } catch (err) {
    problems.push(`块 #${k} (行 ${blk.line}) 求值抛错: ${String(err.message ?? err).split('\n')[0]}`);
    return { k, line: blk.line, value: undefined };
  }
});
const resolvedDirs = evaluated.filter((e) => typeof e.value === 'string'
  && fs.existsSync(e.value) && fs.statSync(e.value).isDirectory()).map((e) => e.value);
const textAnchors = [bundleDir, ...resolvedDirs.map((d) => path.dirname(d))];

for (const e of evaluated) {
  if (typeof e.value !== 'string') {
    if (e.value !== undefined) problems.push(`块 #${e.k}: 期望字符串，实得 ${typeof e.value}`);
    continue;
  }
  if (resolvedDirs.includes(e.value)) {
    const entries = fs.readdirSync(e.value);
    const notSkill = entries.filter((n) => !fs.existsSync(path.join(e.value, n, 'SKILL.md')));
    console.log(`    块 #${e.k} (行 ${e.line}) → 目录 ${e.value}；条目 ${entries.length} 个`);
    if (notSkill.length) problems.push(`块 #${e.k}: 技能根里这些条目不是 <name>/SKILL.md：${notSkill.join(', ')}`);
    continue;
  }
  if (/\{\{/.test(e.value)) problems.push(`块 #${e.k}: persona 正文含 {{...}}，会与 prompt 变量语法冲突`);
  if (e.value.includes('@@')) problems.push(`块 #${e.k}: persona 正文残留未替换的 @@ 占位符`);
  const anchored = textAnchors.filter((a) => e.value.includes(a));
  console.log(`    块 #${e.k} (行 ${e.line}) → 正文 ${e.value.length} 字符；锚定目录 ${anchored.length ? anchored.join(' / ') : '无'}`);
  if (!anchored.length) problems.push(`块 #${e.k}: persona 正文未引用任何已知 bundle 目录（候选：${textAnchors.join(' | ')}）`);
}

// ---------- 2) 技能目录形态 ----------
const skillsDir = path.join(bundleDir, 'skills');
const skillNames = fs.readdirSync(skillsDir).filter((n) => fs.statSync(path.join(skillsDir, n)).isDirectory());
const broken = skillNames.filter((n) => !fs.existsSync(path.join(skillsDir, n, 'SKILL.md')));
const flat = fs.readdirSync(skillsDir).filter((n) => n.endsWith('.md'));
console.log(`[2] skills/: ${skillNames.length} 个技能目录；平铺 .md 文件 ${flat.length} 个（应为 0，否则会被当技能条目）`);
if (broken.length) problems.push(`skill 目录缺 SKILL.md：${broken.join(', ')}`);
if (flat.length) problems.push(`skills/ 根下不应有平铺 .md：${flat.join(', ')}`);

// ---------- 3) 插件包名可解析 ----------
// 安装树候选按环境变量推导（不写死本机路径）：全局 npm 前缀 + 当前 node 可执行文件同级。
const installBases = [
  process.env.APPDATA
    ? path.join(process.env.APPDATA, 'npm', 'node_modules', '@deepseek-ai', 'dsh', 'node_modules') + path.sep
    : null,
  path.join(path.dirname(process.execPath), 'node_modules') + path.sep,
].filter(Boolean);
let reqInstall = null;
for (const base of installBases) {
  try { reqInstall = createRequire(base); reqInstall.resolve('@deepseek-ai/dsh-persona/package.json'); break; } catch { reqInstall = null; }
}
const names = [...new Set([...fs.readFileSync(patchPath, 'utf8').replace(/!!js /g, '')
  .matchAll(/^\s*name:\s*'([^']+)'\s*$/gm)].map((m) => m[1]))].filter((n) => !n.startsWith('cordis:'));
let unresolved = [];
if (reqInstall) {
  for (const n of names) {
    const segs = n.split('/');
    const isSubpath = segs.length > 2 || (n.startsWith('@') && segs.length > 2);
    try {
      if (isSubpath) reqInstall.resolve(n); else reqInstall.resolve(`${n}/package.json`);
    } catch { unresolved.push(n); }
  }
  console.log(`[3] patch 引用插件包名 ${names.length} 个；未能解析 ${unresolved.length} 个${reqInstall ? '' : '（未找到 dsh 安装树，跳过）'}`);
  if (unresolved.length) problems.push(`插件包名无法解析：${unresolved.join(', ')}`);
} else {
  console.log('[3] 跳过：未能在标准 npm 前缀下定位 dsh 安装树');
}

console.log(`\n== 预检结论: ${problems.length === 0 ? 'PASS' : 'FAIL' + '\n - ' + problems.join('\n - ')} ==`);
process.exit(problems.length === 0 ? 0 : 1);
