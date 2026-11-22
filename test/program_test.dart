import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/handedness.dart';
import 'package:rohab/exercises/exercise_catalog.dart';
import 'package:rohab/program/baseline.dart';
import 'package:rohab/program/daily_plan.dart';
import 'package:rohab/program/pain.dart';
import 'package:rohab/program/program_settings.dart';
import 'package:rohab/program/therapist_pin.dart';

const s = ProgramSettings.defaults;

void main() {
  group('catalog', () {
    test('three levels, at most 4 steps each, unique ids', () {
      for (final level in [1, 2, 3]) {
        expect(ExerciseCatalog.forLevel(level), isNotEmpty);
      }
      for (final e in ExerciseCatalog.all) {
        expect(e.steps.length, lessThanOrEqualTo(4), reason: e.id);
      }
      final ids = ExerciseCatalog.all.map((e) => e.id).toSet();
      expect(ids.length, ExerciseCatalog.all.length);
      // Ids saved by earlier versions still resolve.
      for (final id in ['open_close', 'finger_touches', 'spread_fingers']) {
        expect(ExerciseCatalog.byId(id), isNotNull);
      }
    });
  });

  group('level placement', () {
    const normal = HandRange(open: 5, closed: 255); // 250 degrees

    test('little movement is level 1 and camera-limited', () {
      final r = LevelPlacement.result(
        affectedHand: Handedness.right,
        affected: const HandRange(open: 150, closed: 170),
        other: normal,
        takenAt: DateTime(2026, 11, 20),
      );
      expect(r.level, 1);
      expect(r.cameraLimited, isTrue);
    });

    test('fingers that cannot straighten put you at level 1', () {
      expect(LevelPlacement.place(
          const HandRange(open: 130, closed: 250), normal), 1);
    });

    test('under half the other hand is level 1', () {
      expect(LevelPlacement.place(
          const HandRange(open: 60, closed: 170), normal), 1); // 110/250
    });

    test('half to 85 % is level 2', () {
      expect(LevelPlacement.place(
          const HandRange(open: 40, closed: 220), normal), 2); // 180/250
    });

    test('85 % or more is level 3', () {
      expect(LevelPlacement.place(
          const HandRange(open: 10, closed: 235), normal), 3); // 225/250
    });

    test('without the other hand a typical range stands in', () {
      expect(LevelPlacement.place(
          const HandRange(open: 20, closed: 250), null), 3); // 230/260
      expect(LevelPlacement.place(
          const HandRange(open: 50, closed: 200), null), 2); // 150/260
    });

    test('a measurement is due again after 7 days', () {
      final r = LevelPlacement.result(
        affectedHand: Handedness.left,
        affected: normal,
        takenAt: DateTime(2026, 11, 1),
      );
      expect(r.isDueAt(DateTime(2026, 11, 7)), isFalse);
      expect(r.isDueAt(DateTime(2026, 11, 8)), isTrue);
    });
  });

  group('daily plan', () {
    test('level 1 plans three level-1 exercises, rotating by day', () {
      final p = DailyPlan.build(
          level: 1, goal: 90, settings: s, dayNumber: 0, doneById: {});
      expect(p.items.map((i) => i.exercise.level).toSet(), {1});
      expect(p.items, hasLength(3));
      // Holds use half-size sets and count double toward the goal.
      final hold = p.items.firstWhere((i) => i.exercise.id == 'hold_open');
      expect(hold.setSize, 5);
      expect(p.plannedTotal, 90);
      final next = DailyPlan.build(
          level: 1, goal: 90, settings: s, dayNumber: 1, doneById: {});
      expect(next.items.map((i) => i.exercise.id),
          isNot(equals(p.items.map((i) => i.exercise.id))));
    });

    test('level 2 rotates three of its exercises by day', () {
      final a = DailyPlan.build(
          level: 2, goal: 90, settings: s, dayNumber: 0, doneById: {});
      final b = DailyPlan.build(
          level: 2, goal: 90, settings: s, dayNumber: 1, doneById: {});
      expect(a.items, hasLength(3));
      expect(a.items.map((i) => i.exercise.id),
          isNot(equals(b.items.map((i) => i.exercise.id))));
      // 90 reps over 3 exercises in sets of 10: 3 sets each.
      expect(a.items.first.sets, 3);
      expect(a.plannedTotal, 90);
    });

    test('next is the first unfinished exercise; done is capped', () {
      final p = DailyPlan.build(
          level: 2,
          goal: 60,
          settings: s,
          dayNumber: 0,
          doneById: {'open_close': 25});
      expect(p.items.first.exercise.id, 'open_close');
      expect(p.items.first.complete, isTrue);
      expect(p.items.first.setsDone, 2);
      expect(p.next!.exercise.id, isNot('open_close'));
      expect(p.doneTotal, 20);
    });
  });

  group('goal progression', () {
    test('met without fatigue: up 10 %, rounded to 10', () {
      expect(GoalProgression.next(100,
          const DayOutcome(goal: 100, reps: 100, fatigued: false, painRose: false), s), 110);
      expect(GoalProgression.next(115,
          const DayOutcome(goal: 115, reps: 120, fatigued: false, painRose: false), s), 130);
    });

    test('capped at the maximum', () {
      expect(GoalProgression.next(290,
          const DayOutcome(goal: 290, reps: 300, fatigued: false, painRose: false), s), 300);
    });

    test('fatigue or a missed goal holds it', () {
      expect(GoalProgression.next(100,
          const DayOutcome(goal: 100, reps: 100, fatigued: true, painRose: false), s), 100);
      expect(GoalProgression.next(100,
          const DayOutcome(goal: 100, reps: 60, fatigued: false, painRose: false), s), 100);
    });

    test('rising pain lowers it, not below the minimum', () {
      expect(GoalProgression.next(100,
          const DayOutcome(goal: 100, reps: 100, fatigued: false, painRose: true), s), 90);
      expect(GoalProgression.next(20,
          const DayOutcome(goal: 20, reps: 20, fatigued: false, painRose: true), s), 20);
    });

    test('off when the therapist turns it off', () {
      expect(GoalProgression.next(100,
          const DayOutcome(goal: 100, reps: 100, fatigued: false, painRose: false),
          s.copyWith(autoProgress: false)), 100);
    });
  });

  group('pain rules', () {
    test('high pain before advises rest', () {
      expect(PainRules.before(7, s), PainAdvice.restToday);
      expect(PainRules.before(6, s), PainAdvice.ok);
    });

    test('a rise of 2 or more is a warning', () {
      expect(PainRules.after(2, 4, s), PainAdvice.painRose);
      expect(PainRules.after(2, 3, s), PainAdvice.ok);
      expect(PainRules.after(5, 2, s), PainAdvice.ok);
    });
  });

  group('settings', () {
    test('round-trip through JSON, including no level override', () {
      final t = s.copyWith(levelOverride: () => 2, setSize: 15, autoProgress: false);
      final back = ProgramSettings.fromJson(t.toJson());
      expect(back.levelOverride, 2);
      expect(back.setSize, 15);
      expect(back.autoProgress, isFalse);
      expect(ProgramSettings.fromJson(s.toJson()).levelOverride, isNull);
    });
  });

  group('therapist PIN', () {
    test('4 digits only', () {
      expect(TherapistPin.isValid('1234'), isTrue);
      expect(TherapistPin.isValid('123'), isFalse);
      expect(TherapistPin.isValid('12a4'), isFalse);
    });

    test('matches only the same PIN', () {
      final h = TherapistPin.hash('2468');
      expect(TherapistPin.matches('2468', h), isTrue);
      expect(TherapistPin.matches('2469', h), isFalse);
      expect(TherapistPin.matches('2468', null), isFalse);
    });
  });
}
