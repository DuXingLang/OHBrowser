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

/**
 * 地址栏输入归一化（纯函数，不依赖 ArkUI，可被 Node 单测直接验证）：
 * - 空串返回空串（由调用方忽略）；
 * - 已带已知协议（http/https/ftp/file/data）时原样保留；
 * - 类主机输入（域名、IPv4、localhost，可带端口与路径）补 https:// 前缀；
 * - 其余输入按搜索词处理，交给必应搜索。
 */

// 仅白名单协议视为“已带协议头”；避免把 "c++: xxx" 之类的搜索词误判为协议
const KNOWN_SCHEME: RegExp = /^(https?|ftp|file|data):/i;

// localhost/127.0.0.1 开头的本地地址也按主机处理
const LOCALHOST: RegExp = /^(localhost|127\.0\.0\.1)(:\d+)?(\/|$)/i;

export function formatUrl(addr: string): string {
  const input = addr.trim();
  if (input.length === 0) {
    return '';
  }
  // 已带协议头（如 https://example.com、file:///data/...）时不再拼接
  if (KNOWN_SCHEME.test(input)) {
    return input;
  }
  // 类主机输入（域名、IPv4、localhost，可带端口与路径）补全 https 协议
  const hostLike = !/\s/.test(input) && (input.includes('.') || LOCALHOST.test(input));
  if (hostLike) {
    return 'https://' + input;
  }
  // 其余输入按搜索词处理
  return `https://www.bing.com/search?q=${encodeURIComponent(input)}`;
}
