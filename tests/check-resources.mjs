// 静态资源引用校验
// 校验目标：源码里的 $r('app.type.name')、$rawfile('file')，以及 json5 配置里的 $string:/$media:/$color:/$profile: 引用
//            必须能在对应 resources 目录中找到定义，否则编译期会直接失败（资源不存在是 HAP 构建失败的高频原因）
// 运行：node tests/check-resources.mjs
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const problems = [];
const warn = (msg) => problems.push(msg);
const rel = (p) => relative(ROOT, p).replace(/\\/g, '/');

/** 递归遍历目录，返回文件绝对路径列表 */
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

/** 读取 element/<key>.json 中定义的所有资源名 */
function elementNames(dir, key) {
  const file = join(dir, `${key}.json`);
  if (!existsSync(file)) {
    return [];
  }
  const json = JSON.parse(readFileSync(file, 'utf8'));
  return (json[key] ?? []).map((item) => item.name);
}

/** 收集一个 resources 目录下所有限定词目录（base/dark/en_US…）的资源定义 */
function collectResources(resDir) {
  const res = { color: new Set(), string: new Set(), media: new Set(), profile: new Set(), rawfile: new Set() };
  if (!existsSync(resDir)) {
    return res;
  }
  for (const ent of readdirSync(resDir, { withFileTypes: true })) {
    if (!ent.isDirectory()) {
      continue;
    }
    if (ent.name === 'rawfile') {
      for (const f of readdirSync(join(resDir, 'rawfile'))) {
        res.rawfile.add(f);
      }
      continue;
    }
    const qdir = join(resDir, ent.name);
    for (const key of ['color', 'string']) {
      for (const n of elementNames(join(qdir, 'element'), key)) {
        res[key].add(n);
      }
    }
    const mediaDir = join(qdir, 'media');
    if (existsSync(mediaDir)) {
      for (const f of readdirSync(mediaDir)) {
        const dot = f.lastIndexOf('.');
        if (dot > 0) {
          res.media.add(f.slice(0, dot));
        }
      }
    }
    const profileDir = join(qdir, 'profile');
    if (existsSync(profileDir)) {
      for (const f of readdirSync(profileDir)) {
        const dot = f.lastIndexOf('.');
        res.profile.add(dot > 0 ? f.slice(0, dot) : f);
      }
    }
  }
  return res;
}

const MAIN_RES = collectResources(join(ROOT, 'entry/src/main/resources'));
const TEST_RES = collectResources(join(ROOT, 'entry/src/ohosTest/resources'));
const APP_RES = collectResources(join(ROOT, 'AppScope/resources'));

// 1) 扫描源码中的 $r / $rawfile 引用
const sourceRoots = [join(ROOT, 'entry/src/main/ets'), join(ROOT, 'entry/src/ohosTest/ets')];
const sources = sourceRoots.flatMap((dir) => walk(dir)).filter((f) => /\.(ets|ts)$/.test(f));
let resourceRefCount = 0;
for (const file of sources) {
  const text = readFileSync(file, 'utf8');
  const isTest = /[\\/]ohosTest[\\/]/.test(file);
  const res = isTest ? TEST_RES : MAIN_RES;
  const resName = isTest ? 'ohosTest/resources' : 'main/resources';
  for (const m of text.matchAll(/\$r\(\s*['"]app\.(\w+)\.(\w+)['"]\s*\)/g)) {
    const type = m[1];
    const name = m[2];
    resourceRefCount++;
    // 图片类资源允许通过 .png/.svg 后缀引用同一资源，这里统一按不带后缀名比对
    const lookup = type === 'media' ? name : name;
    if (!res[type]) {
      warn(`${rel(file)}: 未知资源类型 app.${type}（应为 color/string/media/float/…）`);
    } else if (!res[type].has(lookup)) {
      warn(`${rel(file)}: $r('app.${type}.${lookup}') 在 ${resName} 中不存在`);
    }
  }
  for (const m of text.matchAll(/\$rawfile\(\s*['"]([^'"]+)['"]\s*\)/g)) {
    resourceRefCount++;
    if (!res.rawfile.has(m[1])) {
      warn(`${rel(file)}: $rawfile('${m[1]}') 在 ${resName}/rawfile 中不存在`);
    }
  }
}

// 2) 扫描配置文件的资源引用（$string:xxx / $media:xxx / $color:xxx / $profile:xxx）
const configFiles = [
  [join(ROOT, 'entry/src/main/module.json5'), MAIN_RES, 'main/resources'],
  [join(ROOT, 'entry/src/ohosTest/module.json5'), TEST_RES, 'ohosTest/resources'],
  [join(ROOT, 'AppScope/app.json5'), APP_RES, 'AppScope/resources'],
  [join(ROOT, 'build-profile.json5'), APP_RES, 'AppScope/resources']
];
let configRefCount = 0;
for (const [file, res, resName] of configFiles) {
  if (!existsSync(file)) {
    continue;
  }
  const text = readFileSync(file, 'utf8');
  for (const m of text.matchAll(/\$(string|media|color|profile):([\w.]+)/g)) {
    const type = m[1];
    const name = m[2];
    configRefCount++;
    if (!res[type] || !res[type].has(name)) {
      warn(`${rel(file)}: $${type}:${name} 在 ${resName} 中不存在`);
    }
  }
}

if (problems.length > 0) {
  console.error(`[check-resources] 发现 ${problems.length} 处资源引用问题：`);
  for (const p of problems) {
    console.error(`  ✗ ${p}`);
  }
  process.exit(1);
}
console.log(
  `[check-resources] 通过：${sources.length} 个源文件 ${resourceRefCount} 处源码资源引用、` +
  `${configFiles.length} 个配置文件 ${configRefCount} 处配置资源引用全部命中。`
);