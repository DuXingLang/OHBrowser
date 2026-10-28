## 项目上下文摘要：编译错误修复（WebDarkMode / FullScreenExitHandler）

生成时间：2026-10-28 15:10（第八轮）

### 任务与现象

用户在有 DevEco 的机器上编译，报出 3 条错误（路径为 D:/SXD/...，本工作目录 `D:\project\Browser` 为同一源码）：

1. `Browser.ets:405:39`：`Namespace 'webview' has no exported member 'FullScreenExitHandler'`
2. `TitleBar.ets:396:57`：`Property 'WebDarkMode' does not exist on type 'typeof webview'`
3. `TitleBar.ets:396:82`：同上

另有同类型字段声明 `Browser.ets:306`（`webview.FullScreenExitHandler`）。

### 相似实现（≥3，均为官方 API 12 文档示例，本地副本 `.git/dsh-docs/`）

1. `.git/dsh-docs/web-attr.md:1605-1622`（`.darkMode()` 示例）：虽然 `import { webview } from '@kit.ArkWeb';`，但枚举写法是裸 `@State mode: WebDarkMode = WebDarkMode.On;`。
2. `.git/dsh-docs/web-attr.md:5291-5313`（`.onFullScreenEnter()` 示例）：`handler: FullScreenExitHandler | null = null;` 裸写。
3. `.git/dsh-docs/web-attr.md:5331-5356`（`.onFullScreenExit()` 示例）：同样裸写 `FullScreenExitHandler`。
4. 反向证据：`.git/dsh-docs/webview.md`（`@ohos.web.webview` 的 js-apis）全文检索无 `WebDarkMode` / `FullScreenExitHandler`；而 `WebDownloadDelegate`、`WebDownloadItem`、`WebCookieManager`、`WebStorage` 都以 `webview.X` 形式出现 → 两类符号归属不同的声明文件（`component/web.d.ts` 全局 vs `@ohos.web.webview` 命名空间）。

### 项目内既有约定

- 全局枚举裸用：`TitleBar.ets:393` `CacheMode.None` / `CacheMode.Default`、`:387` `MixedMode.All`，编译未报错，反证全局声明在该文件可用。
- 静态检查层：`tests/check-structure.mjs` 原有规则（相对导入符号、ForEach 三参数、TAG 声明、@ObjectLink 传参、rawfile HTML）；本次新增 4.3 全局符号归属规则。
- 注释/文档/提交信息一律简体中文；本机无 SDK，验证靠 `node --test` + 静态检查 + 文档核对。

### 修改点

| 文件:行 | 改动 |
| --- | --- |
| `entry/src/main/ets/model/Browser.ets:305-308` | 补注释；字段 `private fullScreenHandler: FullScreenExitHandler \| null = null`（去 `webview.` 前缀） |
| `entry/src/main/ets/model/Browser.ets:407` | `enterWebFullScreen(handler: FullScreenExitHandler)`（去前缀） |
| `entry/src/main/ets/common/TitleBar.ets:16` | 删除 `import webview from '@ohos.web.webview';`（改后无引用） |
| `entry/src/main/ets/common/TitleBar.ets:395-396` | 补注释；`.darkMode(this.settings.forceDark ? WebDarkMode.On : WebDarkMode.Auto)` |
| `tests/check-structure.mjs:43-97` | 新增 `maskComments()`：把 `//` 与 `/* */` 注释替换为等长空格，供符号匹配使用 |
| `tests/check-structure.mjs:418-432` | 新增 4.3 规则：`webview.WebDarkMode` / `webview.FullScreenExitHandler` 出现即失败 |

### 测试模式

- 单测：`node --test`（Node 内置 test runner），本轮 20 pass / 0 fail。
- 静态检查：`node tests/check-json5.mjs`（8 个 json5）、`node tests/check-resources.mjs`（23 文件 83 处引用）、`node tests/check-structure.mjs`（23 文件 38 导入 / 7 ForEach / 8 TAG / 6 个 @ObjectLink 组件 8 处调用 / 4 HTML）。
- 回归验证方式：临时在 `entry/src/main/ets/model/__probe.ets` 写入两处错误写法，运行检查器得到恰好 2 条报错，随后删除探针恢复全绿。