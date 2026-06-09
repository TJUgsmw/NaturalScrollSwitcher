# NaturalScrollSwitcher 0.5.1

Fixes the main v0.5.0 failure mode where editable event taps could be unavailable without the app falling back to a usable strategy.

## What's included

- Three runtime modes: Event Correction, Global Fallback, and Manual Only.
- Automatic fallback from editable event taps to listen-only global setting sync when Accessibility permission is missing or macOS rejects event modification.
- Manual mouse and trackpad switches always write the system natural scrolling setting.
- Clearer menu diagnostics for run mode, recent input source, recent action, and missing permissions.
- Existing event-level correction for ordinary USB/Bluetooth wheel mice when both Input Monitoring and Accessibility permissions are available.
- Existing custom app icon, menu bar icon, bilingual menu text, and drag-to-Applications DMG.

## Install

Download the `.dmg` or `.zip`, open `NaturalScrollSwitcher.app`, and grant both Input Monitoring and Accessibility permissions when macOS asks.

If only Input Monitoring is granted, automatic switching still works through the global setting fallback. Grant Accessibility as well for immediate event-level mouse wheel correction.

This app is ad-hoc signed for local use, not notarized by Apple. macOS may show a first-run warning.
