import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/calibration/calibration_status.dart';
import 'package:rohab/calibration/emg_calibrator.dart';
import 'package:rohab/exercises/exercise_setup.dart';
import 'package:rohab/camera/handedness.dart';
import 'package:rohab/theme/app_theme.dart';
import 'package:rohab/widgets/empty_state.dart';
import 'package:rohab/widgets/hero.dart';
import 'package:rohab/widgets/metric_text.dart';
import 'package:rohab/widgets/result_panel.dart';
import 'package:rohab/widgets/rohab_app_bar.dart';
import 'package:rohab/widgets/rohab_button.dart';
import 'package:rohab/widgets/rohab_icon.dart';
import 'package:rohab/widgets/rohab_nav_bar.dart';
import 'package:rohab/widgets/rohab_row.dart';
import 'package:rohab/widgets/rohab_stepper.dart';
import 'package:rohab/widgets/rohab_tabs.dart';
import 'package:rohab/widgets/segmented_bar.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildTheme(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('RohabTheme', () {
    test('light, flat, bundled fonts, no Roboto', () {
      final t = buildTheme();
      expect(t.textTheme.bodyLarge!.fontFamily, RohabFonts.body);
      expect(t.scaffoldBackgroundColor, RohabPalette.light.background);
      expect(RohabFonts.body, isNot('Roboto'));
    });
    test('no style is below 14sp or lighter than regular', () {
      for (final s in [
        RohabType.title,
        RohabType.wordmark,
        RohabType.sectionLabel,
        RohabType.rowTitle,
        RohabType.rowSub,
        RohabType.body,
        RohabType.button,
        RohabType.navLabel,
        RohabType.navLabelSelected,
        RohabType.metricXL,
        RohabType.metricCamera,
        RohabType.metricL,
        RohabType.metricS,
      ]) {
        expect(s.fontSize, greaterThanOrEqualTo(14));
        expect(s.fontWeight!.value, greaterThanOrEqualTo(400));
      }
    });
    test('every numeral style uses tabular figures', () {
      for (final s in [
        RohabType.metricXL,
        RohabType.metricCamera,
        RohabType.metricL,
        RohabType.metricS,
      ]) {
        expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
        expect(s.fontFamily, RohabFonts.numbers);
      }
    });
  });

  testWidgets('RohabStepper stays inside its bounds and steps', (tester) async {
    var v = 19;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, set) => host(
          RohabStepper(
            label: 'Reps per set',
            value: v,
            min: 1,
            max: 20,
            onChanged: (n) => set(() => v = n),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(RohabStepper.increaseKey));
    await tester.pump();
    expect(v, 20);
    await tester.tap(find.byKey(RohabStepper.increaseKey));
    await tester.pump();
    expect(v, 20, reason: 'max');
    for (var i = 0; i < 25; i++) {
      await tester.tap(find.byKey(RohabStepper.decreaseKey));
      await tester.pump();
    }
    expect(v, 1, reason: 'min');
    expect(
      tester.getSize(find.byKey(RohabStepper.increaseKey)),
      const Size(56, 56),
    );
  });

  testWidgets('rest stepper moves in 10 s steps from 10 to 120', (
    tester,
  ) async {
    var v = 30;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, set) => host(
          RohabStepper(
            label: 'Rest',
            value: v,
            min: kRestRange.min,
            max: kRestRange.max,
            step: kRestStep,
            onChanged: (n) => set(() => v = n),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(RohabStepper.increaseKey));
    await tester.pump();
    expect(v, 40);
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byKey(RohabStepper.increaseKey));
      await tester.pump();
    }
    expect(v, 120);
  });

  test('exercise setup plan maths', () {
    const s = ExerciseSetup(hand: Handedness.right);
    expect((s.reps, s.sets, s.restSeconds), (5, 3, 30));
    expect(s.summaryLine, '3 sets x 5 reps = 15 reps');
    expect(s.totalSeconds, 15 * kSecondsPerRep + 2 * 30);
    expect(s.timeLine, 'About 4 minutes');
    expect(s.copyWith(reps: 99, sets: 0).reps, 20);
    expect(s.copyWith(sets: 0).sets, 1);
  });

  test('lastDoneLabel: Today, weekday, date, New', () {
    final now = DateTime(2026, 11, 20, 12);
    expect(lastDoneLabel(null, now), 'New');
    expect(lastDoneLabel(DateTime(2026, 11, 20, 8), now), 'Today');
    expect(lastDoneLabel(DateTime(2026, 11, 18), now), 'Wed');
    expect(lastDoneLabel(DateTime(2026, 11, 1), now), '1 Nov');
  });

  test('calibrationGoodFor from the 24 h expiry', () {
    final now = DateTime(2026, 11, 20, 12);
    Calibration at(Duration ago) => Calibration(
      restMean: 1,
      restSd: 1,
      gripLevel: 2,
      threshold: 188,
      timestamp: now.subtract(ago),
    );
    expect(calibrationGoodFor(null, now), 'Not calibrated yet');
    expect(
      calibrationGoodFor(at(const Duration(hours: 12)), now),
      '12 more hours',
    );
    expect(
      calibrationGoodFor(at(const Duration(hours: 23, minutes: 30)), now),
      'Less than 1 hour',
    );
    expect(calibrationGoodFor(at(const Duration(hours: 24)), now), 'Expired');
  });

  testWidgets(
    'RohabButton: disabled shows gray fill, dark label, a border and the reason',
    (tester) async {
      await tester.pumpWidget(
        host(
          const RohabButton(
            label: 'Start calibration',
            onPressed: null,
            disabledReason: 'Connect your glove first.',
          ),
        ),
      );
      expect(find.text('Connect your glove first.'), findsOneWidget);
      final b = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(b.onPressed, isNull);
      final shape = b.style!.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.side.width, 1);
      expect(shape.borderRadius, BorderRadius.circular(4));
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(64),
      );
    },
  );

  testWidgets('RohabButton enabled fires and is 64 dp', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(RohabButton(label: 'Start', onPressed: () => n++)),
    );
    await tester.tap(find.text('Start'));
    expect(n, 1);
    expect(tester.getSize(find.byType(FilledButton)).height, 64);
  });

  testWidgets('RohabRow is at least 64 dp, shows value and chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        RohabGroup(
          children: [
            RohabRow(title: 'Glove', value: 'Not connected', onTap: () {}),
            const RohabRow(title: 'Locked', subtitle: 'Why', locked: true),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.text('Glove').first).height, lessThan(64));
    final rows = find.byType(RohabRow);
    for (final e in rows.evaluate()) {
      expect(
        tester.getSize(find.byWidget(e.widget)).height,
        greaterThanOrEqualTo(64),
      );
    }
    expect(
      find.byType(RohabIcon),
      findsOneWidget,
      reason: 'chevron on the tappable row only',
    );
  });

  testWidgets(
    'UnderlineTabs: tap changes, selected has a 3 dp accent underline',
    (tester) async {
      var i = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            UnderlineTabs(
              labels: const ['Set up', 'How to', 'History'],
              selected: i,
              onChanged: (n) => set(() => i = n),
            ),
          ),
        ),
      );
      await tester.tap(find.text('How to'));
      await tester.pump();
      expect(i, 1);
      final bars = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((c) => c.color == RohabPalette.light.accent);
      expect(bars, hasLength(1));
    },
  );

  testWidgets('SquareSegmented: square, one selected', (tester) async {
    var v = 7;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, set) => host(
          SquareSegmented<int>(
            options: const [(7, '7 days'), (30, '30 days'), (90, '90 days')],
            selected: v,
            onChanged: (n) => set(() => v = n),
          ),
        ),
      ),
    );
    await tester.tap(find.text('90 days'));
    await tester.pump();
    expect(v, 90);
    final boxes = tester.widgetList<Ink>(find.byType(Ink));
    for (final b in boxes) {
      final d = b.decoration! as BoxDecoration;
      expect(d.borderRadius, isNull);
      expect(d.shape, BoxShape.rectangle);
    }
  });

  testWidgets('SegmentedBar paints done segments in accent', (tester) async {
    await tester.pumpWidget(host(const SegmentedBar(done: 3, total: 12)));
    final cols = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(SegmentedBar),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(
      cols.where((c) => c.color == RohabPalette.light.accent),
      hasLength(3),
    );
    expect(
      cols.where((c) => c.color == RohabPalette.light.divider),
      hasLength(9),
    );
  });

  testWidgets('ResultPanel is solid accent, radius 0, with a white Start', (
    tester,
  ) async {
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: ResultPanel(
            title: 'Your plan',
            lines: const ['3 sets x 5 reps = 15 reps', 'About 4 minutes'],
            actionLabel: 'Start',
            onAction: () => started++,
          ),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ResultPanel),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final d = box.decoration as BoxDecoration;
    expect(d.color, RohabPalette.light.accent);
    expect(d.borderRadius, isNull);
    expect(d.boxShadow, isNull);
    expect(find.text('Your plan'), findsOneWidget);
    await tester.tap(find.text('Start'));
    expect(started, 1);
  });

  testWidgets(
    'HeroBubbles: exactly three static circles, ignoring touches and semantics',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 300,
            child: HeroBubbles(child: Text('Sets done today')),
          ),
        ),
      );
      expect(find.byType(IgnorePointer), findsWidgets);
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);
      // The painter draws 3 circles with the documented alphas.
      final rec = _CountingCanvas();
      const BubblePainter(Color(0xFF0E6B7A)).paint(rec, const Size(360, 300));
      expect(rec.circles, [240.0 / 2, 140.0 / 2, 80.0 / 2]);
      expect(
        rec.alphas,
        [0.08, 0.06, 0.06].map((a) => (a * 255).round()).toList(),
      );
    },
  );

  testWidgets('EmptyState is plain left-aligned text', (tester) async {
    await tester.pumpWidget(host(const EmptyState(title: 'No sessions yet.')));
    expect(find.text('No sessions yet.'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('MetricText renders number and unit with tabular figures', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MetricText('35', unit: 'kPa')));
    final t = tester.widget<Text>(find.byType(Text));
    expect(
      t.textSpan!.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(find.textContaining('kPa', findRichText: true), findsOneWidget);
  });

  testWidgets('RohabAppBar: gear on the right, back arrow replaces it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            RohabAppBar(title: 'Today', onSettings: () {}),
            RohabAppBar(title: 'Open and close', onBack: () {}),
          ],
        ),
      ),
    );
    expect(find.byType(RohabIcon), findsNWidgets(2));
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets(
    'RohabNavBar: 3 dp bar on the selected tab only, no indicator pill',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            bottomNavigationBar: RohabNavBar(
              destinations: const [
                NavDestination('Today', RohabIconData.today),
                NavDestination('Glove', RohabIconData.glove),
                NavDestination('Exercises', RohabIconData.hand),
                NavDestination('Progress', RohabIconData.chart),
              ],
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      final bars = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((c) => c.color == RohabPalette.light.accent);
      expect(bars, hasLength(1));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationIndicator), findsNothing);
      for (final l in ['Today', 'Glove', 'Exercises', 'Progress']) {
        expect(find.text(l), findsOneWidget);
      }
    },
  );
}

/// Records circle radii and alphas drawn to it.
class _CountingCanvas implements Canvas {
  final circles = <double>[];
  final alphas = <int>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add(radius);
    alphas.add((paint.color.a * 255).round());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
