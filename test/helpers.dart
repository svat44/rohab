import 'dart:math';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/app/app.dart';
import 'package:rohab/app/providers.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';
import 'package:rohab/exercises/exercise_providers.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/screens/home_screen.dart';
import 'package:rohab/widgets/bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Launches the full app on a 390 x 844 phone with a seeded mock glove.
Future<MockGloveService> pumpRohab(
  WidgetTester tester, {
  MockGloveService? glove,
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final g = glove ?? MockGloveService(random: Random(7));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gloveServiceProvider.overrideWithValue(g),
      sharedPreferencesProvider.overrideWithValue(sp),
      if (clock != null) clockProvider.overrideWithValue(clock),
      ...overrides,
    ],
    child: const RohabApp(),
  ));
  await tester.pump();
  return g;
}

/// Unmounts the app and stops the mock's timers.
Future<void> finish(WidgetTester tester, MockGloveService glove) async {
  await tester.pumpWidget(const SizedBox());
  glove.dispose();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byType(BottomNav), matching: find.text(label)));
  await tester.pump();
}

Future<void> connectFromHome(WidgetTester tester) async {
  await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
  await tester.pump(MockGloveService.connectDelay);
}

/// One saved session, for seeding.
ExerciseSessionRecord session({
  String exercise = 'open_close',
  int reps = 10,
  int target = 10,
  double? rangeMin = 18,
  double? rangeMax = 94,
  String unit = '%',
  required DateTime at,
}) =>
    ExerciseSessionRecord(
      exerciseId: exercise,
      mode: 'camera',
      reps: reps,
      targetReps: target,
      rangeMin: rangeMin,
      rangeMax: rangeMax,
      durationSec: 40,
      startedAt: at,
      metricUnit: unit,
    );

/// An in-memory database with [seed] saved, for tests that read sessions.
Future<AppDatabase> seededDb(
    WidgetTester tester, List<ExerciseSessionRecord> seed) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
      closeStreamsSynchronously: true));
  await tester.runAsync(() async {
    final repo = DriftExerciseSessionRepository(db);
    for (final r in seed) {
      await repo.save(r);
    }
  });
  return db;
}

/// Lets drift work started under the test's fake clock finish.
Future<void> settleDb(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

/// Launches the app on [db] with a fixed clock.
Future<MockGloveService> pumpRohabOn(
  WidgetTester tester,
  AppDatabase db, {
  required DateTime now,
  Map<String, Object> prefs = const {},
}) =>
    pumpRohab(tester,
        prefs: prefs,
        clock: () => now,
        overrides: [appDatabaseProvider.overrideWithValue(db)]);

Future<void> closeDb(WidgetTester tester, AppDatabase db) async {
  await settleDb(tester);
  await tester.runAsync(db.close);
}

/// Scrolls the visible list until [key] is built and on screen.
Future<void> reveal(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  if (target.evaluate().isEmpty) {
    final list = find.byType(Scrollable).hitTestable().first;
    // Back to the top first: the target may be above the current spot.
    await tester.drag(list, const Offset(0, 5000));
    await tester.pump();
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 200, scrollable: list);
    }
  }
  await tester.ensureVisible(target);
  await tester.pump();
}
