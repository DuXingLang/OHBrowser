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
