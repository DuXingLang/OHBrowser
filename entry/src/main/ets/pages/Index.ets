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
import { Browser } from '../model/Browser';
import Logger from '../model/Logger';
import { PhoneHeader, PhoneToolBar } from '../common/PhoneLayout';
import { TabletTitle, BrowserTabs, WebTab } from '../common/TitleBar';

const TAG: string = '[browser.Index]';

@Entry
@Component
struct Index {
  // true 使用手机布局；false 使用平板（多页签）布局
  @State isPhone: boolean = false;
  @State browser: Browser = new Browser();
  private listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(orientation:landscape)');

  // 屏幕方向变化回调：横屏切换为平板布局，竖屏切换为手机布局
  orientationCallback = (result: mediaquery.MediaQueryResult) => {
    this.isPhone = !result.matches;
    Logger.info(TAG, `orientationCallback end, isPhone = ${this.isPhone}`);
  }

  onDeviceChange() {
    Logger.info(TAG, `onDeviceChange`);
    this.browser = new Browser();
  }

  aboutToAppear() {
    try {
      const deviceType = deviceInfo.deviceType;
      if (deviceType === 'tablet' || deviceType === '2in1') {
        // 平板/2in1 屏幕较大，始终使用多页签平板布局
        this.isPhone = false;
      } else if (deviceType === 'default') {
        // 模拟器/预览器形态未知，跟随屏幕方向切换布局
        this.isPhone = !this.listener.matches;
        this.listener.on('change', this.orientationCallback);
      } else {
        // 手机固定使用手机布局
        this.isPhone = true;
      }
      Logger.info(TAG, `aboutToAppear deviceType = ${deviceType}, isPhone = ${this.isPhone}`);
    } catch (e) {
      Logger.info(TAG, `getSync unexpected error: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Column() {
      if (this.isPhone) {
        PhoneHeader({ browser: $browser })
      } else {
        TabletTitle({ browser: $browser })
        Progress({ value: this.browser.progress, total: 100 })
          .color($r('app.color.progress_blue'))
          .visibility(this.browser.hideProgress ? Visibility.Hidden : Visibility.Visible)
          .flexShrink(0)
        BrowserTabs({ browser: $browser })
        Divider().color($r('app.color.divider_color')).width('100%').flexShrink(0)
      }
      // WebTab 常驻组件树：横竖屏切换仅切换标题栏/工具栏，Web 不销毁，浏览状态不丢失
      WebTab({ browser: $browser, isPhone: $isPhone })
        .layoutWeight(1)
      if (this.isPhone) {
        PhoneToolBar({ browser: $browser })
      }
    }
  }

  onBackPress(): boolean {
    Logger.info(TAG, `enter onBackPress`);
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
