# NaturalScrollSwitcher 0.6.1

Patch release for trackpad switching after the v0.6.0 mouse detection changes.

## What's included

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
