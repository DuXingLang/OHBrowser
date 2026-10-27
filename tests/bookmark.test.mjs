import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  addBookmark,
  removeBookmark,
  normalizeTitle,
  parseBookmarks,
  stringifyBookmarks,
  MAX_BOOKMARK_COUNT
} from '../entry/src/main/ets/model/BookmarkList.ts';

function bookmark(url, title = '标题', time = 1) {
  return { url, title, time };
}

test('addBookmark 追加到最前', () => {
  const list = addBookmark([bookmark('https://a.com')], bookmark('https://b.com'));
  assert.deepEqual(list.map((item) => item.url), ['https://b.com', 'https://a.com']);
});

test('addBookmark 同一 URL 去重且视为最新', () => {
  const first = addBookmark([], bookmark('https://a.com', '旧标题', 1));
  const list = addBookmark(first, bookmark('https://a.com', '新标题', 2));
  assert.equal(list.length, 1);
  assert.equal(list[0].title, '新标题');
});

test('addBookmark 超过上限时丢弃最旧的', () => {
  let list = [];
  for (let i = 0; i < MAX_BOOKMARK_COUNT + 5; i++) {
    list = addBookmark(list, bookmark(`https://site${i}.com`));
  }
  assert.equal(list.length, MAX_BOOKMARK_COUNT);
  assert.equal(list[0].url, `https://site${MAX_BOOKMARK_COUNT + 4}.com`);
  assert.equal(list.some((item) => item.url === 'https://site0.com'), false);
});

test('removeBookmark 删除指定 URL，不存在时原样返回', () => {
  const list = [bookmark('https://a.com'), bookmark('https://b.com')];
  assert.deepEqual(removeBookmark(list, 'https://a.com').map((item) => item.url), ['https://b.com']);
  assert.equal(removeBookmark(list, 'https://c.com').length, 2);
});

test('normalizeTitle 空标题退回域名', () => {
  assert.equal(normalizeTitle('  ', 'https://www.example.com/path?q=1'), 'www.example.com');
  assert.equal(normalizeTitle('已有标题', 'https://www.example.com'), '已有标题');
  assert.equal(normalizeTitle('', 'https://localhost:8080/a'), 'localhost:8080');
});

test('parseBookmarks 丢弃脏数据', () => {
  assert.deepEqual(parseBookmarks(''), []);
  assert.deepEqual(parseBookmarks('not json'), []);
  assert.deepEqual(parseBookmarks('{"url":"https://a.com"}'), []);
  const list = parseBookmarks('[{"url":"https://a.com"},{"title":"无地址"},null,3]');
  assert.equal(list.length, 1);
  assert.equal(list[0].title, 'a.com');
});

test('stringifyBookmarks 与 parseBookmarks 往返一致', () => {
  const list = [bookmark('https://a.com', 'A', 11), bookmark('https://b.com', 'B', 22)];
  assert.deepEqual(parseBookmarks(stringifyBookmarks(list)), list);
});