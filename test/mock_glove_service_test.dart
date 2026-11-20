import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/glove/glove_service.dart';
import 'package:rohab/glove/mock_glove_service.dart';

void main() {
  late MockGloveService glove;

  setUp(() => glove = MockGloveService(random: Random(3)));

  void connect(FakeAsync async) {
    glove.connect();
    async.elapse(MockGloveService.connectDelay);
  }

  test('connects after a short delay', () {
    fakeAsync((async) {
      glove.connect();
      expect(glove.snapshot.value.connection, GloveConnection.connecting);
      async.elapse(MockGloveService.connectDelay);
      expect(glove.snapshot.value.connection, GloveConnection.connected);
      glove.dispose();
    });
  });

  test('start raises pressure to target, holds, vents, counts a rep', () {
    fakeAsync((async) {
      connect(async);
      glove.start();
      async.elapse(const Duration(milliseconds: 500));
      final s1 = glove.snapshot.value;
      expect(s1.state, GloveState.inflating);
      expect(s1.pressureKpa, greaterThan(0));

      async.elapse(const Duration(seconds: 2));
      expect(glove.snapshot.value.state, GloveState.holding);
      expect(glove.snapshot.value.pressureKpa, closeTo(200, 0.5));

      // Hold 2 s, vent 1 s.
      async.elapse(const Duration(seconds: 3, milliseconds: 200));
      expect(glove.snapshot.value.pressureKpa, 0);
      expect(glove.snapshot.value.reps, 1);
      glove.dispose();
    });
  });

  test('stop finishes venting and stays idle', () {
    fakeAsync((async) {
      connect(async);
      glove.start();
      async.elapse(const Duration(seconds: 2));
      glove.stop();
      expect(glove.snapshot.value.state, GloveState.venting);
      async.elapse(const Duration(seconds: 3));
      expect(glove.snapshot.value.state, GloveState.idle);
      expect(glove.snapshot.value.pressureKpa, 0);
      async.elapse(const Duration(seconds: 5));
      expect(glove.snapshot.value.pressureKpa, 0, reason: 'no new cycle');
      expect(glove.snapshot.value.reps, 0, reason: 'cut-short cycle');
      glove.dispose();
    });
  });

  test('emergency vent drops pressure to zero within 300 ms', () {
    fakeAsync((async) {
      connect(async);
      glove.start();
      async.elapse(const Duration(seconds: 3));
      expect(glove.snapshot.value.pressureKpa, closeTo(200, 0.5));
      glove.emergencyVent();
      async.elapse(const Duration(milliseconds: 300));
      expect(glove.snapshot.value.pressureKpa, 0);
      expect(glove.snapshot.value.sessionActive, isFalse);
      glove.dispose();
    });
  });

  test('emergency vent is safe while disconnected and connecting', () {
    fakeAsync((async) {
      expect(glove.emergencyVent(), completes);
      glove.connect();
      expect(glove.emergencyVent(), completes);
      async.elapse(MockGloveService.connectDelay);
      expect(glove.snapshot.value.pressureKpa, 0);
      glove.dispose();
    });
  });

  test('a fault vents the glove and is reported', () {
    fakeAsync((async) {
      connect(async);
      glove.start();
      async.elapse(const Duration(seconds: 2));
      glove.simulateFault(GloveFault.overpressure);
      async.elapse(const Duration(milliseconds: 300));
      final s = glove.snapshot.value;
      expect(s.faults, {GloveFault.overpressure});
      expect(s.pressureKpa, 0);
      expect(s.sessionActive, isFalse);
      glove.start();
      expect(glove.snapshot.value.faults, isEmpty, reason: 'start clears');
      glove.dispose();
    });
  });

  test('EMG stays within 0-1023', () {
    fakeAsync((async) {
      connect(async);
      glove.start();
      for (var i = 0; i < 200; i++) {
        async.elapse(MockGloveService.tick);
        expect(glove.snapshot.value.emg, inInclusiveRange(0, 1023));
      }
      glove.dispose();
    });
  });

  group('simulated EMG', () {
    double meanOver(FakeAsync async, Duration d) {
      final samples = <int>[];
      final sub = glove.emgSamples.listen(samples.add);
      async.elapse(d);
      sub.cancel();
      return samples.reduce((a, b) => a + b) / samples.length;
    }

    test('streams at 50 Hz', () {
      fakeAsync((async) {
        connect(async);
        final samples = <int>[];
        final sub = glove.emgSamples.listen(samples.add);
        async.elapse(const Duration(seconds: 1));
        sub.cancel();
        expect(samples.length, 50);
        glove.dispose();
      });
    });

    for (final preset in MockEmgPreset.values) {
      test('rest about 60, grip about ${preset.gripMean} (${preset.label})',
          () {
        fakeAsync((async) {
          glove.preset = preset;
          connect(async);
          expect(meanOver(async, const Duration(seconds: 4)),
              closeTo(60, 3));
          glove.setPatientCue(PatientCue.grip);
          async.elapse(MockGloveService.effortRamp);
          expect(meanOver(async, const Duration(seconds: 4)),
              closeTo(preset.gripMean, preset.gripSd / 2));
          glove.dispose();
        });
      });
    }

    test('grip ramps over 300 ms', () {
      fakeAsync((async) {
        glove.preset = MockEmgPreset.strong;
        connect(async);
        glove.setPatientCue(PatientCue.grip);
        final early = meanOver(async, const Duration(milliseconds: 100));
        expect(early, lessThan(250));
        glove.dispose();
      });
    });

    test('stores the threshold the app sends', () {
      glove.setEmgThreshold(188);
      expect(glove.emgThreshold, 188);
      glove.dispose();
    });
  });
}
