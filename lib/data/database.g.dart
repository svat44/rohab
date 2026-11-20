// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ExerciseSessionsTable extends ExerciseSessions
    with TableInfo<$ExerciseSessionsTable, ExerciseSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('camera'),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeMinMeta = const VerificationMeta(
    'rangeMin',
  );
  @override
  late final GeneratedColumn<double> rangeMin = GeneratedColumn<double>(
    'range_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeMaxMeta = const VerificationMeta(
    'rangeMax',
  );
  @override
  late final GeneratedColumn<double> rangeMax = GeneratedColumn<double>(
    'range_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    mode,
    reps,
    targetReps,
    rangeMin,
    rangeMax,
    durationSec,
    startedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('range_min')) {
      context.handle(
        _rangeMinMeta,
        rangeMin.isAcceptableOrUnknown(data['range_min']!, _rangeMinMeta),
      );
    }
    if (data.containsKey('range_max')) {
      context.handle(
        _rangeMaxMeta,
        rangeMax.isAcceptableOrUnknown(data['range_max']!, _rangeMaxMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
      rangeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}range_min'],
      ),
      rangeMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}range_max'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  $ExerciseSessionsTable createAlias(String alias) {
    return $ExerciseSessionsTable(attachedDatabase, alias);
  }
}

class ExerciseSessionRow extends DataClass
    implements Insertable<ExerciseSessionRow> {
  final int id;

  /// Stable id from the exercise catalog, e.g. "open_close".
  final String exerciseId;

  /// "camera" now; glove modes later.
  final String mode;
  final int reps;
  final int targetReps;

  /// Smallest and largest openness (or spread) %, 0-100. Null if the hand
  /// was never measured.
  final double? rangeMin;
  final double? rangeMax;
  final int durationSec;
  final DateTime startedAt;
  const ExerciseSessionRow({
    required this.id,
    required this.exerciseId,
    required this.mode,
    required this.reps,
    required this.targetReps,
    this.rangeMin,
    this.rangeMax,
    required this.durationSec,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['mode'] = Variable<String>(mode);
    map['reps'] = Variable<int>(reps);
    map['target_reps'] = Variable<int>(targetReps);
    if (!nullToAbsent || rangeMin != null) {
      map['range_min'] = Variable<double>(rangeMin);
    }
    if (!nullToAbsent || rangeMax != null) {
      map['range_max'] = Variable<double>(rangeMax);
    }
    map['duration_sec'] = Variable<int>(durationSec);
    map['started_at'] = Variable<DateTime>(startedAt);
    return map;
  }

  ExerciseSessionsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSessionsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      mode: Value(mode),
      reps: Value(reps),
      targetReps: Value(targetReps),
      rangeMin: rangeMin == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeMin),
      rangeMax: rangeMax == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeMax),
      durationSec: Value(durationSec),
      startedAt: Value(startedAt),
    );
  }

  factory ExerciseSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSessionRow(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      mode: serializer.fromJson<String>(json['mode']),
      reps: serializer.fromJson<int>(json['reps']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      rangeMin: serializer.fromJson<double?>(json['rangeMin']),
      rangeMax: serializer.fromJson<double?>(json['rangeMax']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'mode': serializer.toJson<String>(mode),
      'reps': serializer.toJson<int>(reps),
      'targetReps': serializer.toJson<int>(targetReps),
      'rangeMin': serializer.toJson<double?>(rangeMin),
      'rangeMax': serializer.toJson<double?>(rangeMax),
      'durationSec': serializer.toJson<int>(durationSec),
      'startedAt': serializer.toJson<DateTime>(startedAt),
    };
  }

  ExerciseSessionRow copyWith({
    int? id,
    String? exerciseId,
    String? mode,
    int? reps,
    int? targetReps,
    Value<double?> rangeMin = const Value.absent(),
    Value<double?> rangeMax = const Value.absent(),
    int? durationSec,
    DateTime? startedAt,
  }) => ExerciseSessionRow(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    mode: mode ?? this.mode,
    reps: reps ?? this.reps,
    targetReps: targetReps ?? this.targetReps,
    rangeMin: rangeMin.present ? rangeMin.value : this.rangeMin,
    rangeMax: rangeMax.present ? rangeMax.value : this.rangeMax,
    durationSec: durationSec ?? this.durationSec,
    startedAt: startedAt ?? this.startedAt,
  );
  ExerciseSessionRow copyWithCompanion(ExerciseSessionsCompanion data) {
    return ExerciseSessionRow(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      mode: data.mode.present ? data.mode.value : this.mode,
      reps: data.reps.present ? data.reps.value : this.reps,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      rangeMin: data.rangeMin.present ? data.rangeMin.value : this.rangeMin,
      rangeMax: data.rangeMax.present ? data.rangeMax.value : this.rangeMax,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSessionRow(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('mode: $mode, ')
          ..write('reps: $reps, ')
          ..write('targetReps: $targetReps, ')
          ..write('rangeMin: $rangeMin, ')
          ..write('rangeMax: $rangeMax, ')
          ..write('durationSec: $durationSec, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    mode,
    reps,
    targetReps,
    rangeMin,
    rangeMax,
    durationSec,
    startedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSessionRow &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.mode == this.mode &&
          other.reps == this.reps &&
          other.targetReps == this.targetReps &&
          other.rangeMin == this.rangeMin &&
          other.rangeMax == this.rangeMax &&
          other.durationSec == this.durationSec &&
          other.startedAt == this.startedAt);
}

class ExerciseSessionsCompanion extends UpdateCompanion<ExerciseSessionRow> {
  final Value<int> id;
  final Value<String> exerciseId;
  final Value<String> mode;
  final Value<int> reps;
  final Value<int> targetReps;
  final Value<double?> rangeMin;
  final Value<double?> rangeMax;
  final Value<int> durationSec;
  final Value<DateTime> startedAt;
  const ExerciseSessionsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.mode = const Value.absent(),
    this.reps = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.rangeMin = const Value.absent(),
    this.rangeMax = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.startedAt = const Value.absent(),
  });
  ExerciseSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String exerciseId,
    this.mode = const Value.absent(),
    required int reps,
    required int targetReps,
    this.rangeMin = const Value.absent(),
    this.rangeMax = const Value.absent(),
    required int durationSec,
    required DateTime startedAt,
  }) : exerciseId = Value(exerciseId),
       reps = Value(reps),
       targetReps = Value(targetReps),
       durationSec = Value(durationSec),
       startedAt = Value(startedAt);
  static Insertable<ExerciseSessionRow> custom({
    Expression<int>? id,
    Expression<String>? exerciseId,
    Expression<String>? mode,
    Expression<int>? reps,
    Expression<int>? targetReps,
    Expression<double>? rangeMin,
    Expression<double>? rangeMax,
    Expression<int>? durationSec,
    Expression<DateTime>? startedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (mode != null) 'mode': mode,
      if (reps != null) 'reps': reps,
      if (targetReps != null) 'target_reps': targetReps,
      if (rangeMin != null) 'range_min': rangeMin,
      if (rangeMax != null) 'range_max': rangeMax,
      if (durationSec != null) 'duration_sec': durationSec,
      if (startedAt != null) 'started_at': startedAt,
    });
  }

  ExerciseSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? exerciseId,
    Value<String>? mode,
    Value<int>? reps,
    Value<int>? targetReps,
    Value<double?>? rangeMin,
    Value<double?>? rangeMax,
    Value<int>? durationSec,
    Value<DateTime>? startedAt,
  }) {
    return ExerciseSessionsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      mode: mode ?? this.mode,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      durationSec: durationSec ?? this.durationSec,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (rangeMin.present) {
      map['range_min'] = Variable<double>(rangeMin.value);
    }
    if (rangeMax.present) {
      map['range_max'] = Variable<double>(rangeMax.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSessionsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('mode: $mode, ')
          ..write('reps: $reps, ')
          ..write('targetReps: $targetReps, ')
          ..write('rangeMin: $rangeMin, ')
          ..write('rangeMax: $rangeMax, ')
          ..write('durationSec: $durationSec, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExerciseSessionsTable exerciseSessions = $ExerciseSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [exerciseSessions];
}

typedef $$ExerciseSessionsTableCreateCompanionBuilder =
    ExerciseSessionsCompanion Function({
      Value<int> id,
      required String exerciseId,
      Value<String> mode,
      required int reps,
      required int targetReps,
      Value<double?> rangeMin,
      Value<double?> rangeMax,
      required int durationSec,
      required DateTime startedAt,
    });
typedef $$ExerciseSessionsTableUpdateCompanionBuilder =
    ExerciseSessionsCompanion Function({
      Value<int> id,
      Value<String> exerciseId,
      Value<String> mode,
      Value<int> reps,
      Value<int> targetReps,
      Value<double?> rangeMin,
      Value<double?> rangeMax,
      Value<int> durationSec,
      Value<DateTime> startedAt,
    });

class $$ExerciseSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseSessionsTable> {
  $$ExerciseSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rangeMin => $composableBuilder(
    column: $table.rangeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rangeMax => $composableBuilder(
    column: $table.rangeMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseSessionsTable> {
  $$ExerciseSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rangeMin => $composableBuilder(
    column: $table.rangeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rangeMax => $composableBuilder(
    column: $table.rangeMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseSessionsTable> {
  $$ExerciseSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rangeMin =>
      $composableBuilder(column: $table.rangeMin, builder: (column) => column);

  GeneratedColumn<double> get rangeMax =>
      $composableBuilder(column: $table.rangeMax, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$ExerciseSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseSessionsTable,
          ExerciseSessionRow,
          $$ExerciseSessionsTableFilterComposer,
          $$ExerciseSessionsTableOrderingComposer,
          $$ExerciseSessionsTableAnnotationComposer,
          $$ExerciseSessionsTableCreateCompanionBuilder,
          $$ExerciseSessionsTableUpdateCompanionBuilder,
          (
            ExerciseSessionRow,
            BaseReferences<
              _$AppDatabase,
              $ExerciseSessionsTable,
              ExerciseSessionRow
            >,
          ),
          ExerciseSessionRow,
          PrefetchHooks Function()
        > {
  $$ExerciseSessionsTableTableManager(
    _$AppDatabase db,
    $ExerciseSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<double?> rangeMin = const Value.absent(),
                Value<double?> rangeMax = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
              }) => ExerciseSessionsCompanion(
                id: id,
                exerciseId: exerciseId,
                mode: mode,
                reps: reps,
                targetReps: targetReps,
                rangeMin: rangeMin,
                rangeMax: rangeMax,
                durationSec: durationSec,
                startedAt: startedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String exerciseId,
                Value<String> mode = const Value.absent(),
                required int reps,
                required int targetReps,
                Value<double?> rangeMin = const Value.absent(),
                Value<double?> rangeMax = const Value.absent(),
                required int durationSec,
                required DateTime startedAt,
              }) => ExerciseSessionsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                mode: mode,
                reps: reps,
                targetReps: targetReps,
                rangeMin: rangeMin,
                rangeMax: rangeMax,
                durationSec: durationSec,
                startedAt: startedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseSessionsTable, ExerciseSessionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseSessionsTable,
                    ExerciseSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseSessionsTable,
      ExerciseSessionRow,
      $$ExerciseSessionsTableFilterComposer,
      $$ExerciseSessionsTableOrderingComposer,
      $$ExerciseSessionsTableAnnotationComposer,
      $$ExerciseSessionsTableCreateCompanionBuilder,
      $$ExerciseSessionsTableUpdateCompanionBuilder,
      (
        ExerciseSessionRow,
        BaseReferences<
          _$AppDatabase,
          $ExerciseSessionsTable,
          ExerciseSessionRow
        >,
      ),
      ExerciseSessionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExerciseSessionsTableTableManager get exerciseSessions =>
      $$ExerciseSessionsTableTableManager(_db, _db.exerciseSessions);
}
