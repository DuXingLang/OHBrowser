/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { test } from 'node:test';
import assert from 'node:assert/strict';
// 直接引用应用源码中的纯函数，测试与实现零漂移（Node >= 22.6 支持 TS 类型剥离）
import { formatUrl } from '../entry/src/main/ets/model/UrlFormatter.ts';

test('空输入返回空串', () => {
  assert.equal(formatUrl(''), '');
  assert.equal(formatUrl('   '), '');
});

test('已带已知协议的 URL 原样保留', () => {
  assert.equal(formatUrl('https://www.jd.com'), 'https://www.jd.com');
  assert.equal(formatUrl('http://example.com/path?q=1'), 'http://example.com/path?q=1');
  assert.equal(formatUrl('file:///data/storage/rawfile/pad.html'), 'file:///data/storage/rawfile/pad.html');
  assert.equal(formatUrl('FTP://example.com'), 'FTP://example.com');
});

test('域名/IP 输入补 https:// 前缀', () => {
  assert.equal(formatUrl('www.jd.com'), 'https://www.jd.com');
  assert.equal(formatUrl('bing.com'), 'https://bing.com');
  assert.equal(formatUrl('192.168.1.100:8080/path'), 'https://192.168.1.100:8080/path');
});

test('localhost/127.0.0.1 输入按主机处理', () => {
  assert.equal(formatUrl('localhost:8080'), 'https://localhost:8080');
  assert.equal(formatUrl('127.0.0.1:9090'), 'https://127.0.0.1:9090');
});

test('含空格或无点输入按搜索词处理', () => {
  assert.equal(
    formatUrl('OpenHarmony 浏览器'),
    `https://www.bing.com/search?q=${encodeURIComponent('OpenHarmony 浏览器')}`
  );
  assert.equal(formatUrl('hello world'), 'https://www.bing.com/search?q=hello%20world');
});

test('搜索词含冒号不再被误判为协议（回归：c++: std::vector）', () => {
  const q = 'c++: std::vector';
  assert.equal(formatUrl('c++: std::vector'), `https://www.bing.com/search?q=${encodeURIComponent(q)}`);
});

test('首尾空格被裁剪后再判断', () => {
  assert.equal(formatUrl('  www.jd.com  '), 'https://www.jd.com');
});
