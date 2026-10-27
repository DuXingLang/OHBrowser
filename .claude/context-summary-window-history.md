# 上下文摘要：第六轮（window.open 新页签 + 历史记录）

- 日期：2026-10-27
- 任务来源：用户「请继续」→ 按 OpenHarmony 5.0.3 官方 ArkWeb 文档补齐能力。

## 文档依据（本地副本）

- `.git/dsh-docs/web-attr.md`：`onWindowNew`(5358-5436)、`onWindowExit`(5437-5471)、`OnWindowNewEvent`(10209-10220)、`ControllerHandler.setWebController`(7303-7315)、`allowWindowOpenMethod`(1719-1744)。
- `.git/dsh-docs/webview.md`：`WebviewController.getUrl/getTitle`。
- `.git/dsh-docs/preferences.md`：`getPreferencesSync`(343)、`putSync`(1515)、`getSync`(1242)、`flush`(1853)（无 flushSync，14+）。

## 关键决策

- `window.open` 弹出页签用 `blank: true` 页签 + `src: ''`，由内核接管，不顶掉当前页；`setWebController(created.controller)` 必须在回调内调用。
- 历史 `HistoryList.ts` **零 import**：Node ESM 要求导入带扩展名而 ArkTS 省略扩展名，曾报 `ERR_MODULE_NOT_FOUND`；宁可零依赖也不引 loader hook。序列化/解析/标题兜底复用 `BookmarkList`（结构一致）。
- 历史与书签共用 `browser_store` 首选项实例（Key `history` / `bookmarks`），确保「清除浏览数据」不漏清。
- 历史在 `onPageEnd` 写入（标题随页取，避免记成「新页签」）；仅 http 开头入库。

## 关键签名/常量（勿凭空发明）

- `addHistory(list, entry)`：空 URL 忽略；同址 filter 后 unshift；`slice(0, 200)`。
- `HISTORY_MAX_COUNT = 200`。
- `formatHistoryTime(time)`：`月-日 时:分`，`time<=0` 返回空串。
- `HistoryStore`：`items/visible`，`init(context)`、`add(entry)`、`remove(url)`、`clear()`、`persist()`。
- `Browser.recordHistory(url, title)`、`openHistory()`、`closeHistory()`、`initHistory(context)`。
- `WebKey.blank`、`openTabForWindow(targetUrl): WebObject | null`、`indexOfTimestamp(timestamp): number`。

## 相关文件

- `entry/src/main/ets/model/HistoryList.ts`、`HistoryStore.ets`
- `entry/src/main/ets/common/HistoryPanel.ets`
- `entry/src/main/ets/model/Browser.ets`、`common/TitleBar.ets`、`common/MoreMenu.ets`、`pages/Index.ets`
- `tests/history.test.mjs`

## 校验

`node --test` 20 pass；check-json5 8 通过；check-resources 23 文件 83 处；check-structure 23 文件 38 导入 / 7 ForEach / 8 TAG / 6 @ObjectLink 组件 8 处调用 / 4 HTML。
