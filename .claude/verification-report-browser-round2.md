# 验证报告（第二轮：整体测试 / 缺陷修复 / 响应式与 UX）

生成时间：2026-10-27 10:45

## 一、验证手段

| 手段 | 命令 | 说明 |
| --- | --- | --- |
| 单元测试 | `node --test` | tests/formatUrl.test.mjs，直接 import 应用源码 |
| 配置校验 | `node tests/check-json5.mjs` | 8 个 json5 配置可解析 |
| 资源校验 | `node tests/check-resources.mjs` | 源码 `$r/$rawfile` 与配置 `$string:/$media:/$color:/$profile:` 逐条比对定义 |
| 结构校验 | `node tests/check-structure.mjs` | 相对导入符号、ForEach 三参数、rawfile HTML 结构 |
| 人工审查 | 通读 4 个 ArkTS 文件 + 4 个 HTML | 编译期无法覆盖的语义与交互时序 |

## 二、执行结果（全部通过）

```
node --test                → 7 pass / 0 fail
node tests/check-json5.mjs → 8 个配置全部解析通过
node tests/check-resources.mjs → 15 个源文件 39 处源码引用、4 个配置文件 16 处配置引用全部命中
node tests/check-structure.mjs → 15 个源文件 14 处导入、5 处 ForEach、4 个 HTML 全部符合约束
```

## 三、本轮发现并修复的缺陷（按严重度）

1. **编译级致命**：`PhoneLayout.ets` 引用不存在的媒体资源 `app.media.aa/bb/add/delete/fresh/home`，HAP 构建必然失败 → 全部映射到真实素材（ic_public_back/add/cancel_filled/refresh/home/advance）。
2. **布局溢出**：手机工具栏 6 个按钮各 `width('20%')`，合计 120% 溢出 → 改 `layoutWeight(1)` 均分。
3. **交互失效**：页签标题用 `Row.width('100%')` 布局，33vp 关闭按钮被挤出屏幕不可点 → 改 Stack + 关闭按钮独立热区（同时消除“一次点击触发选择+关闭”）。
4. **数据源崩溃**：关闭最后一个页签后 Tabs 无数据源 → `deleteTab` 增加守卫与 toast「至少保留一个页签」。
5. **刷新失效**：`tabTitles` 是普通数组，元素赋值不触发 UI 刷新 → 标题移入 `@Observed WebKey.title`，新增 `TabItem` 以 `@ObjectLink` 渲染。
6. **可达性**：页签条不可滚动，多页签无法切换 → 横向 `Scroll` 包裹；手机布局页签数 >1 时补页签条。
7. **状态误导**：前进/后退/关闭无禁用态 → `Browser.canBack/canForward` + `updateHistoryState()`，按钮置灰 0.4。
8. **上限差一**：`addTab` 用 `> MAX_TAB_COUNT` 可建到 11 个 → 改 `>=`。
9. **HTML 语法**：test.html 全角冒号 `margin：0px` 与自闭合 `<div id = "test"/>` 已修；phone.html / pad.html 重做首页样式。
10. **type 不匹配**：`.id(item.id)` 传数字 → 改字符串模板 `toolButton${item.id}`。

## 四、界面/体验/适配改动

- 布局判定由“设备形态”改为“窗口宽度断点 `(width<600vp)`”，手机横竖屏、平板分屏、2in1 自由窗口缩放均能正确切换；断点查询异常时退回设备形态判定。
- 起始首页在启动时一次确定（`homeIsPhone`），旋转不改变 Web 的 `src`，配合 WebTab 常驻组件树，旋转不重载、浏览状态不丢。
- 新增 `zoomAccess(true)`、`darkMode(WebDarkMode.Auto)`；首页 HTML 用 CSS 变量 + `prefers-color-scheme` 自绘深浅色，站点区可滚动、横屏压缩留白、输入框左右热区与字号修正。
- 地址栏 `enterKeyType(Go)`、提交后清空按钮可用态、关闭页签按钮补 `accessibilityText`。

## 五、评分

| 项 | 权重 | 得分 | 说明 |
| --- | --- | --- | --- |
| 代码质量 | 25 | 23 | 风格与既有代码一致，新增常量替代魔法数字 |
| 测试覆盖 | 25 | 21 | 纯函数有单测，静态检查 3 项；UI 时序仍依赖人工审查 |
| 依赖完整性 | 15 | 15 | 未新增依赖，资源引用全部命中 |
| 命名规范 | 15 | 15 | 与工程既有命名一致 |
| 架构一致性 | 20 | 18 | 沿用 @Observed + @ObjectLink 模式 |
| **合计** | 100 | **92** | 通过（≥90） |

## 六、未闭环项（环境限制，非代码问题）

- 未执行 hvigor 编译与真机运行（本机无 DevEco Studio / OpenHarmony SDK），ArkTS 严格模式的编译告警需在有构建链的环境复核。
- 未提供真机截图，效果预览沿用工程原有截图。