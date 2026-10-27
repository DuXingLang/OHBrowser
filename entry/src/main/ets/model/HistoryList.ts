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

/**
 * 历史记录数据与纯函数集合。
 *
 * 这里只放“最近访问 + 去重 + 上限”的逻辑，序列化与标题兜底复用 BookmarkList
 * （见 HistoryStore.ets），因此本文件不 import 任何模块——Node 的 ESM 解析
 * 要求导入带扩展名，而 ArkTS 源码习惯省略扩展名，保持无依赖才能被单测直接加载。
 */
export interface HistoryEntry {
  // 页面标题，展示前由 BookmarkList.normalizeTitle 兜底
  title: string;
  // 页面完整地址，作为去重与删除的唯一键
  url: string;
  // 最近一次访问时间戳
  time: number;
}

// 历史比书签变动频繁，上限更大；超出后丢弃最旧的，避免首选项无限增长
export const HISTORY_MAX_COUNT: number = 200;

/**
 * 记录一次访问：同一 URL 只保留一条并提到最前（更新访问时间），超出上限丢弃最旧。
 */
export function addHistory(list: HistoryEntry[], entry: HistoryEntry): HistoryEntry[] {
  if (entry.url.length === 0) {
    return list;
  }
  const rest: HistoryEntry[] = list.filter((item: HistoryEntry) => item.url !== entry.url);
  rest.unshift(entry);
  return rest.slice(0, HISTORY_MAX_COUNT);
}

/**
 * 删除单条历史：URL 不存在时原样返回，调用方无需判空。
 */
export function removeHistory(list: HistoryEntry[], url: string): HistoryEntry[] {
  return list.filter((item: HistoryEntry) => item.url !== url);
}

/**
 * 历史行的访问时间展示：只给到“月-日 时:分”，历史列表不需要完整年月日。
 * 时间戳缺失（0 或负值）时返回空串，由调用方决定是否隐藏该行。
 */
export function formatHistoryTime(time: number): string {
  if (!(time > 0)) {
    return '';
  }
  const date: Date = new Date(time);
  const pad: (value: number) => string = (value: number) => value < 10 ? `0${value}` : `${value}`;
  return `${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}