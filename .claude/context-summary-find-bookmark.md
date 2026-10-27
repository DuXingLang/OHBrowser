# 上下文摘要：页面内查找 + 书签持久化（第五轮）

生成时间：2026-10-27
任务来源：用户「请继续」（承接 m00001 的四项优化目标，按 OpenHarmony 5.0.3 ArkWeb 官方文档继续补功能）

## 一、需求拆解

1. 页面内查找：关键字高亮、匹配计数、上一个/下一个、关闭即清高亮。
2. 书签：收藏当前页、列表跳转、删除、重启后仍在。
3. 约束：只用 API 12（5.0.3）真实存在的接口；不引入第三方依赖；不改动既有布局分支结构。

## 二、相似实现调研（≥3）

| 位置 | 模式 | 复用点 |
| --- | --- | --- |
| `entry/src/main/ets/common/FindBar.ets`（本轮新增） | 标题栏同级横条 + `@ObjectLink settings` | 与 `PhoneHeader` 同样的「横条 + 输入框」布局习惯 |
| `entry/src/main/ets/common/MoreMenu.ets` | `bindMenu` + `@ObjectLink settings` 显示当前状态 | 新菜单项直接追加，无新组件 |
| `entry/src/main/ets/model/UrlFormatter.ts` | 无 ArkUI 依赖的纯函数 + `tests/*.test.mjs` 覆盖 | 书签序列化照此抽离 |
| `entry/src/main/ets/model/Browser.ets` | controller 调用统一 `?.` + try/catch | 查找/收藏全部沿用，避免 17100001 |

## 三、接口事实（`.git/dsh-docs/` 本地副本核对）

- `searchAllAsync(searchString: string): void` — webview.md:2508
- `clearMatches(): void` — webview.md:2577
- `searchNext(forward: boolean): void` — webview.md:2623
- `onSearchResultReceive(callback: Callback<OnSearchResultReceiveEvent>)` — web-attr.md:5473
- `OnSearchResultReceiveEvent{ activeMatchOrdinal, numberOfMatches, isDoneCounting }` — web-attr.md:10160（序号从 0 开始）
- `getTitle(): string` — webview.md:3309；`getUrl(): string` — webview.md:3540
- `preferences.getPreferencesSync(context, options)` — preferences.md:343；`putSync` — 1515；`getSync` — 1242；`flush()` — 1853
- 结论：**API 12 没有 `findAllAsync`/`findNext`/`flushSync`**（均为 14+ 或不存在），网络示例不可照抄。

## 四、项目约定

- 组件属性用 `@Link`/`@ObjectLink`；能驱动 UI 的状态必须挂在 `@Observed` 对象上（`Browser` 本身不是）。
- 所有 `WebviewController` 调用先判空，再 try/catch，失败只记日志不抛。
- 新文件必须声明 `const TAG: string = '[名字]';`（`check-structure.mjs` 校验）。
- 纯逻辑抽到无 ArkUI 依赖的 `.ts`，这样 Node 能直接 import 单测。

## 五、改动清单

- 新增：`common/FindBar.ets`、`common/BookmarkPanel.ets`、`model/BookmarkList.ts`、`model/BookmarkStore.ets`、`tests/bookmark.test.mjs`
- 修改：`model/Browser.ets`（find/bookmark 方法 + WebSettings 字段 + 三个新 import）、`common/TitleBar.ets`（`onPageBegin` 重置计数、`onSearchResultReceive`）、`common/MoreMenu.ets`（3 个新菜单项）、`pages/Index.ets`（渲染两个面板、`loadBookmarks()`）、`README.md`、`HANDOFF.md`、`.claude/operations-log.md`
- 资源：无新增（图标全部复用 `ic_public_back`/`ic_public_advance`/`ic_public_cancel_filled`）

## 六、验证方式

```bash
node --test                     # 14 用例
node tests/check-json5.mjs
node tests/check-resources.mjs
node tests/check-structure.mjs
```

无 DevEco/SDK，ArkTS 层只能静态审查 + 人工核对签名。