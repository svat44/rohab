/// Signal processing and movement quality for hand exercises. Pure Dart.
library;

import 'dart:math' as math;

/// One Euro filter (Casiez et al., CHI 2012): smooths jittery tracking
/// while keeping fast movements responsive. The cutoff rises with speed,
/// so slow holds are smoothed hard and quick moves lag little.
///
/// Defaults are for joint angles in degrees.
class OneEuroFilter {
  OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.004, this.dCutoff = 1.0});

  /// Hz. Lower = smoother when still.
  final double minCutoff;

  /// Speed coefficient. Higher = less lag when moving.
  final double beta;
  final double dCutoff;

  double? _x;
  double _dx = 0;
  Duration? _t;

  double? get value => _x;

  double filter(double x, Duration t) {
    final prev = _x;
    final prevT = _t;
    _t = t;
    if (prev == null || prevT == null) {
      _x = x;
      return x;
    }
    final dt = (t - prevT).inMicroseconds / 1e6;
    if (dt <= 0) return prev;
    final rawDx = (x - prev) / dt;
    _dx = _lowPass(_dx, rawDx, _alpha(dCutoff, dt));
    final cutoff = minCutoff + beta * _dx.abs();
    return _x = _lowPass(prev, x, _alpha(cutoff, dt));
  }

  void reset() {
    _x = null;
    _t = null;
    _dx = 0;
  }

  static double _alpha(double cutoff, double dt) {
    final tau = 1 / (2 * math.pi * cutoff);
    return 1 / (1 + tau / dt);
  }

  static double _lowPass(double prev, double x, double a) => prev + a * (x - prev);
}

/// SPARC, spectral arc length (Balasubramanian et al. 2012, 2015): the
/// smoothness measure validated for stroke reach-to-grasp. Always negative;
/// closer to 0 is smoother. A single smooth bell-shaped movement scores
/// about -1.4; jerky movements with several speed peaks score lower.
///
/// [speed] is the speed profile (any unit), sampled at [sampleRateHz].
double sparc(
  List<double> speed, {
  required double sampleRateHz,
  int padLevel = 4,
  double cutoffHz = 10,
  double amplitudeThreshold = 0.05,
}) {
  if (speed.length < 3) return double.nan;
  final n = speed.length;
  final nfft = 1 << ((math.log(n) / math.ln2).ceil() + padLevel);
  final df = sampleRateHz / nfft;
  final maxBin = math.min((cutoffHz / df).floor(), nfft - 1);

  // Magnitude spectrum up to the cutoff (direct DFT: n is small).
  final mag = List<double>.filled(maxBin + 1, 0);
  for (var k = 0; k <= maxBin; k++) {
    var re = 0.0, im = 0.0;
    final w = -2 * math.pi * k / nfft;
    for (var i = 0; i < n; i++) {
      re += speed[i] * math.cos(w * i);
      im += speed[i] * math.sin(w * i);
    }
    mag[k] = math.sqrt(re * re + im * im);
  }
  final peak = mag.reduce(math.max);
  if (peak == 0) return double.nan;
  for (var k = 0; k < mag.length; k++) {
    mag[k] /= peak;
  }

  // Adaptive cutoff: keep the band between the first and last bins above
  // the threshold.
  var first = 0, last = 0;
  for (var k = 0; k < mag.length; k++) {
    if (mag[k] >= amplitudeThreshold) {
      last = k;
    }
  }
  for (var k = 0; k < mag.length; k++) {
    if (mag[k] >= amplitudeThreshold) {
      first = k;
      break;
    }
  }
  if (last <= first) return 0;
  final span = (last - first) * df;
  var length = 0.0;
  for (var k = first + 1; k <= last; k++) {
    final dfn = df / span;
    final dm = mag[k] - mag[k - 1];
    length += math.sqrt(dfn * dfn + dm * dm);
  }
  return -length;
}

/// Measurements of one counted repetition.
class RepStats {
  const RepStats({
    required this.amplitude,
    required this.duration,
    required this.peakSpeed,
    required this.smoothness,
  });

  /// Largest minus smallest value during the rep (degrees of closure).
  final double amplitude;
  final Duration duration;

  /// Degrees per second.
  final double peakSpeed;

  /// SPARC. Closer to 0 is smoother.
  final double smoothness;
}

/// Collects samples between rep boundaries and measures each rep.
class RepRecorder {
  final List<double> _values = [];
  final List<Duration> _times = [];

  void add(double value, Duration t) {
    _values.add(value);
    _times.add(t);
  }

  /// Measures the samples since the last call, then starts afresh from the
  /// current sample (one rep's end is the next rep's start).
  RepStats? close() {
    if (_values.length < 3) return null;
    final duration = _times.last - _times.first;
    final secs = duration.inMicroseconds / 1e6;
    final rate = secs > 0 ? (_values.length - 1) / secs : 30.0;
    final speeds = <double>[];
    for (var i = 1; i < _values.length; i++) {
      final dt = (_times[i] - _times[i - 1]).inMicroseconds / 1e6;
      speeds.add(dt > 0 ? (_values[i] - _values[i - 1]).abs() / dt : 0);
    }
    final stats = RepStats(
      amplitude: _values.reduce(math.max) - _values.reduce(math.min),
      duration: duration,
      peakSpeed: speeds.reduce(math.max),
      smoothness: sparc(speeds, sampleRateHz: rate),
    );
    final lastV = _values.last, lastT = _times.last;
    _values
      ..clear()
      ..add(lastV);
    _times
      ..clear()
      ..add(lastT);
    return stats;
  }

  void reset() {
    _values.clear();
    _times.clear();
  }
}

/// Measures every movement swing, counted or not: each time the signal
/// turns back by more than [deadband], the distance from the previous
/// turning point is one excursion. Fatigue shows up in attempts that are
/// too small to count, so it must be measured on all of them.
class ExcursionTracker {
  ExcursionTracker({required this.deadband});

  /// Smaller wiggles are treated as noise (same unit as the signal).
  final double deadband;

  int _dir = 0;
  double? _turn;
  double? _extreme;

  /// Returns the completed excursion when a turn is confirmed, else null.
  double? update(double v) {
    final turn = _turn, ext = _extreme;
    if (turn == null || ext == null) {
      _turn = _extreme = v;
      return null;
    }
    switch (_dir) {
      case 0:
        if ((v - turn).abs() > deadband) {
          _dir = v > turn ? 1 : -1;
          _extreme = v;
        }
      case 1:
        if (v > ext) {
          _extreme = v;
        } else if (ext - v > deadband) {
          _turn = ext;
          _extreme = v;
          _dir = -1;
          return ext - turn;
        }
      default:
        if (v < ext) {
          _extreme = v;
        } else if (v - ext > deadband) {
          _turn = ext;
          _extreme = v;
          _dir = 1;
          return turn - ext;
        }
    }
    return null;
  }

  void reset() {
    _dir = 0;
    _turn = null;
    _extreme = null;
  }
}

/// Flags fatigue when recent movement swings are clearly smaller than the
/// first ones, a sign the movement is degrading and a rest would help.
class FatigueMonitor {
  FatigueMonitor({this.window = 6, this.dropRatio = 0.7});

  final int window;

  /// Recent mean below this fraction of the opening mean = fatigued.
  final double dropRatio;

  final List<double> _amplitudes = [];

  void add(double amplitude) => _amplitudes.add(amplitude);

  bool get isFatigued {
    if (_amplitudes.length < window * 2) return false;
    double mean(Iterable<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
    final opening = mean(_amplitudes.take(window));
    final recent = mean(_amplitudes.skip(_amplitudes.length - window));
    return opening > 0 && recent < opening * dropRatio;
  }

  void reset() => _amplitudes.clear();
}
