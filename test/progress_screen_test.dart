import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/program/date_range.dart';
import 'package:rohab/screens/progress/progress_screen.dart';

import 'helpers.dart';

final now = DateTime(2026, 11, 20, 12);

/// One 10-rep session every 5 days for 100 days, newest on Nov 20.
final seeded = [
  for (var d = 0; d < 100; d += 5)
    session(
      exercise: 'open_close_gentle',
      reps: 10,
      at: DateTime(2026, 11, 20 - d, 9, 30),
    ),
];

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  testWidgets('the range buttons change every number', (tester) async {
    final db = await seededDb(tester, seeded);
    final glove = await pumpRohabOn(tester, db, now: now);
    await tapTab(tester, 'Progress');
    await settleDb(tester);

    expect(textOf(tester, ProgressScreen.heroLabelKey), 'Reps, last 7 days');
    final week = int.parse(textOf(tester, ProgressScreen.heroNumberKey));
    final weekSentence = textOf(tester, ProgressScreen.summaryKey);

    await tester.tap(find.byKey(ProgressScreen.rangeKey(RangeDays.quarter)));
    await settleDb(tester);
    expect(textOf(tester, ProgressScreen.heroLabelKey), 'Reps, last 90 days');
    final quarter = int.parse(textOf(tester, ProgressScreen.heroNumberKey));
    expect(quarter, greaterThan(week));
    expect(textOf(tester, ProgressScreen.summaryKey), isNot(weekSentence));

    await tester.tap(find.byKey(ProgressScreen.rangeKey(RangeDays.month)));
    await settleDb(tester);
    final month = int.parse(textOf(tester, ProgressScreen.heroNumberKey));
    expect(month, inInclusiveRange(week, quarter));
    await finish(tester, glove);
  });

  testWidgets(
    'no sessions: designed empty state, footer says not a medical device',
    (tester) async {
      final glove = await pumpRohab(tester, clock: () => now);
      await tapTab(tester, 'Progress');
      await settleDb(tester);
      expect(find.byKey(ProgressScreen.emptyKey), findsOneWidget);
      expect(find.text('No sessions yet.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(ProgressScreen.footerKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Research prototype. Not a medical device.'),
        findsOneWidget,
      );
      await finish(tester, glove);
    },
  );
}
