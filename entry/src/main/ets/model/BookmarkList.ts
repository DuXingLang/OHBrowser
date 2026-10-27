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
 * 书签数据与纯函数集合。
 *
 * 这里只放不依赖系统能力的逻辑（增删、去重、序列化、标题兜底），
 * 便于用 Node 直接跑单测；持久化在 BookmarkStore.ets 中通过 preferences 完成。
 */

export interface Bookmark {
  // 页面标题，空标题在展示前用 normalizeTitle 兜底
  title: string;
  // 页面完整地址，作为去重与删除的唯一键
  url: string;
  // 收藏时间戳，仅用于“最近添加在前”的排序展示
  time: number;
}

// 书签数量上限：超出后丢弃最旧的，避免首选项体积无限增长
export const MAX_BOOKMARK_COUNT: number = 50;

/**
 * 新增书签：同一 URL 视为同一书签（删旧后插到最前），并按上限截断。
 */
export function addBookmark(list: Bookmark[], bookmark: Bookmark): Bookmark[] {
  const rest: Bookmark[] = list.filter((item: Bookmark) => item.url !== bookmark.url);
  rest.unshift(bookmark);
  return rest.slice(0, MAX_BOOKMARK_COUNT);
}

/**
 * 删除书签：URL 不存在时原样返回，保证调用方无需判空。
 */
export function removeBookmark(list: Bookmark[], url: string): Bookmark[] {
  return list.filter((item: Bookmark) => item.url !== url);
}

/**
 * 标题兜底：标题为空时退回域名，避免书签列表出现大片空白行。
 * 不依赖 URL 解析能力，只做字符串处理以保持纯函数可测。
 */
export function normalizeTitle(title: string, url: string): string {
  const trimmed: string = title.trim();
  if (trimmed.length > 0) {
    return trimmed;
  }
  const withoutScheme: string = url.replace(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//, '');
  const host: string = withoutScheme.split('/')[0];
  return host.length > 0 ? host : url;
}

/**
 * 反序列化：非法 JSON、非数组、缺少 url 的条目一律丢弃，保证不会因脏数据崩溃。
 */
export function parseBookmarks(raw: string): Bookmark[] {
  if (raw.length === 0) {
    return [];
  }
  let parsed: object | null = null;
  try {
    parsed = JSON.parse(raw) as object;
  } catch (error) {
    return [];
  }
  if (!Array.isArray(parsed)) {
    return [];
  }
  const result: Bookmark[] = [];
  for (const item of parsed as Bookmark[]) {
    if (item === null || typeof item !== 'object') {
      continue;
    }
    const url: string = typeof item.url === 'string' ? item.url : '';
    if (url.length === 0) {
      continue;
    }
    const title: string = typeof item.title === 'string' ? item.title : '';
    const time: number = typeof item.time === 'number' ? item.time : 0;
    const entry: Bookmark = { title: normalizeTitle(title, url), url: url, time: time };
    result.push(entry);
  }
  return result;
}

/**
 * 序列化：只保留三个已知字段，避免把运行时附加属性写进首选项。
 */
export function stringifyBookmarks(list: Bookmark[]): string {
  const items: Bookmark[] = list.map((item: Bookmark) => {
    return { title: item.title, url: item.url, time: item.time } as Bookmark;
  });
  return JSON.stringify(items);
}