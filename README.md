# 浏览器

### 介绍
本示例基于 [Web 组件](https://docs.openharmony.cn/pages/v5.0/zh-cn/application-dev/reference/apis-arkweb/js-apis-web.md)展示了一个浏览器的基本功能：展示网页、多页签管理、根据页面历史栈前进回退等，并适配手机与平板（横屏/竖屏）两种窗口形态。

### 效果预览

|首页|打开网址|
|----|------|
|![](screenshots/device/home.png)|![](screenshots/device/jump.png)|

使用说明:
1. 连接Wifi，启动应用，展示默认页面内容;
2. 点击默认页面的图标跳转到对应网页，或者在输入框输入网址（自动补全协议，输入普通文本则作为搜索词跳转搜索）;
3. 页签条可点击切换网页，点击页签上的关闭按钮关闭对应页签（至少保留一个页签）;
4. 点击输入框左侧前进后退按钮进行页面的前进后退，点击主页图标回到主页，点击加号按钮新建页面（页签上限 10 个）;
5. 布局按窗口宽度断点（600vp）切换：宽度小于断点时使用单页签 + 底部工具栏布局，否则使用多页签布局；手机横竖屏、平板分屏、2in1 自由窗口缩放时自动切换，且 Web 组件常驻、浏览状态不丢失;
6. 手机布局存在多个页签时会在工具栏上方显示页签条，可切换页签；前进/后退/关闭按钮不可用时图标置灰;
7. 首页与标题栏跟随系统深浅色，网页内容使用 WebDarkMode.Auto 同步切换;
8. 工具栏右侧「更多」菜单提供：网页放大/缩小/缩放重置、切换桌面版网站、强制深色渲染、启用/禁用缓存、清除浏览数据（历史记录、Cookie、Web 存储）;
9. 页面内触发的下载会保存到应用沙箱 `files/Download/` 目录并弹出开始/完成提示；网页视频等请求全屏时自动隐藏标题栏与工具栏，按返回键先退出全屏;
10. 页签会显示站点图标（取不到时回退为内置图标），主文档 4xx/5xx 与渲染进程异常会给出提示;
11. 「更多」菜单的「在页面中查找」会在标题栏下方展开查找条，输入关键字实时高亮，显示 `当前/总数`，可上一个/下一个跳转，关闭时清除高亮;
12. 「更多」菜单的「收藏当前页」把当前网址存入书签，「书签」展开书签面板可点击跳转或删除；书签通过首选项持久化，重启应用后仍在（本地首页等非 http 页面不可收藏）。

### 工程目录
```
entry/src/main/ets/
|---Application
|   |---AbilityStage.ts                         // 入口
|---pages
|   |---Index.ets                               // 首页（窗口宽度断点、横竖屏布局切换）
|---common
|   |---PhoneLayout.ets                         // 手机端地址栏与底部工具栏
|   |---TitleBar.ets                            // 平板端标题栏、页签条与 Web 组件
|   |---MoreMenu.ets                            // 「更多」菜单（缩放/桌面版/深色/缓存/清除数据/查找/书签）
|   |---FindBar.ets                             // 页面内查找条（上一个/下一个/匹配计数）
|   |---BookmarkPanel.ets                       // 书签面板（收藏当前页/跳转/删除）
|---model
|   |---Logger.ts                               // 日志工具
|   |---Browser.ets                             // 浏览器实例
|   |---UrlFormatter.ts                         // 地址栏输入归一化（纯函数）
|   |---BookmarkList.ts                         // 书签序列化与解析（纯函数）
|   |---BookmarkStore.ets                       // 书签状态与首选项持久化
tests/
|---formatUrl.test.mjs                          // 单元测试（node --test）
|---bookmark.test.mjs                           // 书签序列化单元测试
|---check-json5.mjs                             // 静态检查：json5 配置可解析
|---check-resources.mjs                         // 静态检查：$r/$rawfile 与配置资源引用均已定义
|---check-structure.mjs                         // 静态检查：导入符号、ForEach 三参数、TAG 声明、@ObjectLink 传参、rawfile HTML 结构
```

### 具体实现
+ Web展示与历史栈操作功能在Browser中，源码参考[Browser.ets](entry/src/main/ets/model/Browser.ets)
  + 加载网页及刷新：使用WebController提供的loadUrl可以加载目标网址内容，使用refresh方法刷新页面;
  + 页面前进后退功能：页面在前进或者后退前使用accessForward/accessBackward查询是否有历史记录,然后调用forward/backward进行前进/后退操作;
  + 前进后退可用态：onPageEnd 与页签切换后调用 updateHistoryState 同步 canBack/canForward，供工具栏置灰展示;
  + 地址栏输入归一化：[UrlFormatter.ts](entry/src/main/ets/model/UrlFormatter.ts) 对输入做协议补全与搜索词归一化;
+ 横竖屏适配：源码参考[Index.ets](entry/src/main/ets/pages/Index.ets)
  + 用 mediaquery 监听窗口宽度断点 `(width<600vp)` 决定布局，手机横竖屏、平板分屏与 2in1 自由窗口缩放都能正确切换；断点查询失败时退回设备形态判定;
  + 起始首页按设备形态选定后运行期不再变化，Web 组件常驻组件树，横竖屏切换时不销毁，浏览状态不丢失;
+ 首页页面：[phone.html](entry/src/main/resources/rawfile/phone.html) 与 [pad.html](entry/src/main/resources/rawfile/pad.html)
  + 页面自绘深浅色变量（prefers-color-scheme），站点栅格按宽度自适应并在矮屏/横屏时压缩留白，站点区可滚动；默认快捷站点含百度（https://baidu.com）等入口，点击图标直接访问。
+ 扩展能力（基于 OpenHarmony 5.0.x ArkWeb API），源码参考[Browser.ets](entry/src/main/ets/model/Browser.ets)与[MoreMenu.ets](entry/src/main/ets/common/MoreMenu.ets)
  + 缩放：Web 组件开启 `zoomAccess(true)`，`WebviewController.zoom(factor)` 的入参是相对当前比例的倍数，因此按「目标倍数 / 当前倍数」换算，累计倍数限制在 0.5–4 倍;
  + 桌面版 UA：`getUserAgent()` 备份原始 UA，`setCustomUserAgent()` 切换为桌面版 UA 后刷新，切回时恢复备份的移动版 UA;
  + 深色渲染：`darkMode(WebDarkMode.On)` 与 `forceDarkAccess(true)` 绑定同一个开关，关闭时回到 `WebDarkMode.Auto` 跟随系统;
  + 缓存策略：`cacheMode(CacheMode.None)` 强制回源、`CacheMode.Default` 走默认策略，切换后自动刷新当前页;
  + 清除浏览数据：`clearHistory()`、`WebCookieManager.clearAllCookiesSync()`、`WebStorage.deleteAllData()` 逐个 try/catch 调用，单个失败不影响其余;
  + 下载：在 `onControllerAttached` 中创建并绑定 `WebDownloadDelegate`，`onBeforeDownload` 里必须调用 `item.start(路径)`，否则下载停留在等待状态；文件落到应用沙箱 `files/Download/`，无需申请公共目录权限;
  + 页签图标：`onFaviconReceived` 拿到 PixelMap 后写入对应 `WebKey`，页签条通过 @ObjectLink 精确刷新;
  + 网页全屏：`onFullScreenEnter` 保存 `FullScreenExitHandler` 并隐藏应用内控件，`onFullScreenExit` 或返回键（先退出全屏）恢复;
  + 异常提示：`onErrorReceive`（加载失败）、`onHttpErrorReceive`（4xx/5xx，仅主文档）、`onRenderExited`（渲染进程异常后自动重载）分别给出提示;
  + 所有 controller 调用先判空并 try/catch：新建页签、页签切换瞬间 Web 未挂载会抛 17100001「controller 未与 Web 组件关联」;
+ 状态与菜单联动：可切换的显示/网络行为收敛在 `WebSettings`（@Observed）中，菜单用 @ObjectLink 显示当前状态，Web 组件用 @ObjectLink 绑定 `cacheMode`/`darkMode`，切换后立即生效;
+ 页面内查找：源码参考[FindBar.ets](entry/src/main/ets/common/FindBar.ets)
  + 只用 OpenHarmony 5.0.3 存在的三个接口：`searchAllAsync(keyword)` 开始查找、`searchNext(forward)` 上一个/下一个、`clearMatches()` 清除高亮（5.0.3 没有 `findAllAsync`/`findNext`）;
  + 匹配数由 Web 组件 `onSearchResultReceive` 异步回调给出，`activeMatchOrdinal` 从 0 开始，界面显示 `${findIndex + 1}/${findTotal}`，无匹配时显示 `0/0` 并禁用前后跳转;
  + 页面跳转（`onPageBegin`）后旧匹配失效，只重置计数、不收起查找条;
+ 书签：源码参考[BookmarkStore.ets](entry/src/main/ets/model/BookmarkStore.ets)与[BookmarkList.ts](entry/src/main/ets/model/BookmarkList.ts)
  + 序列化与解析抽成纯函数（`parseBookmarks`/`stringifyBookmarks`），可用 `node --test` 直接覆盖，异常输入一律返回空列表而不是抛错;
  + 持久化用 `preferences.getPreferencesSync(context, { name: 'browser_store' })` + `putSync`/`getSync`，写入后 `flush()` 异步落盘（API 12 没有 `flushSync`）;
  + 书签状态放在 `@Observed BookmarkStore` 上，面板用 @ObjectLink 绑定，收藏/删除后列表精确刷新;

### 相关权限

[ohos.permission.INTERNET](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/security/AccessToken/permissions-for-all.md#ohospermissioninternet)

[ohos.permission.GET_WIFI_INFO](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/security/AccessToken/permissions-for-all.md#ohospermissionget_wifi_info)

### 依赖

不涉及。

### 约束与限制

1. 本示例仅支持标准系统上运行;
2. 本示例已适配API version 12版本SDK（OpenHarmony 5.0.0 Release），版本号：5.0.0.12;
3. 本示例需要使用DevEco Studio 5.0.0及以上版本（配套hvigor 3.0.9）才可编译运行;
4. 单元测试与静态检查依赖Node.js 22.6+：根目录执行 `node --test` 运行单测，依次执行 `node tests/check-json5.mjs`、`node tests/check-resources.mjs`、`node tests/check-structure.mjs` 运行静态检查（工程不提供 npm 脚本，避免根目录 package.json 与 oh-package.json5 冲突）。

### 下载

如需单独下载本工程，执行如下命令：
```
git init
git config core.sparsecheckout true
echo code/BasicFeature/Web/Browser/ > .git/info/sparse-checkout
git remote add origin https://gitee.com/openharmony/applications_app_samples.git
git pull origin master
```
