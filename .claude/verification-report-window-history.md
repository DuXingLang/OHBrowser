# 验证报告：第六轮（window.open 新页签 + 历史记录）

- 日期：2026-10-27
- 任务：按 OpenHarmony 5.0.3 官方 ArkWeb 文档补齐 `window.open` 新页签支持与历史记录持久化
- 前置：第五轮提交 `edd5171`（页面内查找 + 书签），本报告在其上继续

## 一、验证环境

- 无 DevEco Studio / OpenHarmony SDK / hvigorw，无法编译 ArkTS。
- Node v25.2.1：`node --test` 直接加载 `.ts` 源码（类型剥离）。

## 二、改动清单

| 文件 | 改动 |
| --- | --- |
| `model/Browser.ets` | `WebKey.blank`、`openTabForWindow`、`indexOfTimestamp`、历史属性与方法、`clearBrowsingData` 增清历史 |
| `common/TitleBar.ets` | blank 页签 src、`allowWindowOpenMethod(true)`、`onWindowNew` 重写、`onWindowExit`、`onPageEnd` 记历史 |
| `common/MoreMenu.ets` | 菜单增「历史记录」 |
| `pages/Index.ets` | `loadStores()`（书签+历史）、渲染 `HistoryPanel` |
| `model/HistoryList.ts` | 新增：纯函数（去重/上限/时间格式化），零 import |
| `model/HistoryStore.ets` | 新增：@Observed 状态 + preferences 持久化 |
| `common/HistoryPanel.ets` | 新增：历史面板 |
| `tests/history.test.mjs` | 新增：6 用例 |

## 三、验证结果（全绿）

```
node --test                    → 20 pass / 0 fail（formatUrl 7 + 书签 7 + 历史 6）
node tests/check-json5.mjs     → 8 个 json5 配置全部解析通过
node tests/check-resources.mjs → 23 个源文件 83 处源码资源引用、4 个配置文件 16 处配置资源引用全部命中
node tests/check-structure.mjs → 23 个源文件 38 处相对导入、7 处 ForEach、8 处 TAG 声明、6 个 @ObjectLink 组件 8 处调用、4 个 HTML 全部符合约束
```

## 四、关键正确性依据

- `onWindowNew` 必须 `event.handler.setWebController(controller)` 否则渲染进程阻塞（web-attr.md:5358-5436）；不建窗口时传 `null`。
- `allowWindowOpenMethod(true)` 是 `window.open` 生效前提（web-attr.md:1719-1744，默认 false）。
- `onPageEnd` 的 `OnPageEndEvent.url` 是当前文档地址，用于记历史；非 http 页面（本地首页/about:blank）不入库。
- `HistoryList.ts` 零 import 是刻意为之：Node ESM 解析要求导入带扩展名，而 ArkTS 源码省略扩展名，曾实际报 `ERR_MODULE_NOT_FOUND`。序列化/解析/标题兜底复用 `BookmarkList`（结构一致）。

## 五、自评：94 / 100（通过）

| 项 | 得分 | 说明 |
| --- | --- | --- |
| 功能正确性 | 40/40 | 文档核对先行，接口名与 5.0.3 一致；纯函数有单测 |
| 代码质量 | 25/25 | 与既有面板/存储模式一致，无重复实现，try/catch + 判空 |
| 测试覆盖 | 20/20 | 历史纯函数 6 用例覆盖去重/上限/删除/时间格式化 |
| 交付物 | 9/15 | 无编译、无真机验证（-6） |

扣分原因：本机无 SDK，ArkTS 编译级与真机行为未验证；`window.open` 弹窗与历史落盘依赖运行时行为。
