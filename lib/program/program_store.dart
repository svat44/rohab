import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'program_settings.dart';

/// Therapist settings, PIN hash and today's goal, on this device.
class ProgramStore {
  ProgramStore(this._prefs);

  static const settingsKey = 'rohab.program.settings.v1';
  static const pinKey = 'rohab.program.pinHash.v1';
  static const goalKey = 'rohab.program.goal.v1';

  final SharedPreferences _prefs;

  ProgramSettings loadSettings() {
    final raw = _prefs.getString(settingsKey);
    if (raw == null) return ProgramSettings.defaults;
    try {
      final j = jsonDecode(raw);
      return j is Map<String, Object?>
          ? ProgramSettings.fromJson(j)
          : ProgramSettings.defaults;
    } on FormatException {
      return ProgramSettings.defaults;
    }
  }

  Future<void> saveSettings(ProgramSettings s) =>
      _prefs.setString(settingsKey, jsonEncode(s.toJson()));

  String? get pinHash => _prefs.getString(pinKey);

  Future<void> savePinHash(String hash) => _prefs.setString(pinKey, hash);

  /// The current daily goal and the day it was set ("yyyy-mm-dd").
  ({int goal, String date})? loadGoal() {
    final raw = _prefs.getString(goalKey);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return (goal: j['goal'] as int, date: j['date'] as String);
    } on Object {
      return null;
    }
  }

  Future<void> saveGoal(int goal, DateTime day) => _prefs.setString(
    goalKey,
    jsonEncode({'goal': goal, 'date': dayKey(day)}),
  );

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
