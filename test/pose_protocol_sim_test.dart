// A.4: the three test-protocol poses, run through the REAL exercise
// controller (hand check, range calibration, counting) with a SCRIPTED
// hand. This checks the counting and calibration logic. It says nothing
// about how well MediaPipe detects a real curled or limited hand: that
// needs the phone (docs in README, "Camera test protocol").
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/camera_permission.dart';
import 'package:rohab/camera/mock_hand_tracker.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';
import 'package:rohab/debug/diagnostics.dart';
import 'package:rohab/debug/protocol_report.dart';
import 'package:rohab/exercises/camera_exercise_controller.dart';
import 'package:rohab/exercises/exercise_catalog.dart';

class _Granted implements CameraPermission {
  @override
  Future<CameraAccess> status() async => CameraAccess.granted;
  @override
  Future<CameraAccess> request() async => CameraAccess.granted;
  @override
  Future<void> openSettings() async {}
}

class _Null extends ExerciseSessionRepository {
  @override
  Future<int> save(ExerciseSessionRecord record) async => 0;
  @override
  Future<List<ExerciseSessionRow>> all() async => const [];
  @override
  Future<void> deleteAll() async {}
}

/// A scripted hand. The tracker clock starts at 0: the hand check passes
/// at about 1 s, "open wide" is sampled to about 4 s, "fist" to about 7 s,
/// then counting starts.
HandScript script({
  required double calOpen,
  required double calClosed,
  required double repOpen,
  required double repClosed,
  Duration period = const Duration(milliseconds: 1600),
  Duration? dropoutAt,
  Duration dropoutLength = Duration.zero,
}) {
  return (t) {
    if (dropoutAt != null && t >= dropoutAt && t < dropoutAt + dropoutLength) {
      return null;
    }
    if (t < const Duration(milliseconds: 4050)) return HandPose(curl: calOpen);
    if (t < const Duration(milliseconds: 7050)) return HandPose(curl: calClosed);
    final p = ((t - const Duration(milliseconds: 7050)).inMicroseconds %
            period.inMicroseconds) /
        period.inMicroseconds;
    return HandPose(curl: p < 0.5 ? repOpen : repClosed);
  };
}

Future<PoseResult> run(
  WidgetTester tester,
  PoseSpec spec,
  MockHandTracker tracker,
) async {
  final diag = DiagnosticsCollector();
  final c = CameraExerciseController(
    exercise: ExerciseCatalog.openClose,
    trackerFactory: () => tracker,
    permission: _Granted(),
    repository: _Null(),
    loadRange: () => null,
    saveRange: (_) {},
    setSize: 9999,
    diagnostics: diag,
  );
  unawaited(c.start());
  for (var i = 0; i < 300 && c.step != FlowStep.exercise; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (c.step == FlowStep.calibrationFailed) {
      c.dispose();
      unawaited(tracker.stop());
      await tester.pump(const Duration(milliseconds: 100));
      return PoseResult(
          pose: spec, seconds: 0, avgFps: 0, detectionPercent: 0,
          dropouts: 0, reps: 0, note: 'range too small to calibrate');
    }
  }
  expect(c.step, FlowStep.exercise, reason: spec.id);
  final start = diag.snapshot(c.now);
  for (var i = 0; i < 300; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final s = RunSummary.between(start, diag.snapshot(c.now));
  final reps = c.reps;
  unawaited(c.endExercise());
  await tester.pump(const Duration(milliseconds: 100));
  c.dispose();
  unawaited(tracker.stop());
  await tester.pump(const Duration(milliseconds: 100));
  return PoseResult(
    pose: spec, seconds: s.seconds, avgFps: s.avgFps,
    detectionPercent: s.detectionPercent, dropouts: s.dropouts, reps: reps);
}

PoseSpec spec(String id, String title) => PoseSpec(id, title, '');

void main() {
  final results = <PoseResult>[];

  tearDownAll(() {
    debugPrint('\nSimulated poses (scripted hand, 30 s counting each):\n'
        '${formatProtocolTable(results)}\n');
  });

  testWidgets('A. full open and close counts about 17 reps', (tester) async {
    final r = await run(tester, PoseSpec.all[0],
        MockHandTracker(script: script(calOpen: 0, calClosed: 1, repOpen: 0, repClosed: 1)));
    results.add(r);
    expect(r.reps, inInclusiveRange(15, 19));
    expect(r.dropouts, 0);
    expect(r.detectionPercent, closeTo(100, 1));
    expect(r.avgFps, closeTo(30, 2));
  });

  testWidgets('B. limited range counts when calibrated at that range',
      (tester) async {
    final r = await run(tester, PoseSpec.all[1],
        MockHandTracker(script: script(calOpen: 0.35, calClosed: 0.65, repOpen: 0.35, repClosed: 0.65)));
    results.add(r);
    expect(r.reps, inInclusiveRange(15, 19));
  });

  testWidgets('C. curled (claw) hand counts when calibrated at that range',
      (tester) async {
    final r = await run(tester, PoseSpec.all[2],
        MockHandTracker(script: script(calOpen: 0.5, calClosed: 0.85, repOpen: 0.5, repClosed: 0.85)));
    results.add(r);
    expect(r.reps, inInclusiveRange(15, 19));
  });

  testWidgets('B2. limited moves after a full-range calibration: counts 0',
      (tester) async {
    // Known limitation, by design of the 80 % / 20 % rule: the person must
    // reach 80 % of the range they calibrated at.
    final r = await run(tester, spec('b2', 'B2. Limited, calibrated at full range'),
        MockHandTracker(script: script(calOpen: 0, calClosed: 1, repOpen: 0.35, repClosed: 0.65)));
    results.add(r);
    expect(r.reps, 0);
  });

  testWidgets('C2. a range under 30 degrees cannot be calibrated',
      (tester) async {
    final r = await run(tester, spec('c2', 'C2. Tiny range (about 10 degrees)'),
        MockHandTracker(script: script(calOpen: 0.5, calClosed: 0.54, repOpen: 0.5, repClosed: 0.54)));
    results.add(r);
    expect(r.note, 'range too small to calibrate');
  });

  testWidgets('D. noise and 1 in 7 low-confidence frames still count',
      (tester) async {
    final r = await run(tester, spec('d', 'D. Full range, noisy, 1 in 7 low confidence'),
        MockHandTracker(
          script: script(calOpen: 0, calClosed: 1, repOpen: 0, repClosed: 1),
          noise: 0.003, lowConfidenceEvery: 7));
    results.add(r);
    expect(r.reps, inInclusiveRange(14, 19));
    expect(r.detectionPercent, closeTo(86, 3));
    expect(r.reliable, isFalse, reason: 'detection under 90 %');
  });

  testWidgets('E. a 1.2 s dropout is counted and does not break counting',
      (tester) async {
    final r = await run(tester, spec('e', 'E. Full range, 1.2 s dropout'),
        MockHandTracker(script: script(calOpen: 0, calClosed: 1, repOpen: 0, repClosed: 1,
            dropoutAt: const Duration(seconds: 20), dropoutLength: const Duration(milliseconds: 1200))));
    results.add(r);
    expect(r.dropouts, 1);
    expect(r.reps, inInclusiveRange(13, 18));
  });
}
