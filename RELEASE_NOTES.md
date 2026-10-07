# NaturalScrollSwitcher 0.7.2

## 中文

修复 macOS 27 上触控板操作时 CPU 占用过高的问题。旧版会对每个手势重复写日志和刷新菜单栏，新版只在输入设备变化时更新设置和界面。

- 保留鼠标默认关闭、触控板默认开启系统自然滚动的行为，以及独立设备偏好。
- HID 监听只接收垂直/水平滚轮值，避免处理无关输入。
- 默认关闭详细事件日志；诊断写入改为后台执行，日志最大 1 MiB，旧版过大的日志自动保留近期内容。
- 已授权时不再每两秒检查权限和刷新菜单，改为菜单打开、唤醒和会话激活时检查。
- 请求权限后的临时检查最多持续两分钟。
- 仅需输入监控权限；本地 ad-hoc 签名更新后可能需要重新启用该权限。

## English

Fixes excessive CPU use during trackpad input on macOS 27. Source detection now updates settings and the menu only when the active device changes. Reassigning an unchanged status bar title is avoided.

HID callbacks are limited to wheel values. Detailed snapshots are disabled by default, diagnostics run on a utility queue, and the log is capped at 1 MiB. Oversized legacy logs are trimmed to recent entries without reading the whole file into memory.

Permanent permission polling has been removed. Checks happen when opening the menu, waking the Mac, or activating the session. Temporary polling after requesting permission ends after two minutes or once permission is granted.

Defaults remain Natural Scrolling Off for a mouse and On for a trackpad. Only Input Monitoring is required. Ad-hoc signed updates may need that permission enabled again.
