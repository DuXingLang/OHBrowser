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
8. 待执行：git commit（中文提交信息）。

## 已知限制
- 本环境无 DevEco Studio/hvigor 构建链，未执行 hvigorw 真机编译验证；已通过 Node 单测与 json5 语法校验替代。
