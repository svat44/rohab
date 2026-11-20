import 'package:drift/drift.dart';

import 'database.dart';

/// A finished exercise, as saved.
class ExerciseSessionRecord {
  const ExerciseSessionRecord({
    required this.exerciseId,
    required this.mode,
    required this.reps,
    required this.targetReps,
    required this.rangeMin,
    required this.rangeMax,
    required this.durationSec,
    required this.startedAt,
    this.metricUnit = 'deg',
    this.avgAmplitude,
    this.avgPeakSpeed,
    this.avgSmoothness,
    this.fatigued = false,
  });

  final String exerciseId;
  final String mode;
  final int reps;
  final int targetReps;
  final double? rangeMin;
  final double? rangeMax;
  final int durationSec;
  final DateTime startedAt;

  /// "deg" or "%": the unit of the range and amplitude values.
  final String metricUnit;
  final double? avgAmplitude;
  final double? avgPeakSpeed;
  final double? avgSmoothness;
  final bool fatigued;
}

/// Saves and reads exercise sessions. Progress (next session) reads it.
abstract class ExerciseSessionRepository {
  Future<int> save(ExerciseSessionRecord record);

  Future<List<ExerciseSessionRow>> all();
}

class DriftExerciseSessionRepository implements ExerciseSessionRepository {
  DriftExerciseSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> save(ExerciseSessionRecord r) =>
      _db.into(_db.exerciseSessions).insert(ExerciseSessionsCompanion.insert(
            exerciseId: r.exerciseId,
            mode: Value(r.mode),
            reps: r.reps,
            targetReps: r.targetReps,
            rangeMin: Value(r.rangeMin),
            rangeMax: Value(r.rangeMax),
            durationSec: r.durationSec,
            startedAt: r.startedAt,
            metricUnit: Value(r.metricUnit),
            avgAmplitude: Value(r.avgAmplitude),
            avgPeakSpeed: Value(r.avgPeakSpeed),
            avgSmoothness: Value(r.avgSmoothness),
            fatigued: Value(r.fatigued),
          ));

  @override
  Future<List<ExerciseSessionRow>> all() => (_db.select(_db.exerciseSessions)
        ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
      .get();
}

/// Keeps sessions in memory only. Used where there is no SQLite (the web
/// preview).
class InMemoryExerciseSessionRepository implements ExerciseSessionRepository {
  final List<ExerciseSessionRow> _rows = [];

  @override
  Future<int> save(ExerciseSessionRecord r) async {
    final id = _rows.length + 1;
    _rows.add(ExerciseSessionRow(
      id: id,
      exerciseId: r.exerciseId,
      mode: r.mode,
      reps: r.reps,
      targetReps: r.targetReps,
      rangeMin: r.rangeMin,
      rangeMax: r.rangeMax,
      durationSec: r.durationSec,
      startedAt: r.startedAt,
      metricUnit: r.metricUnit,
      avgAmplitude: r.avgAmplitude,
      avgPeakSpeed: r.avgPeakSpeed,
      avgSmoothness: r.avgSmoothness,
      fatigued: r.fatigued,
    ));
    return id;
  }

  @override
  Future<List<ExerciseSessionRow>> all() async => List.of(_rows);
}
