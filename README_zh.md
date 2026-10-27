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
3. 页签条可点击切换网页，点击页签上的关闭按钮关闭对应页签;
4. 点击输入框左侧前进后退按钮进行页面的前进后退，点击主页图标回到主页，点击加号按钮新建页面（页签上限 10 个）;
5. 手机竖屏使用单页签 + 底部工具栏布局，手机横屏/平板/2in1 使用多页签布局，屏幕旋转时自动切换且浏览状态不丢失。

### 工程目录
```
entry/src/main/ets/
|---Application
|   |---AbilityStage.ts                         // 入口
|---pages
|   |---Index.ets                               // 首页（设备形态判定、横竖屏布局切换）
|---common
|   |---PhoneLayout.ets                         // 手机端地址栏与底部工具栏
|   |---TitleBar.ets                            // 平板端标题栏、页签条与 Web 组件
|---model
|   |---Logger.ts                               // 日志工具
|   |---Browser.ets                             // 浏览器实例
|   |---UrlFormatter.ts                         // 地址栏输入归一化（纯函数）
tests/                                          // Node 单元测试（node --test）
```

### 具体实现
+ Web展示与历史栈操作功能在Browser中，源码参考[Browser.ets](entry/src/main/ets/model/Browser.ets)
  + 加载网页及刷新：使用WebController提供的loadUrl可以加载目标网址内容，使用refresh方法刷新页面;
  + 页面前进后退功能：页面在前进或者后退前使用accessForward/accessBackward查询是否有历史记录,然后调用forward/backward进行前进/后退操作;
  + 地址栏输入归一化：[UrlFormatter.ts](entry/src/main/ets/model/UrlFormatter.ts) 对输入做协议补全与搜索词归一化;
+ 横竖屏适配：源码参考[Index.ets](entry/src/main/ets/pages/Index.ets)
  + 平板/2in1 固定使用多页签布局，手机竖屏使用底部工具栏布局，手机横屏与模拟器跟随屏幕方向（mediaquery）自动切换;
  + Web 组件常驻组件树，横竖屏切换时不销毁，浏览状态不丢失。

### 相关权限

[ohos.permission.INTERNET](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/security/AccessToken/permissions-for-all.md#ohospermissioninternet)

[ohos.permission.GET_WIFI_INFO](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/security/AccessToken/permissions-for-all.md#ohospermissionget_wifi_info)

### 依赖

不涉及。

### 约束与限制

1. 本示例仅支持标准系统上运行;
2. 本示例已适配API version 12版本SDK（OpenHarmony 5.0.0 Release），版本号：5.0.0.12;
3. 本示例需要使用DevEco Studio 5.0.0及以上版本（配套hvigor 3.0.9）才可编译运行;
4. 单元测试依赖Node.js 22.6+，在工程根目录执行 `node --test` 运行。

### 下载

如需单独下载本工程，执行如下命令：
```
git init
git config core.sparsecheckout true
echo code/BasicFeature/Web/Browser/ > .git/info/sparse-checkout
git remote add origin https://gitee.com/openharmony/applications_app_samples.git
git pull origin master
```
