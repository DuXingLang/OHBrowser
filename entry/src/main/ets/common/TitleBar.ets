/*
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
import { Browser, LoadingStatus, WebObject } from '../model/Browser';
import Logger from '../model/Logger';
import webview from '@ohos.web.webview';
import { promptAction } from '@kit.ArkUI';

const TAG: string = '[TitleBar]';
// 无障碍建议的最小点击热区（vp）
const BUTTON_WIDTH: number = 40;
// 图标显示尺寸
const ICON_SIZE: number = 24;
const BUTTON_RADIUS: number = 4;
// 页签固定宽度
const TAB_WIDTH: number = 180;

interface TitleButtonItem {
  imageSrc: Resource,
  id: number
}

@Component
export struct TabletTitle {
  @Link browser: Browser;
  @State arrayIndex: number = 0;
  private addr: string = '';
  private navigationButton: Array<{
    imageSrc: Resource,
    id: number
  }> = [
    {
      imageSrc: $r('app.media.ic_public_back'),
      id: 1
    },
    {
      imageSrc: $r('app.media.ic_public_advance'),
      id: 2
    },
    {
      imageSrc: $r('app.media.ic_public_refresh'),
      id: 3
    },
    {
      imageSrc: $r('app.media.ic_public_home'),
      id: 4
    },
  ]
  private actionButton: Array<{
    imageSrc: Resource,
    id: number
  }> = [
    {
      imageSrc: $r('app.media.submit'),
      id: 5
    },
    {
      imageSrc: $r('app.media.ic_public_add'),
      id: 6
    },
  ]

  build() {
    Row() {
      ForEach(this.navigationButton, (item, index) => {
        Button({ type: ButtonType.Normal }) {
          Image(item.imageSrc).width(ICON_SIZE).height(ICON_SIZE)
        }
        .margin(8)
        .id(`navigationButton${index}`)
        .width(BUTTON_WIDTH)
        .height(BUTTON_WIDTH)
        .backgroundColor(this.arrayIndex === item.id ? $r('app.color.press_bg') : $r('app.color.transparent'))
        .borderRadius(BUTTON_RADIUS)
        .flexShrink(0)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.arrayIndex = item.id;
          }

          if (event.type === TouchType.Up) {
            this.arrayIndex = 0;
          }
        })
        .onClick((event: ClickEvent) => {
          switch (item.id) {
            case 1:
              this.browser.Back();
              break;
            case 2:
              this.browser.Forward();
              break;
            case 3:
              this.browser.Refresh();
              break;
            case 4:
              this.browser.webControllerArray[this.browser.tabArrayIndex]?.controller
                .loadUrl($rawfile('pad.html'));
              break;
          }
        })
      }, item => item.id.toString())

      TextInput({ placeholder: $r('app.string.Input_url'), text: this.browser.inputValue })
        .placeholderFont({ size: 18, weight: 500 })
        .fontSize(18)
        .margin(2)
        .id('inputUrl')
        .layoutWeight(1)
        .onChange((value: string) => {
          this.addr = value;
        })
        .onSubmit((enterKey: EnterKeyType) => {
          Logger.info(TAG, `onSubmit`)
          if (this.addr.length !== 0) {
            // 统一走 Browser.loadUrl，由 formatUrl 做协议补全与搜索词归一化
            this.browser.loadUrl(this.addr);
            this.addr = '';
          }
        })

      ForEach(this.actionButton, (item: TitleButtonItem, index: number) => {
        Button({ type: ButtonType.Normal }) {
          Image(item.imageSrc).width(ICON_SIZE).height(ICON_SIZE)
        }
        .margin(8)
        .id(`actionButton${index}`)
        .width(BUTTON_WIDTH)
        .height(BUTTON_WIDTH)
        .backgroundColor(this.arrayIndex === item.id ? $r('app.color.press_bg') : $r('app.color.transparent'))
        .borderRadius(BUTTON_RADIUS)
        .flexShrink(0)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.arrayIndex = item.id;
          }
          if (event.type === TouchType.Up) {
            this.arrayIndex = 0;
          }
        })
        .onClick((event: ClickEvent) => {
          if (item.id === 5) {
            if (this.addr.length !== 0) {
              // 统一走 Browser.loadUrl，由 formatUrl 做协议补全与搜索词归一化
              this.browser.loadUrl(this.addr);
              this.addr = '';
            }
          } else if (item.id === 6) {
            Logger.info(TAG, `add tab index = ` + this.arrayIndex);
            this.browser.addTab();
          }
        })
      }, (item: TitleButtonItem) => item.id.toString())
    }
    .width('100%')
    .height(48)
    .padding({ right: 5 })
    .backgroundColor($r('app.color.page_bg'))
    .flexShrink(0)
  }
}

@Component
export struct BrowserTabs {
  @Link browser: Browser;
  @State tabButtonIndex: number = -1;

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Start }) {
      ForEach(this.browser.webArray, (item, index) => {
        Row() {
          Row() {
            // 展示实际页面标题（onPageEnd 时更新），空标题回退为“主页”
            Text(this.browser.tabTitles[item.key] ?? '主页')
              .fontSize(14)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .flexShrink(1)
          .justifyContent(FlexAlign.Center)
          .height('100%')

          Button({ type: ButtonType.Normal }) {
            Image($r('app.media.ic_public_cancel_filled')).width(20).height(20)
          }
          .backgroundColor(this.tabButtonIndex === item.key ? $r('app.color.press_bg') : $r('app.color.transparent'))
          .id('cancelBtn')
          .margin({ right: 2 })
          .width(33)
          .height(33)
          .borderRadius(5)
          .flexShrink(0)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.tabButtonIndex = item.key;
            } else if (event.type === TouchType.Up) {
              this.tabButtonIndex = -1;
            }
          })
          .onClick((event: ClickEvent) => {
            if (this.browser.webArray.length > 1) {
              this.browser.deleteTab(item.key);
            }
          })
        }
        .width(TAB_WIDTH)
        .height('100%')
        .backgroundColor(this.browser.tabArrayIndex === item.key
          ? $r('app.color.tab_active_bg') : $r('app.color.tab_bar_bg'))
        .onClick((event: ClickEvent) => {
          Logger.info(TAG, `key= ${item.key}`);
          this.browser.setTabArrayIndex(item.key);
          this.browser.tabsController.changeIndex(item.key);
        })

        Divider().vertical(true).color($r('app.color.divider_color'))
      }, (item) => item.timestamp.toString())
    }
    .height(33)
    .flexShrink(0)
    .backgroundColor($r('app.color.tab_bar_bg'))
  }
}

@Component
export struct WebTab {
  @Link browser: Browser;
  @Link isPhone: boolean;
  isRegistered: boolean = false;
  testObj = {
    test: (addr: string) => {
      // HTML 端传入裸域名，统一走 formatUrl 做协议补全与搜索词归一化
      this.browser.loadUrl(addr);
    },
    searchWord: (word: string) => {
      Logger.info(`search word= ${word}`);
      this.browser.loadUrl(word);
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.Start, controller: this.browser.tabsController }) {
      ForEach(this.browser.webArray, (item, index) => {
        TabContent() {
          Web({
            src: this.isPhone ? $rawfile('phone.html') : $rawfile('pad.html'),
            controller: this.browser?.webControllerArray[item.key]?.controller
          })
            .javaScriptAccess(true)
            .fileAccess(true)
            .domStorageAccess(true)
            .mixedMode(MixedMode.All)
            .multiWindowAccess(true)
            .onWindowNew((event) => {
              Logger.info(TAG, `onWindowNew targetUrl: ` + event.targetUrl);
              if (event.targetUrl !== 'about:blank' && event.targetUrl !== '') {
                this.browser?.webControllerArray[item.key]?.controller.loadUrl(event.targetUrl);
              }
              event.handler.setWebController(null);
            })
            .onPageBegin((event) => {
              Logger.info(TAG, `onPageBegin= ${JSON.stringify(event)}`)
              if (event.url.startsWith('http')) {
                this.browser.inputValue = event.url;
              } else {
                this.browser.inputValue = '';
              }
              this.browser.loadingStatus = LoadingStatus.LOADING;
            })
            .onPageEnd((event) => {
              Logger.info(TAG, `onPageEnd= ${JSON.stringify(event)}`)
              if (item.key < this.browser.webControllerArray.length
                && this.browser.webControllerArray[item.key]?.controller) {
                this.browser.webControllerArray[item.key]?.controller?.runJavaScript('adapterDevice()');
                this.browser.loadingStatus = LoadingStatus.END;
                this.registerFunc(this.browser.webControllerArray[item.key]);
                // 用实际页面标题更新页签显示，空标题回退为“主页”
                try {
                  this.browser.setTabTitle(item.key,
                    this.browser.webControllerArray[item.key]?.controller?.getTitle() ?? '');
                } catch (error) {
                  Logger.error(TAG, `getTitle failed: ${JSON.stringify(error)}`);
                }
              }
            })
            .onProgressChange((event) => {
              Logger.info(TAG, `onProgressChange`);
              this.browser.progress = event.newProgress;
              if (this.browser.progress === 100) {
                this.browser.hideProgress = true;
                this.browser.progress = 0;
              } else {
                this.browser.hideProgress = false;
              }
            })
            .onErrorReceive((event) => {
              // 仅主文档加载失败时提示，避免子资源错误频繁打扰
              if (event && event.request.isMainFrame()) {
                promptAction.showToast({ message: '网页加载失败，请检查网络' });
              }
            })
        }
      }, (item) => item.timestamp.toString())
    }
    .barHeight(0)
    .scrollable(false)
  }

  registerFunc(webObject: WebObject) {
    if (!webObject.isRegistered) {
      Logger.info(TAG, `registerFunc`);
      webObject.controller.registerJavaScriptProxy(this.testObj, 'etsObj', ['test', 'searchWord']);
      webObject.isRegistered = true;
      webObject.controller.refresh();
    }
  }
}
