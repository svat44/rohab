import 'package:drift/drift.dart';

part 'database.g.dart';

/// One finished exercise. Numbers only: never video, images or landmarks.
@DataClassName('ExerciseSessionRow')
class ExerciseSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable id from the exercise catalog, e.g. "open_close".
  TextColumn get exerciseId => text()();

  /// "camera" now; glove modes later.
  TextColumn get mode => text().withDefault(const Constant('camera'))();
  IntColumn get reps => integer()();
  IntColumn get targetReps => integer()();

  /// Smallest and largest value reached, in [metricUnit]: finger bend in
  /// degrees (mean MCP + PIP + DIP) or spread %. Null if never measured.
  RealColumn get rangeMin => real().nullable()();
  RealColumn get rangeMax => real().nullable()();

  /// "deg" or "%". Added in schema 2; older rows were openness %.
  TextColumn get metricUnit => text().withDefault(const Constant('%'))();

  /// Per-rep averages (schema 2): movement size in [metricUnit], peak
  /// speed in [metricUnit] per second, SPARC smoothness (closer to 0 is
  /// smoother).
  RealColumn get avgAmplitude => real().nullable()();
  RealColumn get avgPeakSpeed => real().nullable()();
  RealColumn get avgSmoothness => real().nullable()();

  /// Later reps were clearly smaller than the first (schema 2).
  BoolColumn get fatigued => boolean().withDefault(const Constant(false))();
  IntColumn get durationSec => integer()();
  DateTimeColumn get startedAt => dateTime()();
}

@DriftDatabase(tables: [ExerciseSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(exerciseSessions, exerciseSessions.metricUnit);
            await m.addColumn(exerciseSessions, exerciseSessions.avgAmplitude);
            await m.addColumn(exerciseSessions, exerciseSessions.avgPeakSpeed);
            await m.addColumn(exerciseSessions, exerciseSessions.avgSmoothness);
            await m.addColumn(exerciseSessions, exerciseSessions.fatigued);
          }
        },
      );
}
