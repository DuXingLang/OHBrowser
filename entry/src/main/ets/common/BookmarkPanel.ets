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
import { Bookmark, normalizeTitle } from '../model/BookmarkList';
import { BookmarkStore } from '../model/BookmarkStore';

// 面板最大高度：书签多时内部滚动，避免把网页区域挤没
const PANEL_MAX_HEIGHT: number = 320
const PANEL_HEADER_HEIGHT: number = 44
const BOOKMARK_ROW_HEIGHT: number = 56
const PANEL_ICON_SIZE: number = 18
const PANEL_BUTTON_SIZE: number = 32
const EMPTY_TIP_PADDING: number = 24

/**
 * 书签面板。
 *
 * 与查找栏同样是“标题栏下方一条区域”，展开时占据固定高度、内部滚动，
 * 不改动 Web 组件在组件树中的位置，因此展开/收起都不会让网页重载。
 */
@Component
export struct BookmarkPanel {
  @Link browser: Browser;
  // 书签列表与展开状态都在 @Observed 对象上，增删后本组件精确刷新
  @ObjectLink bookmarks: BookmarkStore;

  build() {
    Column() {
      Row() {
        Text('书签')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('收藏当前页')
          .fontSize(13)
          .fontColor($r('app.color.progress_blue'))
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .onClick(() => {
            this.browser.addCurrentPageBookmark();
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
        .accessibilityText('收起书签')
        .onClick(() => {
          this.browser.closeBookmarks();
        })
      }
      .width('100%')
      .height(PANEL_HEADER_HEIGHT)
      .padding({ left: 16, right: 8 })
      .flexShrink(0)

      Divider().color($r('app.color.divider_light')).width('100%')

      if (this.bookmarks.items.length === 0) {
        Text('还没有书签，点击「收藏当前页」添加')
          .fontSize(13)
          .fontColor($r('app.color.fg_secondary'))
          .padding(EMPTY_TIP_PADDING)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.bookmarks.items, (item: Bookmark) => {
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
                  Text(item.url)
                    .fontSize(11)
                    .fontColor($r('app.color.fg_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .margin({ top: 2 })
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
                .accessibilityText('删除书签')
                .onClick(() => {
                  this.bookmarks.remove(item.url);
                })
              }
              .width('100%')
              .height(BOOKMARK_ROW_HEIGHT)
              .padding({ left: 16, right: 8 })
              .onClick(() => {
                // 点击整行跳转，并收起面板把屏幕还给网页
                this.browser.loadUrl(item.url);
                this.browser.closeBookmarks();
              })
            }
          }, (item: Bookmark) => item.url)
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