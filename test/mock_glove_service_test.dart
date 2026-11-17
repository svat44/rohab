import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/glove/glove_service.dart';
import 'package:rohab/glove/mock_glove_service.dart';

void main() {
  late MockGloveService glove;

  setUp(() => glove = MockGloveService());

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
      expect(glove.snapshot.value.pressureKpa, closeTo(40, 0.5));

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
      expect(glove.snapshot.value.pressureKpa, closeTo(40, 0.5));
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
}
