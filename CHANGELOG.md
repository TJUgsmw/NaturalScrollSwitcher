# Changelog

## 0.7.2

- Fixes excessive CPU use during trackpad input on macOS 27 by delivering source changes instead of every gesture to the menu and settings code.
- Avoids setting an unchanged menu bar title, which triggered repeated AppKit status item snapshots on macOS 27.0.1.
- Filters HID input values to vertical and horizontal wheels while retaining support for Bluetooth mice outside the standard mouse collection.
- Disables detailed event snapshots by default; logs only startup, runtime changes, and setting writes.
- Writes diagnostics on a utility queue, reuses the date formatter and file handle, and caps the log at 1 MiB, including oversized logs from older versions.
- Removes permanent two-second permission polling. Permissions are checked on menu opening, wake, and session activation; temporary polling is limited to two minutes after a permission request.
- Preserves immediate mouse/trackpad source transitions, manual switching, and detection after automatic switching resumes.
- Adds gesture-burst and bounded-log regression checks and a zero-payload load probe for local performance comparisons.

## 0.7.1

- Uses live system switching as the primary mode: mouse input turns the real macOS natural scrolling setting off, and trackpad input turns it on.
- Input Monitoring is the only required permission; Accessibility is no longer requested.
- Removes the fixed trackpad baseline that could immediately turn natural scrolling back on after the user switched to a mouse.
- Applies natural scrolling through the same live system interface used by System Settings, then synchronizes the global preference value.
- Removes Force Mouse Direction Correction and migrates its saved value away because it could double-invert mouse scrolling.
- Global Fallback now writes only when the detected input source changes.

## 0.7.0

- Event correction now uses each scroll event's live natural-scroll direction from `NSEvent.isDirectionInvertedFromDevice`.
- This fixes cases where `defaults` already shows the requested value but macOS keeps using the previous scroll direction until System Settings is toggled manually.
- Diagnostics now log the event-level natural-scroll state as `eventNatural=...`.

## 0.6.9

- Fixed a double-inversion bug in Force Mouse Direction Correction.
- Forced mouse correction no longer reverses mouse events when the macOS global natural scrolling setting already matches the mouse preference.
- This prevents the app from turning a correctly disabled mouse natural scrolling state back into natural scrolling.

## 0.6.8

- Changed Force Mouse Direction Correction to suppress the original mouse wheel event and repost an inverted synthetic event.
- Synthetic reposted events are marked with `eventSourceUserData` to avoid recursive event tap handling.
- This targets environments where in-place scroll event edits are observed in diagnostics but do not affect the final scrolling behavior.

## 0.6.7

- Added a Force Mouse Direction Correction menu toggle for systems where macOS shows natural scrolling as off but the final mouse wheel direction still behaves as if it is on.
- The forced correction path inverts mouse wheel events when the mouse preference is Natural Off, even if the global system setting already matches that preference.
- Added self-test coverage for forced mouse correction.

## 0.6.6

- Restored the original contract that mouse input writes the macOS global natural scrolling setting to the mouse preference and trackpad input writes it to the trackpad preference.
- Fixed manual "Switch to Mouse" in Event Correction mode so it immediately writes the mouse preference instead of preserving the trackpad baseline.
- Event-level correction remains a transition aid and now uses the actual current system setting as its baseline again, avoiding double correction after the global setting changes.

## 0.6.5

- Fixed Event Correction mode so it keeps the macOS global natural scrolling setting aligned with the trackpad preference instead of repeatedly switching the global setting between mouse and trackpad.
- Mouse wheel direction is now corrected against that stable trackpad baseline, which avoids relying on macOS to immediately reload the global preference after every device switch.
- Preference writes now refresh `cfprefsd` after synchronization to reduce stale natural scrolling behavior in Global Fallback and manual writes.
- Broadened HID wheel monitoring so Bluetooth mice that expose wheel input outside the standard mouse collection can still be recognized as mouse input.
- Added a self-test for trackpad event correction when the active baseline is still on the mouse preference.

## 0.6.4

- Filtered trackpad-like HID devices out of the recent mouse wheel override so built-in trackpad scrolling is less likely to be misclassified as mouse input.
- Added a local event diagnostics log at `~/Library/Logs/NaturalScrollSwitcher/events.log` with source classification, run mode, system setting value, and raw scroll fields.

## 0.6.3

- Restored the original behavior where the macOS global natural scrolling setting follows the active input source: mouse writes the mouse preference, trackpad writes the trackpad preference.
- Kept event-level correction only as a transition aid while the current system setting has not yet caught up to the detected mouse preference.
- Avoided double-inverting mouse wheel events once the system setting already matches the mouse preference.

## 0.6.2

- Fixed GitHub Actions dependency installation by using a project-local Python virtual environment for Pillow.
- Updated build instructions to avoid PEP 668 `externally-managed-environment` failures on newer macOS runners.

## 0.6.1

- Fixed an over-broad mouse heuristic that could classify touch-phase trackpad scroll events as mouse wheel input.
- Reduced the HID mouse wheel override window so switching from mouse to trackpad is less likely to affect the first trackpad scroll.

## 0.6.0

- Stopped requesting Input Monitoring and Accessibility permissions automatically on every launch; permissions are now requested only when the user chooses the menu action.
- Added HID-level mouse wheel monitoring so ordinary USB/Bluetooth wheel mice are preferred as mouse input even when their CGEvent scroll fields look touch-like.
- Changed discrete wheel classification so non-continuous wheel events remain mouse input even if macOS attaches a scroll phase.
- Added `CODESIGN_IDENTITY` and `CODESIGN_KEYCHAIN` support to packaging so local builds can use a stable signing identity and avoid TCC permission resets across updates.
- Documented why ad-hoc signatures use a changing `cdhash` identity and can require re-granting macOS permissions after reinstalling or updating the app.

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
