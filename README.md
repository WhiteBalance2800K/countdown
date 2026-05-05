# Countdown

English | [简体中文](#简体中文)

Countdown is a small macOS SwiftUI app for tracking expiry dates, renewals, and time-sensitive items.

Current version: `v0.2`

## Screenshots

<p align="center">
  <img src="Resources/screenshot-dashboard.png" alt="Countdown dashboard" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown settings" width="45%">
</p>

## What's New In v0.2

- Added a language switcher in Settings.
- Added 10 app languages: Simplified Chinese, English, Spanish, Hindi, Arabic, French, Bengali, Portuguese, Russian, and Japanese.
- Localized the main dashboard, add/edit dialog, settings dialog, date display, and Bark push text.
- Connected the selected language to native date formatting and the macOS date picker locale.
- Kept all localization preferences local through `UserDefaults`.

## Features

- Add, edit, and delete countdown items.
- Enter an expiry date directly or by remaining days.
- Compact card layout with color-coded ring progress.
- Manual drag ordering with a lightweight arrange mode.
- One-click ordering by near or far expiry dates.
- Light and dark mode support through native macOS appearance.
- Language switcher with 10 app languages.
- Optional Bark push reminders for 7 days before expiry and on the due date.
- Local-first persistence with no account or external service required for core usage.

## Persistence

Countdown keeps user data outside the source tree:

- Countdown cards: `~/Library/Application Support/Countdown/items.json`
- UI, language, and push preferences: macOS `UserDefaults` via SwiftUI `@AppStorage`

The repository does not include personal countdown data. Local backups and build outputs are excluded by `.gitignore`.

## Requirements

- macOS 13 or later
- Swift 6.2 or later

## Run From Source

```bash
swift run
```

## Build The App Bundle

```bash
bash scripts/build_app.sh
open dist/Countdown.app
```

The generated app bundle is written to `dist/Countdown.app`.

## Bark Push Setup

1. Install Bark on your iPhone and copy the Bark push URL.
2. Open Countdown settings.
3. Paste a URL like:

```text
https://api.day.app/your-key
```

Countdown appends the notification title and body automatically.

## Project Structure

```text
Sources/Countdown/        SwiftUI app source
Resources/                App icon and public screenshots
scripts/build_app.sh      Local .app bundle build script
```

## License

MIT. See [LICENSE](LICENSE).

---

## 简体中文

[English](#countdown) | 简体中文

Countdown 是一个 macOS SwiftUI 小工具，用来追踪到期日、续费日和其他需要提前关注的时间节点。

当前版本：`v0.2`

## 截图

<p align="center">
  <img src="Resources/screenshot-dashboard.png" alt="Countdown 主界面" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown 设置界面" width="45%">
</p>

## v0.2 更新内容

- 设置页新增语言切换。
- 支持 10 种语言：简体中文、英语、西班牙语、印地语、阿拉伯语、法语、孟加拉语、葡萄牙语、俄语、日语。
- 主界面、添加/编辑弹框、设置弹框、日期显示和 Bark 推送文案已接入本地化。
- 选择语言后，原生日期格式和 macOS 日期选择器会跟随切换。
- 语言偏好通过 `UserDefaults` 本地保存，不依赖账号或外部服务。

## 功能

- 新增、编辑、删除倒计时项目。
- 支持直接选择到期日期，也支持按剩余天数录入。
- 紧凑卡片布局，使用圆环和颜色表达紧迫程度。
- 支持手动拖拽排序，并提供轻量调整模式。
- 支持一键按临近或较远到期日排序。
- 跟随 macOS 深色/浅色模式。
- 设置页支持 10 种语言切换。
- 可选 Bark 推送提醒，支持到期前 7 天和到期当天推送。
- 核心功能本地优先，不需要账号或外部服务。

## 持久化

Countdown 会把用户数据保存在源码目录之外：

- 倒计时卡片：`~/Library/Application Support/Countdown/items.json`
- UI、语言和推送偏好：通过 SwiftUI `@AppStorage` 写入 macOS `UserDefaults`

仓库不会包含个人倒计时数据。本地备份和构建产物已通过 `.gitignore` 排除。

## 环境要求

- macOS 13 或更高版本
- Swift 6.2 或更高版本

## 从源码运行

```bash
swift run
```

## 构建 App

```bash
bash scripts/build_app.sh
open dist/Countdown.app
```

生成的 App 位于 `dist/Countdown.app`。

## Bark 推送设置

1. 在 iPhone 上安装 Bark，并复制 Bark 推送地址。
2. 打开 Countdown 设置。
3. 填入类似下面的地址：

```text
https://api.day.app/your-key
```

Countdown 会自动在地址后追加通知标题和内容。

## 项目结构

```text
Sources/Countdown/        SwiftUI 应用源码
Resources/                App 图标和公开截图
scripts/build_app.sh      本地 .app 打包脚本
```

## 许可证

MIT。见 [LICENSE](LICENSE)。
