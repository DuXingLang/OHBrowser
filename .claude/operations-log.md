# 操作日志
# Browser 示例优化（OpenHarmony 5.x）

## 2026-10-27
1. 建立基线：git 基线 2056c72（原 API 9 版本），所有修改在工作区进行。
2. 核心代码重写：
   - Browser.ets：formatUrl 输入归一化、页签标题数组、deleteTab 切页延时修复、页签上限、空引用保护、promptAction 替换废弃 prompt。
   - Logger.ts：hilog 变参拼接修复。
   - PhoneLayout.ets：拆为 PhoneHeader + PhoneToolBar，去掉废弃 Navigation 结构。
   - Index.ets：方向监听注册修复、平板/手机/模拟器形态判定、WebTab 常驻避免旋转销毁、onBackPress 吞返回键修复。
   - TitleBar.ets：热区/图标尺寸优化、placeholder 资源化、页签标题显示真实网页标题、移除 5.x 失效的 userAgent 逻辑、新增主文档加载失败 toast。
3. 5.x 迁移：module.json5（srcEntry/exported/2in1）、build-profile.json5（compatibleSdkVersion 5.0.0(12)）、hvigor 3.0.9（modelVersion 5.0.0）、hypium 1.0.19、app.json5 1.1.0。
4. 资源修复：base/dark 双主题颜色资源、base string.json 占位文案修复、新增 en_US 资源目录。
5. HTML 修复：phone.html 全角冒号、自闭合 div、缺 viewport 与 adapterDevice；pad.html 全角冒号、缺失分号、isPhone 未声明。
6. 单元测试：UrlFormatter.ts 抽取纯函数，tests/formatUrl.test.mjs 7 用例全过；tests/check-json5.mjs 校验 8 个 json5 全过。
7. 文档：README_zh.md 同步 API 12 迁移说明。
8. 提交 `164919b`（中文提交信息，25 文件 +733/−315）。

## 2026-10-27 第二轮（整体测试 / 缺陷修复 / 响应式与 UX）
9. 建立静态测试层（tests/，Node 直跑，无构建链也能回归）：
   - `check-resources.mjs`：源码 `$r/$rawfile` 与 json5 `$string:/$media:/$color:/$profile:` 引用逐条对照 base/dark/en_US/rawfile 定义；
   - `check-structure.mjs`：相对导入符号、ForEach 三参数、rawfile HTML（自闭合/全角标点/本地图片/getElementById/on* 函数/etsObj 注册）；
   - package.json 增加 `npm run check` 串联三个脚本。
10. 静态检查首轮报错并修复：
    - PhoneLayout.ets 引用不存在的 `app.media.aa/bb/add/delete/fresh/home`（编译必失败）→ 映射到 ic_public_back/add/cancel_filled/refresh/home/advance；
    - PhoneToolBar 6×`width('20%')` 溢出 → `layoutWeight(1)`；`.id(item.id)` 数值改字符串模板；
    - Browser.deleteTab 增加“至少保留一个页签”守卫 + toast；页签上限判断 `>` 改 `>=`；
    - 页签标题移入 `@Observed WebKey.title`，新增 `TabItem(@ObjectLink)`；页签条改 Stack 布局，关闭按钮独立热区，避免一次点击触发选择+关闭；页签条套横向 Scroll；onSelect 增加越界守卫。
11. 响应式重构：Index.ets 改用 mediaquery `'(width<600vp)'` 断点（try/catch 失败退回 deviceType）；`homeIsPhone` 启动时一次确定保证 Web src 稳定；手机布局页签数 >1 时补页签条；Web 增加 `zoomAccess`/`darkMode(Auto)`；根容器补齐 100% 尺寸与背景色。
12. UX：前进/后退/关闭不可用时置灰（`canBack/canForward` + `updateHistoryState()`）；地址栏 `enterKeyType(Go)`；提交后清空按钮可用态；关闭按钮补 `accessibilityText`。
13. 首页 HTML 重做：手机/平板首页改用 CSS 变量实现 `prefers-color-scheme` 深浅色、栅格自适应 + 站点区滚动、横屏/矮屏压缩留白、输入框左右留白与字号修正；pad.html 补 head/meta viewport，`adapterDevice` 改为空实现（不再强制 720 布局宽度）。
14. 检查器自身修复：CSS 全角标点检测先剔除 `/* */` 注释，避免中文注释误报。
15. 文档：README_zh.md（使用说明/工程目录/具体实现/约束）同步；HANDOFF.md 更新；新增 `.claude/context-summary-browser-round2.md` 与 `.claude/verification-report-browser-round2.md`。

## 已知限制
- 本环境无 DevEco Studio/hvigor 构建链，未执行 hvigorw 真机编译验证；已通过 Node 单测 + 三项静态检查 + 人工审查替代。

### 第三轮：崩溃修复 + Chrome 风格顶栏 + package.json 移除
16. 修复 17100001 崩溃：addTab/deleteTab 后 updateHistoryState 在 Web 未挂载时抛异常。updateHistoryState/Back/Forward/两处主页 loadUrl 全部 try/catch 兜底。
17. TabletTitle 重做为「页签条 + 药丸地址栏工具栏」的 Chrome 风格；PhoneHeader/PhoneToolBar 同步药丸地址栏与 5 键均分布局；索引页移除重复页签条。
18. base/dark color.json 改用 Chrome 调色板，新增 omnibox_bg/text_primary/fg_secondary。
19. 删除根目录 package.json（与 oh-package.json5 重复导致无法编译打包），Node 测试改直接执行；README/HANDOFF 验证命令同步。
20. phone.html / pad.html 站点数组首位新增百度快捷入口（baidu.com，使用已有 baidu.png）。
21. 验证：node --test 7 pass；check-json5 8 文件通过；check-resources 46 处引用命中；check-structure 15 导入/5 ForEach/4 HTML 通过。

### 第四轮：按 OpenHarmony 5.0.3 ArkWeb 官方文档补功能
22. 文档获取：`docs.openharmony.cn` 的 v5.0.3 页面 404，改用 gitee `OpenHarmony-5.0.3-Release` 分支的 `js-apis-webview.md` 与 `ts-basic-components-web.md`，逐条核对签名后再实现，避免臆造接口。
23. 发现并修复编译/运行级缺陷：`PhoneLayout.ets` 的 `Logger.error(TAG, ...)` 使用未声明 `TAG` → 补常量；`check-structure.mjs` 新增「TAG 必须本文件声明」规则。
24. 新增 `WebSettings(@Observed)`：desktopMode/forceDark/noCache/zoomScale/isFullScreen 集中在 @Observed 对象上，Web 属性与菜单文案用 `@ObjectLink` 绑定（`Browser` 非 @Observed，标量直接挂它不会刷新）。
25. `Browser.ets` 新增能力：`zoomIn/zoomOut/resetZoom`（zoom 相对倍数换算，0.5–4 倍）、`toggleDesktopMode`（getUserAgent 备份 + setCustomUserAgent）、`toggleForceDark`（darkMode + forceDarkAccess）、`toggleNoCache`（cacheMode）、`clearBrowsingData`（clearHistory + clearAllCookiesSync + WebStorage.deleteAllData，各自 try/catch）、`attachDownloadDelegate`/`WebDownloadDelegate`（onBeforeDownload 里 `item.start(沙箱 Download 路径)`）、`setTabFavicon`、`enterFullScreen`/`exitFullScreen`、`handleHttpError`/`handleRenderExit`。
26. `TitleBar.ets`：Web 组件绑定 `cacheMode`/`darkMode`/`forceDarkAccess`，新增 `onControllerAttached`（挂下载委托）、`onFaviconReceived`、`onFullScreenEnter/Exit`、`onHttpErrorReceive`、`onRenderExited`；TabItem 显示 favicon 并回退内置图标；平板工具栏加「更多」入口。
27. `PhoneLayout.ets`：手机工具栏 5 键改 6 键（新增「更多」），`Column().layoutWeight(1)` 均分，`MoreMenuButton` 复用。
28. `Index.ets`：新增 `webFullScreen`，全屏时隐藏标题栏/工具栏；`onBackPress` 优先退出网页全屏。
29. 新增 `entry/src/main/ets/common/MoreMenu.ets`（105 行）：`bindMenu(MenuElement[])` 8 项入口（新建页签/放大/缩小/缩放重置/桌面版/深色/缓存/清除数据），文案随 `settings` 变化。
30. 验证：node --test 7 pass；check-json5 8 通过；check-resources 16 文件 48 处；check-structure 16 文件 18 导入/5 ForEach/6 TAG/3 @ObjectLink 组件 5 处调用/4 HTML。
31. 文档：README.md 补扩展能力小节与文件地图，HANDOFF.md 增第四轮说明与 5 条新踩坑（TAG/@ObjectLink/Browser 非 Observed/下载需 start/zoom 相对倍数），新增 `.claude/context-summary-webview-api.md` 与 `.claude/verification-report-webview-api.md`（自评 93 分）。

### 第五轮：页面内查找 + 书签持久化
32. 文档核对：`.git/dsh-docs/webview.md` 确认 API 12 只有 `searchAllAsync`(2508)/`searchNext`(2623)/`clearMatches`(2577)，`web-attr.md` 确认 `onSearchResultReceive`(5473) 与 `OnSearchResultReceiveEvent`(10160)；`preferences.md` 确认 `getPreferencesSync`(343)/`putSync`(1515)/`getSync`(1242)/`deleteSync`(1777)/`flush`(1853)，**没有 flushSync（14+）**。放弃网上 14+ 示例，避免编译不过。
33. `Browser.ets`：`WebSettings` 增 `findVisible/findKeyword/findIndex/findTotal`；新增 `openFindBar/closeFindBar/searchInPage(keyword)/searchNext(forward)/updateFindResult(activeMatchOrdinal, numberOfMatches)/resetFindResult()/clearMatches()`，全部 controller 调用 try/catch（未挂载时 17100001）。
34. `FindBar.ets`（新增）：48vp 横条，输入即搜、Enter 下一个、计数 `${findIndex+1}/${findTotal}`、无匹配显示 `0/0` 并置灰前后按钮；关闭走 `closeFindBar()` 清高亮。`TitleBar.ets` 的 `onPageBegin` 增 `resetFindResult()`，WebTab 增 `onSearchResultReceive`。`MoreMenu.ets` 增「在页面中查找」。
35. `BookmarkList.ts`（新增，纯函数）：`parseBookmarks`/`stringifyBookmarks`/`normalizeTitle`，不依赖 ArkUI 与系统能力；脏数据、缺字段、非数组一律返回空列表而不抛错。
36. `BookmarkStore.ets`（新增，@Observed）：`items`/`visible`，`init(context)` 用 `preferences.getPreferencesSync(context, { name: 'browser_store' })` 读取 Key `bookmarks`，`add/remove/has` 后 `putSync` + `flush()`（失败只记日志，内存书签仍可用）。
37. `BookmarkPanel.ets`（新增）：标题行（收藏当前页/收起）+ 空态提示 + `List`（`constraintSize({ maxHeight: 320 })` 内部滚动），行内标题/网址省略号，删除按钮独立热区，点击整行 `loadUrl` 并收起。
38. `Browser.ets` 增书签入口：`bookmarkStore` 属性、`initBookmarks(context)`、`openBookmarks()`（先 `closeFindBar()`）、`closeBookmarks()`、`addCurrentPageBookmark()`（`getUrl()` 非 http 开头提示「当前页面不支持收藏」，重复收藏提示「已更新该书签」）。
39. `Index.ets`：`import { BookmarkPanel }`；`loadBookmarks()` 在 `aboutToAppear`/`onDeviceChange` 调 `initBookmarks(getContext(this))`（Context 只在页面层取一次）；渲染 `if (!webFullScreen && bookmarkStore.visible) BookmarkPanel(...)`。`MoreMenu.ets` 增「收藏当前页」「书签」两项。
40. 单测：新增 `tests/bookmark.test.mjs` 7 用例（追加置顶、同 URL 去重、超上限丢最旧、删除、标题兜底域名、脏数据丢弃、序列化往返），`node --test` 合计 14 pass。
41. 验证：`node --test` 14 pass / 0 fail；`check-json5` 8 个通过；`check-resources` 20 个源文件 70 处引用；`check-structure` 20 文件 28 导入 / 6 ForEach / 7 TAG / 5 个 @ObjectLink 组件 7 处调用 / 4 HTML。
42. 文档：README.md 补使用说明 11–12 条、文件地图 4 个新文件、具体实现两组小节；HANDOFF.md 增第五轮小节与踩坑 24–27、验证基线更新；新增 `.claude/context-summary-find-bookmark.md` 与 `.claude/verification-report-find-bookmark.md`（自评 94 分）。
43. 提交 `edd5171`（14 文件 +861/−9），推送遇阻：`github.com:443` 四次连接超时（21s），而 `ssh.github.com:443` 可达 → 改用 `git push ssh://git@ssh.github.com:443/DuXingLang/OHBrowser.git master` 成功，`git ls-remote` 确认远端 master 与本地 HEAD 一致；据此补 HANDOFF 踩坑 28（不改 origin）。
