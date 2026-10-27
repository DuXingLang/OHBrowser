# 项目上下文摘要（Browser 优化任务）
生成时间：2026-10-27 10:20

## 相似实现（编码前检索）
- entry/src/main/ets/model/Browser.ets：浏览器状态模型（页签数组 + WebviewController 数组）
- entry/src/main/ets/common/TitleBar.ets：平板布局标题栏/页签条/Web 组件
- entry/src/main/ets/common/PhoneLayout.ets：手机布局（原 PhoneLayout/Navigation）
- entry/src/main/ets/pages/Index.ets：入口页，设备形态判定与布局分支
- entry/src/main/ets/model/Logger.ts：hilog 日志封装

## 项目约定
- 阶段模型 Stage、ArkTS（ets）+ 少量 .ts 工具类
- 常量大写蛇形（MAX_TAB_COUNT），类 PascalCase，成员小驼峰
- 资源一律 $r('app.string.xxx') / $r('app.color.xxx')，深浅色双主题（base/dark）
- 测试：Node 内置 test runner（tests/*.mjs），运行 `node --test`

## 依赖与集成点
- Web 组件 + webview.WebviewController（@ohos.web.webview）
- rawfile 本地首页：phone.html / pad.html，通过 etsObj 代理（registerJavaScriptProxy）回调
- 配置：module.json5、build-profile.json5、hvigor/hvigor-config.json5、AppScope/app.json5

## 任务目标（用户请求，m00001）
1. 修复系统 bug；
2. 优化界面样式与用户体验；
3. 适配不同屏幕分辨率（横屏/竖屏）；
4. 基于 OpenHarmony 5.x 完成迁移与功能完善。
