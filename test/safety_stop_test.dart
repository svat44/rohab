import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/glove/glove_service.dart';
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
  'Calibration': (t) => tapTab(t, 'Calibrate'),
  'Exercises': (t) => tapTab(t, 'Exercises'),
  'Progress': (t) => tapTab(t, 'Progress'),
  'Settings': (t) async {
    await t.tap(find.byKey(AppShell.settingsButtonKey));
    await t.pump();
  },
};

Future<void> _connectAndInflate(WidgetTester tester) async {
  await connectFromHome(tester);
  await tester.tap(find.byKey(HomeScreen.primaryButtonKey)); // Start
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Home: start raises live pressure shown on screen',
      (tester) async {
    final glove = await pumpRohab(tester);
    expect(find.text('Glove not connected'), findsOneWidget);
    expect(find.text('Rohab'), findsOneWidget);

    await _connectAndInflate(tester);
    final shown = double.parse(
        tester.widget<Text>(find.byKey(HomeScreen.pressureKey)).data!);
    expect(shown, greaterThan(10));
    expect(find.text('End session'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3, milliseconds: 500)); // 1 rep
    await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('Session complete.'), findsOneWidget);
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

      await tester.tap(stop); // disconnected
      await tester.pump();
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
    await tapTab(tester, 'Calibrate');
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
    expect(tester.getSize(find.byKey(HomeScreen.primaryButtonKey)).height,
        greaterThanOrEqualTo(64));
    expect(tester.getSize(find.byKey(AppShell.settingsButtonKey)).height,
        greaterThanOrEqualTo(64));
    for (final label in ['Home', 'Calibrate', 'Exercises', 'Progress']) {
      final tab = find.ancestor(
          of: find.text(label).last, matching: find.byType(InkWell));
      expect(tester.getSize(tab.first).height, greaterThanOrEqualTo(64));
    }
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await finish(tester, glove);
  });

  testWidgets('Home primary button stays in the same place in every state',
      (tester) async {
    final glove = await pumpRohab(tester);
    Rect rect() => tester.getRect(find.byKey(HomeScreen.primaryButtonKey));
    final disconnected = rect();
    await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(rect(), disconnected, reason: 'connecting');
    await tester.pump(MockGloveService.connectDelay);
    expect(find.text('Disconnect'), findsOneWidget);
    expect(rect(), disconnected, reason: 'connected');
    await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
    await tester.pump(const Duration(seconds: 1));
    expect(rect(), disconnected, reason: 'session active');
    await finish(tester, glove);
  });
}
