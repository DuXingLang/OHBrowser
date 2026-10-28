# 验证报告：编译错误修复（WebDarkMode / FullScreenExitHandler）

- 任务：修复用户 DevEco 构建报出的 3 条 ArkTS 编译错误（`Browser.ets:405:39`、`TitleBar.ets:396:57`、`TitleBar.ets:396:82`）及同类字段 `Browser.ets:306`
- 日期：2026-10-28（第八轮）
- 环境：本机无 DevEco / SDK / hvigorw，编译结论待用户侧复核

## 一、根因

`WebDarkMode`、`FullScreenExitHandler` 声明在 Web 组件侧 `component/web.d.ts` 的**全局作用域**，`@ohos.web.webview` 命名空间没有导出它们。第四轮凭 `webview.WebDarkMode` 写法实现（当时无编译器），旧版踩坑 18 结论写反，错误一直潜伏到真机编译。

## 二、证据

1. 官方 API 12 文档示例（`.git/dsh-docs/web-attr.md`）：
   - `:1605-1622` darkMode 示例：`import { webview }` 后用裸 `WebDarkMode.On`；
   - `:5291-5313`、`:5331-5356` onFullScreenEnter/Exit 示例：裸写 `FullScreenExitHandler`。
2. 反向核对 `.git/dsh-docs/webview.md`：无这两个符号；`WebDownloadDelegate`/`WebCookieManager`/`WebStorage` 才以 `webview.X` 出现。
3. 项目内 `TitleBar.ets` 已有裸 `CacheMode.None` / `MixedMode.All` 且编译不报错，反证全局声明可用。

## 三、改动清单

| 文件 | 改动 |
| --- | --- |
| `entry/src/main/ets/model/Browser.ets:305-308` | 补注释；`fullScreenHandler: FullScreenExitHandler \| null = null` |
| `entry/src/main/ets/model/Browser.ets:407` | `enterWebFullScreen(handler: FullScreenExitHandler)` |
| `entry/src/main/ets/common/TitleBar.ets:16` | 删除不再使用的 `import webview from '@ohos.web.webview'` |
| `entry/src/main/ets/common/TitleBar.ets:395-396` | 补注释；`darkMode(... ? WebDarkMode.On : WebDarkMode.Auto)` |
| `tests/check-structure.mjs:43-97` | 新增 `maskComments()`（注释替换为等长空格） |
| `tests/check-structure.mjs:418-432` | 新增 4.3 规则，拦截 `webview.WebDarkMode` / `webview.FullScreenExitHandler` |

规模：3 文件 +76/−6（`git diff --stat`）。

## 四、验证结果

| 检查 | 结果 |
| --- | --- |
| `node --test` | 20 pass / 0 fail |
| `node tests/check-json5.mjs` | 8 个 json5 通过 |
| `node tests/check-resources.mjs` | 23 个源文件 83 处引用 + 4 个配置 16 处引用，全部命中 |
| `node tests/check-structure.mjs` | 23 文件 38 导入 / 7 ForEach / 8 TAG / 6 个 @ObjectLink 组件 8 处调用 / 4 HTML 通过 |
| 新增规则有效性 | 临时探针文件 `entry/src/main/ets/model/__probe.ets` 写入两处错误写法 → 恰好 2 条报错；删除后全绿 |
| 源码残留检查 | `grep "webview\.WebDarkMode\|webview\.FullScreenExitHandler"` 无命中（注释中的反面示例已被 `maskComments` 排除） |

## 五、自检评分

| 项 | 评价 |
| --- | --- |
| 代码质量 | 最小改动，未触碰相邻逻辑；删除改后成为孤儿的 `webview` 导入 |
| 测试覆盖 | 单测与三项静态检查全绿；新增规则带探针回归验证 |
| 依赖完整性 | 无新增依赖；仅用 Node 内置能力 |
| 命名规范 | 与项目既有 CamelCase / 中文注释一致 |
| 架构一致性 | 改动限于既有 model/common/tests 三层 |

**自评：95 分（通过）**。扣分项：本机无法真实编译，编译结论需用户在有 DevEco 的机器上复核（`hvigorw assembleHap`）。

## 六、遗留与风险

- 用户重新整包编译，确认 3 条错误消失；顺带点一遍全屏进出与 `forceDark` 深色适配。
- 工作区改动未提交（用户未要求 commit/push）。