# NaturalScrollSwitcher 0.6.7

Patch release for machines where the system setting shows the right value but the final mouse wheel direction still feels wrong.

## What's included

- New menu toggle: Force Mouse Direction Correction.
- When this toggle is enabled and mouse natural scrolling is off, mouse wheel events are inverted even if the macOS global natural scrolling setting already reads off.
- This is intended for compatibility with extra scroll processing from remote-control tools, mouse utilities, or apps that do not fully follow the system natural scrolling setting.
- Added self-test coverage for the forced correction path.
- Mouse input writes the macOS global natural scrolling setting to the mouse preference again.
- Trackpad input writes the macOS global natural scrolling setting to the trackpad preference again.
- Manual "Switch to Mouse" now writes the mouse preference even when Event Correction mode is active.
- Event-level correction uses the actual current system setting as its baseline and only corrects while the setting differs from the detected device preference.
- Preference writes now refresh `cfprefsd` after synchronization, improving Global Fallback and manual switching behavior.
- HID wheel monitoring now listens across HID devices, then filters for wheel elements and ignores trackpad-like devices. This helps Bluetooth mice whose wheel is not exposed through the standard mouse collection.
- Trackpad events can be corrected during a stale baseline transition if the event carries invertible scroll deltas.
- Added self-test coverage for pending trackpad correction.
- Trackpad-like HID devices are ignored by the mouse wheel override, reducing false mouse detection from built-in trackpads.
- Local event diagnostics are written to `~/Library/Logs/NaturalScrollSwitcher/events.log`.
- GitHub Actions now installs Pillow in a project-local Python virtual environment instead of using `pip install --user`.
- This avoids PEP 668 `externally-managed-environment` failures on newer macOS runners.
- Fixes an over-broad mouse heuristic that could make touch-phase trackpad scroll events look like mouse wheel input.
- Reduces the recent HID mouse override window so switching from mouse to trackpad is less likely to affect the first trackpad scroll.
- The app no longer requests permissions on every launch; it only reads current permission state unless you click the permission menu item.
- HID-level mouse wheel detection helps classify ordinary USB/Bluetooth wheel mice as mouse input even when macOS reports touch-like scroll fields.
- Discrete wheel events are kept as mouse input even if macOS attaches a scroll phase.
- Packaging supports `CODESIGN_IDENTITY` and `CODESIGN_KEYCHAIN` for stable local signing.
- Existing fallback modes remain: Event Correction, Global Fallback, and Manual Only.
- Existing custom app icon, menu bar icon, bilingual menu text, and drag-to-Applications DMG.

## Install

Download the `.dmg` or `.zip`, open `NaturalScrollSwitcher.app`, and grant both Input Monitoring and Accessibility permissions when macOS asks.

If only Input Monitoring is granted, automatic switching still works through the global setting fallback. Grant Accessibility as well for immediate event-level mouse wheel correction.

The default local package is still ad-hoc signed, not notarized by Apple. Ad-hoc signing uses a changing `cdhash`, so macOS may require permissions again after replacing the app with a newly built copy. For stable local permissions across rebuilds, sign with a persistent local certificate via `CODESIGN_IDENTITY`.
