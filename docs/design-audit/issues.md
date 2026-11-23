# Rohab redesign: issue log

Baseline before this session: `flutter analyze` 0 issues, `flutter test` 299 passed.
After: `flutter analyze` 0 issues, `flutter test` 321 passed (new: contrast, DateRange, components, STOP visibility).

Evidence labels: **device** = seen on the Redmi 7A (release build, 360x800-class screen, 100% text);
**test** = widget/unit test; **code** = read from source only. No screenshots were taken at 200% text or at
412x915, and no before-screenshots were taken this session (the older `screens/*_before.png` are from an
earlier session and show the previous design). Overflow at 200% is covered by widget tests, not by eye.

## The 12 known issues

| # | Issue | Status | Evidence |
|---|---|---|---|
| 1 | Progress filter dead | fixed | `DateRange` + `sessionsIn`; `test/progress_screen_test.dart` (7 < 30 <= 90 reps, label follows), `test/date_range_test.dart`. Device: 7/30/90 buttons render. |
| 2 | Streak shown | closed | No streak widget, provider, copy or test exists in `lib/` or `test/` (grep "streak" is empty). It was already gone before this session. |
| 3 | "1 of 7 days" vs "5 sessions" | fixed | One definition in `lib/program/date_range.dart` (session = saved completed run, practice day = distinct local date). Hero sentence "13 sessions on 1 practice day" is built from the same object; tested. |
| 4 | Blank gap on Exercises | fixed | Exercises is a full list / menu; `EmptyState` exists for empty cases. Device. |
| 5 | Glove-only metrics with no glove | fixed | Reps/pressure rows exist only while connected (`GloveSession`). Camera shows reps from the camera. Note: the "Counted by camera" label was NOT added (see open items). |
| 6 | "Level 3" and running-person icons | fixed | No icons beside rows; one 2 dp outlined icon family (`RohabIcon`). "Level N" text remains as plain section text on the plan screen. Device. |
| 7 | Home duplicate Glove heading, clipped "off." | fixed | One Glove row; rows grow with text (no fixed heights). Device. |
| 8 | Glove 24 h time and "Trigger level" | fixed | `formatWhen(use24h:)` follows the device setting; "Grip sensitivity" with one plain sentence; "good for" computed by `calibrationGoodFor` (tested). Device. |
| 9 | Low fps, debug text, clipped glove status | partly | Debug text is only built under `kDebugMode` (code). Status is wrapped text, not clipped (test). **FPS was not measured and was not changed** (see open items). |
| 10 | Missing Reps-per-set stepper | fixed | `RohabStepper` 1..20 (tested), plus Sets 1..6 and Rest 10..120 in 10 s steps; persisted per exercise. |
| 11 | Low-contrast disabled button | fixed | disabledFill/disabledText 4.58:1, 1 dp border, reason line (`RohabButton`, tested). Device. |
| 12 | Roboto, light numerals, pill nav, wireframe cards | fixed | Bundled fonts, no Roboto; custom `RohabNavBar` with a 3 dp top bar; rows not cards. Greps in SUMMARY.md. Device. |

## Decisions made on ambiguity (simplest, safest, most accessible)

- **STOP moved (user request, mid-session).** The brief asked for a pinned full-width STOP. The user then asked for a stop-sign button top right, shown only during an exercise. Implemented as a 56 dp octagon, top right, over every screen, shown while the glove is active (session running, hand moving/pressurised, calibration in progress, or a fault). It is hidden when the glove is idle or disconnected. **This changes the old "always visible" rule in CLAUDE.md; it needs a human safety sign-off.** Pressure limits are untouched.
- **Type scale reduced (user request).** 24 title, 16 rows/body/buttons, 15 sub-lines, 14 nav and labels, 28/48/64 numbers. Nothing below 14.
- **Fonts changed (user request).** Titles and all numbers use Source Sans 3 (the sans companion of the Source Serif family originally asked for); body uses Atkinson Hyperlegible Next. Barlow and Source Serif were removed. Atkinson's slashed zero was the "weird" number shape.
- **Exercises menu (user request).** The old menu (Camera -> Today's plan) is back. "Practice any exercise" opens the tabbed Camera | Glove | All list, which opens the Set up | How to | History page.
- Nav labels stop scaling at 1.3x and the top-bar title at 1.5x so four tabs and a title fit at 200% text.
- Variable fonts (Atkinson, Source Sans 3) are declared with explicit weights in pubspec and set with `FontVariation('wght')`.
- Settings "About" shows the font credit inline instead of opening a license page, because a pushed page would cover the STOP sign. The OFL texts are registered with `LicenseRegistry`.
- The dark theme was removed (the brief defines one light palette).

## Open items (not done, or not verified)

- **Camera fps:** not measured, not changed. Nothing was done for analysis resolution, isolate offload or frame dropping. A debug-only fps readout already exists (`camera_layout.dart`).
- **Hand toggle (Right | Left)** is stored per exercise but is not wired into the tracker; the tracker still detects handedness itself.
- **"Counted by camera"** label, **Clinic scores**, **Share with your therapist (PDF)** and **Reminders** do not exist in the app; they were not built (the brief said no new features). "Compare with your other hand" opens the hand measurement.
- Therapist, Baseline, Pain check and Welcome screens got the new theme and fonts but were not redesigned row by row.
- No before/after captures at 360x800 200% and 412x915; no goldens.
- Photos at `assets/exercises/<id>.jpg` do not exist yet; How to shows text only.
