import 'package:drift/drift.dart';

import '../camera/handedness.dart';
import '../program/baseline.dart';
import 'database.dart';

/// Hand measurements and pain checks. Numbers only.
abstract class ProgramRepository {
  Future<void> saveBaseline(BaselineResult r);
  Future<BaselineResult?> latestBaseline();
  Future<void> savePain(DateTime at, String phase, int score);

  /// Pain checks on the local day of [day], oldest first.
  Future<List<PainCheckRow>> painOn(DateTime day);
}

DateTime dayStart(DateTime t) => DateTime(t.year, t.month, t.day);

BaselineResult _fromRow(AssessmentRow r) => BaselineResult(
  affectedHand: r.affectedHand == 'left' ? Handedness.left : Handedness.right,
  affected: HandRange(open: r.affectedOpen, closed: r.affectedClosed),
  other: r.otherOpen == null || r.otherClosed == null
      ? null
      : HandRange(open: r.otherOpen!, closed: r.otherClosed!),
  level: r.level,
  cameraLimited: r.cameraLimited,
  takenAt: r.takenAt,
);

class DriftProgramRepository implements ProgramRepository {
  DriftProgramRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveBaseline(BaselineResult r) => _db
      .into(_db.assessments)
      .insert(
        AssessmentsCompanion.insert(
          takenAt: r.takenAt,
          affectedHand: r.affectedHand == Handedness.left ? 'left' : 'right',
          affectedOpen: r.affected.open,
          affectedClosed: r.affected.closed,
          otherOpen: Value(r.other?.open),
          otherClosed: Value(r.other?.closed),
          level: r.level,
          cameraLimited: r.cameraLimited,
        ),
      );

  @override
  Future<BaselineResult?> latestBaseline() async {
    final row =
        await (_db.select(_db.assessments)
              ..orderBy([(a) => OrderingTerm.desc(a.takenAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> savePain(DateTime at, String phase, int score) => _db
      .into(_db.painChecks)
      .insert(PainChecksCompanion.insert(at: at, phase: phase, score: score));

  @override
  Future<List<PainCheckRow>> painOn(DateTime day) {
    final start = dayStart(day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.painChecks)
          ..where(
            (p) =>
                p.at.isBiggerOrEqualValue(start) & p.at.isSmallerThanValue(end),
          )
          ..orderBy([(p) => OrderingTerm.asc(p.at)]))
        .get();
  }
}

/// In memory only, where there is no SQLite (the web preview).
class InMemoryProgramRepository implements ProgramRepository {
  final List<BaselineResult> _baselines = [];
  final List<PainCheckRow> _pain = [];

  @override
  Future<void> saveBaseline(BaselineResult r) async => _baselines.add(r);

  @override
  Future<BaselineResult?> latestBaseline() async =>
      _baselines.isEmpty ? null : _baselines.last;

  @override
  Future<void> savePain(DateTime at, String phase, int score) async =>
      _pain.add(
        PainCheckRow(id: _pain.length + 1, at: at, phase: phase, score: score),
      );

  @override
  Future<List<PainCheckRow>> painOn(DateTime day) async => [
    for (final p in _pain)
      if (dayStart(p.at) == dayStart(day)) p,
  ];
}
