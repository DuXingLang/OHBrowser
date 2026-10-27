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
import { Browser, WebSettings } from '../model/Browser';

const MENU_BUTTON_SIZE: number = 40
const MENU_ICON_SIZE: number = 20

/**
 * “更多”菜单入口。
 *
 * 手机与平板工具栏共用：把缩放、桌面版 UA、深色渲染、缓存策略、清除数据这些
 * 使用频率低但必须有入口的能力收敛到 bindMenu(MenuElement[])，
 * 菜单点击后由框架自动关闭，不需要自己维护弹层状态。
 *
 * settings 用 @ObjectLink 绑定，菜单文案（当前缩放比例、是否桌面版等）随值变化即时刷新。
 */
@Component
export struct MoreMenuButton {
  @Link browser: Browser;
  @ObjectLink settings: WebSettings;
  @Prop buttonSize: number = MENU_BUTTON_SIZE;
  @Prop iconSize: number = MENU_ICON_SIZE;

  private menuItems(): MenuElement[] {
    const items: MenuElement[] = [
      {
        value: '新建页签',
        action: () => {
          this.browser.addTab();
        }
      },
      {
        value: '放大网页',
        action: () => {
          this.browser.zoomIn();
        }
      },
      {
        value: '缩小网页',
        action: () => {
          this.browser.zoomOut();
        }
      },
      {
        value: `缩放重置（当前 ${Math.round(this.settings.zoomScale * 100)}%）`,
        action: () => {
          this.browser.resetZoom();
        }
      },
      {
        value: this.settings.desktopMode ? '切换到移动版网站' : '切换到桌面版网站',
        action: () => {
          this.browser.toggleDesktopMode();
        }
      },
      {
        value: this.settings.forceDark ? '深色渲染：强制开启' : '深色渲染：跟随系统',
        action: () => {
          this.browser.toggleForceDark();
        }
      },
      {
        value: this.settings.noCache ? '缓存：已禁用' : '缓存：已启用',
        action: () => {
          this.browser.toggleNoCache();
        }
      },
      {
        value: '清除浏览数据',
        action: () => {
          this.browser.clearBrowsingData();
        }
      }
    ];
    return items;
  }

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Image($r('app.media.ic_public_more_filled'))
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .borderRadius(this.buttonSize / 2)
    .backgroundColor($r('app.color.transparent'))
    .flexShrink(0)
    .accessibilityText('更多菜单')
    .bindMenu(this.menuItems())
  }
}