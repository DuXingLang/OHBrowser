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
import { Browser, LoadingStatus, WebKey, WebObject } from '../model/Browser';
import Logger from '../model/Logger';
import { promptAction } from '@kit.ArkUI';

const TAG: string = '[TitleBar]';
// 无障碍建议的最小点击热区（vp）
const BUTTON_WIDTH: number = 40;
// 图标显示尺寸
const ICON_SIZE: number = 24;
const BUTTON_RADIUS: number = 4;
// 页签固定宽度
const TAB_WIDTH: number = 180;
// 页签条高度
const TAB_BAR_HEIGHT: number = 33;
// 页签关闭按钮尺寸
const CLOSE_BUTTON_SIZE: number = 33;
const CLOSE_ICON_SIZE: number = 20;
// 不可用按钮的透明度，用于表达“前进/后退”当前不可点击
const DISABLED_OPACITY: number = 0.4;

interface TitleButtonItem {
  imageSrc: Resource,
  id: number
}

@Component
export struct TabletTitle {
  @Link browser: Browser;
  @State arrayIndex: number = 0;
  private addr: string = '';
  private navigationButton: TitleButtonItem[] = [
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
  private actionButton: TitleButtonItem[] = [
    {
      imageSrc: $r('app.media.submit'),
      id: 5
    },
    {
      imageSrc: $r('app.media.ic_public_add'),
      id: 6
    },
  ]

  // 前进/后退不可用时降低图标透明度
  private navOpacity(id: number): number {
    if (id === 1 && !this.browser.canBack) {
      return DISABLED_OPACITY;
    }
    if (id === 2 && !this.browser.canForward) {
      return DISABLED_OPACITY;
    }
    return 1;
  }

  build() {
    Row() {
      ForEach(this.navigationButton, (item: TitleButtonItem, index: number) => {
        Button({ type: ButtonType.Normal }) {
          Image(item.imageSrc).width(ICON_SIZE).height(ICON_SIZE).opacity(this.navOpacity(item.id))
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
      }, (item: TitleButtonItem) => item.id.toString())

      TextInput({ placeholder: $r('app.string.Input_url'), text: this.browser.inputValue })
        .placeholderFont({ size: 18, weight: 500 })
        .fontSize(18)
        .margin(2)
        .id('inputUrl')
        .layoutWeight(1)
        .onChange((value: string) => {
          this.addr = value;
        })
        .enterKeyType(EnterKeyType.Go)
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

// 单个页签：@ObjectLink 绑定 WebKey，标题变化只刷新该页签
@Component
struct TabItem {
  @ObjectLink item: WebKey;
  @Prop active: boolean = false;
  onSelect: (key: number) => void = () => {
  };
  onClose: (key: number) => void = () => {
  };

  build() {
    // 用 Stack 让关闭按钮独立占据右侧热区，避免与页签选择点击嵌套、一次点击触发两个动作
    Stack({ alignContent: Alignment.End }) {
      Row() {
        Text(this.item.title ? this.item.title : '主页')
          .fontSize(14)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ left: 8, right: CLOSE_BUTTON_SIZE + 4 })
      }
      .width('100%')
      .height('100%')
      .onClick((event: ClickEvent) => {
        this.onSelect(this.item.key);
      })

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Image($r('app.media.ic_public_cancel_filled')).width(CLOSE_ICON_SIZE).height(CLOSE_ICON_SIZE)
      }
      .backgroundColor($r('app.color.transparent'))
      .width(CLOSE_BUTTON_SIZE)
      .height(CLOSE_BUTTON_SIZE)
      .borderRadius(5)
      .flexShrink(0)
      .margin({ right: 2 })
      .accessibilityText('关闭页签')
      .onClick((event: ClickEvent) => {
        this.onClose(this.item.key);
      })
    }
    .width(TAB_WIDTH)
    .height('100%')
    .backgroundColor(this.active ? $r('app.color.tab_active_bg') : $r('app.color.tab_bar_bg'))
  }
}

@Component
export struct BrowserTabs {
  @Link browser: Browser;

  build() {
    // 页签数量多于一屏时可横向滚动，避免多余页签被裁掉、无法切换
    Scroll() {
      Row() {
        ForEach(this.browser.webArray, (item: WebKey, index: number) => {
          TabItem({
            item: item,
            active: this.browser.tabArrayIndex === item.key,
            onSelect: (key: number) => {
              Logger.info(TAG, `key= ${key}`);
              // 关闭按钮与页签选择同源事件时可能收到已失效的下标，越界直接忽略
              if (key < 0 || key >= this.browser.webArray.length) {
                return;
              }
              this.browser.setTabArrayIndex(key);
              this.browser.tabsController.changeIndex(key);
              this.browser.updateHistoryState();
            },
            onClose: (key: number) => {
              this.browser.deleteTab(key);
            }
          })
          Divider().vertical(true).color($r('app.color.divider_color'))
        }, (item: WebKey) => item.timestamp.toString())
      }
      .height('100%')
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .height(TAB_BAR_HEIGHT)
    .width('100%')
    .flexShrink(0)
    .backgroundColor($r('app.color.tab_bar_bg'))
  }
}

@Component
export struct WebTab {
  @Link browser: Browser;
  // 起始首页按设备形态决定，运行期保持不变：横竖屏切换时 Web 的 src 不变，避免旋转导致页面重载
  @Prop homeIsPhone: boolean = true;
  // 注入给 HTML 的桥接对象，方法名需与 registerJavaScriptProxy 的第三个参数一致
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
      ForEach(this.browser.webArray, (item: WebKey, index: number) => {
        TabContent() {
          Web({
            src: this.homeIsPhone ? $rawfile('phone.html') : $rawfile('pad.html'),
            controller: this.browser?.webControllerArray[item.key]?.controller
          })
            .javaScriptAccess(true)
            .fileAccess(true)
            .domStorageAccess(true)
            .mixedMode(MixedMode.All)
            .multiWindowAccess(true)
            .zoomAccess(true)
            // 跟随系统深浅色：网页内容一并切换暗色渲染
            .darkMode(WebDarkMode.Auto)
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
                this.browser.updateHistoryState();
              }
            })
            .onProgressChange((event) => {
              Logger.info(TAG, `onProgressChange`);
              this.browser.progress = event.newProgress;
              if (this.browser.progress === 100) {
                this.browser.hideProgress = true;
                this.browser.progress = 0;
                this.browser.updateHistoryState();
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
      }, (item: WebKey) => item.timestamp.toString())
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