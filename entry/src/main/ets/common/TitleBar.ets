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
import { Browser, LoadingStatus, WebKey, WebObject, WebSettings } from '../model/Browser';
import webview from '@ohos.web.webview';
import Logger from '../model/Logger';
import { promptAction } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { MoreMenuButton } from './MoreMenu';

const TAG: string = '[TitleBar]';
// 圆形图标按钮直径（无障碍建议的最小点击热区）
const BUTTON_SIZE: number = 36;
// 工具栏与地址栏图标尺寸
const ICON_SIZE: number = 20;
const OMNIBOX_ICON_SIZE: number = 16;
// 地址栏（药丸）高度与圆角
const OMNIBOX_HEIGHT: number = 36;
const OMNIBOX_RADIUS: number = 18;
// 页签条与单个页签高度
const TAB_STRIP_HEIGHT: number = 40;
const TAB_HEIGHT: number = 34;
// 页签固定宽度与页签关闭按钮尺寸
const TAB_WIDTH: number = 200;
const CLOSE_BUTTON_SIZE: number = 24;
const CLOSE_ICON_SIZE: number = 16;
// 工具栏高度与不可用按钮透明度
const TOOLBAR_HEIGHT: number = 48;
const DISABLED_OPACITY: number = 0.38;
// 页签条右侧“新建页签”按钮尺寸
const NEW_TAB_SIZE: number = 28;

interface ToolButtonItem {
  imageSrc: Resource,
  id: number
}

@Component
export struct TabletTitle {
  @Link browser: Browser;
  @State arrayIndex: number = 0;
  private addr: string = '';
  private toolButton: ToolButtonItem[] = [
    {
      imageSrc: $r('app.media.ic_public_back'),
      id: 1
    },
    {
      imageSrc: $r('app.media.ic_public_advance'),
      id: 2
    },
    {
      imageSrc: $r('app.media.ic_public_home'),
      id: 4
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
    Column() {
      // 页签条：横向滚动 + 新建页签按钮，激活页签白底顶部圆角，与下方工具栏融为一体
      Row() {
        Scroll() {
          Row({ space: 4 }) {
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
            }, (item: WebKey) => item.timestamp.toString())
          }
          .alignItems(VerticalAlign.Bottom)
          .height('100%')
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .height('100%')

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.ic_public_add')).width(16).height(16)
        }
        .id('newTabButton')
        .width(28)
        .height(28)
        .borderRadius(6)
        .backgroundColor($r('app.color.transparent'))
        .margin({ right: 8 })
        .accessibilityText('新建页签')
        .onClick((event: ClickEvent) => {
          this.browser.addTab();
        })
      }
      .width('100%')
      .height(TAB_STRIP_HEIGHT)
      .padding({ left: 4, right: 4 })
      .backgroundColor($r('app.color.tab_bar_bg'))
      .alignItems(VerticalAlign.Bottom)

      Row() {
        ForEach(this.toolButton, (item: ToolButtonItem, index: number) => {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image(item.imageSrc).width(ICON_SIZE).height(ICON_SIZE).opacity(this.navOpacity(item.id))
          }
          .id(`toolButton${item.id}`)
          .width(BUTTON_SIZE)
          .height(BUTTON_SIZE)
          .borderRadius(BUTTON_SIZE / 2)
          .margin({ left: 2, right: 2 })
          .backgroundColor(this.arrayIndex === item.id ? $r('app.color.press_bg') : $r('app.color.transparent'))
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
              case 4:
                // 主页：加载内置平板首页；Web 未挂载时 loadUrl 抛 17100001，兜底忽略
                try {
                  this.browser.webControllerArray[this.browser.tabArrayIndex]?.controller
                    .loadUrl($rawfile('pad.html'));
                } catch (error) {
                  Logger.error(TAG, `loadHome failed: ${JSON.stringify(error)}`);
                }
                break;
              default:
                break;
            }
          })
        }, (item: ToolButtonItem) => item.id.toString())

        // Chrome 风格药丸地址栏：左置 globe 图标，右置刷新按钮，输入区居中
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
            .padding({ left: 6, right: 0 })
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

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image($r('app.media.ic_public_refresh')).width(OMNIBOX_ICON_SIZE).height(OMNIBOX_ICON_SIZE)
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.transparent'))
          .flexShrink(0)
          .accessibilityText('刷新网页')
          .onClick((event: ClickEvent) => {
            this.browser.Refresh();
          })
        }
        .height(OMNIBOX_HEIGHT)
        .borderRadius(OMNIBOX_RADIUS)
        .backgroundColor($r('app.color.omnibox_bg'))
        .padding({ left: 12, right: 4 })
        .layoutWeight(1)
        .margin({ left: 4, right: 8 })

        // 更多菜单：缩放 / 桌面版 UA / 深色渲染 / 缓存策略 / 清除浏览数据
        MoreMenuButton({
          browser: this.browser,
          settings: this.browser.settings,
          buttonSize: BUTTON_SIZE,
          iconSize: ICON_SIZE
        })
      }
      .width('100%')
      .height(TOOLBAR_HEIGHT)
      .padding({ left: 4, right: 4 })
      .backgroundColor($r('app.color.page_bg'))
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
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
    Row() {
      // 选择热区：favicon + 标题占满关闭按钮以外的空间
      Row() {
        if (this.item.favicon !== undefined) {
          // 已拿到站点图标时直接显示，避免所有页签都是同一个内置图标
          Image(this.item.favicon)
            .width(OMNIBOX_ICON_SIZE)
            .height(OMNIBOX_ICON_SIZE)
            .borderRadius(2)
            .objectFit(ImageFit.Contain)
            .flexShrink(0)
        } else {
          Image($r('app.media.ic_public_navigation'))
            .width(OMNIBOX_ICON_SIZE)
            .height(OMNIBOX_ICON_SIZE)
            .opacity(this.active ? 0.9 : 0.5)
            .flexShrink(0)
        }

        Text(this.item.title ? this.item.title : '主页')
          .fontSize(12)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .margin({ left: 6, right: 2 })
          .fontColor(this.active ? $r('app.color.text_primary') : $r('app.color.fg_secondary'))
      }
      .layoutWeight(1)
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
      .borderRadius(CLOSE_BUTTON_SIZE / 2)
      .flexShrink(0)
      .accessibilityText('关闭页签')
      .onClick((event: ClickEvent) => {
        this.onClose(this.item.key);
      })
    }
    .width(TAB_WIDTH)
    .height(TAB_HEIGHT)
    .padding({ left: 8, right: 2 })
    .borderRadius({ topLeft: 8, topRight: 8 })
    .backgroundColor(this.active ? $r('app.color.tab_active_bg') : $r('app.color.transparent'))
  }
}

// 手机布局的页签条：多于一个页签时显示，支持横向滚动
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
        }, (item: WebKey) => item.timestamp.toString())
      }
      .alignItems(VerticalAlign.Bottom)
      .height('100%')
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .height(TAB_STRIP_HEIGHT)
    .width('100%')
    .flexShrink(0)
    .backgroundColor($r('app.color.tab_bar_bg'))
  }
}

@Component
export struct WebTab {
  @Link browser: Browser;
  // 显示/网络行为设置：@ObjectLink 绑定后，切换缓存/深色等状态会重建 Web 组件属性
  @ObjectLink settings: WebSettings;
  // 起始首页按设备形态决定，运行期保持不变：横竖屏切换时 Web 的 src 不变，避免旋转导致页面重载
  @Prop homeIsPhone: boolean = true;
  // 网页全屏状态变化时回调页面，用于隐藏/恢复标题栏与工具栏
  onFullScreenChange: (fullScreen: boolean) => void = () => {
  };
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
            // 长页面始终显示滚动条，便于用户在触屏上判断当前位置
            .verticalScrollBarAccess(true)
            // 缓存策略：禁用时强制每次请求都回源，便于调试弱网首屏
            .cacheMode(this.settings.noCache ? CacheMode.None : CacheMode.Default)
            // 深色渲染：跟随系统；强制开启时把无深色样式的网页也做反色处理
            .darkMode(this.settings.forceDark ? webview.WebDarkMode.On : webview.WebDarkMode.Auto)
            .forceDarkAccess(this.settings.forceDark)
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
            .onHttpErrorReceive((event) => {
              // 4xx/5xx 由服务器正常返回，onErrorReceive 不会触发，这里单独提示错误码
              const code = event?.response?.getResponseCode() ?? 0;
              if (event?.request?.isMainFrame() && code >= 400) {
                promptAction.showToast({ message: `网页返回错误：${code}` });
              }
            })
            .onRenderExited((event) => {
              // 渲染进程异常退出（如内存不足被杀）：提示并尝试重载，避免留下白屏
              Logger.error(TAG, `onRenderExited reason= ${event?.renderExitReason}`);
              promptAction.showToast({ message: '页面渲染异常，正在重新加载' });
              this.browser.webControllerArray[item.key]?.controller?.refresh();
            })
            .onControllerAttached(() => {
              // Web 组件挂载完成、controller 已关联后才能设置下载委托
              this.setupDownload(this.browser.webControllerArray[item.key]);
            })
            .onFaviconReceived((event) => {
              // 站点图标用于页签左上角，取不到时页签回退为内置图标
              if (event?.favicon !== undefined) {
                this.browser.setTabFavicon(item.key, event.favicon);
              }
            })
            .onFullScreenEnter((event) => {
              // 网页视频等请求全屏：隐藏应用标题栏与工具栏，交给网页占满整屏
              this.browser.enterWebFullScreen(event.handler);
              this.onFullScreenChange(true);
            })
            .onFullScreenExit(() => {
              this.browser.exitWebFullScreen();
              this.onFullScreenChange(false);
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

  // 初始化下载能力：页面内触发的下载必须在 onBeforeDownload 中调用 start 才会真正开始。
  // 文件统一落到应用沙箱的 Download 目录，无需申请公共目录读写权限。
  private setupDownload(object: WebObject | undefined) {
    if (object === undefined) {
      return;
    }
    const dir = getContext(this).filesDir + '/Download/';
    try {
      // 目录已存在时 mkdirSync 会抛错，这里只关心“目录可用”这一结果
      fileIo.mkdirSync(dir);
    } catch (error) {
      Logger.info(TAG, `download dir already exists: ${JSON.stringify(error)}`);
    }
    try {
      this.browser.setupDownload(dir);
      this.browser.attachDownloadDelegate(object.controller);
    } catch (error) {
      Logger.error(TAG, `setupDownload failed: ${JSON.stringify(error)}`);
    }
  }
}
