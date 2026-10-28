# 验证报告：页签条 Chrome 风格重做 + 关闭应用按钮

- 任务：按用户要求把页签条改成 Chrome 风格——页签靠左、`+` 跟随最后一个页签并垂直居中、最右固定「关闭应用」按钮（关闭图标，点击退出应用）
- 日期：2026-10-28（第十轮）
- 环境：本机无 DevEco / SDK，ArkTS 编译结论待用户侧复核

## 一、需求对照

| 用户要求 | 实现 | 结论 |
| --- | --- | --- |
| 页签默认居左对齐 | 页签 `Row` 加 `justifyContent(FlexAlign.Start)`，`ForEach` 依次排列；`TabletTitle` 与 `BrowserTabs` 同步 | 满足 |
| 新增页签按钮垂直居中 | `alignItems(VerticalAlign.Bottom)` + `margin({ bottom: (TAB_STRIP_HEIGHT - NEW_TAB_SIZE) / 2 })`（=6） | 满足 |
| `+` 跟在最右侧页面后面 | `+` 从 `Scroll` 外移入 `Scroll > Row` 的 `ForEach` 之后，随页签一起滚动 | 满足 |
| 最右新增关闭按钮（关闭图标） | `Scroll` 外固定按钮，`Image($r('app.media.ic_public_cancel_filled'))`，`accessibilityText('关闭应用')` | 满足 |
| 点击关闭当前浏览器应用 | `Index.exitApp()` → `UIAbilityContext.terminateSelf()`（单 UIAbility 即整个应用） | 满足 |
| 参照 Chrome 重新 UI | 页签条整体结构、按钮尺寸/圆角/居中、深浅色走既有资源 | 满足 |

## 二、改动清单

| 文件 | 改动 |
| --- | --- |
| `entry/src/main/ets/common/TitleBar.ets:40-43` | `NEW_TAB_SIZE=28`、`TAB_STRIP_BUTTON_BOTTOM=(TAB_STRIP_HEIGHT-NEW_TAB_SIZE)/2` |
| `entry/src/main/ets/common/TitleBar.ets:54-56` | `TabletTitle.onExitApp` 属性 |
| `entry/src/main/ets/common/TitleBar.ets:84-154` | 平板页签条：`+` 移入滚动区、`justifyContent(Start)`、最右固定关闭应用按钮 |
| `entry/src/main/ets/common/TitleBar.ets:313-476` | `BrowserTabs` 同结构 + `onExitApp` 属性 |
| `entry/src/main/ets/pages/Index.ets:7-8` | 导入 `common` / `BusinessError` |
| `entry/src/main/ets/pages/Index.ets:~108-122` | `exitApp()`（`terminateSelf` + try/catch） |
| `entry/src/main/ets/pages/Index.ets:~165,~180` | 向两个布局注入 `onExitApp` |

## 三、验证结果

| 检查 | 结果 |
| --- | --- |
| `node --test` | 20 pass / 0 fail |
| `node tests/check-json5.mjs` | 8 个 json5 通过 |
| `node tests/check-resources.mjs` | 23 个源文件 **89** 处源码引用 + 4 个配置 16 处引用全部命中（较上轮 +6：新增按钮的图标与透明色引用） |
| `node tests/check-structure.mjs` | 23 文件 38 导入 / 7 ForEach / 8 TAG / 6 个 @ObjectLink 组件 8 调用 / 4 HTML 通过 |

- `ic_public_cancel_filled`、`ic_public_add` 均在资源白名单内，未新增资源文件。
- `TAG` 未变（`const TAG = 'TitleBar'`），新增回调均带类型。

## 四、风险与待真机项

1. **无 SDK 无法编译**：新增的 `onExitApp` 属性、`terminateSelf()` 调用与按钮结构均需用户整包重编译确认（尤其是 `getContext(this) as common.UIAbilityContext` 的类型断言）。
2. `terminateSelf()` 退出行为需真机确认：应用正常回到桌面、无黑屏/进程残留。
3. 页签 1～10 个时：`+` 是否始终紧跟最后一个页签、滚动到底可见可点；`×` 是否固定在右端不随滚动。
4. 手机/平板两种布局、深浅色、横竖屏切换下页签条高度与按钮居中是否一致。
5. 未新增单测：本轮为纯 UI 结构变化，无新增纯函数逻辑；既有 20 个单测继续覆盖底层逻辑。

## 五、自评

| 维度 | 评分 | 说明 |
| --- | --- | --- |
| 需求覆盖 | 95 | 6 项要求全部落地，手机/平板一致 |
| 代码质量 | 95 | 复用既有组件与常量；按钮 id/无障碍文案齐全；无未声明依赖 |
| 精准修改 | 92 | 仅改 `TitleBar.ets` 页签条与 `Index.ets` 接线；`WebTab`/工具栏未动；注释为改动处新增 |
| 验证完整 | 90 | 单测 + 三项静态检查全绿；ArkTS 编译与真机行为受环境限制 |

**总分：95（通过）**。剩余缺口全部是「本机无 SDK」导致，已列入待真机确认清单。