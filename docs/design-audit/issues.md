# Rohab design audit: issue log

Baseline (before): `flutter analyze` 0 issues, `flutter test` 275 passed.
After: `flutter analyze` 0 issues, `flutter test` 299 passed (24 new/changed).

Screenshots are in `screens/`, named `screen_state_config_before|after.png`.
Configs: 360x800 at 100% text, 360x800 at the app's largest text setting (1.5x,
not 200%), 412x915 at 100%. Only the normal, no-glove state was captured.
Glove states (connected, error, disconnected mid-session) are driven by the mock
glove from the debug menu and were NOT screenshotted; they are covered by widget tests.

## Screen inventory

| Route | Purpose | Primary action | Built by |
|---|---|---|---|
| /welcome | First-run guide | Next | screens/welcome_screen.dart |
| /home | Today's plan, glove section | Measure my hands / Start | screens/home_screen.dart |
| /calibration (Glove tab) | Glove calibration | Start calibration | screens/calibration/* |
| /exercises | Camera or glove | Camera | screens/exercises/exercises_screen.dart |
| /exercises/camera | Today's plan | Continue | program_screen.dart |
| /exercises/camera/all | All exercises | open one | program_screen.dart |
| /exercises/camera/:id | Instructions then live exercise | Start | camera_exercise_flow.dart |
| /exercises/camera/pain | Pain check | Continue | pain_check_screen.dart |
| /progress | Last 7 days and sessions | (read only) | screens/progress/* |
| /settings, /settings/therapist | Text size, delete data, therapist plan | | screens/settings/* |

## Findings

### ISSUE-001 Box around the Continue button
- Severity: S2 | Screen: Exercises > Today's plan, 360x800 (user phone screenshot) | Lens: A, K
- Root cause: `widgets/action_area.dart` always reserved an empty 64 dp secondary slot above the primary button, and the content fade ended in a flat colour at the top of that slot, so a gap plus a hard-edged band read as a box.
- Chosen solution: collapse the empty slot; the fade meets the button. The primary button stays bottom-anchored so it does not move.
- Verification: tests pass; screenshot `camera-list_normal_*_after.png`. Status: fixed. (The fade is a gradient: kept on purpose, the user asked for it. It is the only gradient in the app.)

### ISSUE-002 Mixed materials (denim, linen, brushed metal) and glossy two-tone buttons
- Severity: S2 | Lens: K | Root cause: `widgets/skeuo.dart` textures and `BevelPainter` gloss.
- Chosen solution: user asked for a modern soft-extruded (neumorphic) look. One material (the page), a faint paper grain (about 4%), solid header, solid tab bar, one raised-button recipe (flat fill, 1 px edge, soft shadow that disappears when pressed, darker face and 2 dp shift when pressed). Denim, stitching, leather, linen and metal assets and code deleted.
- Deviation from the brief, on purpose: shadows are dual (light top-left, dark bottom-right) instead of `0 2dp 0` edge shadows, because the user asked for neumorphism. A 1 px border (>= 3:1 for controls) keeps edges visible, since soft shadows alone fail low-vision users.
- Status: fixed (screenshots), glass not used anywhere.

### ISSUE-003 Streak counter
- Severity: S2 | Lens: F | Root cause: `screens/progress/overview.dart` `streak`.
- Solution: removed the field, text, key and tests. Replaced by "Practice days: N of the last 7" and "N reps in the last 7 days". Definitions: session = one saved exercise run; practice day = distinct local date with at least one session. Test: `progress_overview_test.dart` "practice days counts distinct dates, not sessions".
- Status: fixed.

### ISSUE-004 "1 of 7 days" next to "5 sessions"
- Severity: S1 | Root cause: two unlabeled numbers with different windows ("This week" = rolling 7x24 h, bars = 7 calendar days).
- Solution: both blocks now say "Last 7 days" and name what they count. Windows still differ slightly at the edge (rolling hours vs calendar days): documented, not changed (would alter counting).
- Status: fixed, with that caveat.

### ISSUE-005 "Reps this session" with a dash and no glove
- Severity: S2 | Root cause: `home_screen.dart` always showed the reps, hand-state and pressure cards.
- Solution: without a glove Home shows one card, "Glove not connected. Glove exercises are off."; the numbers appear only when connected. STOP banner untouched (it is separate and already hidden without a glove, by design).
- Status: fixed. Not screenshotted with the glove connected.

### ISSUE-006 Decorative or misleading icons
- Severity: S3 | Root cause: `Icons.stairs_outlined` on the level chip, `Icons.sports_handball_outlined` on "With glove", `Icons.directions_walk` on finger walking.
- Solution: stairs removed (text carries "Level 3"); "With glove" uses the Bluetooth icon (meaning: connection); finger walking uses an arrow.
- Status: fixed.

### ISSUE-007 Disabled "Start calibration"
- Severity: S2 | Lens: C, G | Root cause: disabled colours were divider/secondary gray; the reason sat above the button.
- Solution: disabled tokens (`disabledFill`, `disabledText`, 3:1 or better, computed in `test/contrast_test.dart`); reason now one line directly under the button.
- Status: fixed.

### ISSUE-008 Tab bar and Settings button smaller than 64 dp
- Severity: S1 | Lens: D | Root cause: found by `safety_stop_test` while restyling (tab 58 dp, then 60 dp).
- Solution: `minHeight: RohabSize.touchTarget` on each tab. Also the tab bar's `Center`/`Column` expanded to full screen height and zeroed the content: fixed with `heightFactor`/`mainAxisSize.min`.
- Status: fixed (test).

### ISSUE-009 Contrast of new palette
- Severity: S2 | Lens: C | Found by new `contrast_test.dart` (24 pairs, light and dark): control edge 2.9:1 -> now >= 3:1; dark-theme danger text below 4.5:1 -> lightened.
- Status: fixed. Ratios are asserted in the test, not copied here.

## Not reproduced / not done

- **Week / Month / 3 Months filter (brief 4.1)**: does not exist in this app (Progress shows the last 7 days and the last 10 sessions of one exercise). Adding it is a new feature; not added.
- **Reps per set stepper (brief #9)**: exists in the therapist screen (`_Stepper`, "Reps per set"); not missing. Its buttons were not audited against 64 dp.
- **Glove status text clipped (#8)**: banner already wraps (`maxLines: 2`) and grows with text; not reproduced.
- **Blank gap on Exercises (#4)**: the Exercises tab has two cards and nothing else, so the rest is empty by design. Not a clipped list. Left; an empty-state hint would be a new feature.
- **Camera fps / debug text (#7)**: debug text is already behind `kDebugMode`. fps (9-10) NOT measured or improved here: needs the phone. Analysis is already `ResolutionPreset.low`.
- **fl_chart, PDF export, `progress_repository.dart`, `RohabButton` etc. component set, `StopButton` unification, 200% text screenshots, protanopia simulation, haptics/tone on rep count, in-app text-size control step names**: not done. The app uses its own charts, no export exists, and the text-size control already has three steps (1.0/1.25/1.5). Listed as follow-ups in SUMMARY.md.
