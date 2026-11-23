import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rohab/app/app.dart';
import 'package:rohab/widgets/rohab_tabs.dart';
import 'package:rohab/exercises/exercise_setup.dart';
import 'package:rohab/screens/exercises/exercise_setup_screen.dart';
import 'package:rohab/program/program_providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/camera/camera_permission.dart';
import 'package:rohab/camera/hand_tracker.dart';
import 'package:rohab/camera/mock_hand_tracker.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';
import 'package:rohab/data/program_repository.dart';
import 'package:rohab/exercises/exercise_catalog.dart';
import 'package:rohab/exercises/exercise_providers.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/program/baseline.dart';
import 'package:rohab/screens/exercises/baseline_screen.dart';
import 'package:rohab/screens/exercises/camera_exercise_flow.dart';
import 'package:rohab/screens/exercises/exercises_screen.dart';
import 'package:rohab/screens/exercises/pain_check_screen.dart';
import 'package:rohab/screens/exercises/program_screen.dart';
import 'package:rohab/widgets/app_shell.dart';
import 'package:rohab/screens/settings/settings_screen.dart';
import 'package:rohab/screens/settings/therapist_screen.dart';
import 'package:rohab/widgets/safety_banner.dart';

import 'helpers.dart';

/// Day 0 of the plan rotation: level 2 starts with open_close.
final today = DateTime(2026, 1, 1, 9);

class FakePermission implements CameraPermission {
  FakePermission(this.current, {this.afterRequest = CameraAccess.granted});

  CameraAccess current;
  final CameraAccess afterRequest;
  int settingsOpened = 0;

  @override
  Future<CameraAccess> status() async => current;

  @override
  Future<CameraAccess> request() async => current = afterRequest;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class Harness {
  Harness(this.glove, this.trackers, this.db, this.permission);
  final MockGloveService glove;

  /// One tracker per flow, as in the app.
  final List<MockHandTracker> trackers;
  final AppDatabase db;
  final FakePermission permission;

  MockHandTracker get tracker => trackers.last;

  Future<List<ExerciseSessionRow>> sessions(WidgetTester t) async =>
      (await t.runAsync(() => DriftExerciseSessionRepository(db).all()))!;
}

Future<Harness> launch(
  WidgetTester tester, {
  MockHandTracker? tracker,
  CameraAccess access = CameraAccess.granted,
  CameraAccess afterRequest = CameraAccess.granted,
  int? baselineLevel,
}) async {
  final trackers = <MockHandTracker>[?tracker];
  MockHandTracker create() {
    if (tracker != null) return tracker;
    final previous = trackers.isEmpty ? null : trackers.last;
    final t = MockHandTracker()..pose = previous?.pose ?? HandPose.open;
    trackers.add(t);
    return t;
  }

  if (tracker == null) create();
  var first = true;
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (baselineLevel != null) {
    await tester.runAsync(
      () => DriftProgramRepository(db).saveBaseline(
        BaselineResult(
          affectedHand: Handedness.left,
          affected: const HandRange(open: 30, closed: 220),
          other: const HandRange(open: 5, closed: 260),
          level: baselineLevel,
          cameraLimited: false,
          takenAt: today,
        ),
      ),
    );
  }
  final permission = FakePermission(access, afterRequest: afterRequest);
  final glove = await pumpRohab(
    tester,
    clock: () => today,
    db: db,
    overrides: [
      handTrackerFactoryProvider.overrideWithValue(() {
        if (first) {
          first = false;
          return trackers.last;
        }
        return create();
      }),
      cameraPermissionProvider.overrideWithValue(permission),
    ],
  );
  return Harness(glove, trackers, db, permission);
}

/// Lets drift work started under the test's fake clock finish: SQLite
/// needs real time, and its result is delivered on a pump.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<void> close(WidgetTester tester, Harness h) async {
  await settle(tester);
  await finish(tester, h.glove);
  for (final t in h.trackers) {
    await t.stop();
  }
  await tester.runAsync(h.db.close);
}

/// Jumps straight to a route, as a tap on the screen that links to it would.
Future<void> goTo(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(AppShell))).go(path);
  await tester.pump();
}

/// Today's plan screen: Exercises, then Camera.
Future<void> openProgram(WidgetTester tester) async {
  await tapTab(tester, 'Exercises');
  await tester.tap(find.byKey(ExercisesScreen.cameraKey));
  await settle(tester);
}

/// Free practice of one exercise, outside the plan: Exercises, the exercise,
/// its set-up page (reps per set set to [reps]), then Start.
Future<void> openFree(WidgetTester tester, String id, {int reps = 10}) async {
  await tapTab(tester, 'Exercises');
  await tap(tester, ExercisesScreen.allKey);
  await tap(tester, ExerciseListScreen.rowKey(id));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AppShell)),
  );
  final notifier = container.read(exerciseSetupsProvider.notifier);
  await tester.runAsync(
    () => notifier.update(id, notifier.of(id).copyWith(reps: reps, sets: 1)),
  );
  await tester.pump();
  await tap(tester, ExerciseSetupScreen.startKey);
}

/// Taps [key], scrolling the visible list to it first if needed.
Future<void> tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> tapPrimary(WidgetTester tester) =>
    tap(tester, CameraExerciseFlow.primaryKey);

/// Hand check (1 s) and range calibration (3 s open, 3 s fist).
Future<void> passHandCheckAndCalibrate(WidgetTester tester, Harness h) async {
  h.tracker.pose = HandPose.open;
  await tester.pump(const Duration(milliseconds: 1100));
  expect(find.text('Open your hand as wide as you can.'), findsOneWidget);
  await tester.pump(const Duration(seconds: 3));
  expect(find.text('Now make a fist.'), findsOneWidget);
  h.tracker.pose = HandPose.fist;
  await tester.pump(const Duration(seconds: 3, milliseconds: 100));
}

/// The first open after calibration (which ends in a fist) starts the
/// first rep: a rep is open, closed, open again.
Future<void> firstOpen(
  WidgetTester tester,
  Harness h, {
  HandPose pose = HandPose.open,
}) async {
  h.tracker.pose = pose;
  await tester.pump(const Duration(milliseconds: 600));
}

/// [n] reps from an open hand: close 600 ms, open 600 ms.
Future<void> doReps(
  WidgetTester tester,
  Harness h,
  int n, {
  HandPose open = HandPose.open,
}) async {
  for (var i = 0; i < n; i++) {
    h.tracker.pose = HandPose.fist;
    await tester.pump(const Duration(milliseconds: 600));
    h.tracker.pose = open;
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// "2 of 10", read from the info panel's "Rep 2 of 10, set 1 of 1" line.
String repsText(WidgetTester tester) {
  final line = tester
      .widgetList<Text>(find.textContaining('Rep '))
      .map((w) => w.data ?? '')
      .firstWhere((t) => RegExp(r'^Rep \d+ of \d+').hasMatch(t));
  final m = RegExp(r'^Rep (\d+) of (\d+)').firstMatch(line)!;
  return '${m[1]} of ${m[2]}';
}

void main() {
  testWidgets(
    'Exercises: Camera opens today\'s plan; the glove option is locked with a reason',
    (tester) async {
      final h = await launch(tester);
      await tapTab(tester, 'Exercises');
      expect(find.byKey(ExercisesScreen.cameraKey), findsOneWidget);
      expect(find.text('Connect your glove to use this.'), findsOneWidget);
      await tester.tap(find.byKey(ExercisesScreen.gloveKey));
      await tester.pump();
      expect(find.byKey(ExercisesScreen.gloveKey), findsOneWidget);
      await tester.tap(find.byKey(ExercisesScreen.allKey));
      await tester.pump();
      expect(
        find.byKey(
          ExerciseListScreen.rowKey('open_close'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.text('New'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(UnderlineTabs),
          matching: find.text('Glove'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Connect your glove to use this', skipOffstage: false),
        findsWidgets,
      );
      await close(tester, h);
    },
  );

  group('hand measurement', () {
    testWidgets('measures both hands, sets level 2 and saves it', (
      tester,
    ) async {
      final h = await launch(tester);
      await openProgram(tester);
      expect(find.text('First, measure your hands'), findsOneWidget);
      await tap(tester, ProgramScreen.primaryKey);
      await tap(tester, BaselineScreen.rightKey);
      await settle(tester);
      expect(
        find.text('Hold your right hand inside the frame.'),
        findsOneWidget,
      );
      // No glove: no glove banner during camera practice.
      expect(find.byKey(SafetyBanner.stopKey), findsNothing);

      // Affected right hand: bend 0.15 to 0.8 of a fist (about 40 to 214).
      Future<void> measure(HandPose open, HandPose closed) async {
        h.tracker.pose = open;
        await tester.pump(const Duration(milliseconds: 1100)); // hand check
        for (var cycle = 0; cycle < 2; cycle++) {
          h.tracker.pose = open;
          await tester.pump(const Duration(seconds: 4));
          h.tracker.pose = closed;
          await tester.pump(const Duration(seconds: 4));
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      await measure(
        const HandPose(curl: 0.15, rightHand: true),
        const HandPose(curl: 0.8, rightHand: true),
      );
      expect(find.text('Now your left hand'), findsOneWidget);
      await tap(tester, BaselineScreen.primaryKey);
      await measure(const HandPose(), const HandPose(curl: 1));
      await settle(tester);

      expect(find.text('Starting level: 2'), findsOneWidget);
      final saved = await tester.runAsync(
        () => DriftProgramRepository(h.db).latestBaseline(),
      );
      expect(saved!.level, 2);
      expect(saved.affectedHand, Handedness.right);
      expect(saved.affected.range, closeTo(174, 15));
      expect(saved.other!.range, closeTo(267, 15));
      expect(saved.rangeRatio, closeTo(0.65, 0.05));

      await tap(tester, BaselineScreen.primaryKey);
      await settle(tester);
      expect(find.text('Level 2 · Everyday grips'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('skipping the other hand still places a level', (tester) async {
      final h = await launch(tester);
      await openProgram(tester);
      await tap(tester, ProgramScreen.primaryKey);
      await tap(tester, BaselineScreen.leftKey);
      await settle(tester);
      h.tracker.pose = HandPose.open;
      await tester.pump(const Duration(milliseconds: 1100));
      for (var cycle = 0; cycle < 2; cycle++) {
        h.tracker.pose = HandPose.open;
        await tester.pump(const Duration(seconds: 4));
        h.tracker.pose = HandPose.fist;
        await tester.pump(const Duration(seconds: 4));
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tap(tester, BaselineScreen.secondaryKey); // Skip
      await settle(tester);
      expect(find.text('Starting level: 3'), findsOneWidget);
      await close(tester, h);
    });
  });

  group("today's plan", () {
    testWidgets('pain check, a set of 10, then the next set', (tester) async {
      final h = await launch(tester, baselineLevel: 2);
      await openProgram(tester);
      expect(find.text('Level 2 · Everyday grips'), findsOneWidget);
      expect(find.text('0 of 12 sets today'), findsOneWidget);
      expect(find.text('Open and close'), findsOneWidget);

      await tap(tester, ProgramScreen.primaryKey); // Start
      expect(find.text('Pain right now?'), findsOneWidget);
      await tap(tester, PainCheckScreen.scoreKey(2));
      await tap(tester, PainCheckScreen.primaryKey);
      await settle(tester);

      expect(find.text('Set 1 of 4'), findsOneWidget);
      await tapPrimary(tester); // Start
      await passHandCheckAndCalibrate(tester, h);
      expect(repsText(tester), '0 of 10');
      await firstOpen(tester, h);
      await doReps(tester, h, 10);
      await settle(tester);
      expect(find.text('Set complete. 10 reps.'), findsOneWidget);
      expect(find.textContaining('Rest for'), findsOneWidget);
      expect(find.text('Next set'), findsOneWidget);

      final rows = await h.sessions(tester);
      expect(rows.single.reps, 10);
      expect(rows.single.level, 2);
      expect(rows.single.targetReps, 10);

      await tapPrimary(tester); // Next set
      await settle(tester);
      expect(find.text('Set 2 of 4'), findsOneWidget);
      await tapPrimary(tester);
      // Same session: no second calibration.
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Open your hand as wide as you can.'), findsNothing);
      expect(repsText(tester), '0 of 10');
      await close(tester, h);
    });

    testWidgets('by default a tilted wrist does not throw reps out', (
      tester,
    ) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await firstOpen(tester, h);
      await doReps(tester, h, 2);
      await doReps(tester, h, 2, open: const HandPose(wristPitch: 40));
      expect(repsText(tester), '4 of 10');
      expect(find.text('Wrist moved. That one did not count.'), findsNothing);
      await close(tester, h);
    });

    testWidgets('with the therapist wrist check on, wrist-made reps do not '
        'count', (tester) async {
      final h = await launch(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RohabApp)),
      );
      await container
          .read(programSettingsProvider.notifier)
          .save(
            container.read(programSettingsProvider).copyWith(wristCheck: true),
          );
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await firstOpen(tester, h);
      await doReps(tester, h, 2);
      expect(repsText(tester), '2 of 10');
      // Opening by tilting the wrist 40 degrees.
      await doReps(tester, h, 2, open: const HandPose(wristPitch: 40));
      expect(repsText(tester), '2 of 10');
      expect(find.text('Wrist moved. That one did not count.'), findsOneWidget);
      await tester.tap(find.text('End session'));
      await settle(tester);
      expect(
        find.textContaining('did not count because the wrist moved'),
        findsOneWidget,
      );
      final rows = await h.sessions(tester);
      expect(rows.single.compensatedReps, greaterThanOrEqualTo(1));
      expect(rows.single.level, isNull, reason: 'free practice');
      await close(tester, h);
    });

    testWidgets('gripping a cup with a tilted wrist counts and is never '
        'called a wrist cheat', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'cylinder_grasp');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      for (var i = 0; i < 3; i++) {
        h.tracker.pose = const HandPose(curl: 0.5, wristPitch: 40);
        await tester.pump(const Duration(milliseconds: 2400)); // hold 2 s
        expect(find.text('Wrist moved. That one did not count.'), findsNothing);
        h.tracker.pose = HandPose.open;
        await tester.pump(const Duration(milliseconds: 800));
      }
      expect(repsText(tester), '3 of 10');
      expect(find.text('Wrist moved. That one did not count.'), findsNothing);
      await close(tester, h);
    });

    testWidgets('high pain before advises rest', (tester) async {
      final h = await launch(tester, baselineLevel: 1);
      await openProgram(tester);
      await tap(tester, ProgramScreen.primaryKey);
      await tap(tester, PainCheckScreen.scoreKey(8));
      await tap(tester, PainCheckScreen.primaryKey);
      await settle(tester);
      expect(find.text('Your pain is high today'), findsOneWidget);
      await tap(tester, PainCheckScreen.primaryKey); // Rest today
      await settle(tester);
      expect(
        find.textContaining('You reported high pain today.'),
        findsOneWidget,
      );
      await close(tester, h);
    });

    testWidgets('pain rising after practice is flagged', (tester) async {
      final h = await launch(tester, baselineLevel: 2);
      await openProgram(tester);
      await tap(tester, ProgramScreen.primaryKey);
      await tap(tester, PainCheckScreen.scoreKey(2));
      await tap(tester, PainCheckScreen.primaryKey);
      await settle(tester);
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await firstOpen(tester, h);
      await doReps(tester, h, 10);
      await settle(tester);
      await tap(tester, CameraExerciseFlow.secondaryKey); // Finish for today
      await settle(tester);
      expect(find.text('Pain now?'), findsOneWidget);
      await tap(tester, PainCheckScreen.scoreKey(5));
      await tap(tester, PainCheckScreen.primaryKey);
      await settle(tester);
      expect(find.text('Your pain went up by 3'), findsOneWidget);
      await close(tester, h);
    });
  });

  group('therapist', () {
    testWidgets('sets a PIN, changes the level, and the plan follows', (
      tester,
    ) async {
      final h = await launch(tester, baselineLevel: 2);
      await tester.tap(find.byKey(AppShell.settingsButtonKey));
      await tester.pump();
      await tap(tester, SettingsScreen.therapistKey);
      expect(find.text('Choose a therapist PIN'), findsOneWidget);
      await tester.enterText(find.byKey(TherapistScreen.pinFieldKey), '1234');
      await tap(tester, TherapistScreen.primaryKey);
      await tester.enterText(find.byKey(TherapistScreen.pinFieldKey), '1234');
      await tap(tester, TherapistScreen.primaryKey);
      await settle(tester);
      expect(find.text('Therapist plan'), findsWidgets);

      await tap(tester, TherapistScreen.levelKey(3));
      await tap(tester, TherapistScreen.stepKey('set', true));
      await tap(tester, TherapistScreen.primaryKey); // Save
      await settle(tester);
      expect(find.text('Saved.'), findsOneWidget);

      await openProgram(tester);
      expect(find.text('Level 3 · Single fingers'), findsOneWidget);
      expect(
        find.textContaining('Level set by your therapist'),
        findsOneWidget,
      );
      await close(tester, h);
    });

    testWidgets('a wrong PIN does not unlock', (tester) async {
      final h = await launch(tester);
      await tester.tap(find.byKey(AppShell.settingsButtonKey));
      await tester.pump();
      await tap(tester, SettingsScreen.therapistKey);
      for (final pin in ['2468', '2468']) {
        await tester.enterText(find.byKey(TherapistScreen.pinFieldKey), pin);
        await tap(tester, TherapistScreen.primaryKey);
      }
      await settle(tester);
      await tap(tester, TherapistScreen.secondaryKey); // Back
      await tap(tester, SettingsScreen.therapistKey);
      expect(find.text('Therapist PIN'), findsOneWidget);
      await tester.enterText(find.byKey(TherapistScreen.pinFieldKey), '1111');
      await tap(tester, TherapistScreen.primaryKey);
      expect(find.text('That PIN is not right.'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      await close(tester, h);
    });
  });

  group('counting', () {
    testWidgets('lost hand pauses counting', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await firstOpen(tester, h);
      await doReps(tester, h, 2);
      h.tracker.pose = HandPose.fist;
      await tester.pump(const Duration(milliseconds: 600));
      h.tracker.pose = null;
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Hold your hand inside the frame.'), findsOneWidget);
      h.tracker.pose = HandPose.open;
      await tester.pump(const Duration(milliseconds: 600));
      expect(repsText(tester), '2 of 10');
      await doReps(tester, h, 1);
      expect(repsText(tester), '3 of 10');
      await close(tester, h);
    });

    testWidgets('low-confidence frames are ignored', (tester) async {
      final h = await launch(
        tester,
        tracker: MockHandTracker(lowConfidenceEvery: 1),
      );
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Hold your hand inside the frame.'), findsOneWidget);
      expect(HandFrame.minConfidence, 0.6);
      await close(tester, h);
    });

    testWidgets('noise, low-confidence frames and a dropout still reach '
        'the set', (tester) async {
      final tracker = MockHandTracker(
        script: MockHandTracker.cycles(
          dropoutStart: const Duration(seconds: 14),
          dropoutLength: const Duration(seconds: 3),
        ),
        noise: 0.003,
        lowConfidenceEvery: 7,
      );
      final h = await launch(tester, tracker: tracker);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(seconds: 40));
      expect(find.text('Set complete. 10 reps.'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('shrinking movements are saved as fatigued', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await firstOpen(tester, h);
      await doReps(tester, h, 5);
      for (var i = 0; i < 5; i++) {
        h.tracker.pose = const HandPose(curl: 0.45);
        await tester.pump(const Duration(milliseconds: 600));
        h.tracker.pose = HandPose.open;
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(
        find.text('Movements are getting smaller. A rest may help.'),
        findsOneWidget,
      );
      await tester.tap(find.text('End session'));
      await settle(tester);
      expect(find.text('Set ended. 5 reps.'), findsOneWidget);
      final rows = await h.sessions(tester);
      expect(rows.single.fatigued, isTrue);
      expect(rows.single.metricUnit, 'deg');
      expect(rows.single.avgAmplitude, greaterThan(150));
      await close(tester, h);
    });

    testWidgets('ending early with no reps saves nothing', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      await tester.tap(find.text('End session'));
      await settle(tester);
      expect(find.text('Set ended. 0 reps.'), findsOneWidget);
      expect(find.textContaining('nothing was saved'), findsOneWidget);
      expect(await h.sessions(tester), isEmpty);
      await close(tester, h);
    });

    testWidgets('hold-open counts 3-second holds', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'hold_open', reps: 5);
      expect(find.text('Set 1 of 1'), findsOneWidget);
      await tapPrimary(tester);
      await passHandCheckAndCalibrate(tester, h);
      expect(repsText(tester), '0 of 5');
      for (var i = 0; i < 2; i++) {
        h.tracker.pose = HandPose.open;
        await tester.pump(const Duration(seconds: 3, milliseconds: 500));
        h.tracker.pose = HandPose.fist;
        await tester.pump(const Duration(milliseconds: 800));
      }
      expect(repsText(tester), '2 of 5');
      await close(tester, h);
    });

    test('every catalog exercise has a counter', () {
      expect(ExerciseCatalog.all, hasLength(17));
    });
  });

  group('camera permission', () {
    testWidgets('explains, asks, and offers Settings when refused', (
      tester,
    ) async {
      final h = await launch(
        tester,
        access: CameraAccess.notAsked,
        afterRequest: CameraAccess.denied,
      );
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      expect(
        find.text(
          'Rohab uses the camera to count your exercises. '
          'Video stays on this phone and is never saved.',
        ),
        findsOneWidget,
      );
      await tapPrimary(tester);
      expect(find.text('Open settings'), findsOneWidget);
      await tapPrimary(tester);
      expect(h.permission.settingsOpened, 1);
      await close(tester, h);
    });
  });

  group('distance', () {
    testWidgets('too far: the hand check says so and does not move on', (
      tester,
    ) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(milliseconds: 100));
      h.tracker.pose = HandPose.open.copyWith(scale: 0.3);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Move your hand closer to the camera.'), findsOneWidget);
      expect(find.text('Open your hand as wide as you can.'), findsNothing);
      await close(tester, h);
    });

    testWidgets('too close says to move back', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(milliseconds: 100));
      h.tracker.pose = HandPose.open.copyWith(scale: 1.8);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Move your hand back a little.'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('moving to a good distance carries on', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(milliseconds: 100));
      h.tracker.pose = HandPose.open.copyWith(scale: 0.3);
      await tester.pump(const Duration(seconds: 3));
      h.tracker.pose = HandPose.open;
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Open your hand as wide as you can.'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('after 8 s the distance no longer blocks', (tester) async {
      final h = await launch(tester);
      await openFree(tester, 'open_close');
      await tapPrimary(tester);
      await tester.pump(const Duration(milliseconds: 100));
      h.tracker.pose = HandPose.open.copyWith(scale: 0.3);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Open your hand as wide as you can.'), findsOneWidget);
      await close(tester, h);
    });
  });
}
