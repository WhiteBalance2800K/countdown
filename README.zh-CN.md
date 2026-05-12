# Countdown

[English](README.md) | 简体中文

Countdown 是一个 macOS SwiftUI 小工具，用来追踪到期日、续费日和其他需要提前关注的时间节点。

当前版本：`v0.5`

## 截图

<p align="center">
  <img src="Resources/screenshot-dashboard.png" alt="Countdown 主界面" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown 设置界面" width="45%">
</p>

## v0.5 更新内容

- 大幅优化调整卡片时的流畅度，卡片移位改为弹性布局动画。
- 拖拽过程中不再反复写入数据文件，落下卡片后再保存新顺序。
- 去掉调整模式下持续抖动的卡片动画，改为更稳的拖起浮动反馈。

## v0.4 更新内容

- 增加倒计时数据自动备份，`items.json` 损坏时会提示恢复状态。
- 增加 macOS 菜单栏入口，可快速打开 Countdown、新增项目、打开设置和退出。
- 设置页新增开机启动选项。
- 为 GitHub Release 构建并上传 `.app` 压缩包。

## v0.3 更新内容

- README 拆分为独立英文页面和简体中文页面。
- GitHub 默认 README 保持英文显示。
- 截图部分调整为两张图片左右并排，并缩小为半宽展示。
- 更新版本信息为 `v0.3`。

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
- 支持菜单栏快速入口。
- 支持登录 macOS 后自动启动。
- 核心功能本地优先，不需要账号或外部服务。

## 持久化

Countdown 会把用户数据保存在源码目录之外：

- 倒计时卡片：`~/Library/Application Support/Countdown/items.json`
- 倒计时数据备份：`~/Library/Application Support/Countdown/backups/`
- UI、语言和推送偏好：通过 SwiftUI `@AppStorage` 写入 macOS `UserDefaults`
- 开机启动：通过 macOS 登录项 `SMAppService` 管理

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

生成的 App 位于 `dist/Countdown.app`，Release 压缩包位于 `dist/Countdown-v0.5-macOS.zip`。

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
