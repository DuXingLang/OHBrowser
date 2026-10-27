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
import { Browser } from '../model/Browser';
import { normalizeTitle } from '../model/BookmarkList';
import { HistoryEntry, formatHistoryTime } from '../model/HistoryList';
import { HistoryStore } from '../model/HistoryStore';

// 面板最大高度：历史条数多（上限 200）时内部滚动，避免把网页区域挤没
const PANEL_MAX_HEIGHT: number = 320
const PANEL_HEADER_HEIGHT: number = 44
const HISTORY_ROW_HEIGHT: number = 52
const PANEL_ICON_SIZE: number = 18
const PANEL_BUTTON_SIZE: number = 32
const EMPTY_TIP_PADDING: number = 24
const META_FONT_SIZE: number = 11
const ROW_MARGIN_TOP: number = 2

/**
 * 历史记录面板。
 *
 * 与书签面板同构：标题栏下方固定高度区域 + 内部滚动列表，
 * Web 组件在组件树中的位置不变，展开/收起不会让网页重载。
 */
@Component
export struct HistoryPanel {
  @Link browser: Browser;
  // 历史列表与展开状态都在 @Observed 对象上，增删/清空后本组件精确刷新
  @ObjectLink history: HistoryStore;

  build() {
    Column() {
      Row() {
        Text('历史记录')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('清空')
          .fontSize(13)
          .fontColor($r('app.color.progress_blue'))
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .opacity(this.history.items.length === 0 ? 0.4 : 1)
          .enabled(this.history.items.length > 0)
          .onClick(() => {
            this.history.clear();
          })
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.ic_public_cancel_filled'))
            .width(PANEL_ICON_SIZE)
            .height(PANEL_ICON_SIZE)
            .objectFit(ImageFit.Contain)
        }
        .width(PANEL_BUTTON_SIZE)
        .height(PANEL_BUTTON_SIZE)
        .borderRadius(PANEL_BUTTON_SIZE / 2)
        .backgroundColor($r('app.color.transparent'))
        .accessibilityText('收起历史记录')
        .onClick(() => {
          this.browser.closeHistory();
        })
      }
      .width('100%')
      .height(PANEL_HEADER_HEIGHT)
      .padding({ left: 16, right: 8 })
      .flexShrink(0)

      Divider().color($r('app.color.divider_light')).width('100%')

      if (this.history.items.length === 0) {
        Text('还没有访问记录')
          .fontSize(13)
          .fontColor($r('app.color.fg_secondary'))
          .padding(EMPTY_TIP_PADDING)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.history.items, (item: HistoryEntry) => {
            ListItem() {
              Row() {
                Column() {
                  // 标题为空时用域名兜底，避免出现空白行
                  Text(normalizeTitle(item.title, item.url))
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Row() {
                    Text(item.url)
                      .fontSize(META_FONT_SIZE)
                      .fontColor($r('app.color.fg_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(formatHistoryTime(item.time))
                      .fontSize(META_FONT_SIZE)
                      .fontColor($r('app.color.fg_secondary'))
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .margin({ top: ROW_MARGIN_TOP })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button({ type: ButtonType.Normal, stateEffect: true }) {
                  Image($r('app.media.ic_public_cancel_filled'))
                    .width(PANEL_ICON_SIZE)
                    .height(PANEL_ICON_SIZE)
                    .objectFit(ImageFit.Contain)
                }
                .width(PANEL_BUTTON_SIZE)
                .height(PANEL_BUTTON_SIZE)
                .borderRadius(PANEL_BUTTON_SIZE / 2)
                .backgroundColor($r('app.color.transparent'))
                .accessibilityText('删除该记录')
                .onClick(() => {
                  this.history.remove(item.url);
                })
              }
              .width('100%')
              .height(HISTORY_ROW_HEIGHT)
              .padding({ left: 16, right: 8 })
              .onClick(() => {
                // 点击整行跳转，并收起面板把屏幕还给网页
                this.browser.loadUrl(item.url);
                this.browser.closeHistory();
              })
            }
          }, (item: HistoryEntry) => item.url)
        }
        .width('100%')
        .constraintSize({ maxHeight: PANEL_MAX_HEIGHT })
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.page_bg'))
    .border({ width: { bottom: 1 }, color: $r('app.color.divider_light') })
  }
}