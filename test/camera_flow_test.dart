import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/camera/camera_permission.dart';
import 'package:rohab/camera/hand_tracker.dart';
import 'package:rohab/camera/mock_hand_tracker.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';
import 'package:rohab/exercises/exercise_catalog.dart';
import 'package:rohab/exercises/exercise_providers.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/screens/exercises/camera_exercise_flow.dart';
import 'package:rohab/screens/exercises/exercises_screen.dart';
import 'package:rohab/widgets/safety_banner.dart';

import 'helpers.dart';

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

  /// One tracker per exercise flow, as in the app.
  final List<MockHandTracker> trackers;
  final AppDatabase db;
  final FakePermission permission;

  /// The current flow's tracker.
  MockHandTracker get tracker => trackers.last;
}

Future<Harness> launch(
  WidgetTester tester, {
  MockHandTracker? tracker,
  CameraAccess access = CameraAccess.granted,
  CameraAccess afterRequest = CameraAccess.granted,
}) async {
  final trackers = <MockHandTracker>[?tracker];
  MockHandTracker create() {
    if (tracker != null) return tracker;
    final previous = trackers.isEmpty ? null : trackers.last;
    final t = MockHandTracker()..pose = previous?.pose ?? HandPose.open;
    trackers.add(t);
    return t;
  }

  // A tracker exists before Start so tests can set its pose.
  if (tracker == null) create();
  var first = true;
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
      closeStreamsSynchronously: true));
  final permission = FakePermission(access, afterRequest: afterRequest);
  final glove = await pumpRohab(tester, overrides: [
    handTrackerFactoryProvider.overrideWithValue(() {
      if (first) {
        first = false;
        return trackers.last;
      }
      return create();
    }),
    cameraPermissionProvider.overrideWithValue(permission),
    exerciseSessionRepositoryProvider
        .overrideWithValue(DriftExerciseSessionRepository(db)),
  ]);
  return Harness(glove, trackers, db, permission);
}

/// Lets a drift write started under the test's fake clock finish: SQLite
/// work needs real time, and its result is delivered on a pump.
Future<void> settleDb(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

Future<void> close(WidgetTester tester, Harness h) async {
  await settleDb(tester);
  await finish(tester, h.glove);
  for (final t in h.trackers) {
    await t.stop();
  }
  await tester.runAsync(h.db.close);
}

Future<void> openExercise(WidgetTester tester, String id) async {
  await tapTab(tester, 'Exercises');
  await tester.tap(find.byKey(ExercisesScreen.cameraKey));
  await tester.pump();
  await tester.tap(find.byKey(CameraExerciseListScreen.rowKey(id)));
  await tester.pump();
}

Future<void> tapPrimary(WidgetTester tester) async {
  await tester.tap(find.byKey(CameraExerciseFlow.primaryKey));
  await tester.pump();
}

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
/// first rep: a rep is open (>= 80 %), closed (<= 20 %), open again.
Future<void> firstOpen(WidgetTester tester, Harness h) async {
  h.tracker.pose = HandPose.open;
  await tester.pump(const Duration(milliseconds: 600));
}

/// [n] reps from an open hand: close 600 ms, open 600 ms.
Future<void> doReps(WidgetTester tester, Harness h, int n) async {
  for (var i = 0; i < n; i++) {
    h.tracker.pose = HandPose.fist;
    await tester.pump(const Duration(milliseconds: 600));
    h.tracker.pose = HandPose.open;
    await tester.pump(const Duration(milliseconds: 600));
  }
}

String repsText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(CameraExerciseFlow.repsKey)).data!;

void main() {
  testWidgets('Exercises shows Camera active and With glove disabled',
      (tester) async {
    final h = await launch(tester);
    await tapTab(tester, 'Exercises');
    expect(find.text("Practice with your phone's camera. No glove needed."),
        findsOneWidget);
    expect(find.text('Available when your glove is connected.'),
        findsOneWidget);
    // The glove row does nothing.
    await tester.tap(find.byKey(ExercisesScreen.gloveKey));
    await tester.pump();
    expect(find.byKey(ExercisesScreen.gloveKey), findsOneWidget);
    await tester.tap(find.byKey(ExercisesScreen.cameraKey));
    await tester.pump();
    for (final e in ExerciseCatalog.all) {
      expect(find.text(e.title), findsOneWidget);
      expect(find.text(e.description), findsOneWidget);
      expect(find.text('${e.targetReps} ${e.repUnit}'), findsWidgets);
      expect(e.steps.length, lessThanOrEqualTo(4));
    }
    await close(tester, h);
  });

  testWidgets('full Open and close exercise saves a session with 10 reps',
      (tester) async {
    final h = await launch(tester);
    await openExercise(tester, 'open_close');
    expect(find.text('1 · 2 · 3'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.byKey(SafetyBanner.stopKey), findsOneWidget);

    await tapPrimary(tester); // Start
    expect(find.text('Hold your hand inside the frame.'), findsOneWidget);
    expect(h.tracker.started, isTrue);
    expect(find.byKey(SafetyBanner.stopKey), findsOneWidget);

    await passHandCheckAndCalibrate(tester, h);
    expect(repsText(tester), '0 of 10');
    expect(find.byKey(SafetyBanner.stopKey), findsOneWidget);

    await firstOpen(tester, h);
    expect(repsText(tester), '0 of 10');
    await doReps(tester, h, 4);
    expect(repsText(tester), '4 of 10');
    await doReps(tester, h, 6);

    expect(find.text('Exercise complete. 10 reps.'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Range of motion: \d+°$')),
        findsOneWidget);
    expect(find.text('Next exercise'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(h.tracker.started, isFalse, reason: 'camera off when done');

    await settleDb(tester);
    final rows = (await tester.runAsync(
        () => DriftExerciseSessionRepository(h.db).all()))!;
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.exerciseId, 'open_close');
    expect(row.mode, 'camera');
    expect(row.reps, 10);
    expect(row.targetReps, 10);
    // Finger bend in degrees: synthetic open hand about 0, fist about 217.
    expect(row.metricUnit, 'deg');
    expect(row.rangeMin, lessThan(30));
    expect(row.rangeMax, greaterThan(180));
    expect(row.avgAmplitude, greaterThan(150));
    expect(row.avgPeakSpeed, greaterThan(0));
    expect(row.avgSmoothness, lessThan(0));
    expect(row.fatigued, isFalse);
    expect(row.durationSec, inInclusiveRange(10, 14));
    await close(tester, h);
  });

  testWidgets('lost hand pauses counting and shows the frame message',
      (tester) async {
    final h = await launch(tester);
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await passHandCheckAndCalibrate(tester, h);
    await firstOpen(tester, h);
    await doReps(tester, h, 2);
    expect(repsText(tester), '2 of 10');

    // Close (half a rep), then the hand leaves for 3 s.
    h.tracker.pose = HandPose.fist;
    await tester.pump(const Duration(milliseconds: 600));
    h.tracker.pose = null;
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold your hand inside the frame.'), findsOneWidget);

    // Coming back open must not complete the half rep.
    h.tracker.pose = HandPose.open;
    await tester.pump(const Duration(milliseconds: 600));
    expect(repsText(tester), '2 of 10');
    expect(find.text('Hold your hand inside the frame.'), findsNothing);
    h.tracker.pose = HandPose.fist;
    await tester.pump(const Duration(milliseconds: 600));
    h.tracker.pose = HandPose.open;
    await tester.pump(const Duration(milliseconds: 600));
    expect(repsText(tester), '3 of 10');
    await close(tester, h);
  });

  testWidgets('range is calibrated once per session', (tester) async {
    final h = await launch(tester);
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await passHandCheckAndCalibrate(tester, h);
    await firstOpen(tester, h);
    await doReps(tester, h, 10);
    expect(find.text('Next exercise'), findsOneWidget);

    await tapPrimary(tester); // Next exercise: Finger touches
    expect(find.text('Finger touches'), findsWidgets);
    await tapPrimary(tester); // Start
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Open your hand as wide as you can.'), findsNothing);
    expect(repsText(tester), '0 of 8');
    await close(tester, h);
  });

  testWidgets('shrinking movements suggest a rest and are saved as fatigued',
      (tester) async {
    final h = await launch(tester);
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await passHandCheckAndCalibrate(tester, h);
    await firstOpen(tester, h);
    await doReps(tester, h, 5); // full fist to full open
    expect(repsText(tester), '5 of 10');
    // Tired: only half closing, too small to count.
    for (var i = 0; i < 5; i++) {
      h.tracker.pose = const HandPose(curl: 0.45);
      await tester.pump(const Duration(milliseconds: 600));
      h.tracker.pose = HandPose.open;
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(repsText(tester), '5 of 10');
    expect(find.text('Movements are getting smaller. A rest may help.'),
        findsOneWidget);
    await tester.tap(find.text('End exercise'));
    await tester.pump();
    expect(find.text('Exercise ended. 5 reps.'), findsOneWidget);
    expect(find.textContaining('Your later movements were smaller.'),
        findsOneWidget);
    await settleDb(tester);
    final rows = (await tester.runAsync(
        () => DriftExerciseSessionRepository(h.db).all()))!;
    expect(rows.single.fatigued, isTrue);
    expect(rows.single.reps, 5);
    await close(tester, h);
  });

  testWidgets('End exercise early with no reps saves nothing',
      (tester) async {
    final h = await launch(tester);
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await passHandCheckAndCalibrate(tester, h);
    await tester.tap(find.text('End exercise'));
    await tester.pump();
    expect(find.text('Exercise ended. 0 reps.'), findsOneWidget);
    expect(find.text('Nothing was saved.'), findsOneWidget);
    await settleDb(tester);
    final rows = (await tester.runAsync(
        () => DriftExerciseSessionRepository(h.db).all()))!;
    expect(rows, isEmpty);
    await close(tester, h);
  });

  testWidgets('low-confidence frames are ignored', (tester) async {
    final h = await launch(tester,
        tracker: MockHandTracker(lowConfidenceEvery: 1));
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold your hand inside the frame.'), findsOneWidget);
    expect(HandFrame.minConfidence, 0.6);
    await close(tester, h);
  });

  testWidgets(
      'scripted cycles with noise, low-confidence frames and a dropout '
      'reach the target', (tester) async {
    final tracker = MockHandTracker(
      script: MockHandTracker.cycles(
        dropoutStart: const Duration(seconds: 14),
        dropoutLength: const Duration(seconds: 3),
      ),
      noise: 0.003,
      lowConfidenceEvery: 7,
    );
    final h = await launch(tester, tracker: tracker);
    await openExercise(tester, 'open_close');
    await tapPrimary(tester);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('Exercise complete. 10 reps.'), findsOneWidget);
    await close(tester, h);
  });

  group('camera permission', () {
    testWidgets('explains, asks, and offers Settings when refused',
        (tester) async {
      final h = await launch(tester,
          access: CameraAccess.notAsked, afterRequest: CameraAccess.denied);
      await openExercise(tester, 'open_close');
      await tapPrimary(tester); // Start
      expect(
          find.text('Rohab uses the camera to count your exercises. '
              'Video stays on this phone and is never saved.'),
          findsOneWidget);
      await tapPrimary(tester); // Allow camera
      expect(find.text('Open settings'), findsOneWidget);
      expect(h.tracker.started, isFalse);
      await tapPrimary(tester);
      expect(h.permission.settingsOpened, 1);
      await close(tester, h);
    });

    testWidgets('granted after asking starts the camera', (tester) async {
      final h = await launch(tester, access: CameraAccess.notAsked);
      await openExercise(tester, 'open_close');
      await tapPrimary(tester);
      await tapPrimary(tester); // Allow camera
      expect(h.tracker.started, isTrue);
      expect(find.text('Hold your hand inside the frame.'), findsOneWidget);
      await close(tester, h);
    });
  });
}
