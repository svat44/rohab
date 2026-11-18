import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/calibration/emg_calibrator.dart';

/// 250 rest samples alternating 50 / 70: mean exactly 60, SD exactly 10.
final rest = [for (var i = 0; i < 250; i++) i.isEven ? 50 : 70];

List<int> trial(int level) => List.filled(100, level);

void main() {
  group('EmgCalibrator.compute', () {
    test('normal case: strong grip', () {
      final r = EmgCalibrator.compute(
          rest: rest, trials: [trial(370), trial(380), trial(390)]);
      expect(r.restMean, 60);
      expect(r.restSd, 10);
      expect(r.gripLevel, 380);
      expect(r.threshold, 188); // 60 + 0.4 x 320
      expect(r.isValid, isTrue);
    });

    test('weak case still passes', () {
      final r = EmgCalibrator.compute(
          rest: rest, trials: [trial(130), trial(140), trial(150)]);
      expect(r.gripLevel, 140);
      expect(r.threshold, 92); // 60 + 0.4 x 80
      expect(r.isValid, isTrue);
    });

    test('no signal fails validation', () {
      final r = EmgCalibrator.compute(
          rest: rest, trials: [trial(64), trial(65), trial(66)]);
      expect(r.gripLevel, 65);
      expect(r.isValid, isFalse);
    });

    test('fails when grip clears 3 SD but not 1.5 x rest', () {
      // Quiet rest (SD 0) at 100; grip 140 > 100 + 0 but < 150.
      final r = EmgCalibrator.compute(
          rest: List.filled(250, 100), trials: [trial(140)]);
      expect(r.isValid, isFalse);
    });

    test('fails when grip clears 1.5 x rest but not 3 SD', () {
      // Rest mean 60, SD 30; grip 145 >= 90 but < 150.
      final noisy = [for (var i = 0; i < 250; i++) i.isEven ? 30 : 90];
      final r = EmgCalibrator.compute(rest: noisy, trials: [trial(145)]);
      expect(r.restSd, 30);
      expect(r.isValid, isFalse);
    });

    test('median ignores one outlier trial (high)', () {
      final r = EmgCalibrator.compute(
          rest: rest, trials: [trial(380), trial(900), trial(370)]);
      expect(r.gripLevel, 380);
    });

    test('median ignores one outlier trial (missed grip)', () {
      final r = EmgCalibrator.compute(
          rest: rest, trials: [trial(380), trial(62), trial(400)]);
      expect(r.gripLevel, 380);
      expect(r.isValid, isTrue);
    });

    test('rejects empty input', () {
      expect(() => EmgCalibrator.compute(rest: [], trials: [trial(1)]),
          throwsArgumentError);
      expect(() => EmgCalibrator.compute(rest: rest, trials: []),
          throwsArgumentError);
    });
  });

  group('rounding', () {
    test('rounds to nearest integer', () {
      expect(EmgCalibrator.thresholdFor(60, 381), 188); // 188.4
      expect(EmgCalibrator.thresholdFor(60, 382), 189); // 188.8
    });

    test('halves round up', () {
      expect(EmgCalibrator.thresholdFor(10, 11.25), 11); // 10.5
      expect(EmgCalibrator.thresholdFor(60, 383.75), 190); // 189.5
    });

    test('threshold sits 40% of the way from rest to grip', () {
      expect(EmgCalibrator.thresholdFor(0, 1000), 400);
    });
  });

  group('helpers', () {
    test('trimTrial keeps the middle 2 s of a 3 s trial', () {
      final samples = List.generate(150, (i) => i);
      final trimmed = EmgCalibrator.trimTrial(samples);
      expect(trimmed.length, 100);
      expect(trimmed.first, 25);
      expect(trimmed.last, 124);
    });

    test('median of an even count averages the middle two', () {
      expect(EmgCalibrator.median([1, 4, 2, 3]), 2.5);
    });

    test('SD is the population SD', () {
      expect(EmgCalibrator.populationSd([2, 4, 4, 4, 5, 5, 7, 9]), 2);
    });
  });

  group('Calibration', () {
    final c = Calibration(
      restMean: 60,
      restSd: 10,
      gripLevel: 380,
      threshold: 188,
      timestamp: DateTime(2026, 11, 18, 9),
    );

    test('expires after 24 hours', () {
      expect(c.isExpiredAt(DateTime(2026, 11, 19, 8, 59)), isFalse);
      expect(c.isExpiredAt(DateTime(2026, 11, 19, 9)), isTrue);
    });

    test('round-trips through JSON with only signal data', () {
      final json = c.toJson();
      expect(json.keys.toSet(),
          {'restMean', 'restSD', 'gripLevel', 'threshold', 'timestamp'});
      final back = Calibration.fromJson(json)!;
      expect(back.threshold, 188);
      expect(back.timestamp, c.timestamp);
    });

    test('malformed JSON loads as null', () {
      expect(Calibration.fromJson({'threshold': 'x'}), isNull);
    });
  });
}
