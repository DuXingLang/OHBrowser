# HANDOFF — OpenHarmony Browser 示例优化（会话交接）

> 写给零上下文的新会话。接手前请通读本文，尤其是最后的“踩坑清单”。
> 更新时间：2026-10-27 17:05 · 工作目录 `D:\project\Browser` · Git 流程：`2056c72`（原版）→ `164919b`（第一轮优化）→ 第二轮及以后见最新 commit

---

## 一、我们在做什么任务

基于开源项目 [applications_app_samples 的 Browser 示例](https://gitcode.com/openharmony/applications_app_samples/tree/master/code/BasicFeature/Web/Browser)（本仓库为其独立检出，git 基线 `2056c72`，原为 API 9 版本），满足四项用户需求：

1. **修复系统 bug**
2. **优化界面样式与用户体验**
3. **适配不同屏幕分辨率（横屏/竖屏）**
4. **基于 OpenHarmony 5.x（API 12）迁移并完善功能**

用户没有提出超出这四项的需求；全程中文交付（CLAUDE.md 要求）。

## 二、当前状态

- 第一轮（`164919b`，25 文件 +733/−315）：5.x 迁移、核心重写、深浅色资源、HTML 语法修复、首页布局、formatUrl 单测。
- 第二轮（`90d35e7`）：补齐**静态测试层**，据此找出并修复 10 项缺陷；布局判定改为窗口宽度断点；首页 HTML 改自绘深浅色 + 自适应栅格；文档三件套同步。
- 第三轮（本轮）：修复新增页签崩溃（17100001）、顶栏按 Chrome 风格重做（页签条 + 药丸地址栏 + 圆形按钮）、删除与 oh-package.json5 冲突的根目录 package.json、首页新增百度快捷入口。
- 第四轮（当前工作区未提交）：按 OpenHarmony 5.0.3 官方 ArkWeb 文档补齐能力（缩放 / 桌面版 UA / 强制深色 / 缓存策略 / 清除浏览数据 / 下载 / 页签图标 / 网页全屏 / HTTP 与渲染异常提示），顺带修复 `PhoneLayout.ets` 使用未声明 `TAG` 的编译级缺陷，并给静态检查器加了 TAG 与 @ObjectLink 传参两类规则。

## 三、验证怎么跑（本机可跑，无需 SDK）

```bash
node --test                     # 单元测试：7 用例
node tests/check-json5.mjs      # 静态检查：json5 配置可解析
node tests/check-resources.mjs  # 静态检查：资源引用均已定义
node tests/check-structure.mjs  # 静态检查：导入符号 / ForEach / rawfile HTML
```

当前基线结果（改动后必须仍然全绿）：

```
node --test                    → 7 pass / 0 fail
node tests/check-json5.mjs     → 8 个 json5 配置全部解析通过
node tests/check-resources.mjs → 16 个源文件 48 处源码资源引用、4 个配置文件 16 处配置引用全部命中
node tests/check-structure.mjs → 16 个源文件 18 处相对导入、5 处 ForEach、6 处 TAG 声明、3 个 @ObjectLink 组件 5 处调用、4 个 HTML 全部符合约束
```

## 四、本轮关键改动（含“为什么”）

### 静态测试层（新增，替代不可用的编译器）
- `tests/check-resources.mjs`：把所有 `$r('app.type.name')`、`$rawfile('x')`、json5 里的 `$string:/$media:/$color:/$profile:` 与 base/dark/en_US/rawfile 实际定义逐条比对。**它抓出了编译必失败的资源缺失**。
- `tests/check-structure.mjs`：相对导入的符号是否真被目标文件导出、ForEach 是否带 keyGenerator、rawfile HTML 的自闭合/全角标点/本地图片/getElementById/on* 函数/`etsObj.*` 注册一致性。
- `package.json` 加 `npm run check`。

### 缺陷修复（按严重度）
1. `PhoneLayout.ets` 引用不存在的 `app.media.aa/bb/add/delete/fresh/home` → 全部映射真实素材（ic_public_back/add/cancel_filled/refresh/home/advance），**否则 HAP 构建直接失败**。
2. 手机工具栏 6 个按钮 `width('20%')` 合计 120% 溢出 → `layoutWeight(1)`。
3. 页签标题 `Row.width('100%')` 把 33vp 关闭按钮挤出屏幕 → 改 `Stack`，关闭按钮独立热区，顺带消除“一次点击同时触发选择+关闭”。
4. `deleteTab` 可关闭最后一个页签（Tabs 无数据源）→ 守卫 + toast「至少保留一个页签」。
5. 页签标题存在普通数组里，元素赋值不触发刷新 → 标题移入 `@Observed WebKey.title`，`TabItem` 用 `@ObjectLink` 渲染。
6. 页签条不可滚动 → 横向 `Scroll` 包裹；手机布局页签数 >1 时补页签条。
7. 前进/后退/关闭无禁用态 → `Browser.canBack/canForward` + `updateHistoryState()`（onPageEnd、进度 100、页签增删切时调用），按钮 0.4 置灰。
8. `addTab` 上限判断 `>` 改 `>=`（原来能建到 11 个）。
9. `.id(item.id)` 传数字 → 字符串模板 `toolButton${item.id}`。
10. `test.html` 全角冒号与自闭合 div 修复。

### 响应式（核心设计）
- `Index.ets`：`mediaquery.matchMediaSync('(width<600vp)')` 决定布局，注册 `on('change')`、`aboutToDisappear` 注销；查询异常时退回 `deviceInfo.deviceType` 判定（**不能因为断点语法不可用就白屏**）。
- `homeIsPhone` 只在启动时确定一次：手机→phone.html、平板/2in1→pad.html、形态未知按启动宽度；这样旋转时 Web 的 `src` 不变，配合 WebTab 常驻组件树，**旋转不重载、浏览状态不丢**。
- 首页 HTML：CSS 变量 + `prefers-color-scheme` 自绘深浅色；站点区 `flex:1 + overflow-y:auto`；横屏/矮屏压缩留白；输入框左右留白修正。

### 第三轮（崩溃修复 + Chrome 风格顶栏）
- **17100001 崩溃**：`addTab`/`deleteTab` 后 50ms 调 `updateHistoryState()`，此时新页签的 Web 组件尚未挂载，`accessBackward()` 抛 `The WebviewController must be associated with a Web component`。修复：`updateHistoryState`、`Back`、`Forward` 与两处主页按钮 `loadUrl` 全部 try/catch 兜底（失败视为无历史）。
- **顶栏重做（Chrome 风格）**：`TabletTitle` = 页签条（横向可滚动 + 新建页签按钮）+ 工具栏（圆形前进/后退/主页 + 药丸地址栏 + 刷新）；手机 `PhoneHeader` 改药丸地址栏，`PhoneToolBar` 改 5 键均分；索引页签条不再重复渲染。
- **配色**：base/dark `color.json` 换 Chrome 调色板（`omnibox_bg` #F1F3F4/#202124、`text_primary`、`fg_secondary` 等）。
- **删除根目录 package.json**：与 `oh-package.json5` 重复导致无法编译打包；测试改为直接 `node` 执行，不再依赖 npm 脚本。
- **首页新增百度快捷入口**：`phone.html` / `pad.html` 站点数组首位加入 `./baidu.png` → `baidu.com`。

### 第四轮（按官方 ArkWeb 文档补功能）
文档来源：`docs.openharmony.cn` 的 v5.0.3 页面返回 404，最终以 gitee 仓库 `OpenHarmony-5.0.3-Release` 分支下的 `js-apis-webview.md` 与 `ts-basic-components-web.md` 为准逐条核对签名，**没有凭空发明 API**。

- **状态对象 `WebSettings`（@Observed）**：`desktopMode`/`forceDark`/`noCache`/`zoomScale`/`isFullScreen` 统一放在一个 @Observed 类里，菜单按钮与 Web 组件都通过 @ObjectLink 绑定。原因：`Browser` 本身不是 @Observed，散落在它上面的标量改了不会触发 UI 重建，`cacheMode`/`darkMode` 这类属性就不会重新下发。
- **缩放**：`zoomAccess(true)` + `WebviewController.zoom(factor)`，factor 是**相对当前比例**的倍数，所以传 `目标倍数 / 当前倍数`，累计倍数夹在 0.5–4。
- **桌面版 UA**：`getUserAgent()` 先备份 → `setCustomUserAgent(桌面 UA)` → `refresh()`；切回时用备份的移动版 UA。
- **强制深色**：`darkMode(WebDarkMode.On)` + `forceDarkAccess(true)` 同一个开关；关闭回 `WebDarkMode.Auto`。
- **缓存策略**：`cacheMode(CacheMode.None / CacheMode.Default)`，切换后自动刷新。
- **清除浏览数据**：`clearHistory()` / `WebCookieManager.clearAllCookiesSync()` / `WebStorage.deleteAllData()` 三个各包一层 try/catch，一个失败不影响其余。
- **下载**：`onControllerAttached` 里建 `WebDownloadDelegate` 并 `setDownloadDelegate`；`onBeforeDownload` 必须 `item.start(dir + getSuggestedFileName())`，否则一直是 PENDING。落盘目录 `getContext(this).filesDir + '/Download/'`（沙箱内，不需要公共目录权限）。
- **页签图标**：`onFaviconReceived` → `setTabFavicon(key, PixelMap)` → 写到 `@Observed WebKey.favicon`，TabItem 里 `if (favicon !== undefined)` 显示，否则回退内置图标。
- **网页全屏**：`onFullScreenEnter` 保存 `FullScreenExitHandler` 并回调 Index 置 `webFullScreen=true` 隐藏标题栏/工具栏；`onFullScreenExit` 恢复；`onBackPress` 在全屏时优先退出全屏。
- **异常提示**：`onErrorReceive`（加载失败）、`onHttpErrorReceive`（仅主文档且 code>=400 提示错误码）、`onRenderExited`（渲染进程被杀 → toast + refresh）。
- **`PhoneLayout.ets` 编译级缺陷**：`Logger.error(TAG, ...)` 用了从未声明的 `TAG`（运行到该行只会拿到 undefined，编译期不报错）。已补 `const TAG: string = '[PhoneLayout]';`，并在 `check-structure.mjs` 加了「用了 TAG 必须自己声明」的规则。
- **菜单组件 `MoreMenu.ets`**：`bindMenu(MenuElement[])`，手机/平板工具栏共用；手机端用 `Column().layoutWeight(1)` 包一层，保证 6 个入口等分热区。

## 五、未闭环（环境限制，非代码问题）

- 本机无 DevEco Studio / OpenHarmony SDK / hvigorw，**未做编译与真机运行验证**。换有 DevEco 5.0+ 的环境执行 `hvigorw assembleHap` 复核 ArkTS 严格模式告警。
- 真机手测清单：手机竖屏/横屏各走一遍新增页签→切换→关闭→旋转；平板上限 10 页签；深色模式下首页与网页配色；无历史时按返回键应退出应用。
- 第四轮待真机确认项：更多菜单 8 个入口逐项生效（尤其切换缓存/深色后当前页自动刷新）、页面内下载能落盘到 `files/Download/`、视频网站全屏进出、页签图标刷新、断网时的错误提示文案。

## 六、踩过的坑（绝对不要再踩）

1. **PowerShell 执行策略拦 npm 脚本**：`npm test` 可能报 UnauthorizedAccess。用 `node --test` / `node tests/xxx.mjs` 直跑。
2. **`node --test tests/` 在 Windows 上把目录当模块加载报 MODULE_NOT_FOUND**：用 `node --test`（无参）或指定文件。
3. **Node 单测直接 import 应用源码可行**（Node ≥22.6 默认剥离 TS 类型），不要复制逻辑到测试。**根目录不要再放 package.json**——与 oh-package.json5 冲突会导致无法编译打包；`.mjs` 天然 ESM，语法探测会把 `import/export` 的 .ts 当 ESM 处理。
4. **ArkTS 跨文件引用的类/枚举必须 export**（`@Observed export class WebKey`）。
5. **ForEach 必须写第三个 keyGenerator 参数**。
6. **长文件一次性 write 后必须 read 回来核对**（历史上 TitleBar.ets 被写坏过一次：内容截断 + 杂散字符）。
7. **5.x 字段改名**：`srcEntrance`→`srcEntry`（module 与 ability 两级、含 ohosTest）、`visible`→`exported`、删 `uiSyntax`；hvigor-config 用 `modelVersion 5.0.0` + `@ohos/hvigor-ohos-plugin 3.0.9`，不要再写 `hvigorVersion`。
8. **HTML 自闭合 `<div/>` 不合法**；CSS 里全角冒号 `margin：0px` 整条样式失效且肉眼难发现——`check-structure.mjs` 已覆盖这两类。
9. **协议判定别用宽正则**：`c++: std::vector` 会被误判成 URL；已改白名单 `/^(https?|ftp|file|data):/i`，回归用例在 `tests/formatUrl.test.mjs`。
10. **`webview.once('webInited')` 与自定义 userAgent 在 API 12 失效**，不要恢复。
11. **横竖屏不要销毁重建 Web**：WebTab 必须在 if 分支外常驻并 `.layoutWeight(1)`。
12. **页签标题不要再放回普通数组**：必须挂在 `@Observed` 对象的属性上，否则改了不刷新。
13. **静态检查器自身也会错**：CSS 全角标点检查最初把中文注释里的“：”判成错误 → 现在先剔除 `/* */` 注释。出现“只有一处莫名报错”时先怀疑检查器。
14. **图标素材清单别靠记忆**：本工程只有 `ic_public_add/advance/back/cancel_filled/home/more_filled/navigation/refresh`、`icon.png`、`submit.png`，没有 aa/bb/add/delete/fresh/home。改图标前先跑 `node tests/check-resources.mjs`。
15. **pad.html 的 `adapterDevice` 现在是空实现**（原来靠改 viewport 写死 `width=720`，与 device-width 自适应冲突）。函数名不能删——ArkTS `onPageEnd` 会 `runJavaScript('adapterDevice()')` 调用它（`TitleBar.ets`）。
16. git 提交后 LF→CRLF warning 是 Windows 正常现象，无需处理。
17. `Browser.ets` 里 `import { formatUrl } from './UrlFormatter'; export { formatUrl };` 这两行是给外部与单测用的转出，**别删**。
18. **`WebDarkMode` 不能裸写**：必须 `import webview from '@ohos.web.webview'` 后用 `webview.WebDarkMode.Auto`；`loadUrl`/`accessBackward`/`accessForward` 在 Web 未挂载时抛 17100001，必须 try/catch，否则点击新增页签即崩溃。
19. **用了 `TAG` 必须自己声明**：`Logger.info(TAG, ...)` 里的 `TAG` 若本文件没有 `const TAG`，编译期不报错、运行到该行才炸（`PhoneLayout.ets` 就踩了）。`check-structure.mjs` 已加规则。
20. **@ObjectLink 必须由父组件传参**：`MoreMenuButton`/`WebTab` 都需要 `settings`，漏传会在运行时抛「ObjectLink must be initialized」。检查器已校验所有调用点。
21. **不要给 `Browser` 直接加会驱动 UI 的开关**：`Browser` 不是 @Observed，加了也不会刷新。要联动的状态放 `WebSettings`（@Observed），用 @ObjectLink 绑。
22. **下载不调用 `item.start()` 就永远 PENDING**：`WebDownloadDelegate` 只在 `onBeforeDownload` 里主动指定保存路径才会真正开始；委托对象必须由 Browser 持有引用，否则会被回收导致回调丢失。
23. **`zoom(factor)` 是相对倍数不是绝对值**：直接传 1.5 会在当前比例上再乘 1.5，必须换算成 `目标 / 当前`。

## 七、关键文件地图

```
entry/src/main/ets/
├── model/Browser.ets          # 页签/控制器/标题/canBack·canForward/formatUrl 转出
├── model/UrlFormatter.ts      # 纯函数：地址栏输入归一化（有单测）
├── model/Logger.ts            # hilog 封装（已修变参）
├── common/TitleBar.ets        # 平板：TabletTitle / TabItem / BrowserTabs / WebTab（含下载、favicon、全屏）
├── common/PhoneLayout.ets     # 手机：PhoneHeader / PhoneToolBar（含更多菜单入口）
├── common/MoreMenu.ets        # 「更多」菜单：缩放/桌面版 UA/深色/缓存/清除数据
├── pages/Index.ets            # 入口：宽度断点/形态判定/布局分支/全屏隐藏/onBackPress
└── Application/AbilityStage.ts、MainAbility/MainAbility.ts   # 未改动
entry/src/main/resources/
├── base/dark/en_US/element/*  # 三套资源（颜色/字符串）
├── rawfile/phone.html pad.html # 本地首页（自绘深浅色 + 自适应栅格）
└── rawfile/test.html          # 演示页（已修语法）
tests/
├── formatUrl.test.mjs         # 7 用例（node --test）
├── check-json5.mjs            # json5 解析
├── check-resources.mjs        # 资源引用一致性
└── check-structure.mjs        # 导入符号 / ForEach / TAG 声明 / @ObjectLink 传参 / HTML 结构
.claude/
├── context-summary-browser-round2.md
├── verification-report-browser-round2.md   # 自评 92 分
├── verification-report-webview-api.md      # 第四轮（官方 API 补功能，自评 93 分）
├── context-summary-webview-api.md          # 第四轮上下文摘要
├── context-summary-browser-optimization.md # 第一轮
├── verification-report-browser-optimization.md
└── operations-log.md          # 各轮流水
```

## 八、环境备忘

- 工作目录 `D:\project\Browser`；分支 master；Node v25.2.1（支持 TS 直跑）。
- 无 DevEco Studio / OpenHarmony SDK / hvigorw：ArkTS 层改动只能靠静态检查 + 人工审查。
- CLAUDE.md 要求：中文交付、修改前先读文件、`.claude/` 三件套、自评 ≥90 通过。