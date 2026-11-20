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

  /// Smallest and largest openness (or spread) %, 0-100. Null if the hand
  /// was never measured.
  RealColumn get rangeMin => real().nullable()();
  RealColumn get rangeMax => real().nullable()();
  IntColumn get durationSec => integer()();
  DateTimeColumn get startedAt => dateTime()();
}

@DriftDatabase(tables: [ExerciseSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
