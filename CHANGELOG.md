# Changelog

## 0.5.1

- Added runtime fallback modes: Event Correction, Global Fallback, and Manual Only.
- Event taps now try editable correction first and automatically fall back to listen-only global setting sync when Accessibility permission is missing or macOS rejects the editable tap.
- Manual mouse and trackpad menu actions now always write the selected system natural scrolling setting.
- Improved menu diagnostics for run mode, recent input source, recent action, and permission state.
- Clarified permission guidance so missing Accessibility permission no longer makes the app appear silently broken.

## 0.5.0

- Changed scrolling reliability strategy to keep the system natural scrolling setting aligned with the trackpad preference.
- Added event-level correction for ordinary mouse wheel scrolling when the mouse preference differs from the trackpad baseline.
- Improved scroll source classification so Bluetooth wheel mice are not treated as trackpads only because they report continuous scrolling.
- Added recent-action diagnostics for corrected mouse scroll, pass-through mouse scroll, and pass-through trackpad scroll.
- Requires both Input Monitoring and Accessibility permissions for event-level correction.

## 0.4.0

- Added a custom macOS app icon, menu bar template icon, and generated icon resources.
- Added a polished drag-to-Applications DMG background with app and Applications layout.
- Updated packaging scripts to regenerate and bundle visual assets automatically.

## 0.3.0

- Added Chinese and English menu localization based on the macOS preferred language.
- Added localized listener, permission, status, and natural scrolling state text.
- Refined the GitHub README into a Chinese-first bilingual project homepage.

## 0.2.0

- Added menu preferences for choosing whether mouse input should enable or disable natural scrolling.
- Added menu preferences for choosing whether trackpad input should enable or disable natural scrolling.
- Kept the original defaults: mouse natural scrolling off, trackpad natural scrolling on.

## 0.1.0

- Added a macOS menu bar app that switches the global natural scrolling setting by detected input source.
- Mouse wheel input sets natural scrolling off.
- Trackpad continuous scroll or gesture input sets natural scrolling on.
- Added manual menu actions, permission prompts, local packaging scripts, and a small self-test target.
