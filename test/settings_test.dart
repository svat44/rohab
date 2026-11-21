import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/config/app_info.dart';
import 'package:rohab/data/exercise_session_repository.dart';
import 'package:rohab/screens/exercises/exercises_screen.dart';
import 'package:rohab/screens/progress/progress_screen.dart';
import 'package:rohab/screens/settings/settings_screen.dart';
import 'package:rohab/settings/settings_controller.dart';
import 'package:rohab/widgets/app_shell.dart';

import 'helpers.dart';

final now = DateTime(2026, 11, 20, 12);
const prefKey = 'rohab.settings.textSize.v1';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(AppShell.settingsButtonKey));
  await tester.pump();
}

double scaleOf(WidgetTester tester) => MediaQuery.textScalerOf(
        tester.element(find.byKey(AppShell.wordmarkKey)))
    .scale(1);

Future<int> rowCount(WidgetTester tester, db) async =>
    (await tester.runAsync(() => DriftExerciseSessionRepository(db).all()))!
        .length;

void main() {
  testWidgets('text size applies app-wide and survives a restart',
      (tester) async {
    final db = await seededDb(tester, const []);
    var glove = await pumpRohabOn(tester, db, now: now);
    expect(scaleOf(tester), 1.0);
    await openSettings(tester);
    for (final (size, scale) in [
      (TextSize.large, 1.25),
      (TextSize.largest, 1.5),
      (TextSize.normal, 1.0),
      (TextSize.largest, 1.5),
    ]) {
      await reveal(tester, SettingsScreen.textSizeKey(size));
      await tester.tap(find.byKey(SettingsScreen.textSizeKey(size)));
      await tester.pump();
      expect(scaleOf(tester), scale, reason: size.label);
    }
    final stored = (await SharedPreferences.getInstance()).getString(prefKey);
    expect(stored, 'largest');
    await finish(tester, glove);

    // Restart: a new app on the same stored preferences.
    glove = await pumpRohabOn(tester, db, now: now, prefs: {prefKey: stored!});
    expect(scaleOf(tester), 1.5);
    await openSettings(tester);
    final button = tester.widget<Material>(find.descendant(
        of: find.byKey(SettingsScreen.textSizeKey(TextSize.largest)),
        matching: find.byType(Material)).first);
    expect(button, isNotNull);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('an unknown stored size falls back to Normal', (tester) async {
    final db = await seededDb(tester, const []);
    final glove =
        await pumpRohabOn(tester, db, now: now, prefs: {prefKey: 'huge'});
    expect(scaleOf(tester), 1.0);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('clear all data: Cancel keeps sessions, Delete removes them',
      (tester) async {
    final db = await seededDb(tester, [
      session(at: DateTime(2026, 11, 18)),
      session(exercise: 'spread_fingers', at: DateTime(2026, 11, 19)),
      session(exercise: 'finger_touches', at: DateTime(2026, 11, 20)),
    ]);
    final glove = await pumpRohabOn(tester, db, now: now, prefs: {prefKey: 'large'});
    await openSettings(tester);
    expect(await rowCount(tester, db), 3);

    Future<void> tapKey(Key k) async {
      await reveal(tester, k);
      await tester.tap(find.byKey(k));
      await tester.pump();
    }

    expect(find.byKey(SettingsScreen.confirmDeleteKey), findsNothing);
    await tapKey(SettingsScreen.clearKey);
    expect(find.text('Delete all saved sessions? This cannot be undone.'),
        findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tapKey(SettingsScreen.cancelDeleteKey);
    await settleDb(tester);
    expect(await rowCount(tester, db), 3, reason: 'Cancel does nothing');
    expect(find.byKey(SettingsScreen.confirmDeleteKey), findsNothing);
    expect(find.byKey(SettingsScreen.clearedKey), findsNothing);

    await tapKey(SettingsScreen.clearKey);
    await tapKey(SettingsScreen.confirmDeleteKey);
    await settleDb(tester);
    expect(await rowCount(tester, db), 0);
    expect(find.byKey(SettingsScreen.clearedKey), findsOneWidget);
    // The text size setting is not touched.
    expect(scaleOf(tester), 1.25);

    // Progress now shows its empty state.
    await tester.tap(find.byKey(AppShell.closeSettingsKey));
    await tester.pump();
    await tapTab(tester, 'Progress');
    await settleDb(tester);
    expect(find.byKey(ProgressScreen.emptyKey), findsOneWidget);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('the delete confirmation does not cover STOP', (tester) async {
    final db = await seededDb(tester, const []);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openSettings(tester);
    await reveal(tester, SettingsScreen.clearKey);
    await tester.tap(find.byKey(SettingsScreen.clearKey));
    await tester.pump();
    expect(find.text('STOP'), findsOneWidget);
    final stop = tester.getCenter(find.text('STOP'));
    final hit = tester.hitTestOnBinding(stop);
    expect(hit.path.any((e) => e.target.runtimeType.toString().contains('Render')),
        isTrue);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('About shows the version and the plain line', (tester) async {
    final db = await seededDb(tester, const []);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openSettings(tester);
    await reveal(tester, SettingsScreen.aboutKey);
    expect(find.text('Rohab version $kAppVersion'), findsOneWidget);
    expect(
        find.text('Rohab is not a medical device. Ask your therapist before '
            'changing your exercises.'),
        findsOneWidget);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: ([\d.]+)', multiLine: true)
        .firstMatch(pubspec)!.group(1), kAppVersion);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('no overflow at 1.5x on every tab and the therapist screen',
      (tester) async {
    final db = await seededDb(tester, [
      for (var i = 0; i < 10; i++)
        session(reps: 5 + i, unit: 'deg', rangeMin: 12, rangeMax: 230,
            at: DateTime(2026, 11, 11 + i, 9)),
    ]);
    final glove =
        await pumpRohabOn(tester, db, now: now, prefs: {prefKey: 'largest'});
    expect(scaleOf(tester), 1.5);
    Future<void> check(String where) async {
      await settleDb(tester);
      expect(tester.takeException(), isNull, reason: where);
    }

    await check('Home');
    await tester.tap(find.byKey(const Key('home-primary')));
    await tester.pump(const Duration(milliseconds: 800));
    await check('Home connected');
    for (final tab in ['Calibrate', 'Exercises', 'Progress']) {
      await tapTab(tester, tab);
      await check(tab);
    }
    await tapTab(tester, 'Exercises');
    await tester.tap(find.byKey(ExercisesScreen.cameraKey));
    await check('Plan (not measured yet)');
    await openSettings(tester);
    await check('Settings');
    await reveal(tester, SettingsScreen.clearKey);
    await tester.tap(find.byKey(SettingsScreen.clearKey));
    await tester.pump();
    await check('Settings with confirmation');
    await reveal(tester, SettingsScreen.therapistKey);
    await tester.tap(find.byKey(SettingsScreen.therapistKey));
    await check('Therapist PIN');
    await finish(tester, glove);
    await closeDb(tester, db);
  });
}
