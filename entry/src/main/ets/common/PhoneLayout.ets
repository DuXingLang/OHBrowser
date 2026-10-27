/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { Browser } from '../model/Browser';
import Logger from '../model/Logger';
import { MoreMenuButton } from './MoreMenu';

const TAG: string = '[PhoneLayout]';
// 工具栏图标显示尺寸
const TOOL_ICON_SIZE: number = 24
// 地址栏内图标尺寸
const OMNIBOX_ICON_SIZE: number = 16
// 无障碍建议的最小点击热区（vp）
const TOUCH_TARGET: number = 40
// 工具栏高度
const TOOLBAR_HEIGHT: number = 48
// 地址栏高度与圆角（Chrome 药丸样式）
const OMNIBOX_HEIGHT: number = 36
const OMNIBOX_RADIUS: number = 18
// 页签条高度（手机布局多页签时显示）
const TAB_STRIP_HEIGHT: number = 40
// 不可用按钮的透明度，用于表达“前进/后退/关闭”当前不可点击
const DISABLED_OPACITY: number = 0.38

interface ButtonItem {
  imageSrc: Resource;
  id: number;
}

// 手机布局顶部区：药丸地址栏（左 globe、右刷新）+ 进度条
@Component
export struct PhoneHeader {
  @Link browser: Browser;
  private addr: string = '';

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_public_navigation'))
          .width(OMNIBOX_ICON_SIZE)
          .height(OMNIBOX_ICON_SIZE)
          .opacity(0.55)
          .flexShrink(0)

        TextInput({ placeholder: $r('app.string.Input_url'), text: this.browser.inputValue })
          .placeholderFont({ size: 14 })
          .fontSize(14)
          .height(32)
          .id('inputUrl')
          .layoutWeight(1)
          .backgroundColor($r('app.color.transparent'))
          .padding({ left: 6, right: 4 })
          .onChange((value: string) => {
            this.addr = value;
          })
          .enterKeyType(EnterKeyType.Go)
          .onSubmit(() => {
            // 统一走 Browser.loadUrl，由 formatUrl 做协议补全与搜索词归一化
            if (this.addr.length === 0) {
              return;
            }
            this.browser.loadUrl(this.addr);
            this.addr = '';
          })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.ic_public_refresh')).width(OMNIBOX_ICON_SIZE).height(OMNIBOX_ICON_SIZE)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.transparent'))
        .flexShrink(0)
        .accessibilityText('刷新网页')
        .onClick(() => {
          this.browser.Refresh();
        })
      }
      .width('100%')
      .height(OMNIBOX_HEIGHT)
      .borderRadius(OMNIBOX_RADIUS)
      .backgroundColor($r('app.color.omnibox_bg'))
      .padding({ left: 12, right: 4 })

      // 加载进度条：仅加载中显示
      Progress({ value: this.browser.progress, total: 100 })
        .color($r('app.color.progress_blue'))
        .height(2)
        .margin({ top: 2 })
        .visibility(this.browser.hideProgress ? Visibility.Hidden : Visibility.Visible)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6, left: 8, right: 8 })
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }
}

// 手机布局底部工具栏：后退/前进/主页/新建/关闭
@Component
export struct PhoneToolBar {
  @Link browser: Browser;
  private toolPoneArray: ButtonItem[] = [
    {
      imageSrc: $r('app.media.ic_public_back'), id: 3
    },
    {
      imageSrc: $r('app.media.ic_public_advance'), id: 6
    },
    {
      imageSrc: $r('app.media.ic_public_home'), id: 5
    },
    {
      imageSrc: $r('app.media.ic_public_add'), id: 1
    },
    {
      imageSrc: $r('app.media.ic_public_cancel_filled'), id: 2
    }
  ];

  // 各按钮的可用态：不可用时降低透明度，避免用户反复点击无响应
  private toolOpacity(id: number): number {
    switch (id) {
      case 3:
        return this.browser.canBack ? 1 : DISABLED_OPACITY;
      case 6:
        return this.browser.canForward ? 1 : DISABLED_OPACITY;
      case 2:
        return this.browser.webArray.length > 1 ? 1 : DISABLED_OPACITY;
      default:
        return 1;
    }
  }

  build() {
    Column() {
      Divider().color($r('app.color.divider_light'))
      Row() {
        ForEach(this.toolPoneArray, (item: ButtonItem) => {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image(item.imageSrc)
              .width(TOOL_ICON_SIZE)
              .height(TOOL_ICON_SIZE)
              .opacity(this.toolOpacity(item.id))
          }
          .id(`toolButton${item.id}`)
          .backgroundColor($r('app.color.transparent'))
          .layoutWeight(1)
          .height('100%')
          .accessibilityText(this.toolAccessibility(item.id))
          .onClick(() => {
            switch (item.id) {
              case 1:
                this.browser.addTab();
                break;
              case 2:
                this.browser.deleteTab(this.browser.getTabArrayIndex());
                break;
              case 3:
                this.browser.Back();
                break;
              case 5:
                // 主页：空保护后加载内置首页；Web 未挂载时 loadUrl 抛 17100001，兜底忽略
                try {
                  this.browser.webControllerArray[this.browser.tabArrayIndex]?.controller
                    .loadUrl($rawfile('phone.html'));
                } catch (error) {
                  Logger.error(TAG, `loadHome failed: ${JSON.stringify(error)}`);
                }
                break;
              case 6:
                this.browser.Forward();
                break;
              default:
                break;
            }
          })
        }, (item: ButtonItem) => item.id.toString())

        // 更多菜单：缩放 / 桌面版 UA / 深色渲染 / 缓存策略 / 清除浏览数据，
        // 与其余按钮等分宽度，保证 6 个入口在窄屏上也均分热区
        Column() {
          MoreMenuButton({
            browser: this.browser,
            settings: this.browser.settings,
            buttonSize: TOUCH_TARGET,
            iconSize: TOOL_ICON_SIZE
          })
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .height(TOOLBAR_HEIGHT)
    .width('100%')
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }

  // 无障碍文案：说明按钮用途
  private toolAccessibility(id: number): string {
    switch (id) {
      case 3:
        return '后退';
      case 6:
        return '前进';
      case 5:
        return '主页';
      case 1:
        return '新建页签';
      case 2:
        return '关闭页签';
      default:
        return '';
    }
  }
}
