## 项目上下文摘要：页签条 Chrome 风格重做 + 关闭应用按钮

生成时间：2026-10-28 16:20（第十轮）

### 任务与验收

用户需求（m00392，逐字）：

1. 调整浏览器页签默认居左对齐；
2. 新增页签按钮在页签栏垂直居中，参照 Chrome 浏览器，新增页签按钮跟在最右侧的页面后面，页签栏最右侧新增一个关闭按钮，用关闭图标表示，点击关闭图标，关闭当前浏览器应用；
3. 参照 Chrome 浏览器风格，重新进行 UI 设计和实现。

验收：页签靠左依次排列；`+` 在条内垂直居中且紧跟最后一个页签（随页签滚动，不在最右端）；`×` 固定在页签条最右、不随页签滚动，点击后退出应用；手机与平板两种布局一致；深浅色、横竖屏不回归。

### 相似实现（≥3）

1. 项目内已有页签条：`entry/src/main/ets/common/TitleBar.ets` 的 `TabletTitle`（平板）与 `BrowserTabs`（手机）——页签为固定宽 `TAB_WIDTH=200` 的 `TabItem`，`Row` 内 `ForEach`，外面套横向 `Scroll`；`TabItem` 用 `topRadius` 圆角 + 白色底与工具栏融合。
2. Chrome 桌面顶栏行为（网络截图/常识，未引入外部代码）：页签靠左排列，「+」紧跟最后一个页签；窗口控制区固定在条最右；新建页签不可用时 `+` 置灰。
3. 项目内既有退出/上下文写法：`getContext(this) as common.UIAbilityContext` 在 `TitleBar.ts` 下载目录（`context.filesDir`）、`Index.ets` 初始化等位置已用过；`terminateSelf()` 是官方 UIAbilityContext 方法（`@ohos.app.ability.common` + `@kit.AbilityKit`）。
4. 项目内既有图标：`ic_public_add` 已用于原「+」按钮；`ic_public_cancel_filled` 已用于 `TabItem` 关闭按钮与 `MoreMenu` 关闭项，两枚图标都在白名单内。

### 项目约定

- ArkTS，`TitleBar.ets` 单文件导出 `TabletTitle` / `TabItem` / `BrowserTabs` / `WebTab`，`TAG = 'TitleBar'` 已声明。
- 组件属性需显式类型（`onExitApp: () => void = () => {}`）；回调参数须写类型（`(event: ClickEvent)`），不能裸参数。
- 颜色/图标一律走 `$r('app.color.*')` / `$r('app.media.*')`，新增引用必须命中 `check-resources.mjs`。
- 注释、文档、提交信息一律简体中文；本机无 SDK，验证靠 `node --test` + 三项静态检查。

### 修改点

| 文件:行 | 改动 |
| --- | --- |
| `entry/src/main/ets/common/TitleBar.ets:40-43` | 新增常量 `NEW_TAB_SIZE = 28`、`TAB_STRIP_BUTTON_BOTTOM = (TAB_STRIP_HEIGHT - NEW_TAB_SIZE) / 2`（=6），用注释说明「页签条内按钮垂直居中」 |
| `entry/src/main/ets/common/TitleBar.ets:54-56` | `TabletTitle` 增加 `onExitApp: () => void = () => {}` |
| `entry/src/main/ets/common/TitleBar.ets:84-154` | 平板页签条重写：`Scroll > Row` 内 `ForEach` + `+` 按钮（`left:4, bottom:6`，id `newTabButton`）；`Row.justifyContent(FlexAlign.Start)`；`Scroll` 外最右固定关闭应用按钮（`ic_public_cancel_filled`，id `exitButton`，`accessibilityText('关闭应用')`，`onClick → this.onExitApp()`） |
| `entry/src/main/ets/common/TitleBar.ets:313-476` | `BrowserTabs` 同步为同一结构（`Row { Scroll { ForEach + "+" }, exitButton }`），加 `onExitApp` 属性与同款两个按钮；外层补 `padding({left:4,right:4})` |
| `entry/src/main/ets/pages/Index.ets:7-8` | 新增 `import common from '@ohos.app.ability.common';`、`import { BusinessError } from '@kit.BasicServicesKit';` |
| `entry/src/main/ets/pages/Index.ets:~108-122` | 新增 `private exitApp(): void`：`getContext(this) as common.UIAbilityContext` → `terminateSelf().catch(...)`，try/catch + `BusinessError` |
| `entry/src/main/ets/pages/Index.ets:~165,~180` | `TabletTitle` / `BrowserTabs` 注入 `onExitApp: () => { this.exitApp(); }` |

### 关键决策与理由

- `+` 放滚动区内（`ForEach` 之后）而不是固定在右端：用户要求「跟在最右侧的页面后面」，Chrome 的「+」会随页签一起被推到可视区外；这样页签多时滚动到底即可见。
- `×` 放 `Scroll` 外：若放滚动区内，页签一多就会被滚出屏幕，违背「页签栏最右侧固定关闭按钮」。
- 垂直居中用 `alignItems(Bottom)` + `margin.bottom = (TAB_STRIP_HEIGHT - NEW_TAB_SIZE) / 2`，复用页签「底边对齐、顶部留圆角」的既有布局，避免引入绝对定位。
- 退出用 `terminateSelf()`：本工程只有一个 UIAbility（`MainAbility`），即关闭整个应用；不新增权限。`onExitApp` 由 `Index` 注入，两个布局共用同一逻辑。
- 关闭图标沿用 `ic_public_cancel_filled`（与页签关闭按钮一致），不新增资源，避免资源白名单变动。

### 测试模式

- 单测：`node --test`（20 用例，纯函数层，未新增用例——本轮只动 UI 结构，无新增纯逻辑）。
- 静态检查：`check-json5`（8 配置）、`check-resources`（23 文件 89 处源码引用，较上轮 +6，来自新增按钮的图标与透明色引用）、`check-structure`（23 文件 38 导入 / 7 ForEach / 8 TAG / 6 @ObjectLink 组件 8 调用 / 4 HTML）。
- 风险点：无法本机编译，ArkTS 语法需用户侧复核；`onExitApp` 默认空实现避免未注入时崩溃。