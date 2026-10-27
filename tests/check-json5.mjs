/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * JSON5 配置语法校验：解析全部 json5 文件，失败即非零退出。
 * 仅用于本地可信配置文件校验（new Function 解析，不适用于不可信输入）。
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (name === 'node_modules' || name === '.hvigor' || name === '.git' || name === '.idea') continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      walk(p, out);
    } else if (p.endsWith('.json5')) {
      out.push(p);
    }
  }
  return out;
}

const files = walk(ROOT);
let failed = 0;
for (const file of files) {
  const text = readFileSync(file, 'utf8')
    .replace(/^\s*\/\*[\s\S]*?\*\//gm, ''); // 去掉文件头块注释
  try {
    new Function(`return (${text})`)();
    console.log(`✔ ${relative(ROOT, file)}`);
  } catch (e) {
    console.error(`✖ ${relative(ROOT, file)}: ${e.message}`);
    ++failed;
  }
}

if (failed > 0) {
  console.error(`${failed} 个 json5 文件解析失败`);
  process.exit(1);
}
console.log('全部 json5 配置解析通过');
