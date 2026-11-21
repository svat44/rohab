import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/data/database.dart';
import 'package:rohab/data/exercise_session_repository.dart';

import 'helpers.dart';

final now = DateTime(2026, 11, 20, 12);

/// 14 sessions: 12 open_close, 1 finger_touches, 1 spread_fingers.
List<ExerciseSessionRecord> seed() => [
      // Twelve open_close sessions, one per day, oldest first; the 1st is 12
      // days ago and the 12th is today at 09:00.
      for (var i = 0; i < 12; i++)
        session(
          exercise: 'open_close',
          reps: i + 1,
          at: DateTime(2026, 11, 9 + i, 9),
        ),
      session(exercise: 'finger_touches', reps: 5, target: 5,
          at: DateTime(2026, 11, 18, 10)),
      session(exercise: 'spread_fingers', reps: 7,
          at: DateTime(2026, 11, 5, 10)), // outside the week
    ];

void main() {
  // The same behavior from the real database and the in-memory stand-in.
  final makers = <String, Future<ExerciseSessionRepository> Function()>{
    'drift': () async {
      final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
          closeStreamsSynchronously: true));
      addTearDown(db.close);
      return DriftExerciseSessionRepository(db);
    },
    'in memory': () async => InMemoryExerciseSessionRepository(),
  };

  for (final entry in makers.entries) {
    group('session queries (${entry.key})', () {
      late ExerciseSessionRepository repo;

      setUp(() async {
        repo = await entry.value();
        for (final r in seed()) {
          await repo.save(r);
        }
      });

      test('sessionsFor returns one exercise, newest first, with a limit',
          () async {
        final rows = await repo.sessionsFor('open_close', limit: 10);
        expect(rows, hasLength(10));
        expect(rows.every((r) => r.exerciseId == 'open_close'), isTrue);
        expect(rows.first.reps, 12, reason: 'newest');
        expect(rows.last.reps, 3, reason: 'tenth newest');
        for (var i = 1; i < rows.length; i++) {
          expect(rows[i - 1].startedAt.isAfter(rows[i].startedAt), isTrue);
        }
      });

      test('limit smaller than the data, and larger', () async {
        expect(await repo.sessionsFor('open_close', limit: 3), hasLength(3));
        expect(await repo.sessionsFor('open_close', limit: 50), hasLength(12));
        expect((await repo.sessionsFor('finger_touches')).single.reps, 5);
      });

      test('equal times are ordered newest saved first', () async {
        final t = DateTime(2026, 11, 20, 11);
        await repo.save(session(exercise: 'pinch', reps: 1, at: t));
        await repo.save(session(exercise: 'pinch', reps: 2, at: t));
        final rows = await repo.sessionsFor('pinch');
        expect(rows.map((r) => r.reps), [2, 1]);
      });

      test('weeklySummary counts the last 7 days across exercises', () async {
        final w = await repo.weeklySummary(now: now);
        // open_close on Nov 14-20 is 7 days: Nov 14 09:00 is within 7 days
        // of Nov 20 12:00 (6 d 3 h); Nov 13 09:00 is 7 d 3 h, outside.
        // Days Nov 14..20 are sessions i = 5..11 (reps 6..12) = 7 sessions,
        // plus finger_touches on Nov 18. spread_fingers (Nov 5) is outside.
        expect(w.sessions, 8);
        expect(w.reps, 6 + 7 + 8 + 9 + 10 + 11 + 12 + 5);
      });

      test('weeklySummary ignores sessions after now', () async {
        await repo.save(session(reps: 99, at: DateTime(2026, 11, 25)));
        final w = await repo.weeklySummary(now: now);
        expect(w.sessions, 8);
      });

      test('allSessions returns everything, oldest first', () async {
        final rows = await repo.allSessions();
        expect(rows, hasLength(14));
        for (var i = 1; i < rows.length; i++) {
          expect(rows[i - 1].startedAt.isAfter(rows[i].startedAt), isFalse);
        }
      });

      test('empty results', () async {
        expect(await repo.sessionsFor('hold_open'), isEmpty);
        final fresh = await entry.value();
        expect(await fresh.allSessions(), isEmpty);
        final w = await fresh.weeklySummary(now: now);
        expect((w.sessions, w.reps), (0, 0));
        expect(await fresh.sessionsFor('open_close'), isEmpty);
      });

      test('deleteAll removes every session', () async {
        await repo.deleteAll();
        expect(await repo.allSessions(), isEmpty);
        expect(await repo.sessionsFor('open_close'), isEmpty);
        // Still works afterwards.
        await repo.save(session(at: now));
        expect(await repo.allSessions(), hasLength(1));
      });
    });
  }
}
