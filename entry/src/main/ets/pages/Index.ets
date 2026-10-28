/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import deviceInfo from '@ohos.deviceInfo';
import mediaquery from '@ohos.mediaquery';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';
import { Browser } from '../model/Browser';
import Logger from '../model/Logger';
import { PhoneHeader, PhoneToolBar } from '../common/PhoneLayout';
import { TabletTitle, BrowserTabs, WebTab } from '../common/TitleBar';
import { FindBar } from '../common/FindBar';
import { BookmarkPanel } from '../common/BookmarkPanel';
import { HistoryPanel } from '../common/HistoryPanel';

const TAG: string = '[browser.Index]';
// 布局断点：窗口宽度小于 600vp 用手机单页签布局，否则用多页签布局
// 用窗口宽度而非设备形态判定，手机横竖屏、平板分屏、2in1 自由窗口缩放都能正确切换
const PHONE_BREAKPOINT: string = '(width<600vp)';

@Entry
@Component
struct Index {
  // true 使用手机布局；false 使用平板（多页签）布局
  @State isPhone: boolean = false;
  @State browser: Browser = new Browser();
  // 网页全屏（视频等）状态：由 WebTab 的 onFullScreenEnter/Exit 回调驱动，true 时隐藏应用控件
  @State webFullScreen: boolean = false;
  // 起始首页由设备形态决定且运行期不变，保证旋转时 Web 的 src 不变化、页面不重载
  private homeIsPhone: boolean = true;
  private widthListener: mediaquery.MediaQueryListener | undefined = undefined;

  // 窗口宽度跨越断点时切换布局
  onWidthChange = (result: mediaquery.MediaQueryResult) => {
    this.isPhone = result.matches;
    Logger.info(TAG, `width changed, isPhone = ${this.isPhone}`);
  }

  onDeviceChange() {
    Logger.info(TAG, `onDeviceChange`);
    this.browser = new Browser();
    this.loadStores();
  }

  // 书签与历史都需要 Context 才能访问首选项，集中在这里初始化，避免 UI 组件各自持有 Context
  loadStores() {
    try {
      this.browser.initBookmarks(getContext(this));
    } catch (e) {
      Logger.error(TAG, `initBookmarks failed: ${JSON.stringify(e)}`);
    }
    try {
      this.browser.initHistory(getContext(this));
    } catch (e) {
      Logger.error(TAG, `initHistory failed: ${JSON.stringify(e)}`);
    }
  }

  // 页签条最右侧的关闭按钮：退出当前浏览器应用。
  // 本工程只有一个 UIAbility，terminateSelf() 即关闭整个应用。
  private exitApp(): void {
    Logger.info(TAG, `exitApp`);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.terminateSelf().catch((error: BusinessError) => {
        Logger.error(TAG, `terminateSelf failed: ${JSON.stringify(error)}`);
      });
    } catch (e) {
      Logger.error(TAG, `exitApp failed: ${JSON.stringify(e)}`);
    }
  }

  aboutToAppear() {
    let deviceType: string = 'default';
    try {
      deviceType = deviceInfo.deviceType;
      Logger.info(TAG, `deviceType = ${deviceType}`);
    } catch (e) {
      Logger.error(TAG, `get deviceType failed: ${JSON.stringify(e)}`);
    }
    try {
      this.widthListener = mediaquery.matchMediaSync(PHONE_BREAKPOINT);
      this.isPhone = this.widthListener.matches;
      this.widthListener.on('change', this.onWidthChange);
      Logger.info(TAG, `aboutToAppear isPhone = ${this.isPhone}`);
    } catch (e) {
      // 断点查询不可用时退回设备形态判定，避免监听失败导致布局异常
      Logger.error(TAG, `matchMediaSync failed: ${JSON.stringify(e)}`);
      this.isPhone = deviceType !== 'tablet' && deviceType !== '2in1';
    }
    // 起始首页按设备形态决定：手机用 phone.html，平板/2in1 用 pad.html，
    // 形态未知（模拟器/预览器）时取启动瞬间的布局结果，运行期不再变化
    if (deviceType === 'phone') {
      this.homeIsPhone = true;
    } else if (deviceType === 'default') {
      this.homeIsPhone = this.isPhone;
    } else {
      this.homeIsPhone = false;
    }
    Logger.info(TAG, `homeIsPhone = ${this.homeIsPhone}`);
    this.loadStores();
  }

  aboutToDisappear() {
    this.widthListener?.off('change', this.onWidthChange);
    this.widthListener = undefined;
  }

  build() {
    Column() {
      // 网页全屏（视频等）时隐藏所有应用内控件，只保留 Web 占满整屏
      if (!this.webFullScreen) {
        if (this.isPhone) {
          PhoneHeader({ browser: $browser })
        } else {
          TabletTitle({
            browser: $browser,
            onExitApp: () => {
              this.exitApp();
            }
          })
          Progress({ value: this.browser.progress, total: 100 })
            .color($r('app.color.progress_blue'))
            .visibility(this.browser.hideProgress ? Visibility.Hidden : Visibility.Visible)
            .flexShrink(0)
          // 页签条已内置于 TabletTitle（页签条 + 工具栏一体），此处不再重复渲染
          Divider().color($r('app.color.divider_color')).width('100%').flexShrink(0)
        }
      }
      // 页面内查找栏：展开时占用一条独立横条，与标题栏/工具栏互不遮挡
      if (!this.webFullScreen && this.browser.settings.findVisible) {
        FindBar({ browser: $browser, settings: this.browser.settings })
      }
      // 书签面板与查找栏同级，展开时同样是独立横条
      if (!this.webFullScreen && this.browser.bookmarkStore.visible) {
        BookmarkPanel({ browser: $browser, bookmarks: this.browser.bookmarkStore })
      }
      // 历史记录面板同样与查找栏同级
      if (!this.webFullScreen && this.browser.historyStore.visible) {
        HistoryPanel({ browser: $browser, history: this.browser.historyStore })
      }
      // WebTab 常驻组件树：横竖屏切换仅切换标题栏/工具栏，Web 不销毁，浏览状态不丢失
      WebTab({
        browser: $browser,
        settings: this.browser.settings,
        homeIsPhone: this.homeIsPhone,
        onFullScreenChange: (fullScreen: boolean) => {
          this.webFullScreen = fullScreen;
        }
      })
        .layoutWeight(1)
      if (!this.webFullScreen && this.isPhone) {
        // 手机布局没有页签条，存在多个页签时补一条页签栏，否则用户无法切回之前的页签
        if (this.browser.webArray.length > 1) {
          BrowserTabs({
            browser: $browser,
            onExitApp: () => {
              this.exitApp();
            }
          })
        }
        PhoneToolBar({ browser: $browser })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  onBackPress(): boolean {
    Logger.info(TAG, `enter onBackPress`);
    // 网页全屏时返回键先退出全屏，而不是直接后退网页
    if (this.webFullScreen) {
      this.browser.requestExitFullScreen();
      this.webFullScreen = false;
      return true;
    }
    try {
      const controller = this.browser.webControllerArray[this.browser.tabArrayIndex]?.controller;
      // 仅在当前页可后退时消费返回键；否则交还系统处理（退出应用），
      // 修复原实现“加载中即视为可后退”导致的返回无响应问题
      if (controller?.accessBackward()) {
        controller.backward();
        return true;
      }
      return false;
    } catch (e) {
      Logger.info(TAG, `onBackPress error: ${JSON.stringify(e)}`);
      return false;
    }
  }
}