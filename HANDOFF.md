# HANDOFF — OpenHarmony Browser 示例优化（会话交接）

> 写给零上下文的新会话：先读「一、任务」「二、现状必读」「三、卡在哪」「四、下一步计划」「八、踩坑」，其余按需查阅。
> 更新时间：2026-10-28 · 工作目录 `D:\project\Browser` · 分支 `master` · 当前 HEAD 见 `git log -1`（第十轮已提交，**未推送**）

---

## 一、任务

基于开源项目 [applications_app_samples 的 Browser 示例](https://gitcode.com/openharmony/applications_app_samples/tree/master/code/BasicFeature/Web/Browser)（本仓库为其独立检出，git 基线 `2056c72`，原为 API 9 版本），满足用户四项需求：

1. **修复系统 bug**
2. **优化界面样式与用户体验**
3. **适配不同屏幕分辨率（横屏/竖屏）**
4. **基于 OpenHarmony 5.x（API 12）迁移并完善功能**

约束：全程中文交付（CLAUDE.md）；不引入用户未要求的新功能；改前先读文件；`.claude/` 三件套（上下文摘要 / 验证报告 / 操作日志）+ 自评 ≥90。

## 二、现状必读

### 提交链

`2056c72`（原版）→ `164919b`（一轮）→ `90d35e7`（二轮）→ `5e6ccb5`（三轮）→ `45cff8e`（四轮）→ `edd5171`（五轮）→ `5c51869`（六轮）→ `c866326`（七轮，文档）→ `6055add`（八轮，编译错误修复，7 文件 +204/−10）→ `ba24ee0`（九轮，文档）→ **十轮（页签条 Chrome 风格，7 文件 +263/−46，未推送；哈希见 `git log -1`）**

### 一句话现状

四项需求对应的能力都已实现（5.x 迁移、界面重做、响应式、页签/查找/书签/历史/下载/全屏等）；用户在有 DevEco 的机器上编译报出的 3 条 `webview.WebDarkMode` / `webview.FullScreenExitHandler` 错误已在第八轮修复并提交；第九轮做了全量「源码 × 官方文档」审计，结论是**没有其他同类或新增编译错误**，只补了文档；第十轮按用户要求把页签条重做成 Chrome 风格（页签靠左、`+` 紧跟最后一个页签并垂直居中、最右侧固定「关闭应用」按钮），改动待用户整包重编译复核。

### 已完成能力（按轮次）

- 一轮（`164919b`，25 文件 +733/−315）：5.x 迁移、核心重写、深浅色资源、HTML 语法修复、首页布局、formatUrl 单测。
- 二轮（`90d35e7`）：补齐静态测试层并据此修 10 项缺陷；布局判定改为窗口宽度断点；首页 HTML 自绘深浅色 + 自适应栅格。
- 三轮（`5e6ccb5`）：修新增页签崩溃（17100001）；Chrome 风格顶栏（页签条 + 药丸地址栏 + 圆形按钮）；删除与 `oh-package.json5` 冲突的根目录 `package.json`；首页加百度快捷入口。
- 四轮（`45cff8e`）：按官方 ArkWeb 文档补缩放 / 桌面版 UA / 强制深色 / 缓存策略 / 清除浏览数据 / 下载 / 页签图标 / 网页全屏 / 异常提示；修 `PhoneLayout.ets` 未声明 `TAG`；检查器加 TAG 与 @ObjectLink 规则。
- 五轮（`edd5171`）：页面内查找（搜索三接口 + 结果事件）与书签（纯函数 + preferences 持久化 + 面板），补 7 个书签单测。
- 六轮（`5c51869`）：`window.open` 新页签（`onWindowNew`/`onWindowExit` + `allowWindowOpenMethod`）与历史记录（纯函数 + preferences + 面板），补 6 个历史单测。
- 七轮（`c866326`）：仅更新交接文档。
- 八轮（`6055add`）：修 3 条编译错误（命名空间误写）；`check-structure.mjs` 新增 4.3 规则防回归；文档同步。
- 九轮（`ba24ee0`）：全量 API 审计（未发现其他编译错误）+ 重写交接文档 + README 同步；无代码改动。
- 十轮（本会话末提交）：页签条 Chrome 风格重做——页签靠左、`+` 跟随最后一个页签并垂直居中、最右侧固定「关闭应用」按钮（`terminateSelf`），手机 `BrowserTabs` 与平板 `TabletTitle` 同结构；无 Web 能力改动。

### 源码规模

16 个 ets/ts 源文件、4 个 rawfile HTML、6 个 json5 配置。

## 三、卡在哪（唯一卡点）

本机**没有 DevEco Studio / OpenHarmony SDK / hvigorw**（`DEVECO_SDK_HOME`、`HOS_SDK_HOME`、`OHOS_SDK` 均空；`C:\Program Files\Huawei`、`D:\Huawei`、`%LOCALAPPDATA%\Huawei` 均不存在），因此：

- **无法编译 ArkTS、无法真机运行**；所有 ArkTS 改动只能靠「Node 单测 + 三项静态检查 + 人工对照官方文档」保证。
- 编译级错误与运行时行为必须在有 SDK 的环境复核。

**新会话接手时第一件事：请用户在有 DevEco 的机器上整包重编译一次。** 构建输出里的 `ERROR: ArkTS:ERROR File: ...:行:列 ...` 是唯一可信判据。

## 四、下一步计划（按优先级）

1. **【最高】等用户整包重编译**：确认第八轮修的 3 条错误消失、且没有新 ERROR，并按第六节手测第十轮页签条。有新报错时：报错行号 → 在 `.git/dsh-docs/` 里 grep 对应签名 → 最小改动。
2. **【高】推送当前提交**（本机 `github.com:443` 被阻断）：
   `git push ssh://git@ssh.github.com:443/DuXingLang/OHBrowser.git master`
   （`origin` 保持 https 不动；PowerShell 会把 git 的 stderr 当错误，输出 `master -> master` 后 exit 1 属正常。）
3. **【高】真机手测**（清单见第六节）。
4. **【中】检查器增强**：把 `tests/check-structure.mjs` 的 4.3 规则从「只拦 `webview.WebDarkMode` / `webview.FullScreenExitHandler`」扩展为「Web 组件全局符号白名单」，同类误写在静态检查阶段就拦住。
5. **【低，尚未获用户要求，先问再动】** 可选增强：书签/历史导出、下载管理面板等。

## 五、改代码前必读的设计事实

- **文档来源**：gitee `OpenHarmony-5.0.3-Release` 分支的 `js-apis-webview.md`、`ts-basic-components-web.md`；本地副本在 `.git/dsh-docs/`（`web-attr.md` 10,428 行、`webview.md` 17,138 行、`preferences.md`）。改任何 webview/Web 调用前先在这里 grep 签名，**不要信网上 API 14+ 的名字**（`findAllAsync`/`findNext`/`flushSync` 在 API 12 都不存在）。
- **符号归属（第八轮教训）**：`WebDarkMode`、`FullScreenExitHandler`、`MixedMode`、`CacheMode` 声明在 Web 组件侧 `component/web.d.ts` 的**全局作用域**，必须裸写；`WebviewController` / `WebDownloadDelegate` / `WebDownloadItem` / `WebCookieManager` / `WebStorage` 才在 `@ohos.web.webview` 命名空间。
- **API 12 真实签名**：`loadUrl(url: string | Resource, headers?)`、`accessBackward(): boolean`、`backward(): void`、`refresh(): void`、`zoom(factor: number): void`（相对倍数）、`getUserAgent(): string`、`setCustomUserAgent(userAgent: string)`、`getTitle()`、`getUrl()`、`runJavaScript(script: string): Promise<string>`（单参重载）、`searchAllAsync(searchString: string)`、`searchNext(forward: boolean)`、`clearMatches()`、`clearHistory()`、`registerJavaScriptProxy(object, name, methodList, ...)`、`setDownloadDelegate(delegate)`。
- **事件字段**：`OnWindowNewEvent{isAlert, isUserTrigger, targetUrl, handler}`、`FullScreenEnterEvent{handler: FullScreenExitHandler}`、`OnSearchResultReceiveEvent{activeMatchOrdinal, numberOfMatches, isDoneCounting}`、`OnPageBeginEvent/OnPageEndEvent{url}`、`OnProgressChangeEvent{newProgress}`、`OnErrorReceiveEvent{request, error}`、`OnHttpErrorReceiveEvent{request, response}`、`OnRenderExitedEvent{renderExitReason}`、`OnFaviconReceivedEvent{favicon: PixelMap}`。
- **枚举值**：`MixedMode{All=0, Compatible=1, None=2}`、`CacheMode{Default=0, None=1, Online=2, Only=3}`、`WebDarkMode{Off=0, On=1, Auto=2}`。
- **UI 状态对象**：`Browser` 不是 @Observed，直接加会驱动 UI 的字段不会刷新；联动态放 `WebSettings`（@Observed，@ObjectLink 绑定）或 `@Observed WebKey.favicon/title`；`BookmarkStore`/`HistoryStore` 同理。
- **Web 未挂载时**：`accessBackward`/`accessForward`/`loadUrl` 等会抛 17100001（`The WebviewController must be associated with a Web component`），必须 try/catch（三轮已因此崩过）。
- **页签**：上限 `MAX_TAB_COUNT=10`；`WebTab` 必须常驻组件树（if 分支外 + `.layoutWeight(1)`），旋转不重载；`window.open` 承接页签 `src` 必须留空（`item.blank ? '' : 首页`），否则会顶掉内核跳转。
- **页签条（第十轮）**：页签固定宽 `TAB_WIDTH=200` 靠左依次排列；`+` 按钮必须放在滚动区（`Scroll > Row`）内、`ForEach` 之后，才会跟随最后一个页签；「关闭应用」按钮必须放在 `Scroll` 外，否则会随页签一起滚走；条内垂直居中靠 `alignItems(Bottom)` + `margin({ bottom: (TAB_STRIP_HEIGHT - NEW_TAB_SIZE) / 2 })`（=6），不要引入绝对定位；关闭应用 = `UIAbilityContext.terminateSelf()`（单 Ability 即整个应用），`BrowserTabs` 与 `TabletTitle` 都通过 `onExitApp` 回调由 Index 注入。
- **窗口**：`onWindowNew` 里必须调 `handler.setWebController(...)`（拒绝开窗传 `null`，文档正文明确允许），否则渲染进程阻塞；`allowWindowOpenMethod(true)` 不开则 `window.open` 被静默拦截；`onWindowExit`（网页 `window.close()`）用 `timestamp` 反查页签下标（关闭后 key 会重编号）。
- **查找**：`activeMatchOrdinal` 从 0 开始，展示要 +1；无匹配显示 `0/0` 并置灰上/下一个；`onPageBegin` 时 `resetFindResult()` 只清计数、不收起查找条。
- **下载**：`onBeforeDownload` 里必须 `item.start(dir + item.getSuggestedFileName())` 才会真正开始（否则永远 PENDING）；落盘目录 `getContext(this).filesDir + '/Download/'`（沙箱内，免权限）；委托对象必须由 `Browser` 持有引用，否则被回收。
- **全屏**：`onFullScreenEnter(event.handler)` 保存 `FullScreenExitHandler`；退出调用 `handler.exitFullScreen()`；`onBackPress` 在全屏时优先退出全屏。
- **持久化**：`preferences.getPreferencesSync(context, { name: 'browser_store' })` + `putSync`/`getSync` + `flush()`（**没有 flushSync**）；书签上限 50、历史上限 200，序列化/解析复用 `BookmarkList`。
- **首页与响应式**：`homeIsPhone` 只在启动时确定一次（手机 phone.html / 平板·2in1 pad.html / 未知按启动宽度），Web 的 `src` 运行期不变；布局用 `mediaquery.matchMediaSync('(width<600vp)')`，查询异常退回 `deviceInfo.deviceType`。
- **图标白名单**：只有 `ic_public_add/advance/back/cancel_filled/home/more_filled/navigation/refresh`、`icon.png`、`submit.png`；改图标前跑 `check-resources.mjs`。

## 六、待真机确认清单

- 第八轮：重新**整包编译**确认 3 条错误消失；全屏进出与 `forceDark` 深色适配仍正常。
- 第十轮：页签条在 1～10 个页签下：页签靠左、超过一屏可横向滚动到底看到 `+` 按钮并点击新建、`+` 与 `×` 在条内垂直居中；最右「关闭应用」点击后应用退出（无黑屏/残留）；手机与平板两种布局、深浅色下样式一致。
- 通用流程：手机竖屏/横屏各走一遍新增页签→切换→关闭→旋转；平板上限 10 页签；深色下首页与网页配色；无历史时按返回键应退出应用。
- 第四轮能力：更多菜单 8 个入口逐项生效（切换缓存/深色后当前页自动刷新）、下载能落盘到 `files/Download/`、视频全屏进出、页签图标刷新、断网错误提示文案。
- 查找/书签：中文关键字匹配计数、跨页后计数归零、面板在小屏与横屏下的高度与滚动、重启后书签仍在（`flush()` 是否真正落盘）、同址重复收藏只剩一条。
- window.open/历史：10 页签上限时正确拒绝、`onWindowExit` 后页签关闭、历史面板布局、重启后历史仍在、`clearBrowsingData` 同时清空历史。

## 七、验证怎么跑（本机可跑，无需 SDK）

```bash
node --test                     # 单元测试：20 用例（formatUrl 7 + 书签 7 + 历史 6）
node tests/check-json5.mjs      # json5 配置可解析
node tests/check-resources.mjs  # $r/$rawfile 与配置资源引用均已定义
node tests/check-structure.mjs  # 导入符号 / ForEach / TAG / @ObjectLink 传参 / 全局符号归属 / rawfile HTML
```

当前基线（改完必须仍然全绿）：

```
node --test                    → 20 pass / 0 fail
node tests/check-json5.mjs     → 8 个 json5 配置全部解析通过
node tests/check-resources.mjs → 23 个源文件 89 处源码资源引用、4 个配置文件 16 处配置引用全部命中
node tests/check-structure.mjs → 23 个源文件 38 处相对导入、7 处 ForEach、8 处 TAG 声明、6 个 @ObjectLink 组件 8 处调用、4 个 HTML 全部符合约束
```

## 八、踩过的坑（绝对不要再踩）

1. **PowerShell 执行策略拦 npm 脚本**：`npm test` 可能报 UnauthorizedAccess。用 `node --test` / `node tests/xxx.mjs` 直跑。
2. **`node --test tests/` 在 Windows/Node 25 上把目录当模块加载报 MODULE_NOT_FOUND**：用 `node --test`（无参）或指定文件。
3. **Node 单测直接 import 应用源码可行**（Node ≥22.6 默认剥离 TS 类型），不要复制逻辑到测试。**根目录不要再放 package.json**——与 `oh-package.json5` 冲突会导致无法编译打包；`.mjs` 天然 ESM。
4. **ArkTS 跨文件引用的类/枚举必须 export**（`@Observed export class WebKey`）。
5. **ForEach 必须写第三个 keyGenerator 参数**。
6. **长文件一次性 write 后必须 read 回来核对**（历史上 `TitleBar.ets` 被写坏过一次：内容截断 + 杂散字符）。
7. **5.x 字段改名**：`srcEntrance`→`srcEntry`（module 与 ability 两级、含 ohosTest）、`visible`→`exported`、删 `uiSyntax`；hvigor-config 用 `modelVersion 5.0.0` + `@ohos/hvigor-ohos-plugin 3.0.9`，不要再写 `hvigorVersion`。
8. **HTML 自闭合 `<div/>` 不合法**；CSS 里全角冒号 `margin：0px` 整条样式失效且肉眼难发现——`check-structure.mjs` 已覆盖。
9. **协议判定别用宽正则**：`c++: std::vector` 会被误判成 URL；已改白名单 `/^(https?|ftp|file|data):/i`，回归用例在 `tests/formatUrl.test.mjs`。
10. **`webview.once('webInited')` 与自定义 userAgent 在 API 12 失效**，不要恢复。
11. **横竖屏不要销毁重建 Web**：WebTab 必须在 if 分支外常驻并 `.layoutWeight(1)`。
12. **页签标题不要再放回普通数组**：必须挂在 `@Observed` 对象的属性上，否则改了不刷新。
13. **静态检查器自身也会错**：CSS 全角标点检查最初把中文注释里的“：”判成错误 → 现在先剔除 `/* */` 注释。出现“只有一处莫名报错”时先怀疑检查器。
14. **图标素材清单别靠记忆**：本工程只有 `ic_public_add/advance/back/cancel_filled/home/more_filled/navigation/refresh`、`icon.png`、`submit.png`，没有 aa/bb/add/delete/fresh/home。改图标前先跑 `node tests/check-resources.mjs`。
15. **pad.html 的 `adapterDevice` 现在是空实现**（原来靠改 viewport 写死 `width=720`，与 device-width 自适应冲突）。函数名不能删——`onPageEnd` 会 `runJavaScript('adapterDevice()')` 调用它。
16. git 提交后 LF→CRLF warning 是 Windows 正常现象，无需处理。
17. **`Browser.ets` 里 `import { formatUrl } from './UrlFormatter'; export { formatUrl };` 是转出，别删**（外部与单测依赖）。
18. **`WebDarkMode` / `FullScreenExitHandler` 必须裸写**：二者在 `component/web.d.ts`（Web 组件全局作用域），`@ohos.web.webview` 没有导出；写成 `webview.WebDarkMode` / `webview.FullScreenExitHandler` 会报 `Property ... does not exist on type 'typeof webview'` 与 `Namespace 'webview' has no exported member ...`（第八轮实打实被用户编译报出来过）。
19. **用了 `TAG` 必须自己声明**：`Logger.info(TAG, ...)` 里的 `TAG` 若本文件没有 `const TAG`，编译期不报错、运行到该行才炸（`PhoneLayout.ets` 踩过）。检查器已加规则。
20. **@ObjectLink 必须由父组件传参**：`MoreMenuButton`/`WebTab` 都需要 `settings`，漏传会在运行时抛「ObjectLink must be initialized」。检查器已校验所有调用点。
21. **不要给 `Browser` 直接加会驱动 UI 的开关**：`Browser` 不是 @Observed，加了不会刷新。联动态放 `WebSettings`（@Observed），用 @ObjectLink 绑。
22. **下载不调用 `item.start()` 就永远 PENDING**：只在 `onBeforeDownload` 里主动指定保存路径才会真正开始；委托对象必须由 `Browser` 持有引用。
23. **`zoom(factor)` 是相对倍数不是绝对值**：直接传 1.5 会在当前比例上再乘 1.5，必须换算成 `目标 / 当前`，并夹在 0.5–4。
24. **别信网上 14+ 的 API 名字**：`findAllAsync`/`findNext`/`flushSync` 在 API 12 都不存在，对应 `searchAllAsync`/`searchNext`/`flush`。改任何 controller/首选项调用前，先在 `.git/dsh-docs/` 里 grep 签名。
25. **`activeMatchOrdinal` 从 0 开始**：直接显示会得到「0/5」，必须 +1。
26. **书签/历史面板别插在 Web 上面覆盖**：用兄弟节点（固定高度、内部 List 滚动）而不是 overlay，避免盖住网页且不触发重载。
27. **`constraintSize({ maxHeight })` 比写死 height 好**：内容少时不留大片空白，多时到上限才滚。
28. **本机 `github.com:443` 被阻断时改用 SSH 443 推送**：`Test-NetConnection github.com -Port 443` 为 False，但 `ssh.github.com:443` 可达（本机已有 `~/.ssh/id_ed25519`，认证身份 DuXingLang）。一次性命令：`git push ssh://git@ssh.github.com:443/DuXingLang/OHBrowser.git master`，不要为此改 `origin`。
29. **提交信息文件每次用新文件名**：`write` 到 `.git\dsh-msg-<轮次>.txt`（旧名被删后会报 “file no longer exists”）；`git commit -F` 后 `Remove-Item`；`git add` **不要用 `-A`**（会把消息文件纳入暂存），改显式列路径；不要提交 `.git/dsh-docs/` 与临时脚本。
30. **PowerShell 直跑 Node 的 `node --test tests/` 会 MODULE_NOT_FOUND**（把目录当模块），要用 `node --test`（无参）或指定文件；`node --import` 不参与（无 loader hook）。
31. **文档签名与正文可能不一致**：`ControllerHandler.setWebController(controller: WebviewController)` 的签名行没写 `| null`，但正文/示例明确允许传 `null`，实际 d.ts 接受 `null`（用户构建未报错即证明）。以「构建结果 + 正文」为准，不要只看签名行。
32. **页签条的 `+`/`×` 位置**：`+` 放在 `Scroll > Row` 之外会固定在最右、离开最后一个页签（Chrome 行为是跟随最后页签，必须放滚动区内 `ForEach` 之后）；`×` 放滚动区内会随页签滚走（必须放 `Scroll` 外）；两者在 `Row alignItems(Bottom)` 下靠 `margin.bottom` 居中，改 `TAB_STRIP_HEIGHT` 时公式自动跟随。

## 九、关键文件地图

```
entry/src/main/ets/
├── model/Browser.ets          # 页签/控制器/标题/canBack·canForward/缩放/UA/清数据/下载/全屏/查找/书签历史入口/formatUrl 转出
├── model/UrlFormatter.ts      # 纯函数：地址栏输入归一化（有单测）
├── model/Logger.ts            # hilog 封装（已修变参）
├── model/BookmarkList.ts      # 纯函数：书签序列化/解析/标题兜底（有单测）
├── model/BookmarkStore.ets    # @Observed 书签状态 + preferences 持久化
├── model/HistoryList.ts       # 纯函数：历史去重/上限/时间格式化（有单测）
├── model/HistoryStore.ets     # @Observed 历史状态 + preferences 持久化
├── common/TitleBar.ets        # 平板：TabletTitle / TabItem / BrowserTabs / WebTab（下载、favicon、全屏、查找、窗口回调）
├── common/PhoneLayout.ets     # 手机：PhoneHeader / PhoneToolBar（含更多菜单入口）
├── common/MoreMenu.ets        # 「更多」菜单：缩放/桌面版 UA/深色/缓存/清除数据/查找/书签/历史
├── common/FindBar.ets         # 页面内查找条
├── common/BookmarkPanel.ets   # 书签面板
├── common/HistoryPanel.ets    # 历史面板
├── pages/Index.ets            # 入口：宽度断点/形态判定/布局分支/全屏隐藏/onBackPress
└── Application/AbilityStage.ts、MainAbility/MainAbility.ts   # 未改动
entry/src/main/resources/
├── base/dark/en_US/element/*  # 三套资源（颜色/字符串）
├── rawfile/phone.html pad.html # 本地首页（自绘深浅色 + 自适应栅格）
└── rawfile/test.html          # 演示页
tests/
├── formatUrl.test.mjs         # 7 用例
├── bookmark.test.mjs          # 7 用例：书签序列化/解析
├── history.test.mjs           # 6 用例：历史去重/上限/删除/时间格式化
├── check-json5.mjs            # json5 解析
├── check-resources.mjs        # 资源引用一致性
└── check-structure.mjs        # 导入符号/ForEach/TAG/@ObjectLink/全局符号归属(4.3)/HTML 结构
.claude/
├── context-summary-*.md / verification-report-*.md   # 各轮三件套（第八轮：…-webview-symbols-fix.md，自评 95；第十轮：…-tab-strip-chrome.md）
└── operations-log.md          # 各轮流水（接手前通读）
.git/dsh-docs/                 # 官方 API 12 文档本地副本（web-attr.md / webview.md / preferences.md），只读参考
```

## 十、环境备忘

- 工作目录 `D:\project\Browser`；分支 `master`；Node v25.2.1（支持 TS 直跑）；git 用户已配置（历史提交可查）。
- **无 DevEco Studio / OpenHarmony SDK / hvigorw**：ArkTS 层改动只能靠静态检查 + 人工审查 + 用户侧编译。
- CLAUDE.md 要求：中文交付、改前先读文件、`.claude/` 三件套、自评 ≥90 通过；只做用户要求的事，不做“顺手重构”。
- **推送**：`git push ssh://git@ssh.github.com:443/DuXingLang/OHBrowser.git master`（`github.com:443` 在本机被阻断；`origin` 仍为 https，勿改）。
- 当前 HEAD（第十轮提交）未推送；工作区干净；哈希以 `git log -1` 为准。