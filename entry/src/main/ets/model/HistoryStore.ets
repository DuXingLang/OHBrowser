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
import { parseBookmarks, stringifyBookmarks } from './BookmarkList';
import { HistoryEntry, HISTORY_MAX_COUNT, addHistory, removeHistory } from './HistoryList';

const TAG: string = '[HistoryStore]'
// 与书签共用同一个首选项实例，换成独立的实例名会导致清除数据时漏清
const STORE_NAME: string = 'browser_store'
const KEY_HISTORY: string = 'history'

/**
 * 历史记录状态与持久化。
 *
 * 与 BookmarkStore 同样的模式：数组整体替换触发 @ObjectLink 刷新，
 * 同步写 + 异步 flush 落盘。历史写入频繁，不在这里做节流，
 * 因为同一次访问只会写一次（onPageEnd）。
 */
@Observed
export class HistoryStore {
  // 历史列表，最近访问的在前
  items: HistoryEntry[] = []
  // 历史面板是否展开
  visible: boolean = false
  private store: preferences.Preferences | null = null

  init(context: common.Context) {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const raw: string = this.store.getSync(KEY_HISTORY, '[]') as string;
      // 解析与标题兜底复用书签的实现（结构一致），这里只按历史的上限截断
      this.items = parseBookmarks(raw).slice(0, HISTORY_MAX_COUNT);
      Logger.info(TAG, `load history count= ${this.items.length}`);
    } catch (error) {
      Logger.error(TAG, `init failed: ${JSON.stringify(error)}`);
    }
  }

  add(entry: HistoryEntry) {
    this.items = addHistory(this.items, entry);
    this.persist();
  }

  remove(url: string) {
    this.items = removeHistory(this.items, url);
    this.persist();
  }

  // 清空历史：内存与磁盘同时清理，供「清除浏览数据」与面板的「清空」共用
  clear() {
    this.items = [];
    this.persist();
  }

  private persist() {
    if (this.store === null) {
      return;
    }
    try {
      this.store.putSync(KEY_HISTORY, stringifyBookmarks(this.items));
      const result: Promise<void> = this.store.flush();
      result.catch((error: BusinessError) => {
        Logger.error(TAG, `flush failed: ${JSON.stringify(error)}`);
      });
    } catch (error) {
      Logger.error(TAG, `persist failed: ${JSON.stringify(error)}`);
    }
  }
}