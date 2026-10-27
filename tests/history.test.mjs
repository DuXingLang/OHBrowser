import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  addHistory,
  removeHistory,
  formatHistoryTime,
  HISTORY_MAX_COUNT
} from '../entry/src/main/ets/model/HistoryList.ts';

function entry(url, title = '标题', time = 1) {
  return { url, title, time };
}

test('addHistory 新记录插到最前', () => {
  const list = addHistory([entry('https://a.com')], entry('https://b.com'));
  assert.deepEqual(list.map((item) => item.url), ['https://b.com', 'https://a.com']);
});

test('addHistory 同一 URL 只保留一条并更新为最新', () => {
  const first = addHistory([], entry('https://a.com', '旧标题', 1));
  const list = addHistory(first, entry('https://a.com', '新标题', 9));
  assert.equal(list.length, 1);
  assert.equal(list[0].title, '新标题');
  assert.equal(list[0].time, 9);
});

test('addHistory 空 URL 直接忽略', () => {
  const list = [entry('https://a.com')];
  assert.equal(addHistory(list, entry('')).length, 1);
});

test('addHistory 超上限丢弃最旧', () => {
  let list = [];
  for (let i = 0; i < HISTORY_MAX_COUNT + 10; i++) {
    list = addHistory(list, entry(`https://site${i}.com`));
  }
  assert.equal(list.length, HISTORY_MAX_COUNT);
  assert.equal(list[0].url, `https://site${HISTORY_MAX_COUNT + 9}.com`);
  assert.equal(list.some((item) => item.url === 'https://site0.com'), false);
});

test('removeHistory 删除指定条目，不存在时原样返回', () => {
  const list = [entry('https://a.com'), entry('https://b.com')];
  assert.deepEqual(removeHistory(list, 'https://a.com').map((item) => item.url), ['https://b.com']);
  assert.equal(removeHistory(list, 'https://c.com').length, 2);
});

test('formatHistoryTime 输出月-日 时:分，时间戳缺失返回空串', () => {
  const time = new Date(2026, 2, 5, 9, 7).getTime();
  assert.equal(formatHistoryTime(time), '03-05 09:07');
  assert.equal(formatHistoryTime(0), '');
});