/// EMG calibration math. Pure Dart: no Flutter imports.
///
/// Learns a user's resting and gripping muscle signal (EMG envelope,
/// 0-1023, sampled at 50 Hz) and derives the trigger threshold for
/// assisted grip.
library;

import 'dart:math' as math;

class EmgCalibrator {
  EmgCalibrator._();

  static const sampleRateHz = 50;
  static const restSeconds = 5;
  static const restSampleCount = restSeconds * sampleRateHz; // 250

  static const trialCount = 3;
  static const trialSeconds = 3;
  static const trialSampleCount = trialSeconds * sampleRateHz; // 150
  static const betweenTrialsSeconds = 5;
  static const betweenTrialsSampleCount =
      betweenTrialsSeconds * sampleRateHz; // 250

  /// 0.5 s dropped from each end of a trial; keeps the middle 2 s.
  static const trialTrimSampleCount = sampleRateHz ~/ 2; // 25

  /// Threshold sits this far from rest toward grip.
  static const thresholdFraction = 0.4;

  static const invalidMessage =
      "We couldn't tell rest from grip. Check the sensor position and try again.";

  /// Middle 2 s of a 3 s trial.
  static List<int> trimTrial(List<int> trial) {
    if (trial.length <= 2 * trialTrimSampleCount) {
      throw ArgumentError.value(
        trial.length,
        'trial',
        'too short to trim 0.5 s from each end',
      );
    }
    return trial.sublist(
      trialTrimSampleCount,
      trial.length - trialTrimSampleCount,
    );
  }

  /// restMean + 0.4 x (gripLevel - restMean), rounded to an integer
  /// (halves round away from zero).
  static int thresholdFor(double restMean, double gripLevel) =>
      (restMean + thresholdFraction * (gripLevel - restMean)).round();

  /// [rest]: the rest samples. [trials]: each trial's samples, already
  /// trimmed with [trimTrial].
  static CalibrationResult compute({
    required List<int> rest,
    required List<List<int>> trials,
  }) {
    if (rest.isEmpty) throw ArgumentError.value(rest, 'rest', 'is empty');
    if (trials.isEmpty || trials.any((t) => t.isEmpty)) {
      throw ArgumentError.value(trials, 'trials', 'needs non-empty trials');
    }
    final restMean = mean(rest);
    final restSd = populationSd(rest);
    final gripLevel = median([for (final t in trials) mean(t)]);
    final valid =
        gripLevel >= restMean + 3 * restSd && gripLevel >= 1.5 * restMean;
    return CalibrationResult(
      restMean: restMean,
      restSd: restSd,
      gripLevel: gripLevel,
      threshold: thresholdFor(restMean, gripLevel),
      isValid: valid,
    );
  }

  static double mean(List<num> xs) =>
      xs.fold<double>(0, (a, b) => a + b) / xs.length;

  /// Population standard deviation (divides by n).
  static double populationSd(List<num> xs) {
    final m = mean(xs);
    final variance =
        xs.fold<double>(0, (a, b) => a + (b - m) * (b - m)) / xs.length;
    return math.sqrt(variance);
  }

  static double median(List<num> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid].toDouble() : (s[mid - 1] + s[mid]) / 2;
  }
}

class CalibrationResult {
  const CalibrationResult({
    required this.restMean,
    required this.restSd,
    required this.gripLevel,
    required this.threshold,
    required this.isValid,
  });

  final double restMean;
  final double restSd;
  final double gripLevel;
  final int threshold;

  /// False when rest and grip could not be told apart.
  final bool isValid;
}

/// A saved calibration. Contains signal levels and a time only: no names
/// and no medical information.
class Calibration {
  const Calibration({
    required this.restMean,
    required this.restSd,
    required this.gripLevel,
    required this.threshold,
    required this.timestamp,
  });

  factory Calibration.fromResult(CalibrationResult r, DateTime timestamp) =>
      Calibration(
        restMean: r.restMean,
        restSd: r.restSd,
        gripLevel: r.gripLevel,
        threshold: r.threshold,
        timestamp: timestamp,
      );

  static const validFor = Duration(hours: 24);

  final double restMean;
  final double restSd;
  final double gripLevel;
  final int threshold;
  final DateTime timestamp;

  bool isExpiredAt(DateTime now) => now.difference(timestamp) >= validFor;

  Map<String, Object> toJson() => {
    'restMean': restMean,
    'restSD': restSd,
    'gripLevel': gripLevel,
    'threshold': threshold,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  /// Returns null for missing or malformed data.
  static Calibration? fromJson(Map<String, Object?> json) {
    final restMean = json['restMean'];
    final restSd = json['restSD'];
    final gripLevel = json['gripLevel'];
    final threshold = json['threshold'];
    final timestamp = json['timestamp'];
    if (restMean is! num ||
        restSd is! num ||
        gripLevel is! num ||
        threshold is! int ||
        timestamp is! String) {
      return null;
    }
    final time = DateTime.tryParse(timestamp);
    if (time == null) return null;
    return Calibration(
      restMean: restMean.toDouble(),
      restSd: restSd.toDouble(),
      gripLevel: gripLevel.toDouble(),
      threshold: threshold,
      timestamp: time.toLocal(),
    );
  }
}
