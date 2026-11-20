import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';

void main() {
  test('saves and reads a session with numbers only', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftExerciseSessionRepository(db);
    final id = await repo.save(ExerciseSessionRecord(
      exerciseId: 'open_close',
      mode: 'camera',
      reps: 10,
      targetReps: 10,
      rangeMin: 18,
      rangeMax: 94,
      durationSec: 42,
      startedAt: DateTime(2026, 11, 20, 9),
    ));
    final rows = await repo.all();
    expect(rows, hasLength(1));
    expect(rows.single.id, id);
    expect(rows.single.reps, 10);
    expect(rows.single.mode, 'camera');
    expect(rows.single.rangeMax, 94);
    // The table has only these columns: no media, no landmarks.
    expect(db.exerciseSessions.$columns.map((c) => c.name).toSet(), {
      'id', 'exercise_id', 'mode', 'reps', 'target_reps', 'range_min',
      'range_max', 'duration_sec', 'started_at',
    });
  });
}
