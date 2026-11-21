/// Tracking diagnostics for on-phone testing. Debug builds only.
///
/// Keeps counts and timings. Never landmarks, images or video, and nothing
/// is written to disk.
library;

import 'package:flutter/foundation.dart';

import '../camera/hand_tracker.dart';

/// Counters at one moment, for measuring a run as the difference between
/// two snapshots.
class DiagnosticsSnapshot {
  const DiagnosticsSnapshot({
    required this.at,
    required this.results,
    required this.confident,
    required this.dropouts,
  });

  final Duration at;

  /// Tracker results so far, with a hand or not.
  final int results;

  /// Frames with a hand at confidence of at least [HandFrame.minConfidence].
  final int confident;

  /// Dropouts longer than [DiagnosticsCollector.dropoutMin] so far.
  final int dropouts;
}

/// One measured run (for example, 30 s of one pose).
class RunSummary {
  const RunSummary({
    required this.seconds,
    required this.avgFps,
    required this.detectionPercent,
    required this.dropouts,
  });

  factory RunSummary.between(DiagnosticsSnapshot a, DiagnosticsSnapshot b) {
    final seconds = (b.at - a.at).inMicroseconds / 1e6;
    final results = b.results - a.results;
    return RunSummary(
      seconds: seconds,
      avgFps: seconds > 0 ? results / seconds : 0,
      detectionPercent:
          results > 0 ? ((b.confident - a.confident) / results * 100).clamp(0, 100).toDouble() : 0,
      dropouts: b.dropouts - a.dropouts,
    );
  }

  final double seconds;
  final double avgFps;

  /// Share of tracker results that were confident frames.
  final double detectionPercent;

  /// Gaps with no confident frame, longer than 0.5 s.
  final int dropouts;
}

class DiagnosticsCollector extends ChangeNotifier {
  DiagnosticsCollector({this.log = false});

  static const window = Duration(seconds: 10);
  static const dropoutMin = Duration(milliseconds: 500);
  static const _notifyEvery = Duration(milliseconds: 500);

  /// Print a line to the console about once a second.
  final bool log;

  /// Extra text for the overlay and log: openness and rep state.
  String Function()? extra;

  int _results = 0;
  int _confident = 0;
  int _dropouts = 0;
  bool _inDropout = false;
  Duration? _lastConfident;
  Duration _start = Duration.zero;
  bool _started = false;
  Duration _lastNotify = Duration.zero;
  Duration _lastLog = Duration.zero;
  final List<DiagnosticsSnapshot> _samples = [];

  /// Results per second over the last second.
  double fps = 0;

  /// Confident frames as a share of results, over the last 10 s.
  double detectionPercent = 0;

  /// Time since the last confident frame, when it is over half a second.
  Duration dropout = Duration.zero;

  /// A confident frame arrived.
  void onFrame(HandFrame frame, Duration now) {
    if (!frame.isUsable) return;
    _confident++;
    _lastConfident = now;
    if (_inDropout) {
      _inDropout = false;
      dropout = Duration.zero;
    }
  }

  /// Call regularly (every tick) with the tracker's running result count.
  void tick(Duration now, int resultsTotal) {
    if (!_started) {
      _started = true;
      _start = now;
    }
    _results = resultsTotal;
    final gap = now - (_lastConfident ?? _start);
    if (gap > dropoutMin) {
      dropout = gap;
      if (!_inDropout) {
        _inDropout = true;
        _dropouts++;
      }
    }
    final s = snapshot(now);
    _samples.add(s);
    while (_samples.length > 1 && now - _samples.first.at > window) {
      _samples.removeAt(0);
    }
    final oneSecond = _samples.lastWhere(
      (x) => now - x.at >= const Duration(seconds: 1),
      orElse: () => _samples.first,
    );
    final span = (now - oneSecond.at).inMicroseconds / 1e6;
    fps = span > 0 ? (s.results - oneSecond.results) / span : 0;
    final first = _samples.first;
    final results = s.results - first.results;
    detectionPercent = results > 0
        ? ((s.confident - first.confident) / results * 100).clamp(0, 100).toDouble()
        : 0;
    if (now - _lastNotify >= _notifyEvery) {
      _lastNotify = now;
      notifyListeners();
    }
    if (log && now - _lastLog >= const Duration(seconds: 1)) {
      _lastLog = now;
      debugPrint('[diag] ${describe()}');
    }
  }

  DiagnosticsSnapshot snapshot(Duration now) => DiagnosticsSnapshot(
        at: now,
        results: _results,
        confident: _confident,
        dropouts: _dropouts,
      );

  /// One line, for the log.
  String describe() => 'fps=${fps.toStringAsFixed(1)} '
      'detect10s=${detectionPercent.toStringAsFixed(0)}% '
      'dropout=${(dropout.inMilliseconds / 1000).toStringAsFixed(1)}s'
      '${extra == null ? '' : ' ${extra!()}'}';
}
