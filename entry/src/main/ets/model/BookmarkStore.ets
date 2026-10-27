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
import common from '@ohos.app.ability.common';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';
import { Bookmark, addBookmark, removeBookmark, parseBookmarks, stringifyBookmarks } from './BookmarkList';

const TAG: string = '[BookmarkStore]'
// 首选项实例名与存储 Key：改名会导致已有书签读不到，后续不要随意变更
const STORE_NAME: string = 'browser_store'
const KEY_BOOKMARKS: string = 'bookmarks'

/**
 * 书签状态与持久化。
 *
 * 列表本体是 @Observed 上的数组字段：整体替换数组才会让 @ObjectLink 组件刷新，
 * 因此增删都走“生成新数组再赋值”的方式（见 BookmarkList.ts 的纯函数）。
 * 落盘用 preferences 的同步写 + 异步 flush，避免在 UI 线程上等待磁盘。
 */
@Observed
export class BookmarkStore {
  // 书签列表，最近添加的在前
  items: Bookmark[] = []
  // 书签面板是否展开
  visible: boolean = false
  private store: preferences.Preferences | null = null

  // 首次使用时加载已保存的书签；重复调用直接返回，避免重复读取磁盘
  init(context: common.Context) {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const raw: string = this.store.getSync(KEY_BOOKMARKS, '[]') as string;
      this.items = parseBookmarks(raw);
      Logger.info(TAG, `load bookmarks count= ${this.items.length}`);
    } catch (error) {
      Logger.error(TAG, `init failed: ${JSON.stringify(error)}`);
    }
  }

  add(bookmark: Bookmark) {
    this.items = addBookmark(this.items, bookmark);
    this.persist();
  }

  remove(url: string) {
    this.items = removeBookmark(this.items, url);
    this.persist();
  }

  has(url: string): boolean {
    return this.items.some((item: Bookmark) => item.url === url);
  }

  private persist() {
    if (this.store === null) {
      return;
    }
    try {
      this.store.putSync(KEY_BOOKMARKS, stringifyBookmarks(this.items));
      // API 12 只有异步 flush：失败时仅记录日志，内存中的书签仍然可用
      const result: Promise<void> = this.store.flush();
      result.catch((error: BusinessError) => {
        Logger.error(TAG, `flush failed: ${JSON.stringify(error)}`);
      });
    } catch (error) {
      Logger.error(TAG, `persist failed: ${JSON.stringify(error)}`);
    }
  }
}