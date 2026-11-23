# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
Stroke survivors, mostly older, often using one hand, some with low vision,
tremor or reduced dexterity, many not used to apps. They use Rohab at home,
seated, usually in a room with ordinary daylight or lamp light, often with a
carer nearby. A therapist sets the plan (PIN-protected therapist screen).
Test device: Redmi 7A (low-end Android, about 360 dp wide, 2 GB RAM).

## Product Purpose
Companion app for a soft robotic stroke-rehab glove (ESP32 over BLE) and for
camera-only hand exercises (front camera plus MediaPipe, video never saved).
It guides daily exercises, counts reps, tracks range and progress, and keeps
the glove safe. Success: the patient does today's exercises without help,
and trusts the app enough to keep doing them.

## Positioning
A rehab tool that feels like the clinic's own paperwork and patient portal,
not a fitness gadget: plain words, one action per screen, safety always
visible.

## Operating Context
- STOP and the connection banner appear on every screen while a glove is
  connected. Pressure target 35 kPa, hard cap 50 kPa (`lib/config/pressure_limits.dart`).
- Camera exercises need the whole hand in frame; the screen is read at arm's length.
- Exercise content follows `docs/rehab-science.md`; a therapist reviews any new exercise.

## Capabilities and Constraints
- Flutter, Android and iOS. Riverpod, go_router, drift.
- Video is never stored; only rep counts and ranges.
- Do not change safety behaviour (STOP, limits) without asking.
- Low-end phone: no heavy animation, no big assets.

## Brand Commitments
Name: Rohab. App icon blues (#54C5F8, #29B6F6, #01579B). STOP stays red and unchanged in behaviour.

## Evidence on Hand
No patient photos or testimonials. Exercise names and demo data are synthetic.

## Product Principles
1. Familiar beats clever: use patterns patients already know from clinics, banks and patient portals.
2. One clear action per screen, in plain words.
3. Safety is never hidden or restyled into something less obvious.
4. Never rely on colour, shadow or fine detail alone to carry meaning.
5. Calm: no streak pressure, no looping motion near the exercise.

## Accessibility & Inclusion
Touch targets at least 56 dp (primary 64 dp), body text at least 18 sp, contrast at
least 4.5:1, layout survives 200% text scale, works one-handed and with TalkBack,
reduced motion respected.
