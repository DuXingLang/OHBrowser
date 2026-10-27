# 项目上下文摘要（第四轮：按官方 ArkWeb 文档补功能）

生成时间：2026-10-27 17:10

## 一、任务来源

用户要求「根据 OpenHarmony 官方 webview 文档补充完善应用功能」，给出的文档链接为
`https://docs.openharmony.cn/pages/v5.0.3/zh-cn/application-dev/reference/apis-arkweb/js-apis-webview.md`。

## 二、文档获取

- `docs.openharmony.cn` 的 v5.0.3 页面返回 404，不可用。
- 以 gitee `openharmony/docs` 仓库 `OpenHarmony-5.0.3-Release` 分支下的 Markdown 为准：
  - `js-apis-webview.md`（WebviewController、下载、Cookie/Storage）
  - `ts-basic-components-web.md`（Web 组件属性与事件）
- 工程 `compatibleSdkVersion` 为 `5.0.0(12)`，所以只采用 API 12 及以下的能力，标注 14+ 的一律不用。

## 三、相似实现检索（≥3）

- `entry/src/main/ets/model/Browser.ets`：页签数组 + `WebController` 数组 + `loadUrl`，扩展能力挂在这里最自然。
- `entry/src/main/ets/common/TitleBar.ets` 的 `WebTab`：Web 组件属性与事件的实际绑定处。
- `entry/src/main/ets/common/PhoneLayout.ets`：工具栏按钮样式与热区规范（40vp 热区、24vp 图标）。
- `entry/src/main/ets/pages/Index.ets`：布局分支与 `onBackPress` 的既有拦截逻辑。

## 四、项目约定

- 命名：类 PascalCase、常量全大写下划线、私有字段 camelCase。
- 日志：`Logger.info(TAG, ...)`，**每个文件必须自己声明 `TAG`**。
- 状态：会被 UI 读取并需要联动的状态必须放在 `@Observed` 类上，用 `@ObjectLink` 绑定。
- 异常：所有 controller 调用先判空 + try/catch（Web 未挂载会抛 17100001）。
- 校验：本机无 SDK，只能靠 `node --test` + `tests/check-*.mjs` 三个静态检查器。

## 五、接口与集成点

| 能力 | 采用 API | 集成位置 |
| --- | --- | --- |
| 缩放 | `zoomAccess(true)` + `WebviewController.zoom(factor)` | Browser 方法 + MoreMenu 入口 |
| 桌面版 UA | `getUserAgent()` / `setCustomUserAgent()` | Browser 方法（备份原始 UA） |
| 强制深色 | `darkMode` + `forceDarkAccess` | WebTab 属性绑定 `WebSettings.forceDark` |
| 缓存策略 | `cacheMode(CacheMode.None / Default)` | WebTab 属性绑定 `WebSettings.noCache` |
| 清除数据 | `clearHistory()` / `WebCookieManager.clearAllCookiesSync()` / `WebStorage.deleteAllData()` | Browser 方法 |
| 下载 | `WebDownloadDelegate.onBeforeDownload` + `WebDownloadItem.start(path)` | Browser 持有 delegate，WebTab 的 `onControllerAttached` 绑定 |
| 页签图标 | `onFaviconReceived` | WebKey.favicon + TabItem |
| 网页全屏 | `onFullScreenEnter/Exit` + `FullScreenExitHandler` | WebTab → Index 的 `webFullScreen` |
| 异常提示 | `onErrorReceive` / `onHttpErrorReceive` / `onRenderExited` | WebTab |

## 六、约束

- 不得引入新依赖（Node 侧仅用内置模块）。
- 不改动 `formatUrl` 语义与其 7 条单测。
- 下载必须落在应用沙箱内（`getContext(this).filesDir + '/Download/'`），避免申请公共目录权限。