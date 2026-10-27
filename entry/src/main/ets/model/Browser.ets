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

  constructor(key: number, timestamp: number) {
    this.key = key
    this.timestamp = timestamp
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

export class Browser {
  inputValue: string = ""
  tabArrayIndex: number = 0
  progress: number = 0
  hideProgress: boolean = true
  loadingStatus: LoadingStatus = LoadingStatus.END

  webArray: Array<WebKey> = [new WebKey(0, new Date().getTime())]
  // 页签条展示的标题，与 webArray 同步维护；加载完成后由 onPageEnd 更新为实际页面标题
  tabTitles: Array<string> = ['主页']
  tabsController: TabsController = new TabsController()
  webControllerArray: Array<WebObject> = [new WebObject(new webview.WebviewController(), false)]

  deleteTab(index: number) {
    Logger.info(TAG, `delete before tab index= ${index} controller length ${this.webControllerArray.length} tabArrayIndex= ${this.tabArrayIndex}`)
    this.webArray.splice(index, 1)
    this.webControllerArray.splice(index, 1)
    this.tabTitles.splice(index, 1)
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
    }, TAB_SWITCH_DELAY)
  }

  getWebArray() {
    return this.webArray
  }

  addTab() {
    if (this.webArray.length > MAX_TAB_COUNT) {
      promptAction.showToast({
        message: '页签数量已满'
      })
      return;
    }
    let webController: webview.WebviewController = new webview.WebviewController();
    let object = new WebObject(webController, false)
    this.webControllerArray.push(object)
    this.webArray.push(new WebKey(this.webArray.length, new Date().getTime()))
    this.tabTitles.push('主页')
    this.tabArrayIndex = this.webArray.length - 1
    Logger.info(TAG, `add tab index= ${this.tabArrayIndex}`)
    setTimeout(() => {
      this.tabsController.changeIndex(this.tabArrayIndex)
    }, TAB_SWITCH_DELAY)
  }

  setTabArrayIndex(tabArrayIndex: number) {
    this.tabArrayIndex = tabArrayIndex
  }

  getTabArrayIndex() {
    return this.tabArrayIndex
  }

  setTabTitle(key: number, title: string) {
    if (key < 0 || key >= this.tabTitles.length) {
      return;
    }
    // 空标题回退为“主页”，避免页签显示空白
    this.tabTitles[key] = title.length > 0 ? title : '主页'
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
    if (this.webControllerArray[this.tabArrayIndex]?.controller.accessBackward()) {
      this.webControllerArray[this.tabArrayIndex]?.controller.backward();
    }
  }

  Forward() {
    if (this.webControllerArray[this.tabArrayIndex]?.controller.accessForward()) {
      this.webControllerArray[this.tabArrayIndex]?.controller.forward();
    }
  }

  Refresh() {
    this.webControllerArray[this.tabArrayIndex]?.controller.refresh();
  }
}
