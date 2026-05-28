# NaturalScrollSwitcher

一个轻量、安静的 macOS 菜单栏工具：自动根据你正在使用鼠标还是触控板，切换系统“自然滚动”方向。

[![Build](https://github.com/TJUgsmw/NaturalScrollSwitcher/actions/workflows/build.yml/badge.svg)](https://github.com/TJUgsmw/NaturalScrollSwitcher/actions)

## 中文简介

macOS 的“自然滚动”是全局设置，系统没有给鼠标和触控板分别保存两个开关。NaturalScrollSwitcher 会监听滚动输入来源：

- 检测到普通鼠标滚轮时，按你的鼠标偏好设置自然滚动。
- 检测到触控板连续滚动或手势时，按你的触控板偏好设置自然滚动。
- 默认保持常见习惯：鼠标自然滚动关闭，触控板自然滚动开启。
- 你也可以在菜单里分别选择鼠标和触控板是否开启自然滚动。
- App 菜单会跟随 macOS 系统语言显示中文或英文。

## 下载和安装

从 [Releases](https://github.com/TJUgsmw/NaturalScrollSwitcher/releases) 下载最新版本的 `.dmg` 或 `.zip`，然后打开 `NaturalScrollSwitcher.app`。

当前版本是本地 ad-hoc 签名，没有 Apple notarization。如果 macOS 提示“无法验证开发者”，可以在“系统设置 -> 隐私与安全性”里允许打开。

首次运行后，请给 App 授权：

1. 点击菜单栏里的 `NS On` 或 `NS Off`。
2. 选择“请求权限...”或打开“输入监控设置”。
3. 在系统设置中为 `NaturalScrollSwitcher.app` 启用输入监控权限。
4. 退出并重新打开 App。

某些 macOS 环境也可能要求辅助功能权限，菜单里会显示当前权限状态。

## 使用说明

菜单项会根据系统语言显示中文或英文。中文环境下主要菜单包括：

- `自动切换`：启用或暂停自动识别鼠标/触控板。
- `鼠标自然滚动`：勾选后，鼠标模式会开启自然滚动；取消勾选则关闭。
- `触控板自然滚动`：勾选后，触控板模式会开启自然滚动；取消勾选则关闭。
- `切换到鼠标: 自然滚动开启/关闭`：立刻按鼠标偏好应用系统设置。
- `切换到触控板: 自然滚动开启/关闭`：立刻按触控板偏好应用系统设置。
- `打开输入监控设置`：打开 macOS 输入监控权限页面。
- `打开辅助功能设置`：打开 macOS 辅助功能权限页面。

Magic Mouse 的滚动事件更接近触控设备，v0.3.0 暂不承诺稳定识别。普通 USB/蓝牙滚轮鼠标是当前主要支持目标。

## 从源码构建

项目使用 Swift Package + AppKit，不需要 Xcode 工程文件。

```sh
swift run NaturalScrollSelfTest
swift build -c release
./scripts/build_app.sh
```

生成的 App 在：

```text
dist/NaturalScrollSwitcher.app
```

## 打包 Release

```sh
./scripts/package_release.sh
```

会生成：

```text
dist/NaturalScrollSwitcher-0.3.0-macos-<arch>.zip
dist/NaturalScrollSwitcher-0.3.0-macos-<arch>.dmg
dist/checksums.txt
```

推送 tag 后，GitHub Actions 会自动构建并创建 Release：

```sh
git tag v0.3.0
git push origin v0.3.0
```

## 隐私

见 [docs/PRIVACY.md](docs/PRIVACY.md)。简短版本：App 只在本机监听滚动/手势事件元信息，用来判断输入来源；不记录键盘输入，不联网，不上传数据，不包含分析统计。

---

## English

NaturalScrollSwitcher is a small macOS menu bar utility that changes the system natural scrolling preference based on whether you are using a mouse or a trackpad.

macOS exposes natural scrolling as one global setting. This app watches scroll input metadata and updates that global setting only when the detected input source changes.

### Features

- Mouse wheel input uses your mouse natural scrolling preference.
- Trackpad continuous scroll or gesture input uses your trackpad natural scrolling preference.
- Defaults: natural scrolling off for mouse, on for trackpad.
- Separate menu preferences for mouse and trackpad natural scrolling.
- Chinese or English menu text based on the macOS preferred language.
- Local packaging scripts for `.app`, `.zip`, and `.dmg` artifacts.

### Install

Download the latest `.dmg` or `.zip` from [Releases](https://github.com/TJUgsmw/NaturalScrollSwitcher/releases), then open `NaturalScrollSwitcher.app`.

The app is ad-hoc signed for local use and is not notarized by Apple. macOS may show a first-run security warning.

On first launch, grant Input Monitoring permission when prompted. Some systems may also ask for Accessibility permission.

### Build

```sh
swift run NaturalScrollSelfTest
swift build -c release
./scripts/package_release.sh
```

### Notes

Magic Mouse is not a stable v0.3.0 target because its scroll events are closer to touch devices than ordinary mouse wheels.
