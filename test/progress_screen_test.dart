import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/screens/exercises/exercises_screen.dart';
import 'package:rohab/screens/progress/progress_screen.dart';

import 'helpers.dart';

final now = DateTime(2026, 11, 20, 12);

/// 10 open_close sessions, newest on Nov 20, in degrees of finger bend.
final tenSessions = [
  for (var i = 0; i < 10; i++)
    session(
      reps: 5 + i,
      rangeMin: 10.0 + i,
      rangeMax: 200.0 + i,
      unit: 'deg',
      at: DateTime(2026, 11, 11 + i, 9, 30),
    ),
];

Future<void> openProgress(WidgetTester tester) async {
  await tapTab(tester, 'Progress');
  await settleDb(tester);
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  testWidgets('10 seeded sessions show the summary, charts and list',
      (tester) async {
    final handle = tester.ensureSemantics();
    final db = await seededDb(tester, tenSessions);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openProgress(tester);

    expect(textOf(tester, ProgressScreen.summaryKey),
        // Nov 13 09:30 is outside the 7 days before Nov 20 12:00; Nov 14-20
        // are inside: reps 8 to 14.
        'This week: 7 sessions, ${8 + 9 + 10 + 11 + 12 + 13 + 14} reps.');
    expect(find.byKey(ProgressScreen.repsChartKey), findsOneWidget);
    expect(find.byKey(ProgressScreen.rangeChartKey), findsOneWidget);
    // Charts read out the same numbers as the list.
    final reps = find.bySemanticsLabel(RegExp(r'^Reps per session'));
    expect(reps, findsOneWidget);
    final label = tester.getSemantics(reps).label;
    for (var i = 0; i < 10; i++) {
      expect(label, contains('Nov ${11 + i}: ${5 + i} of 10 reps'));
    }
    final range = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Range per session')));
    expect(range.label, contains('Nov 20: 19°–209°'));
    expect(range.label, contains('Nov 11: 10°–200°'));
    // Newest first: reps 14 of 10 on Nov 20.
    await reveal(tester, ProgressScreen.rowKey(0));
    expect(find.text('Nov 20, 09:30'), findsOneWidget);
    expect(find.text('14 of 10 reps'), findsOneWidget);
    expect(find.text('Range 19°–209°'), findsOneWidget);
    expect(find.byKey(ProgressScreen.emptyKey), findsNothing);
    for (var i = 0; i < 10; i++) {
      await reveal(tester, ProgressScreen.rowKey(i));
      expect(find.byKey(ProgressScreen.rowKey(i)), findsOneWidget);
    }

    handle.dispose();
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('no sessions shows the empty state and a way to Exercises',
      (tester) async {
    final db = await seededDb(tester, const []);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openProgress(tester);
    expect(textOf(tester, ProgressScreen.emptyKey),
        'No sessions yet. Start one from Exercises.');
    expect(textOf(tester, ProgressScreen.summaryKey),
        'This week: 0 sessions, 0 reps.');
    expect(find.byKey(ProgressScreen.repsChartKey), findsNothing);
    final button = find.byKey(ProgressScreen.goToExercisesKey);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(64));
    await tester.tap(button);
    await tester.pump();
    expect(find.byKey(ExercisesScreen.cameraKey), findsOneWidget);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('switching exercise updates the list', (tester) async {
    final db = await seededDb(tester, [
      ...tenSessions,
      session(exercise: 'finger_touches', reps: 4, target: 5,
          rangeMin: 20, rangeMax: 150, unit: 'deg', at: DateTime(2026, 11, 19)),
      session(exercise: 'finger_touches', reps: 5, target: 5,
          rangeMin: 25, rangeMax: 160, unit: 'deg', at: DateTime(2026, 11, 20)),
    ]);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openProgress(tester);
    await reveal(tester, ProgressScreen.rowKey(9));
    expect(find.byKey(ProgressScreen.rowKey(9)), findsOneWidget);
    await reveal(tester, ProgressScreen.segmentKey('finger_touches'));

    await tester.tap(find.byKey(ProgressScreen.segmentKey('finger_touches')));
    await settleDb(tester);
    await reveal(tester, ProgressScreen.rowKey(1));
    expect(find.byKey(ProgressScreen.rowKey(1)), findsOneWidget);
    expect(find.byKey(ProgressScreen.rowKey(2)), findsNothing);
    expect(find.text('5 of 5 rounds'), findsOneWidget);
    expect(find.text('4 of 5 rounds'), findsOneWidget);
    await reveal(tester, ProgressScreen.segmentKey('spread_fingers'));

    // Spread has none: empty state, but the week summary is still shown.
    await tester.tap(find.byKey(ProgressScreen.segmentKey('spread_fingers')));
    await settleDb(tester);
    expect(find.byKey(ProgressScreen.emptyKey), findsOneWidget);
    expect(find.byKey(ProgressScreen.rowKey(0)), findsNothing);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('percent sessions (spread) show % and selector is 64 dp',
      (tester) async {
    final db = await seededDb(tester, [
      session(exercise: 'spread_fingers', reps: 10, rangeMin: 18,
          rangeMax: 94, unit: '%', at: DateTime(2026, 11, 20, 8)),
    ]);
    final glove = await pumpRohabOn(tester, db, now: now);
    await openProgress(tester);
    for (final id in ['open_close', 'finger_touches', 'spread_fingers']) {
      expect(tester.getSize(find.byKey(ProgressScreen.segmentKey(id))).height,
          greaterThanOrEqualTo(64));
    }
    await tester.tap(find.byKey(ProgressScreen.segmentKey('spread_fingers')));
    await settleDb(tester);
    await reveal(tester, ProgressScreen.rowKey(0));
    expect(find.text('Range 18%–94%'), findsOneWidget);
    expect(find.text('10 of 10 reps'), findsOneWidget);
    await finish(tester, glove);
    await closeDb(tester, db);
  });

  testWidgets('text at least 16 and no overflow at 1.5x', (tester) async {
    final db = await seededDb(tester, tenSessions);
    final glove = await pumpRohabOn(tester, db,
        now: now, prefs: {'rohab.settings.textSize.v1': 'largest'});
    await openProgress(tester);
    expect(tester.takeException(), isNull);
    for (final e in find.byType(Text).evaluate()) {
      final w = e.widget as Text;
      final size = DefaultTextStyle.of(e).style.merge(w.style).fontSize;
      if (size != null) expect(size, greaterThanOrEqualTo(16), reason: w.data);
    }
    await finish(tester, glove);
    await closeDb(tester, db);
  });
}
