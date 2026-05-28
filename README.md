# NaturalScrollSwitcher

一个本地 macOS 菜单栏小工具：用鼠标滚轮时自动关闭“自然滚动”，用触控板滚动/手势时自动开启“自然滚动”。

## 功能

- 鼠标滚轮输入：设置 macOS 自然滚动为关闭。
- 触控板连续滚动或手势输入：设置 macOS 自然滚动为开启。
- 菜单栏显示当前状态。
- 支持暂停自动切换。
- 支持手动切到鼠标模式或触控板模式。
- 支持从菜单打开相关权限设置。

> 注意：macOS 原生只有一个全局自然滚动设置，并没有给鼠标和触控板分别保存两个开关。本工具会在检测到输入源变化时自动改这个全局设置。

## 系统要求

- macOS 13 或更新版本。
- 普通 USB/蓝牙滚轮鼠标。
- 本机首次运行需要授予 Input Monitoring/输入监控权限；某些系统环境也可能要求 Accessibility/辅助功能权限。

Magic Mouse 的滚动事件更接近触控设备，v0.1.0 暂不承诺稳定识别。

## 安装和运行

下载 release 里的 `.dmg` 或 `.zip`，打开 `NaturalScrollSwitcher.app`。

如果 macOS 提示未验证开发者，可以在“系统设置 -> 隐私与安全性”里允许打开。本项目当前是本地 ad-hoc 签名版本，没有做 Apple notarization。

第一次启动后：

1. 点击菜单栏里的 `NS On` 或 `NS Off`。
2. 选择 `Request Permissions...` 或直接打开权限设置。
3. 在系统设置里给 `NaturalScrollSwitcher.app` 打开输入监控权限。
4. 退出并重新打开 App。

## 使用

```sh
open dist/NaturalScrollSwitcher.app
```

菜单项说明：

- `Automatic Switching`：启用或暂停自动切换。
- `Switch to Mouse: Natural Off`：立刻切到鼠标模式。
- `Switch to Trackpad: Natural On`：立刻切到触控板模式。
- `Open Input Monitoring Settings`：打开输入监控权限设置。
- `Open Accessibility Settings`：打开辅助功能权限设置。

## 从源码构建

这个项目使用 Swift Package + AppKit，不需要 Xcode 工程文件。

```sh
swift run NaturalScrollSelfTest
swift build -c release
./scripts/build_app.sh
```

生成的 App 在：

```text
dist/NaturalScrollSwitcher.app
```

## 打包 release

```sh
./scripts/package_release.sh
```

会生成：

```text
dist/NaturalScrollSwitcher-0.1.0-macos-<arch>.zip
dist/NaturalScrollSwitcher-0.1.0-macos-<arch>.dmg
dist/checksums.txt
```

## GitHub 发布

仓库包含 GitHub Actions 工作流：

- 每次 push 到 `main` 或打开 PR 时会构建并上传 artifact。
- 推送 `v*` tag 时会创建 GitHub Release，并上传 `.zip`、`.dmg` 和 `checksums.txt`。

发布示例：

```sh
git tag v0.1.0
git push origin v0.1.0
```

## 隐私

见 [docs/PRIVACY.md](docs/PRIVACY.md)。
