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
import { Browser, WebSettings } from '../model/Browser';

const FIND_BAR_HEIGHT: number = 48
const FIND_INPUT_HEIGHT: number = 34
const FIND_ICON_SIZE: number = 18
const FIND_BUTTON_SIZE: number = 32
const FIND_COUNTER_WIDTH: number = 44
const DISABLED_OPACITY: number = 0.35

/**
 * 页面内查找栏。
 *
 * 输入关键字后由 Browser.searchInPage 调用 WebviewController.searchAllAsync 高亮全部匹配，
 * 结果经 Web 组件的 onSearchResultReceive 回写到 WebSettings，这里只负责展示“当前/总数”。
 * 关闭时调用 clearMatches 清除高亮，避免离开查找后网页仍残留黄色标记。
 */
@Component
export struct FindBar {
  @Link browser: Browser;
  // 关键字与计数都在 @Observed 对象上，值变化后本组件精确刷新
  @ObjectLink settings: WebSettings;

  // 有匹配时展示“当前/总数”，无匹配时统一显示 0/0
  private counterText(): string {
    if (this.settings.findTotal <= 0) {
      return '0/0';
    }
    return `${this.settings.findIndex + 1}/${this.settings.findTotal}`;
  }

  private hasMatch(): boolean {
    return this.settings.findTotal > 0;
  }

  build() {
    Row({ space: 6 }) {
      TextInput({ placeholder: '在页面中查找', text: this.settings.findKeyword })
        .layoutWeight(1)
        .height(FIND_INPUT_HEIGHT)
        .borderRadius(FIND_INPUT_HEIGHT / 2)
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.omnibox_bg'))
        .fontSize(14)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.browser.searchInPage(value);
        })
        .onSubmit(() => {
          this.browser.searchNext(true);
        })
      Text(this.counterText())
        .fontSize(12)
        .fontColor($r('app.color.fg_secondary'))
        .width(FIND_COUNTER_WIDTH)
        .textAlign(TextAlign.Center)
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Image($r('app.media.ic_public_back'))
          .width(FIND_ICON_SIZE)
          .height(FIND_ICON_SIZE)
          .objectFit(ImageFit.Contain)
      }
      .width(FIND_BUTTON_SIZE)
      .height(FIND_BUTTON_SIZE)
      .borderRadius(FIND_BUTTON_SIZE / 2)
      .backgroundColor($r('app.color.transparent'))
      .opacity(this.hasMatch() ? 1 : DISABLED_OPACITY)
      .accessibilityText('上一个匹配项')
      .onClick(() => {
        this.browser.searchNext(false);
      })
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Image($r('app.media.ic_public_advance'))
          .width(FIND_ICON_SIZE)
          .height(FIND_ICON_SIZE)
          .objectFit(ImageFit.Contain)
      }
      .width(FIND_BUTTON_SIZE)
      .height(FIND_BUTTON_SIZE)
      .borderRadius(FIND_BUTTON_SIZE / 2)
      .backgroundColor($r('app.color.transparent'))
      .opacity(this.hasMatch() ? 1 : DISABLED_OPACITY)
      .accessibilityText('下一个匹配项')
      .onClick(() => {
        this.browser.searchNext(true);
      })
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Image($r('app.media.ic_public_cancel_filled'))
          .width(FIND_ICON_SIZE)
          .height(FIND_ICON_SIZE)
          .objectFit(ImageFit.Contain)
      }
      .width(FIND_BUTTON_SIZE)
      .height(FIND_BUTTON_SIZE)
      .borderRadius(FIND_BUTTON_SIZE / 2)
      .backgroundColor($r('app.color.transparent'))
      .accessibilityText('关闭查找')
      .onClick(() => {
        this.browser.closeFindBar();
      })
    }
    .width('100%')
    .height(FIND_BAR_HEIGHT)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.page_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.divider_light') })
  }
}