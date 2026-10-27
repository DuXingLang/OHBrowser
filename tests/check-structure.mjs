// 结构校验（ArkTS/HTML 静态检查）
// 校验目标：
//   1. 相对导入的模块文件存在，且被导入的符号确实由目标文件导出（ArkTS 编译期报错高发点）
//   2. ForEach 调用带齐三个参数（数组、itemGenerator、keyGenerator），5.x 上缺 keyGenerator 会告警/渲染异常
//   3. rawfile 内 HTML：非空元素不得自闭合、CSS 不得混入全角标点、本地图片引用存在、
//      getElementById / on* 事件绑定的函数必须已定义、etsObj 方法必须已在 ArkTS 侧注册
// 运行：node tests/check-structure.mjs
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const problems = [];
const fail = (msg) => problems.push(msg);
const rel = (p) => relative(ROOT, p).replace(/\\/g, '/');

function walk(dir, out = []) {
  if (!existsSync(dir)) {
    return out;
  }
  for (const ent of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, ent.name);
    if (ent.isDirectory()) {
      walk(p, out);
    } else {
      out.push(p);
    }
  }
  return out;
}

function lineOf(text, index) {
  let line = 1;
  for (let i = 0; i < index && i < text.length; i++) {
    if (text[i] === '\n') {
      line++;
    }
  }
  return line;
}

const sources = [
  ...walk(join(ROOT, 'entry/src/main/ets')),
  ...walk(join(ROOT, 'entry/src/ohosTest/ets'))
].filter((f) => /\.(ets|ts)$/.test(f));

// ---------- 1) 导入符号校验 ----------

/** 收集目标文件对外导出的名字（含 default） */
function exportedNames(text) {
  const names = new Set();
  for (const m of text.matchAll(
    /export\s+(?:default\s+)?(?:declare\s+)?(?:abstract\s+)?(?:struct|class|function|enum|const|let|var|interface|type)\s+([A-Za-z_$][\w$]*)/g
  )) {
    names.add(m[1]);
  }
  for (const m of text.matchAll(/export\s*\{([^}]*)\}\s*(?:from\s*['"][^'"]+['"])?/g)) {
    for (const part of m[1].split(',')) {
      const t = part.trim();
      if (!t) {
        continue;
      }
      const parts = t.split(/\s+as\s+/);
      names.add((parts[1] ?? parts[0]).trim());
    }
  }
  if (/export\s+default\b/.test(text)) {
    names.add('default');
  }
  return names;
}

/** 解析 import 子句，返回需要校验的导出名（default 表示默认导出，* 表示命名空间，跳过符号校验） */
function parseImportClause(clause) {
  const wanted = [];
  const named = clause.match(/\{([^}]*)\}/);
  if (named) {
    for (const part of named[1].split(',')) {
      const t = part.trim().replace(/^type\s+/, '');
      if (!t) {
        continue;
      }
      wanted.push(t.split(/\s+as\s+/)[0].trim());
    }
  }
  if (/\*\s+as\s+[\w$]+/.test(clause)) {
    return wanted; // 命名空间导入，无法静态校验成员
  }
  const rest = clause.replace(/\{[^}]*\}/, '').trim();
  if (/^[A-Za-z_$][\w$]*$/.test(rest)) {
    wanted.push('default');
  } else if (/^type\s+[A-Za-z_$][\w$]*$/.test(rest)) {
    wanted.push('default');
  }
  return wanted;
}

function resolveModule(fromFile, spec) {
  const base = join(dirname(fromFile), spec);
  const candidates = [base, `${base}.ets`, `${base}.ts`, join(base, 'index.ets'), join(base, 'index.ts')];
  return candidates.find((p) => existsSync(p) && statSync(p).isFile()) ?? null;
}

const exportCache = new Map();
let importCount = 0;
for (const file of sources) {
  const text = readFileSync(file, 'utf8');
  for (const m of text.matchAll(/import\s+([^;'"\n]+?)\s+from\s+['"](\.[^'"]+)['"]/g)) {
    const clause = m[1];
    const spec = m[2];
    importCount++;
    const target = resolveModule(file, spec);
    if (!target) {
      fail(`${rel(file)}:${lineOf(text, m.index)} 导入 '${spec}' 无法解析到文件`);
      continue;
    }
    let exported = exportCache.get(target);
    if (!exported) {
      exported = exportedNames(readFileSync(target, 'utf8'));
      exportCache.set(target, exported);
    }
    for (const name of parseImportClause(clause)) {
      const ok = name === 'default'
        ? exported.has('default')
        : exported.has(name);
      if (!ok) {
        fail(`${rel(file)}:${lineOf(text, m.index)} 导入了 ${name === 'default' ? '默认导出' : name}，` +
          `但 ${rel(target)} 未导出该符号`);
      }
    }
  }
}

// ---------- 2) ForEach 参数个数校验 ----------

/** 按顶层逗号切分实参（忽略字符串与括号内部） */
function splitTopLevel(text) {
  const parts = [];
  let depth = 0;
  let current = '';
  let quote = '';
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (quote) {
      current += ch;
      if (ch === '\\') {
        current += text[++i] ?? '';
      } else if (ch === quote) {
        quote = '';
      }
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') {
      quote = ch;
      current += ch;
      continue;
    }
    if (ch === '(' || ch === '[' || ch === '{') {
      depth++;
    } else if (ch === ')' || ch === ']' || ch === '}') {
      depth--;
    }
    if (ch === ',' && depth === 0) {
      parts.push(current.trim());
      current = '';
      continue;
    }
    current += ch;
  }
  if (current.trim()) {
    parts.push(current.trim());
  }
  return parts;
}

let forEachCount = 0;
for (const file of sources) {
  const text = readFileSync(file, 'utf8');
  let idx = 0;
  while ((idx = text.indexOf('ForEach(', idx)) !== -1) {
    const open = idx + 'ForEach'.length;
    let depth = 0;
    let i = open;
    for (; i < text.length; i++) {
      if (text[i] === '(') {
        depth++;
      } else if (text[i] === ')') {
        depth--;
        if (depth === 0) {
          break;
        }
      }
    }
    const args = splitTopLevel(text.slice(open + 1, i));
    forEachCount++;
    if (args.length < 3 || !args[2]) {
      fail(`${rel(file)}:${lineOf(text, idx)} ForEach 缺少第三个参数 keyGenerator`);
    }
    idx = i + 1;
  }
}

// ---------- 3) rawfile HTML 校验 ----------

const rawfileDir = join(ROOT, 'entry/src/main/resources/rawfile');
const htmlFiles = readdirSync(rawfileDir).filter((f) => f.endsWith('.html'));
// 非空（有闭合标签）的元素不允许自闭合写法
const VOID_TAGS = new Set(['br', 'hr', 'img', 'input', 'meta', 'link', 'source', 'area', 'base', 'col', 'embed', 'param', 'track', 'wbr']);

for (const name of htmlFiles) {
  const file = join(rawfileDir, name);
  const text = readFileSync(file, 'utf8');

  // 3.1 非空元素自闭合
  for (const m of text.matchAll(/<([a-zA-Z][\w-]*)\b[^>]*?\/>/g)) {
    if (!VOID_TAGS.has(m[1].toLowerCase())) {
      fail(`${rel(file)}:${lineOf(text, m.index)} <${m[1]} …/> 自闭合写法不合法（HTML 会吞掉后续节点）`);
    }
  }

  // 3.2 CSS 区（<style> 与 style="…"）中不得出现全角标点
  const styleBlocks = [
    ...[...text.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)].map((m) => ({ body: m[1], index: m.index })),
    ...[...text.matchAll(/style\s*=\s*"([^"]*)"/gi)].map((m) => ({ body: m[1], index: m.index }))
  ];
  for (const block of styleBlocks) {
    // 注释里的中文标点不影响解析，先剔除 CSS 注释再检查真实声明
    const body = block.body.replace(/\/\*[\s\S]*?\*\//g, '');
    const bad = body.match(/[：；，（）【】、！]/);
    if (bad) {
      fail(`${rel(file)}:${lineOf(text, block.index)} CSS 中出现全角字符 "${bad[0]}"，样式声明将失效`);
    }
  }

  // 3.3 本地图片引用存在
  for (const m of text.matchAll(/(?:src|href|url\()\s*=?\s*["']?(?:\.\/)?([\w.-]+\.(?:png|jpg|jpeg|svg|ico|gif))["')]/gi)) {
    if (!existsSync(join(rawfileDir, m[1]))) {
      fail(`${rel(file)}:${lineOf(text, m.index)} 引用的资源 ${m[1]} 不存在`);
    }
  }

  // 3.4 getElementById 的 id 必须存在
  for (const m of text.matchAll(/getElementById\(\s*['"]([^'"]+)['"]\s*\)/g)) {
    const id = m[1];
    if (!new RegExp(`id\\s*=\\s*["']${id}["']`).test(text)) {
      fail(`${rel(file)}:${lineOf(text, m.index)} getElementById('${id}') 找不到对应 id 元素`);
    }
  }

  // 3.5 on* 事件属性里调用的函数必须已定义
  const definedFns = new Set([
    ...[...text.matchAll(/function\s+([A-Za-z_$][\w$]*)\s*\(/g)].map((m) => m[1]),
    ...[...text.matchAll(/(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?(?:function|\()/g)].map((m) => m[1])
  ]);
  for (const m of text.matchAll(/\bon[a-z]+\s*=\s*"([^"]*)"/g)) {
    for (const call of m[1].matchAll(/([A-Za-z_$][\w$]*)\s*\(/g)) {
      const fn = call[1];
      if (['if', 'for', 'while', 'return', 'function'].includes(fn)) {
        continue;
      }
      if (!definedFns.has(fn)) {
        fail(`${rel(file)}:${lineOf(text, m.index)} 事件属性调用的函数 ${fn} 未定义`);
      }
    }
  }

  // 3.6 etsObj.xxx 调用必须已在 ArkTS 侧注册
  const proxyCall = readFileSync(join(ROOT, 'entry/src/main/ets/common/TitleBar.ets'), 'utf8')
    .match(/registerJavaScriptProxy\([^,]+,\s*'etsObj',\s*\[([^\]]*)\]/);
  if (proxyCall) {
    const registered = new Set(proxyCall[1].split(',').map((s) => s.trim().replace(/^['"]|['"]$/g, '')).filter(Boolean));
    for (const m of text.matchAll(/etsObj\.([A-Za-z_$][\w$]*)\s*\(/g)) {
      if (!registered.has(m[1])) {
        fail(`${rel(file)}:${lineOf(text, m.index)} 调用了 etsObj.${m[1]}，但 registerJavaScriptProxy 未注册该方法`);
      }
    }
  }
}

if (problems.length > 0) {
  console.error(`[check-structure] 发现 ${problems.length} 处结构问题：`);
  for (const p of problems) {
    console.error(`  ✗ ${p}`);
  }
  process.exit(1);
}
console.log(
  `[check-structure] 通过：${sources.length} 个源文件 ${importCount} 处相对导入、${forEachCount} 处 ForEach、` +
  `${htmlFiles.length} 个 HTML 全部符合结构约束。`
);