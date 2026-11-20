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

  /// Reps not counted because the wrist moved instead (schema 3).
  IntColumn get compensatedReps => integer().withDefault(const Constant(0))();

  /// Program level when done, 1-3 (schema 3). Null for free practice.
  IntColumn get level => integer().nullable()();
}

/// A hand measurement that sets the level (schema 3). Degrees of finger
/// bend (mean MCP + PIP + DIP) at the most open and most closed.
@DataClassName('AssessmentRow')
class Assessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get takenAt => dateTime()();

  /// "left" or "right".
  TextColumn get affectedHand => text()();
  RealColumn get affectedOpen => real()();
  RealColumn get affectedClosed => real()();
  RealColumn get otherOpen => real().nullable()();
  RealColumn get otherClosed => real().nullable()();
  IntColumn get level => integer()();
  BoolColumn get cameraLimited => boolean()();
}

/// Pain 0-10 before and after practice (schema 3).
@DataClassName('PainCheckRow')
class PainChecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();

  /// "before" or "after".
  TextColumn get phase => text()();
  IntColumn get score => integer()();
}

@DriftDatabase(tables: [ExerciseSessions, Assessments, PainChecks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

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
          if (from < 3) {
            await m.addColumn(
                exerciseSessions, exerciseSessions.compensatedReps);
            await m.addColumn(exerciseSessions, exerciseSessions.level);
            await m.createTable(assessments);
            await m.createTable(painChecks);
          }
        },
      );
}
