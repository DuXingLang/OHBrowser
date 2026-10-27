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
import Logger from './Logger'
import { promptAction } from '@kit.ArkUI';
import webview from '@ohos.web.webview';
import { image } from '@kit.ImageKit';
import common from '@ohos.app.ability.common';
import { formatUrl } from './UrlFormatter';
import { Bookmark, normalizeTitle } from './BookmarkList';
import { BookmarkStore } from './BookmarkStore';

export { formatUrl };

export class WebObject {
  controller: webview.WebviewController;
  isRegistered: boolean;
  constructor(controller: webview.WebviewController, isRegistered: boolean) {
    this.controller = controller
    this.isRegistered = isRegistered
  }
}

@Observed
export class WebKey {
  key: number;
  timestamp: number;
  // 页签标题：onPageEnd 时更新为实际页面标题；空标题回退为“主页”。
  // 放在 @Observed 对象上，页签条通过 @ObjectLink 绑定，标题变化可精确触发该页签刷新。
  title: string;
  // 页签图标：由 Web 组件的 onFaviconReceived 事件更新；未收到时页签回退为内置导航图标
  favicon: image.PixelMap | undefined = undefined;

  constructor(key: number, timestamp: number, title: string = '主页') {
    this.key = key
    this.timestamp = timestamp
    this.title = title
  }
}

export enum LoadingStatus {
  LOADING,
  END
}

/**
 * 浏览器可切换的显示与网络行为。
 *
 * 单独抽成 @Observed 类而不是散落在 Browser 上，是因为这些值既要做菜单文案，
 * 又要绑定到 Web 组件属性（cacheMode / darkMode / forceDarkAccess）；
 * 使用时通过 @ObjectLink 绑定本对象，值变化才能精确触发对应组件重建。
 */
@Observed
export class WebSettings {
  // 是否已切换为桌面版 UA
  desktopMode: boolean = false
  // 是否强制网页使用深色渲染
  forceDark: boolean = false
  // 是否禁用 HTTP 缓存（弱网/调试场景强制拉取最新资源）
  noCache: boolean = false
  // 当前缩放倍数，1 表示原始大小；zoom() 入参是相对比例，这里做累计换算
  zoomScale: number = 1
  // 是否处于网页全屏（网页视频等），true 时页面隐藏标题栏与工具栏
  isFullScreen: boolean = false
  // 是否展开页面内查找栏
  findVisible: boolean = false
  // 当前查找关键字，空串表示未在查找
  findKeyword: string = ''
  // 当前匹配项序号（从 0 开始，展示时需 +1）
  findIndex: number = 0
  // 匹配项总数，0 表示无匹配
  findTotal: number = 0
}

const TAG: string = '[browser]'
// 页签数量上限：超过后提示用户并拒绝新建，避免无限制创建 Web 组件导致内存耗尽
const MAX_TAB_COUNT: number = 10
// changeIndex 需等待 Tabs 内 ForEach 完成新 TabContent 渲染，取经验延时
const TAB_SWITCH_DELAY: number = 50
// 页签标题为空时的兜底文案
const DEFAULT_TAB_TITLE: string = '主页'
// 网页缩放：单次缩放步长与上下限（WebviewController.zoom 的入参是相对当前比例的倍数）
const ZOOM_STEP: number = 1.25
const MIN_ZOOM: number = 0.5
const MAX_ZOOM: number = 4
// 桌面版 User-Agent：真实站点据此返回 PC 布局
const DESKTOP_USER_AGENT: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'

export class Browser {
  inputValue: string = ""
  tabArrayIndex: number = 0
  progress: number = 0
  hideProgress: boolean = true
  loadingStatus: LoadingStatus = LoadingStatus.END
  // 当前页签是否可前进/后退，由 updateHistoryState 同步，供工具栏做禁用态展示
  canBack: boolean = false
  canForward: boolean = false

  webArray: Array<WebKey> = [new WebKey(0, new Date().getTime())]
  tabsController: TabsController = new TabsController()
  webControllerArray: Array<WebObject> = [new WebObject(new webview.WebviewController(), false)]

  deleteTab(index: number) {
    // 至少保留一个页签：关闭最后一个页签会让 Tabs 无数据源，Web 组件直接失效
    if (this.webArray.length <= 1) {
      promptAction.showToast({
        message: '至少保留一个页签'
      })
      return
    }
    Logger.info(TAG, `delete before tab index= ${index} controller length ${this.webControllerArray.length} tabArrayIndex= ${this.tabArrayIndex}`)
    this.webArray.splice(index, 1)
    this.webControllerArray.splice(index, 1)
    if (this.tabArrayIndex > index || this.tabArrayIndex === this.webArray.length) {
      this.tabArrayIndex -= 1
    }
    for (let i = index;i < this.webArray.length; ++i) {
      this.webArray[i].key -= 1
    }
    for (let i = 0;i < this.webArray.length; ++i) {
      Logger.info(TAG, `key ${this.webArray[i].key}, time=${this.webArray[i].timestamp}`)
    }
    Logger.info(`delete after tab index=${index}, controller length=${this.webControllerArray.length}, tabArrayIndex=${this.tabArrayIndex}`)
    // 与 addTab 保持一致：先等 ForEach 完成页签重建，再切换选中项，避免切换到未渲染的页签
    setTimeout(() => {
      this.tabsController.changeIndex(this.tabArrayIndex)
      this.updateHistoryState()
    }, TAB_SWITCH_DELAY)
  }

  getWebArray() {
    return this.webArray
  }

  addTab() {
    if (this.webArray.length >= MAX_TAB_COUNT) {
      promptAction.showToast({
        message: '页签数量已满'
      })
      return;
    }
    let webController: webview.WebviewController = new webview.WebviewController();
    let object = new WebObject(webController, false)
    this.webControllerArray.push(object)
    this.webArray.push(new WebKey(this.webArray.length, new Date().getTime()))
    this.tabArrayIndex = this.webArray.length - 1
    Logger.info(TAG, `add tab index= ${this.tabArrayIndex}`)
    setTimeout(() => {
      this.tabsController.changeIndex(this.tabArrayIndex)
      this.updateHistoryState()
    }, TAB_SWITCH_DELAY)
  }

  setTabArrayIndex(tabArrayIndex: number) {
    this.tabArrayIndex = tabArrayIndex
  }

  getTabArrayIndex() {
    return this.tabArrayIndex
  }

  setTabTitle(key: number, title: string) {
    if (key < 0 || key >= this.webArray.length) {
      return;
    }
    // 空标题回退为“主页”，避免页签显示空白
    this.webArray[key].title = title.length > 0 ? title : DEFAULT_TAB_TITLE
  }

  // 同步前进/后退可用状态：页面加载结束、页签切换后调用。
  // 新建页签后 Web 组件尚未挂载时，controller 未关联 Web 组件，
  // accessBackward/accessForward 会抛 17100001，这里兜底为不可前进/后退。
  updateHistoryState() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    try {
      this.canBack = controller?.accessBackward() ?? false;
      this.canForward = controller?.accessForward() ?? false;
    } catch (error) {
      Logger.error(TAG, `updateHistoryState failed: ${JSON.stringify(error)}`);
      this.canBack = false;
      this.canForward = false;
    }
  }

  setInputVal(inputValue: string) {
    this.inputValue = inputValue
  }

  getInputVal() {
    return this.inputValue
  }

  loadUrl(addr: string) {
    const url = formatUrl(addr);
    if (url.length === 0) {
      return;
    }
    this.webControllerArray[this.tabArrayIndex]?.controller.loadUrl(url);
  }

  Back() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    // 新页签 Web 未挂载时 accessBackward 抛 17100001，兜底为忽略点击
    try {
      if (controller?.accessBackward()) {
        controller.backward();
      }
    } catch (error) {
      Logger.error(TAG, `Back failed: ${JSON.stringify(error)}`);
    }
  }

  Forward() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    // 同 updateHistoryState：Web 未挂载时 accessForward 抛 17100001，兜底忽略
    try {
      if (controller?.accessForward()) {
        controller.forward();
      }
    } catch (error) {
      Logger.error(TAG, `Forward failed: ${JSON.stringify(error)}`);
    }
  }

  Refresh() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    // 新页签 Web 未挂载时 refresh 同样会抛 17100001
    try {
      controller?.refresh();
    } catch (error) {
      Logger.error(TAG, `Refresh failed: ${JSON.stringify(error)}`);
    }
  }

  // ==================== 基于 OpenHarmony 5.0.x ArkWeb API 的扩展能力 ====================
  // 以下状态供 UI 菜单展示与 Web 组件属性绑定；所有 controller 调用都先判空 + try/catch，
  // 因为新建页签/页签切换的瞬间 controller 可能尚未与 Web 组件关联（错误码 17100001）。

  // 可切换的显示/网络行为，UI 与 Web 组件共同绑定该对象
  settings: WebSettings = new WebSettings()
  // 移动版原始 UA，切回移动版时恢复
  private mobileUserAgent: string = ''
  // 下载委托需要常驻引用，否则会被回收导致下载回调丢失
  private downloadDelegate: webview.WebDownloadDelegate | null = null
  // 网页全屏退出句柄，由 Web 组件的 onFullScreenEnter 事件提供
  private fullScreenHandler: webview.FullScreenExitHandler | null = null

  // 取当前页签的控制器；未挂载到 Web 组件时返回 undefined
  private getController(): webview.WebviewController | undefined {
    return this.webControllerArray[this.tabArrayIndex]?.controller
  }

  // 放大网页
  zoomIn() {
    this.zoomTo(Math.min(this.settings.zoomScale * ZOOM_STEP, MAX_ZOOM));
  }

  // 缩小网页
  zoomOut() {
    this.zoomTo(Math.max(this.settings.zoomScale / ZOOM_STEP, MIN_ZOOM));
  }

  // 恢复原始缩放比例
  resetZoom() {
    this.zoomTo(1);
  }

  private zoomTo(scale: number) {
    const controller = this.getController();
    if (controller === undefined) {
      return;
    }
    // 目标比例与当前比例一致时无需调用，避免无意义的渲染刷新
    if (Math.abs(scale - this.settings.zoomScale) < 0.001) {
      return;
    }
    try {
      // zoom(factor) 作用于当前比例，故传入“目标倍数 / 当前倍数”
      controller.zoom(scale / this.settings.zoomScale);
      this.settings.zoomScale = scale;
    } catch (error) {
      Logger.error(TAG, `zoom failed: ${JSON.stringify(error)}`);
    }
  }

  // 桌面版/移动版 UA 切换：真实站点据此返回不同布局，切换后刷新才生效
  toggleDesktopMode() {
    const controller = this.getController();
    if (controller === undefined) {
      return;
    }
    try {
      if (!this.settings.desktopMode) {
        this.mobileUserAgent = controller.getUserAgent();
        controller.setCustomUserAgent(DESKTOP_USER_AGENT);
        this.settings.desktopMode = true;
        promptAction.showToast({ message: '已切换到桌面版网站' });
      } else {
        controller.setCustomUserAgent(this.mobileUserAgent);
        this.settings.desktopMode = false;
        promptAction.showToast({ message: '已切换到移动版网站' });
      }
      controller.refresh();
    } catch (error) {
      Logger.error(TAG, `toggleDesktopMode failed: ${JSON.stringify(error)}`);
    }
  }

  // 切换强制深色渲染（Web 组件通过 darkMode + forceDarkAccess 绑定本状态）
  toggleForceDark() {
    this.settings.forceDark = !this.settings.forceDark;
  }

  // 切换缓存策略（Web 组件通过 cacheMode 绑定本状态）
  toggleNoCache() {
    this.settings.noCache = !this.settings.noCache;
    // 缓存策略在组件属性重建后生效，刷新一次让当前页立即按新策略加载
    this.Refresh();
  }

  // 清除浏览数据：历史记录、Cookie、本地存储与 Web 数据
  clearBrowsingData() {
    const controller = this.getController();
    try {
      controller?.clearHistory();
    } catch (error) {
      Logger.error(TAG, `clearHistory failed: ${JSON.stringify(error)}`);
    }
    try {
      webview.WebCookieManager.clearAllCookiesSync();
    } catch (error) {
      Logger.error(TAG, `clearAllCookies failed: ${JSON.stringify(error)}`);
    }
    try {
      webview.WebStorage.deleteAllData();
    } catch (error) {
      Logger.error(TAG, `deleteAllData failed: ${JSON.stringify(error)}`);
    }
    promptAction.showToast({ message: '已清除浏览数据' });
  }

  // 网页请求进入全屏（如视频全屏播放）：隐藏应用标题栏与工具栏，并保存退出句柄
  enterWebFullScreen(handler: webview.FullScreenExitHandler) {
    this.fullScreenHandler = handler;
    this.settings.isFullScreen = true;
  }

  // 网页自行退出全屏（onFullScreenExit 事件）
  exitWebFullScreen() {
    this.settings.isFullScreen = false;
  }

  // 用户主动退出网页全屏：先恢复布局，再回调网页退出全屏
  requestExitFullScreen() {
    this.settings.isFullScreen = false;
    try {
      this.fullScreenHandler?.exitFullScreen();
    } catch (error) {
      Logger.error(TAG, `exitFullScreen failed: ${JSON.stringify(error)}`);
    }
    this.fullScreenHandler = null;
  }

  // 初始化下载能力：页面内触发的下载必须在 onBeforeDownload 中调用 start 才会真正开始
  setupDownload(dir: string) {
    if (this.downloadDelegate !== null) {
      return;
    }
    const delegate = new webview.WebDownloadDelegate();
    delegate.onBeforeDownload((item: webview.WebDownloadItem) => {
      try {
        item.start(dir + item.getSuggestedFileName());
        promptAction.showToast({ message: `开始下载：${item.getSuggestedFileName()}` });
      } catch (error) {
        Logger.error(TAG, `start download failed: ${JSON.stringify(error)}`);
      }
    });
    delegate.onDownloadFinish((item: webview.WebDownloadItem) => {
      promptAction.showToast({ message: `下载完成：${item.getSuggestedFileName()}` });
    });
    delegate.onDownloadFailed((item: webview.WebDownloadItem) => {
      promptAction.showToast({ message: '下载失败，请重试' });
    });
    this.downloadDelegate = delegate;
  }

  // 每个 Web 组件挂载后都要绑定一次下载委托（委托挂在 controller 上，页签切换不共享）
  attachDownloadDelegate(controller: webview.WebviewController) {
    if (this.downloadDelegate === null) {
      return;
    }
    try {
      controller.setDownloadDelegate(this.downloadDelegate);
    } catch (error) {
      Logger.error(TAG, `setDownloadDelegate failed: ${JSON.stringify(error)}`);
    }
  }

  // 更新页签图标：无变化时直接跳过，避免频繁触发页签条重建
  setTabFavicon(key: number, favicon: image.PixelMap) {
    if (key < 0 || key >= this.webArray.length) {
      return;
    }
    this.webArray[key].favicon = favicon;
  }

  // 展开页面内查找栏（不立即查找，等用户输入关键字）
  openFindBar() {
    this.settings.findVisible = true;
    this.settings.findKeyword = '';
    this.settings.findIndex = 0;
    this.settings.findTotal = 0;
  }

  // 收起查找栏并清除网页中的高亮
  closeFindBar() {
    this.settings.findVisible = false;
    this.settings.findKeyword = '';
    this.settings.findIndex = 0;
    this.settings.findTotal = 0;
    this.clearMatches();
  }

  // 关键字变化时重新查找；空关键字只清除已有高亮
  searchInPage(keyword: string) {
    this.settings.findKeyword = keyword;
    if (keyword.length === 0) {
      this.settings.findIndex = 0;
      this.settings.findTotal = 0;
      this.clearMatches();
      return;
    }
    const controller = this.getController();
    try {
      // 结果通过 Web 组件的 onSearchResultReceive 异步返回
      controller?.searchAllAsync(keyword);
    } catch (error) {
      Logger.error(TAG, `searchAllAsync failed: ${JSON.stringify(error)}`);
    }
  }

  // 跳转到下一个/上一个匹配项
  searchNext(forward: boolean) {
    if (this.settings.findTotal <= 0) {
      return;
    }
    const controller = this.getController();
    try {
      controller?.searchNext(forward);
    } catch (error) {
      Logger.error(TAG, `searchNext failed: ${JSON.stringify(error)}`);
    }
  }

  // onSearchResultReceive 回调：序号从 0 开始，只保留最后一次完整统计结果
  updateFindResult(activeMatchOrdinal: number, numberOfMatches: number) {
    this.settings.findIndex = activeMatchOrdinal;
    this.settings.findTotal = numberOfMatches;
  }

  // 页面跳转后旧页面的匹配结果失效，重置计数（保持查找栏展开状态）
  resetFindResult() {
    this.settings.findIndex = 0;
    this.settings.findTotal = 0;
  }

  private clearMatches() {
    const controller = this.getController();
    try {
      controller?.clearMatches();
    } catch (error) {
      Logger.error(TAG, `clearMatches failed: ${JSON.stringify(error)}`);
    }
  }

  // 书签状态与持久化（preferences），UI 通过 @ObjectLink 绑定
  bookmarkStore: BookmarkStore = new BookmarkStore()

  // 首次进入页面时加载已保存的书签
  initBookmarks(context: common.Context) {
    this.bookmarkStore.init(context);
  }

  // 展开/收起书签面板；两者互斥，展开书签时顺带收起查找栏
  openBookmarks() {
    this.closeFindBar();
    this.bookmarkStore.visible = true;
  }

  closeBookmarks() {
    this.bookmarkStore.visible = false;
  }

  // 收藏当前页：地址为空或非网页地址（本地首页、about:blank）时拒绝并提示
  addCurrentPageBookmark() {
    const controller = this.getController();
    let url: string = '';
    let title: string = '';
    try {
      url = controller?.getUrl() ?? '';
      title = controller?.getTitle() ?? '';
    } catch (error) {
      Logger.error(TAG, `getUrl/getTitle failed: ${JSON.stringify(error)}`);
    }
    if (!url.startsWith('http')) {
      promptAction.showToast({ message: '当前页面不支持收藏' });
      return;
    }
    const bookmark: Bookmark = {
      title: normalizeTitle(title, url),
      url: url,
      time: new Date().getTime()
    };
    const exists: boolean = this.bookmarkStore.has(url);
    this.bookmarkStore.add(bookmark);
    promptAction.showToast({ message: exists ? '已更新该书签' : '已添加到书签' });
  }
}