import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/hand_tracker.dart';
import 'package:rohab/debug/diagnostics.dart';
import 'package:rohab/debug/protocol_report.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

HandFrame frame({double confidence = 0.95}) => HandFrame(
      landmarks: SyntheticHand.pose(),
      handedness: Handedness.left,
      confidence: confidence,
      timestamp: Duration.zero,
    );

const dt = Duration(milliseconds: 50);

void main() {
  group('DiagnosticsCollector', () {
    test('fps, 10 s detection rate and no dropouts for a steady 20 fps', () {
      final d = DiagnosticsCollector();
      var results = 0;
      for (var i = 1; i <= 240; i++) {
        final now = dt * i; // 12 s
        if (i % 1 == 0) {
          results++; // 1 result per 50 ms = 20 fps
          d.onFrame(frame(), now);
        }
        d.tick(now, results);
      }
      expect(d.fps, closeTo(20, 1));
      expect(d.detectionPercent, closeTo(100, 1));
      expect(d.dropout, Duration.zero);
      expect(d.snapshot(dt * 240).dropouts, 0);
    });

    test('low-confidence frames lower the detection rate', () {
      final d = DiagnosticsCollector();
      var results = 0;
      for (var i = 1; i <= 200; i++) {
        results++;
        d.onFrame(frame(confidence: i % 4 == 0 ? 0.3 : 0.9), dt * i);
        d.tick(dt * i, results);
      }
      expect(d.detectionPercent, closeTo(75, 3));
    });

    test('a gap over 0.5 s is one dropout and its length is reported', () {
      final d = DiagnosticsCollector();
      var results = 0;
      for (var i = 1; i <= 100; i++) {
        results++; // results keep coming (the tracker runs) ...
        // ... but there is no hand from 2.0 s to 3.0 s.
        final t = dt * i;
        if (t < const Duration(seconds: 2) || t > const Duration(seconds: 3)) {
          d.onFrame(frame(), t);
        }
        d.tick(t, results);
        if (t == const Duration(milliseconds: 2800)) {
          expect(d.dropout.inMilliseconds, inInclusiveRange(750, 850));
        }
      }
      expect(d.snapshot(dt * 100).dropouts, 1);
      expect(d.dropout, Duration.zero, reason: 'hand is back');
    });

    test('a gap under 0.5 s is not a dropout', () {
      final d = DiagnosticsCollector();
      var results = 0;
      for (var i = 1; i <= 100; i++) {
        results++;
        final t = dt * i;
        if (i < 40 || i > 47) d.onFrame(frame(), t); // 0.4 s gap
        d.tick(t, results);
      }
      expect(d.snapshot(dt * 100).dropouts, 0);
    });

    test('RunSummary is the difference between two snapshots', () {
      final d = DiagnosticsCollector();
      var results = 0;
      DiagnosticsSnapshot? a;
      for (var i = 1; i <= 400; i++) {
        results++;
        d.onFrame(frame(confidence: i % 5 == 0 ? 0.2 : 0.9), dt * i);
        d.tick(dt * i, results);
        if (i == 100) a = d.snapshot(dt * i);
      }
      final s = RunSummary.between(a!, d.snapshot(dt * 400));
      expect(s.seconds, closeTo(15, 0.01));
      expect(s.avgFps, closeTo(20, 0.5));
      expect(s.detectionPercent, closeTo(80, 1));
      expect(s.dropouts, 0);
    });

    test('keeps no landmarks: its public state is plain numbers and text', () {
      final d = DiagnosticsCollector()..extra = () => 'open=10%';
      d.tick(dt, 1);
      expect(d.describe(), matches(RegExp(r'^fps=[\d.]+ detect10s=\d+% dropout=[\d.]+s open=10%$')));
    });
  });

  group('protocol report', () {
    PoseResult result(int i, {double fps = 20, double det = 97, int drop = 0,
            int reps = 15, double seconds = 30, String? note}) =>
        PoseResult(
          pose: PoseSpec.all[i], seconds: seconds, avgFps: fps,
          detectionPercent: det, dropouts: drop, reps: reps, note: note);

    test('a good pose is OK; each limit can fail it', () {
      expect(result(0).reliable, isTrue);
      expect(result(0, fps: 12).reliable, isFalse);
      expect(result(0, det: 85).reliable, isFalse);
      expect(result(0, drop: 3).reliable, isFalse);
      expect(result(0, reps: 4).reliable, isFalse); // 8 per 60 s
      expect(result(0, reps: 5).reliable, isTrue); // 10 per 60 s, projected
      expect(result(0, note: 'camera').reliable, isFalse);
    });

    test('a 30 s run is labelled as a projection', () {
      expect(result(0).projected, isTrue);
      expect(result(0, seconds: 60, reps: 10).projected, isFalse);
    });

    test('the table lists every pose, the verdict and the limits', () {
      final table = formatProtocolTable([
        result(0),
        result(1, det: 70),
        result(2, note: 'range too small to calibrate'),
      ]);
      expect(table, contains('A. Full open and close'));
      expect(table, contains('OK'));
      expect(table, contains('UNRELIABLE'));
      expect(table, contains('NOT RUN: range too small to calibrate'));
      expect(table, contains('10 reps/60 s'));
      expect(table, contains('FPS >= 15'));
      expect(table, contains('(projected)'));
    });
  });
}
