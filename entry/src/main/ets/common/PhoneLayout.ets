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
          .onSubmit(() => {
            // 统一走 Browser.loadUrl，由 formatUrl 做协议补全与搜索词归一化
            this.browser.loadUrl(this.addr);
            this.addr = '';
          })

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.submit'))
            .width(TOOL_ICON_SIZE)
            .height(TOOL_ICON_SIZE)
            .opacity(this.hasDown ? 1 : 0.4)
        }
        .backgroundColor($r('app.color.transparent'))
        .width(TOUCH_TARGET)
        .height(TOUCH_TARGET)
        .margin({ left: 8, right: 8 })
        .onClick(() => {
          if (this.addr === '') {
            return;
          }
          this.browser.loadUrl(this.addr);
          this.addr = '';
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

// 手机布局底部工具栏：主页/新标签/关闭/后退/刷新/前进
@Component
export struct PhoneToolBar {
  @Link browser: Browser;
  @State arrayIndex: number = 0;
  private toolPoneArray: ButtonItem[] = [
    {
      imageSrc: $r('app.media.aa'), id: 3
    },
    {
      imageSrc: $r('app.media.add'), id: 1
    },
    {
      imageSrc: $r('app.media.delete'), id: 2
    },
    {
      imageSrc: $r('app.media.fresh'), id: 0
    },
    {
      imageSrc: $r('app.media.home'), id: 5
    },
    {
      imageSrc: $r('app.media.bb'), id: 6
    }
  ];

  build() {
    Row() {
      ForEach(this.toolPoneArray, (item: ButtonItem, index: number) => {
        Column() {
          Divider().color($r('app.color.divider_light'))
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image(item.imageSrc)
              .width(TOOL_ICON_SIZE)
              .height(TOOL_ICON_SIZE)
          }
          .id(item.id)
          .backgroundColor(item.id !== this.arrayIndex ? $r('app.color.transparent') : $r('app.color.press_bg'))
          .width('20%')
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
                this.arrayIndex = 0;
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
        }
        .width('20%')
        .height('100%')
      }, (item: ButtonItem) => item.id.toString())
    }
    .height(TOOLBAR_HEIGHT)
    .width('100%')
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }
}
