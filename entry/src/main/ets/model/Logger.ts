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
import hilog from '@ohos.hilog'

class Logger {
    private domain: number
    private prefix: string
    private format: string = "%{public}s"

    constructor(prefix: string) {
        this.prefix = prefix
        this.domain = 0xFF00
    }

    // hilog 按占位符逐个消费变参；调用处传入的是多个分散参数，
    // 统一拼接为单个字符串再交给单一占位符，避免占位符与参数错位
    private formatArgs(args: any[]): string {
        return args.map(arg => `${arg}`).join(' ')
    }

    debug(...args: any[]) {
        hilog.debug(this.domain, this.prefix, this.format, this.formatArgs(args))
    }

    info(...args: any[]) {
        hilog.info(this.domain, this.prefix, this.format, this.formatArgs(args))
    }

    warn(...args: any[]) {
        hilog.warn(this.domain, this.prefix, this.format, this.formatArgs(args))
    }

    error(...args: any[]) {
        hilog.error(this.domain, this.prefix, this.format, this.formatArgs(args))
    }
}

export default new Logger('[Browser]')
