# Feedback — haptics and sound
## Doctrine
The product is quiet. The device speaks at most twice a day, and silence is the default state of every surface. Haptics are a second channel, never the only one (M-15); nothing fires when the device is silenced; sound is OFF by default and there is no sound design in v2 at all — a money-adjacent app that beeps is a toy.

## The moments that speak
- **Answering the day (the beat):** UIImpactFeedbackGenerator .rigid, intensity 0.7, fired once as the hand seats. The one expressive haptic in the product.
- **Answer buttons touch-down:** .selection — confirms the tap under a tired thumb.
- **Urge surf completes:** .impact .soft 0.5 — a hand on the shoulder, not an alarm.
- **Waiting item comes off hold (notification, if allowed):** system notification sound only if the user's settings allow; the in-app row changes silently.
- **Destructive confirm (erase record):** system alert's own feedback; we add nothing.

## The deliberate silences
Opening the app · tab changes · calendar browsing · month paging · checklist answers · timer ticking (never) · the paywall (a sheet that buzzes is begging) · streak break (NO haptic — the product never punishes; the broken-run message is read, not felt) · widgets (WidgetKit: none by platform rule, designed for).

## Reduce Motion / accessibility
Haptics are unaffected by Reduce Motion (they replace nothing). With haptics unavailable (iPad), all meaning survives — every haptic moment already has its visual state.
