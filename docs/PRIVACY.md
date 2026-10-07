# Privacy

NaturalScrollSwitcher is a local macOS utility.

- It listens for scroll and gesture event metadata so it can infer whether you are using a mouse or trackpad.
- It writes the macOS global natural scrolling preference.
- It does not record keystrokes.
- It does not send data to a server.
- It does not include analytics, telemetry, or network code.
- Local diagnostics record startup, runtime changes, and setting writes. The log is capped at 1 MiB. Detailed input metadata is disabled by default and can be enabled explicitly for troubleshooting.

Automatic detection requires macOS Input Monitoring permission. Accessibility permission is not required for the passive listener.
