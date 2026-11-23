import 'package:drift/drift.dart';

import '../program/date_range.dart';
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
    this.compensatedReps = 0,
    this.level,
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
  final int compensatedReps;
  final int? level;
}

/// Sessions and reps in the last 7 days.
class WeeklySummary {
  const WeeklySummary({required this.sessions, required this.reps});

  final int sessions;
  final int reps;
}

/// Saves and reads exercise sessions. Progress reads it.
abstract class ExerciseSessionRepository {
  Future<int> save(ExerciseSessionRecord record);

  /// Every session, oldest first.
  Future<List<ExerciseSessionRow>> all();

  /// Every session, oldest first. Same as [all]; named for the Progress
  /// screen.
  Future<List<ExerciseSessionRow>> allSessions() => all();

  /// The newest [limit] sessions of one exercise, newest first.
  Future<List<ExerciseSessionRow>> sessionsFor(
    String exerciseId, {
    int limit = 10,
  }) async {
    final rows = [
      for (final r in await all())
        if (r.exerciseId == exerciseId) r,
    ]..sort(_newestFirst);
    return rows.take(limit).toList();
  }

  /// Sessions and reps started in the 7 days up to [now].
  Future<WeeklySummary> weeklySummary({DateTime? now}) async {
    final end = now ?? DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    var sessions = 0, reps = 0;
    for (final r in await all()) {
      if (r.startedAt.isAfter(start) && !r.startedAt.isAfter(end)) {
        sessions++;
        reps += r.reps;
      }
    }
    return WeeklySummary(sessions: sessions, reps: reps);
  }

  /// Sessions started inside [range] (local time), newest first, for one
  /// exercise or all of them. The Progress screen's only data source: change
  /// the range and every number changes with it.
  Future<List<ExerciseSessionRow>> sessionsIn(
    DateRange range, {
    String? exerciseId,
  }) async {
    final rows = [
      for (final r in await all())
        if (range.contains(r.startedAt) &&
            (exerciseId == null || r.exerciseId == exerciseId))
          r,
    ]..sort(_newestFirst);
    return rows;
  }

  /// Sessions, reps and practice days in [range].
  Future<RangeSummary> summaryIn(DateRange range, {String? exerciseId}) async =>
      summarize([
        for (final r in await sessionsIn(range, exerciseId: exerciseId))
          (startedAt: r.startedAt, reps: r.reps),
      ], range);

  /// Deletes every saved session. Nothing else is touched.
  Future<void> deleteAll();

  static int _newestFirst(ExerciseSessionRow a, ExerciseSessionRow b) {
    final c = b.startedAt.compareTo(a.startedAt);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  /// Sessions started on the local day of [day].
  Future<List<ExerciseSessionRow>> on(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return [
      for (final r in await all())
        if (!r.startedAt.isBefore(start) && r.startedAt.isBefore(end)) r,
    ];
  }

  /// The most recent day before [day] with any session, if any.
  Future<DateTime?> lastDayBefore(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    DateTime? last;
    for (final r in await all()) {
      if (r.startedAt.isBefore(start) &&
          (last == null || r.startedAt.isAfter(last))) {
        last = r.startedAt;
      }
    }
    return last == null ? null : DateTime(last.year, last.month, last.day);
  }
}

class DriftExerciseSessionRepository extends ExerciseSessionRepository {
  DriftExerciseSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> save(ExerciseSessionRecord r) => _db
      .into(_db.exerciseSessions)
      .insert(
        ExerciseSessionsCompanion.insert(
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
          compensatedReps: Value(r.compensatedReps),
          level: Value(r.level),
        ),
      );

  @override
  Future<List<ExerciseSessionRow>> all() => (_db.select(
    _db.exerciseSessions,
  )..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).get();

  @override
  Future<List<ExerciseSessionRow>> sessionsFor(
    String exerciseId, {
    int limit = 10,
  }) =>
      (_db.select(_db.exerciseSessions)
            ..where((s) => s.exerciseId.equals(exerciseId))
            ..orderBy([
              (s) => OrderingTerm.desc(s.startedAt),
              (s) => OrderingTerm.desc(s.id),
            ])
            ..limit(limit))
          .get();

  @override
  Future<void> deleteAll() => _db.delete(_db.exerciseSessions).go();
}

/// Keeps sessions in memory only. Used where there is no SQLite (the web
/// preview).
class InMemoryExerciseSessionRepository extends ExerciseSessionRepository {
  final List<ExerciseSessionRow> _rows = [];

  @override
  Future<int> save(ExerciseSessionRecord r) async {
    final id = _rows.length + 1;
    _rows.add(
      ExerciseSessionRow(
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
        compensatedReps: r.compensatedReps,
        level: r.level,
      ),
    );
    return id;
  }

  @override
  Future<List<ExerciseSessionRow>> all() async => List.of(_rows)
    ..sort((a, b) {
      final c = a.startedAt.compareTo(b.startedAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  @override
  Future<void> deleteAll() async => _rows.clear();
}
