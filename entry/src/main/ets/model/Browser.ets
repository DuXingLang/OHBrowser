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
import { formatUrl } from './UrlFormatter';

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

const TAG: string = '[browser]'
// 页签数量上限：超过后提示用户并拒绝新建，避免无限制创建 Web 组件导致内存耗尽
const MAX_TAB_COUNT: number = 10
// changeIndex 需等待 Tabs 内 ForEach 完成新 TabContent 渲染，取经验延时
const TAB_SWITCH_DELAY: number = 50
// 页签标题为空时的兜底文案
const DEFAULT_TAB_TITLE: string = '主页'

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

  // 同步前进/后退可用状态：页面加载结束、页签切换后调用
  updateHistoryState() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    this.canBack = controller?.accessBackward() ?? false;
    this.canForward = controller?.accessForward() ?? false;
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
    if (controller?.accessBackward()) {
      controller.backward();
    }
  }

  Forward() {
    const controller = this.webControllerArray[this.tabArrayIndex]?.controller;
    if (controller?.accessForward()) {
      controller.forward();
    }
  }

  Refresh() {
    this.webControllerArray[this.tabArrayIndex]?.controller.refresh();
  }
}