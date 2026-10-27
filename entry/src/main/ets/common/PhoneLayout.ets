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

// 工具栏图标显示尺寸
const TOOL_ICON_SIZE: number = 24
// 无障碍建议的最小点击热区（vp）
const TOUCH_TARGET: number = 40
// 工具栏高度
const TOOLBAR_HEIGHT: number = 52
// 不可用按钮的透明度，用于表达“前进/后退/关闭”当前不可点击
const DISABLED_OPACITY: number = 0.4

interface ButtonItem {
  imageSrc: Resource;
  id: number;
}

// 手机布局顶部区：地址栏 + 进度条
@Component
export struct PhoneHeader {
  @Link browser: Browser;
  @State hasDown: boolean = false;
  private addr: string = '';

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        TextInput({ placeholder: $r('app.string.Input_url'), text: this.browser.inputValue })
          .placeholderFont({ size: 16, weight: 500 })
          .fontSize(16)
          .height(34)
          .margin({ left: 6 })
          .id('inputUrl')
          .layoutWeight(1)
          .onChange((value: string) => {
            this.addr = value;
            this.hasDown = this.addr.length > 0;
          })
          .enterKeyType(EnterKeyType.Go)
          .onSubmit(() => {
            // 统一走 Browser.loadUrl，由 formatUrl 做协议补全与搜索词归一化
            if (this.addr.length === 0) {
              return;
            }
            this.browser.loadUrl(this.addr);
            this.addr = '';
            this.hasDown = false;
          })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.submit'))
            .width(TOOL_ICON_SIZE)
            .height(TOOL_ICON_SIZE)
            .opacity(this.hasDown ? 1 : DISABLED_OPACITY)
        }
        .backgroundColor($r('app.color.transparent'))
        .width(TOUCH_TARGET)
        .height(TOUCH_TARGET)
        .margin({ left: 8, right: 8 })
        .enabled(this.hasDown)
        .onClick(() => {
          if (this.addr === '') {
            return;
          }
          this.browser.loadUrl(this.addr);
          this.addr = '';
          this.hasDown = false;
        })
      }
      .width('100%')
      .padding({ top: 4, left: 6, right: 6 })

      // 加载进度条：仅加载中显示
      Progress({ value: this.browser.progress, total: 100 })
        .color($r('app.color.progress_blue'))
        .height(2)
        .margin({ top: 2 })
        .visibility(this.browser.hideProgress ? Visibility.Hidden : Visibility.Visible)
    }
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }
}

// 手机布局底部工具栏：后退/新建/关闭/刷新/主页/前进
@Component
export struct PhoneToolBar {
  @Link browser: Browser;
  private toolPoneArray: ButtonItem[] = [
    {
      imageSrc: $r('app.media.ic_public_back'), id: 3
    },
    {
      imageSrc: $r('app.media.ic_public_add'), id: 1
    },
    {
      imageSrc: $r('app.media.ic_public_cancel_filled'), id: 2
    },
    {
      imageSrc: $r('app.media.ic_public_refresh'), id: 0
    },
    {
      imageSrc: $r('app.media.ic_public_home'), id: 5
    },
    {
      imageSrc: $r('app.media.ic_public_advance'), id: 6
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
        // 6 个按钮用 layoutWeight 均分，避免固定百分比（6×20%）超出容器宽度
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
          .onClick(() => {
            switch (item.id) {
              case 0:
                this.browser.Refresh();
                break;
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
                // 主页：空保护后加载内置首页
                this.browser.webControllerArray[this.browser.tabArrayIndex]?.controller.loadUrl($rawfile('phone.html'));
                break;
              case 6:
                this.browser.Forward();
                break;
              default:
                break;
            }
          })
        }, (item: ButtonItem) => item.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
    }
    .height(TOOLBAR_HEIGHT)
    .width('100%')
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }
}