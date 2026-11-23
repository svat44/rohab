import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/config/pressure_limits.dart';
import 'package:rohab/glove/glove_service.dart';
import 'package:rohab/screens/settings/settings_screen.dart';
import 'package:rohab/widgets/bottom_nav.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/screens/calibration/calibration_screen.dart';
import 'package:rohab/screens/calibration/step_layout.dart';
import 'package:rohab/screens/home_screen.dart';
import 'package:rohab/widgets/app_shell.dart';
import 'package:rohab/widgets/safety_banner.dart';

import 'helpers.dart';

/// How to reach each screen from Home.
final screens = <String, Future<void> Function(WidgetTester)>{
  'Home': (t) async {},
  'Glove': (t) => tapTab(t, 'Glove'),
  'Exercises': (t) => tapTab(t, 'Exercises'),
  'Progress': (t) => tapTab(t, 'Progress'),
  'Settings': (t) async {
    await t.tap(find.byKey(AppShell.settingsButtonKey));
    await t.pump();
  },
};

Future<void> _connectAndInflate(WidgetTester tester) async {
  await connectFromHome(tester);
  await tapHomePrimary(tester); // Start
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Home: start raises live pressure shown on screen',
      (tester) async {
    final glove = await pumpRohab(tester);
    // Camera-only use: no glove, so no glove banner.
    expect(find.text('Glove not connected'), findsNothing);
    expect(find.text('Rohab'), findsOneWidget);

    await _connectAndInflate(tester);
    final shown = double.parse(
        tester.widget<Text>(find.byKey(HomeScreen.pressureKey)).data!);
    expect(shown, greaterThan(10));
    expect(shown, lessThanOrEqualTo(kHardLimitKpa));
    expect(find.text('End session'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // 1 rep
    await tapHomePrimary(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('Session complete.'), findsOneWidget);
    await finish(tester, glove);
  });

  testWidgets('Home: reps first, patient state labels, summary only after',
      (tester) async {
    final glove = await pumpRohab(tester);
    String text(Key k) => tester.widget<Text>(find.byKey(k)).data!;
    expect(find.text('Mode'), findsNothing);
    expect(find.text('Disconnect'), findsNothing);

    await connectFromHome(tester);
    expect(text(HomeScreen.stateKey), 'Ready');
    expect(find.byKey(HomeScreen.summaryKey), findsNothing);
    expect(text(HomeScreen.repsKey), '–');

    await tapHomePrimary(tester); // Start
    await tester.pump(const Duration(milliseconds: 500));
    expect(text(HomeScreen.stateKey), 'Closing hand');
    await tester.pump(const Duration(seconds: 2));
    expect(text(HomeScreen.stateKey), 'Holding');
    expect(find.text('Holding'), findsWidgets); // banner says it too
    await tester.pump(const Duration(seconds: 2));
    expect(text(HomeScreen.stateKey), 'Opening hand');
    await tester.pump(const Duration(seconds: 1, milliseconds: 500));
    expect(text(HomeScreen.repsKey), '1');
    for (final raw in ['Idle', 'Inflating', 'Venting']) {
      expect(find.text(raw), findsNothing, reason: 'internal name');
    }

    // Reps is the largest number on Home; pressure is a smaller detail.
    final repsSize = tester.widget<Text>(find.byKey(HomeScreen.repsKey))
        .style!.fontSize!;
    final pressureSize = tester
        .widget<Text>(find.byKey(HomeScreen.pressureKey)).style!.fontSize!;
    expect(repsSize, greaterThan(pressureSize));

    await tapHomePrimary(tester); // End
    await tester.pump(const Duration(seconds: 3));
    expect(text(HomeScreen.summaryKey), 'Session complete. 1 rep.');
    expect(text(HomeScreen.stateKey), 'Ready');

    await tapHomePrimary(tester); // Start again
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(HomeScreen.summaryKey), findsNothing);
    expect(text(HomeScreen.repsKey), '0');
    await finish(tester, glove);
  });

  testWidgets('Disconnect lives in Settings, only when no session runs',
      (tester) async {
    final glove = await pumpRohab(tester);
    await connectFromHome(tester);
    await tester.tap(find.byKey(AppShell.settingsButtonKey));
    await tester.pump();
    expect(find.byKey(SettingsScreen.disconnectKey), findsOneWidget);
    await tester.tap(find.byKey(SettingsScreen.disconnectKey));
    await tester.pump();
    expect(glove.snapshot.value.isConnected, isFalse);
    expect(find.text('Not connected. Connect on Home.'), findsOneWidget);
    await finish(tester, glove);
  });

  testWidgets('banner text is at least 16 and STOP is the largest control',
      (tester) async {
    final glove = await pumpRohab(tester);
    await connectFromHome(tester);
    final banner = find.byType(SafetyBanner);
    for (final e in find.descendant(of: banner, matching: find.byType(Text))
        .evaluate()) {
      final size = DefaultTextStyle.of(e).style
          .merge((e.widget as Text).style).fontSize ?? 14;
      expect(size, greaterThanOrEqualTo(16), reason: (e.widget as Text).data);
    }
    final stop = tester.getSize(find.byKey(SafetyBanner.stopKey));
    expect(stop.height, greaterThanOrEqualTo(80));
    for (final e in find.descendant(of: banner, matching: find.byType(Icon))
        .evaluate()) {
      final r = tester.getSize(find.byWidget(e.widget));
      expect(r.height, lessThan(stop.height));
    }
    // Bottom nav labels too.
    for (final label in ['Home', 'Glove', 'Exercises', 'Progress']) {
      final e = find.descendant(
              of: find.byType(BottomNav), matching: find.text(label))
          .evaluate()
          .single;
      final size = DefaultTextStyle.of(e).style
          .merge((e.widget as Text).style).fontSize!;
      expect(size, greaterThanOrEqualTo(16), reason: label);
    }
    await finish(tester, glove);
  });

  for (final entry in screens.entries) {
    testWidgets('STOP vents to zero from ${entry.key} while inflating',
        (tester) async {
      final glove = await pumpRohab(tester);
      await _connectAndInflate(tester);
      await entry.value(tester);
      expect(find.text(entry.key), findsWidgets);
      expect(glove.snapshot.value.pressureKpa, greaterThan(10));

      final stop = find.byKey(SafetyBanner.stopKey);
      expect(stop, findsOneWidget);
      expect(tester.getSize(stop).height, greaterThanOrEqualTo(80));

      await tester.tap(stop);
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      expect(glove.snapshot.value.sessionActive, isFalse);

      await tester.pump(const Duration(seconds: 5));
      expect(glove.snapshot.value.pressureKpa, 0);
      await finish(tester, glove);
    });
  }

  for (final entry in screens.entries) {
    testWidgets('STOP is safe from ${entry.key} in every state',
        (tester) async {
      final glove = await pumpRohab(tester);
      await entry.value(tester);
      final stop = find.byKey(SafetyBanner.stopKey);

      // STOP appears with the glove, not before.
      expect(stop, findsNothing);
      glove.connect();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(stop); // connecting
      await tester.pump(MockGloveService.connectDelay);
      expect(glove.snapshot.value.isConnected, isTrue);
      await tester.tap(stop); // idle
      await tester.pump();
      glove.start();
      await tester.pump(const Duration(seconds: 3, milliseconds: 200));
      expect(glove.snapshot.value.state, GloveState.holding);
      await tester.tap(stop); // holding
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      glove.start();
      await tester.pump(const Duration(seconds: 2));
      glove.stop();
      await tester.pump(const Duration(milliseconds: 100));
      expect(glove.snapshot.value.state, GloveState.venting);
      await tester.tap(stop); // normal venting
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      glove.start();
      await tester.pump(const Duration(seconds: 2));
      glove.simulateFault(GloveFault.overpressure);
      await tester.pump();
      expect(find.text('Glove vented'), findsOneWidget);
      await tester.tap(stop); // after a fault
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);

      expect(tester.takeException(), isNull);
      await finish(tester, glove);
    });
  }

  testWidgets('STOP banner stays on every calibration step', (tester) async {
    final glove = await pumpRohab(tester);
    await connectFromHome(tester);
    await tapTab(tester, 'Glove');
    await tester.tap(find.byKey(CalibrationScreen.startKey));
    await tester.pump();
    final stop = find.byKey(SafetyBanner.stopKey);
    expect(stop, findsOneWidget); // prepare
    await tester.tap(find.byKey(StepLayout.primaryKey));
    await tester.pump(const Duration(seconds: 1));
    expect(stop, findsOneWidget); // rest
    await tester.pump(const Duration(seconds: 5));
    expect(stop, findsOneWidget); // grip
    await tester.tap(stop);
    await tester.pump(const Duration(milliseconds: 300));
    expect(glove.snapshot.value.pressureKpa, 0);
    await tester.pump(const Duration(seconds: 20));
    expect(stop, findsOneWidget); // review
    await finish(tester, glove);
  });

  testWidgets('touch targets meet minimum sizes on Home', (tester) async {
    final glove = await pumpRohab(tester);
    expect(
        tester
            .getSize(find.byKey(HomeScreen.primaryButtonKey,
                skipOffstage: false))
            .height,
        greaterThanOrEqualTo(64));
    expect(tester.getSize(find.byKey(AppShell.settingsButtonKey)).height,
        greaterThanOrEqualTo(64));
    for (final label in ['Home', 'Glove', 'Exercises', 'Progress']) {
      final tab = find.ancestor(
          of: find.text(label).last, matching: find.byType(InkWell));
      expect(tester.getSize(tab.first).height, greaterThanOrEqualTo(64));
    }
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await finish(tester, glove);
  });
}
