# 项目上下文摘要：页签条「+」双位置与页签居左（第十一轮）

生成时间：2026-10-28 16:45（Asia/Shanghai）

## 任务

用户反馈（m00546 / m00662）：

1. 新增页签按钮「+」要像 Chrome：页签未占满时紧贴页签，占满时固定在右侧；
2. 页签栏里打开的页签没有居左对齐，需要调整。

## 相似实现（改前调研）

- `entry/src/main/ets/common/TitleBar.ets` `TabletTitle`（平板页签条）：第十轮结构 = `Row > Scroll > Row(space:4)[ForEach 页签 + 「+」] + 「×」`，`+` 固定放在滚动区内，页签占满后会被滚出视野；滚动内容 `Row` 只有 `justifyContent(FlexAlign.Start)`、没有宽度。
- `entry/src/main/ets/common/TitleBar.ets` `BrowserTabs`（手机页签条）：与 `TabletTitle` 同结构，差异是外层 `flexShrink(0)`，由 Index 在 `hasMultipleTabs` 时渲染。
- `entry/src/main/ets/common/TitleBar.ets` `TabItem`：页签固定宽 `TAB_WIDTH=200`、高 `TAB_HEIGHT=34`，激活态白底 + 顶部圆角，底边与工具栏融合；宽度固定是本次宽度计算的前提。
- `entry/src/main/ets/pages/Index.ets`：`mediaquery.matchMediaSync('(width<600vp)')` 监听窗口宽度变化并切换布局，说明本项目已有「按实测宽度驱动重建」的既有模式。
- `tests/check-structure.mjs`：校验 ForEach 三参数、TAG、@ObjectLink 传参等；本次改动不改这些结构，基线数字应保持不变。

## 关键结论（根因）

- 页签不居左：`Scroll` 对其内容 `Row` 按内容宽度测量并居中，`Row` 不设宽度时 `justifyContent(FlexAlign.Start)` 无法把页签推到最左；必须显式给内容 `Row` 宽度（未占满取可视宽）。
- `+` 位置：同一个 `+` 无法同时满足「贴页签」和「占满固定右侧」；需按页签条实测宽度二选一渲染，测量用 `onAreaChange`（`Area.width` 运行期为 number，`Number()` 兜底）。

## 项目约定

- 语言：ArkTS（API 12 / OpenHarmony 5.x），注释与文档全中文；
- 样式常量集中在文件顶部，命名 UPPER_SNAKE；
- 状态驱动重建用 `@State`；`Browser` 非 @Observed，读取其 `webArray` 属于响应式链路（@Link 传入）；
- 提交前必跑：`node --test`、`node tests/check-json5.mjs`、`node tests/check-resources.mjs`、`node tests/check-structure.mjs`；
- 本机无 DevEco/SDK，ArkTS 改动只能静态验证，需用户侧整包编译复核。