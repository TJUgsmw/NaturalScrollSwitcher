# NaturalScrollSwitcher 0.6.4

Patch release for trackpad auto-switch diagnostics and HID filtering.

## What's included

- Trackpad-like HID devices are ignored by the mouse wheel override, reducing false mouse detection from built-in trackpads.
- Local event diagnostics are written to `~/Library/Logs/NaturalScrollSwitcher/events.log`.
- Mouse input now writes the macOS natural scrolling setting to the mouse preference.
- Trackpad input now writes the macOS natural scrolling setting to the trackpad preference.
- Event-level correction is only used while the current system setting has not caught up to the detected mouse preference.
- This avoids double-inverting mouse wheel events once the system setting already matches the mouse preference.
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
