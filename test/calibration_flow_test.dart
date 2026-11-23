import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rohab/app/providers.dart';
import 'package:rohab/calibration/calibration_controller.dart';
import 'package:rohab/calibration/calibration_repository.dart';
import 'package:rohab/calibration/emg_calibrator.dart';
import 'package:rohab/glove/glove_service.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/screens/calibration/calibration_screen.dart';
import 'package:rohab/screens/calibration/review_step.dart';
import 'package:rohab/screens/calibration/step_layout.dart';
import 'package:rohab/screens/home_screen.dart';
import 'package:rohab/widgets/app_shell.dart';
import 'package:rohab/widgets/safety_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Full flow is 5 s rest + 3 x 3 s grip + 2 x 5 s rest between = 24 s.
const flowDuration = Duration(seconds: 24, milliseconds: 200);

Future<void> openCalibrationAndStart(WidgetTester tester) async {
  await connectFromHome(tester);
  await tapTab(tester, 'Glove');
  await tester.tap(find.byKey(CalibrationScreen.startKey));
  await tester.pump();
  await tester.tap(find.byKey(StepLayout.primaryKey)); // I'm ready
  await tester.pump();
}

Future<void> choosePreset(WidgetTester tester, MockEmgPreset preset) async {
  await tester.longPress(find.byKey(AppShell.wordmarkKey));
  await tester.pump(const Duration(milliseconds: 400)); // menu slides in
  await tester.tap(find.byKey(const Key('debug-grip')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('preset-${preset.name}')));
  await tester.pump();
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  expect(find.text('Close'), findsNothing, reason: 'sheet closed');
}

class _FakeGlove extends Mock implements GloveService {}

void main() {
  group('Calibration flow (widget)', () {
    testWidgets('completing all 4 steps with Strong saves a threshold',
        (tester) async {
      final glove = await pumpRohab(tester);
      await choosePreset(tester, MockEmgPreset.strong);
      await openCalibrationAndStart(tester);

      expect(find.text('Rest your hand on the table. Stay relaxed.'),
          findsOneWidget);
      await tester.pump(const Duration(seconds: 5, milliseconds: 100));
      expect(find.text('Try to make a fist.'), findsOneWidget);
      expect(find.text('Trial 1 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Relax.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Trial 2 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 11, milliseconds: 100));

      expect(find.text('Trigger level'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.byKey(StepLayout.primaryKey)); // Save
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(CalibrationRepository.storageKey);
      expect(raw, isNotNull);
      final saved = Calibration.fromJson(
          jsonDecode(raw!) as Map<String, Object?>)!;
      expect(saved.restMean, closeTo(60, 3));
      expect(saved.gripLevel, closeTo(380, 15));
      expect(saved.threshold, closeTo(188, 8));
      expect(glove.emgThreshold, saved.threshold, reason: 'sent to glove');
      expect(find.textContaining('Calibration saved.'), findsOneWidget);

      // Calibration never inflated the glove.
      expect(glove.snapshot.value.sessionActive, isFalse);
      expect(glove.snapshot.value.pressureKpa, 0);
      await finish(tester, glove);
    });

    testWidgets('Weak preset still passes', (tester) async {
      final glove = await pumpRohab(tester);
      await choosePreset(tester, MockEmgPreset.weak);
      await openCalibrationAndStart(tester);
      await tester.pump(flowDuration);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text(EmgCalibrator.invalidMessage), findsNothing);
      await finish(tester, glove);
    });

    testWidgets('Weak preset review: marker labels do not overlap',
        (tester) async {
      final glove = await pumpRohab(tester);
      await choosePreset(tester, MockEmgPreset.weak);
      await openCalibrationAndStart(tester);
      await tester.pump(flowDuration);
      Finder label(String name) => find.byWidgetPredicate((w) =>
          w is Text && RegExp('^$name \\d+\$').hasMatch(w.data ?? ''));
      expect(label('Rest'), findsOneWidget);
      expect(label('Grip'), findsOneWidget);
      final rest = tester.getRect(label('Rest'));
      final grip = tester.getRect(label('Grip'));
      expect(rest.overlaps(grip), isFalse);
      await finish(tester, glove);
    });

    testWidgets('No signal fails and offers only Redo', (tester) async {
      final glove = await pumpRohab(tester);
      await choosePreset(tester, MockEmgPreset.noSignal);
      await openCalibrationAndStart(tester);
      await tester.pump(flowDuration);
      expect(find.text(EmgCalibrator.invalidMessage), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Redo'), findsOneWidget);

      // Redo goes back to Step 2.
      await tester.tap(find.byKey(StepLayout.primaryKey));
      await tester.pump();
      expect(find.text('Rest your hand on the table. Stay relaxed.'),
          findsOneWidget);
      await finish(tester, glove);
    });

    testWidgets('Cancel on any step returns to start and saves nothing',
        (tester) async {
      final glove = await pumpRohab(tester);
      await openCalibrationAndStart(tester);
      // Cancel on rest, grip, and review.
      for (final wait in [
        const Duration(seconds: 1),
        const Duration(seconds: 7),
        flowDuration,
      ]) {
        await tester.pump(wait);
        await tester.tap(find.byKey(StepLayout.cancelKey));
        await tester.pump();
        expect(find.byKey(CalibrationScreen.startKey), findsOneWidget);
        await tester.tap(find.byKey(CalibrationScreen.startKey));
        await tester.pump();
        await tester.tap(find.byKey(StepLayout.primaryKey));
        await tester.pump();
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(CalibrationRepository.storageKey), isNull);
      await finish(tester, glove);
    });

    testWidgets('Redo from review restarts at the rest step', (tester) async {
      final glove = await pumpRohab(tester);
      await openCalibrationAndStart(tester);
      await tester.pump(flowDuration);
      await tester.tap(find.byKey(ReviewStep.redoKey));
      await tester.pump();
      expect(find.text('Step 2 of 4 · Rest'), findsOneWidget);
      await finish(tester, glove);
    });

    testWidgets('start is blocked when disconnected or in a session',
        (tester) async {
      final glove = await pumpRohab(tester);
      await tapTab(tester, 'Glove');
      expect(find.text('Connect the glove on Home first.'), findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.byKey(CalibrationScreen.startKey))
              .onPressed,
          isNull);

      await tapTab(tester, 'Home');
      await connectFromHome(tester);
      await tapHomePrimary(tester); // Start
      await tester.pump(const Duration(milliseconds: 100));
      await tapTab(tester, 'Glove');
      expect(find.text('End the session on Home first.'), findsOneWidget);
      await tester.tap(find.byKey(SafetyBanner.stopKey));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('End the session on Home first.'), findsNothing);
      await finish(tester, glove);
    });

    testWidgets('Home shows Calibration needed until calibrated, and after '
        '24 hours', (tester) async {
      var now = DateTime(2026, 11, 18, 9);
      final glove = await pumpRohab(tester, clock: () => now);
      expect(find.byKey(HomeScreen.calibrationNeededKey), findsOneWidget);
      await finish(tester, glove);

      final fresh = Calibration(
        restMean: 60,
        restSd: 10,
        gripLevel: 380,
        threshold: 188,
        timestamp: now.subtract(const Duration(hours: 1)),
      );
      final stored = {
        CalibrationRepository.storageKey: jsonEncode(fresh.toJson())
      };
      final g2 = await pumpRohab(tester, prefs: stored, clock: () => now);
      expect(find.byKey(HomeScreen.calibrationNeededKey), findsNothing);
      await finish(tester, g2);

      now = now.add(const Duration(hours: 24));
      final g3 = await pumpRohab(tester, prefs: stored, clock: () => now);
      expect(find.byKey(HomeScreen.calibrationNeededKey), findsOneWidget);
      await finish(tester, g3);
    });

    testWidgets('saved threshold is sent to the glove on connect',
        (tester) async {
      final now = DateTime(2026, 11, 18, 9);
      final stored = {
        CalibrationRepository.storageKey: jsonEncode(Calibration(
          restMean: 60,
          restSd: 10,
          gripLevel: 380,
          threshold: 188,
          timestamp: now,
        ).toJson()),
      };
      final glove = await pumpRohab(tester, prefs: stored, clock: () => now);
      expect(glove.emgThreshold, isNull);
      await connectFromHome(tester);
      expect(glove.emgThreshold, 188);
      await finish(tester, glove);
    });
  });

  group('CalibrationController with a mocked glove', () {
    late _FakeGlove glove;
    late ValueNotifier<GloveSnapshot> snapshot;
    late StreamController<int> emg;
    late ProviderContainer container;

    setUp(() async {
      glove = _FakeGlove();
      snapshot = ValueNotifier(GloveSnapshot.initial
          .copyWith(connection: GloveConnection.connected));
      emg = StreamController<int>.broadcast(sync: true);
      when(() => glove.snapshot).thenReturn(snapshot);
      when(() => glove.emgSamples).thenAnswer((_) => emg.stream);
      when(() => glove.setEmgThreshold(any())).thenAnswer((_) async {});
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(overrides: [
        gloveServiceProvider.overrideWithValue(glove),
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 18, 9)),
      ]);
    });

    tearDown(() {
      container.dispose();
      emg.close();
    });

    void feed(int n, int value) {
      for (var i = 0; i < n; i++) {
        emg.add(value);
      }
    }

    test('counts samples per phase and never inflates the glove', () async {
      final c = container.read(calibrationControllerProvider.notifier);
      CalibrationFlowState s() => container.read(calibrationControllerProvider);

      c.begin();
      expect(s().step, CalibrationStep.prepare);
      c.ready();
      expect(s().step, CalibrationStep.rest);
      expect(s().secondsLeft, 5);

      feed(249, 60);
      expect(s().step, CalibrationStep.rest);
      expect(s().secondsLeft, 1);
      feed(1, 60);
      expect(s().step, CalibrationStep.grip);
      expect(s().trial, 1);

      for (var trial = 1; trial <= 3; trial++) {
        expect(s().gripPhase, GripPhase.grip);
        // Ramp in the first 0.5 s and out in the last 0.5 s are dropped.
        feed(25, 999);
        feed(100, 380);
        feed(25, 999);
        if (trial < 3) {
          expect(s().gripPhase, GripPhase.relax);
          feed(250, 60);
          expect(s().trial, trial + 1);
        }
      }

      expect(s().step, CalibrationStep.review);
      final r = s().result!;
      expect(r.restMean, 60);
      expect(r.gripLevel, 380, reason: 'trimmed edges excluded');
      expect(r.threshold, 188);

      await c.save();
      expect(container.read(savedCalibrationProvider)!.threshold, 188);
      verify(() => glove.setEmgThreshold(188)).called(1);
      verifyNever(() => glove.start());
      verifyNever(() => glove.setTargetPressure(any()));
    });

    test('disconnect mid-recording cancels and saves nothing', () {
      final c = container.read(calibrationControllerProvider.notifier);
      c.begin();
      c.ready();
      feed(100, 60);
      snapshot.value = GloveSnapshot.initial;
      final s = container.read(calibrationControllerProvider);
      expect(s.step, CalibrationStep.start);
      expect(s.notice, contains('disconnected'));
      expect(container.read(savedCalibrationProvider), isNull);
    });
  });
}
