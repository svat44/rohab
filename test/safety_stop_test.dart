import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/app/app.dart';
import 'package:rohab/glove/glove_service.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/ui/app_shell.dart';
import 'package:rohab/ui/screens/home_screen.dart';
import 'package:rohab/ui/widgets/bottom_nav.dart';
import 'package:rohab/ui/widgets/safety_banner.dart';

/// How to reach each screen from Home.
final screens = <String, Future<void> Function(WidgetTester)>{
  'Home': (t) async {},
  'Calibration': (t) => _tapTab(t, 'Calibrate'),
  'Exercises': (t) => _tapTab(t, 'Exercises'),
  'Progress': (t) => _tapTab(t, 'Progress'),
  'Settings': (t) async {
    await t.tap(find.byKey(AppShell.settingsButtonKey));
    await t.pump();
  },
};

Future<void> _tapTab(WidgetTester t, String label) async {
  await t.tap(find.descendant(
      of: find.byType(BottomNav), matching: find.text(label)));
  await t.pump();
}

Future<MockGloveService> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final glove = MockGloveService();
  await tester.pumpWidget(RohabApp(glove: glove));
  return glove;
}

Future<void> _finish(WidgetTester tester, MockGloveService glove) async {
  await tester.pumpWidget(const SizedBox());
  glove.dispose();
}

Future<void> _connectAndInflate(WidgetTester tester) async {
  await tester.tap(find.byKey(HomeScreen.primaryButtonKey)); // Connect
  await tester.pump(MockGloveService.connectDelay);
  await tester.tap(find.byKey(HomeScreen.primaryButtonKey)); // Start
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Home: start raises live pressure shown on screen',
      (tester) async {
    final glove = await _launch(tester);
    expect(find.text('Not connected'), findsOneWidget);

    await _connectAndInflate(tester);
    final shown = double.parse(
        tester.widget<Text>(find.byKey(HomeScreen.pressureKey)).data!);
    expect(shown, greaterThan(10));
    expect(glove.snapshot.value.pressureKpa, greaterThan(10));
    expect(find.text('End session'), findsOneWidget);

    // End normally and see the summary.
    await tester.pump(const Duration(seconds: 3, milliseconds: 500)); // 1 rep
    await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('Session complete.'), findsOneWidget);
    await _finish(tester, glove);
  });

  for (final entry in screens.entries) {
    testWidgets('STOP vents to zero from ${entry.key} while inflating',
        (tester) async {
      final glove = await _launch(tester);
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

      // It stays at zero: no new cycle starts.
      await tester.pump(const Duration(seconds: 5));
      expect(glove.snapshot.value.pressureKpa, 0);
      await _finish(tester, glove);
    });
  }

  for (final entry in screens.entries) {
    testWidgets('STOP is safe from ${entry.key} in every state',
        (tester) async {
      final glove = await _launch(tester);
      await entry.value(tester);
      final stop = find.byKey(SafetyBanner.stopKey);

      // Disconnected.
      await tester.tap(stop);
      await tester.pump();
      // Connecting.
      glove.connect();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(stop);
      await tester.pump(MockGloveService.connectDelay);
      expect(glove.snapshot.value.isConnected, isTrue);
      // Connected, idle.
      await tester.tap(stop);
      await tester.pump();
      // Holding.
      glove.start();
      await tester.pump(const Duration(seconds: 3, milliseconds: 200));
      expect(glove.snapshot.value.state, GloveState.holding);
      await tester.tap(stop);
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      // Normal venting after End session.
      glove.start();
      await tester.pump(const Duration(seconds: 2));
      glove.stop();
      await tester.pump(const Duration(milliseconds: 100));
      expect(glove.snapshot.value.state, GloveState.venting);
      await tester.tap(stop);
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      // After a fault.
      glove.start();
      await tester.pump(const Duration(seconds: 2));
      glove.simulateFault(GloveFault.overpressure);
      await tester.pump();
      expect(find.text('Glove vented'), findsOneWidget);
      await tester.tap(stop);
      await tester.pump(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);

      expect(tester.takeException(), isNull);
      await _finish(tester, glove);
    });
  }

  testWidgets('touch targets meet minimum sizes on Home', (tester) async {
    final glove = await _launch(tester);
    expect(tester.getSize(find.byKey(HomeScreen.primaryButtonKey)).height,
        greaterThanOrEqualTo(64));
    final settings = tester.getSize(find.byKey(AppShell.settingsButtonKey));
    expect(settings.height, greaterThanOrEqualTo(64));
    for (final label in ['Home', 'Calibrate', 'Exercises', 'Progress']) {
      final tab = find.ancestor(
          of: find.text(label).last, matching: find.byType(InkWell));
      expect(tester.getSize(tab.first).height, greaterThanOrEqualTo(64));
    }
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await _finish(tester, glove);
  });

  testWidgets('Home primary button stays in the same place in every state',
      (tester) async {
    final glove = await _launch(tester);
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
    await _finish(tester, glove);
  });
}
