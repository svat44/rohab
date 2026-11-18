import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'emg_calibrator.dart';

/// Stores the latest calibration on the device. Only signal levels, the
/// threshold and a timestamp are kept.
class CalibrationRepository {
  CalibrationRepository(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const storageKey = 'rohab.calibration.v1';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  Future<void> save(Calibration calibration) async {
    await _prefs.setString(storageKey, jsonEncode(calibration.toJson()));
  }

  /// The saved calibration, expired or not. Null if none or unreadable.
  Calibration? load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? Calibration.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  /// True when there is no calibration or it is older than 24 hours.
  bool isNeeded() {
    final c = load();
    return c == null || c.isExpiredAt(_clock());
  }

  /// The saved calibration if it is still within 24 hours.
  Calibration? loadValid() {
    final c = load();
    return c == null || c.isExpiredAt(_clock()) ? null : c;
  }
}
