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
  static const VerificationMeta _metricUnitMeta = const VerificationMeta(
    'metricUnit',
  );
  @override
  late final GeneratedColumn<String> metricUnit = GeneratedColumn<String>(
    'metric_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('%'),
  );
  static const VerificationMeta _avgAmplitudeMeta = const VerificationMeta(
    'avgAmplitude',
  );
  @override
  late final GeneratedColumn<double> avgAmplitude = GeneratedColumn<double>(
    'avg_amplitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgPeakSpeedMeta = const VerificationMeta(
    'avgPeakSpeed',
  );
  @override
  late final GeneratedColumn<double> avgPeakSpeed = GeneratedColumn<double>(
    'avg_peak_speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgSmoothnessMeta = const VerificationMeta(
    'avgSmoothness',
  );
  @override
  late final GeneratedColumn<double> avgSmoothness = GeneratedColumn<double>(
    'avg_smoothness',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatiguedMeta = const VerificationMeta(
    'fatigued',
  );
  @override
  late final GeneratedColumn<bool> fatigued = GeneratedColumn<bool>(
    'fatigued',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fatigued" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _compensatedRepsMeta = const VerificationMeta(
    'compensatedReps',
  );
  @override
  late final GeneratedColumn<int> compensatedReps = GeneratedColumn<int>(
    'compensated_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    metricUnit,
    avgAmplitude,
    avgPeakSpeed,
    avgSmoothness,
    fatigued,
    durationSec,
    startedAt,
    compensatedReps,
    level,
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
    if (data.containsKey('metric_unit')) {
      context.handle(
        _metricUnitMeta,
        metricUnit.isAcceptableOrUnknown(data['metric_unit']!, _metricUnitMeta),
      );
    }
    if (data.containsKey('avg_amplitude')) {
      context.handle(
        _avgAmplitudeMeta,
        avgAmplitude.isAcceptableOrUnknown(
          data['avg_amplitude']!,
          _avgAmplitudeMeta,
        ),
      );
    }
    if (data.containsKey('avg_peak_speed')) {
      context.handle(
        _avgPeakSpeedMeta,
        avgPeakSpeed.isAcceptableOrUnknown(
          data['avg_peak_speed']!,
          _avgPeakSpeedMeta,
        ),
      );
    }
    if (data.containsKey('avg_smoothness')) {
      context.handle(
        _avgSmoothnessMeta,
        avgSmoothness.isAcceptableOrUnknown(
          data['avg_smoothness']!,
          _avgSmoothnessMeta,
        ),
      );
    }
    if (data.containsKey('fatigued')) {
      context.handle(
        _fatiguedMeta,
        fatigued.isAcceptableOrUnknown(data['fatigued']!, _fatiguedMeta),
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
    if (data.containsKey('compensated_reps')) {
      context.handle(
        _compensatedRepsMeta,
        compensatedReps.isAcceptableOrUnknown(
          data['compensated_reps']!,
          _compensatedRepsMeta,
        ),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
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
      metricUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_unit'],
      )!,
      avgAmplitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_amplitude'],
      ),
      avgPeakSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_peak_speed'],
      ),
      avgSmoothness: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_smoothness'],
      ),
      fatigued: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fatigued'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      compensatedReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}compensated_reps'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      ),
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

  /// Smallest and largest value reached, in [metricUnit]: finger bend in
  /// degrees (mean MCP + PIP + DIP) or spread %. Null if never measured.
  final double? rangeMin;
  final double? rangeMax;

  /// "deg" or "%". Added in schema 2; older rows were openness %.
  final String metricUnit;

  /// Per-rep averages (schema 2): movement size in [metricUnit], peak
  /// speed in [metricUnit] per second, SPARC smoothness (closer to 0 is
  /// smoother).
  final double? avgAmplitude;
  final double? avgPeakSpeed;
  final double? avgSmoothness;

  /// Later reps were clearly smaller than the first (schema 2).
  final bool fatigued;
  final int durationSec;
  final DateTime startedAt;

  /// Reps not counted because the wrist moved instead (schema 3).
  final int compensatedReps;

  /// Program level when done, 1-3 (schema 3). Null for free practice.
  final int? level;
  const ExerciseSessionRow({
    required this.id,
    required this.exerciseId,
    required this.mode,
    required this.reps,
    required this.targetReps,
    this.rangeMin,
    this.rangeMax,
    required this.metricUnit,
    this.avgAmplitude,
    this.avgPeakSpeed,
    this.avgSmoothness,
    required this.fatigued,
    required this.durationSec,
    required this.startedAt,
    required this.compensatedReps,
    this.level,
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
    map['metric_unit'] = Variable<String>(metricUnit);
    if (!nullToAbsent || avgAmplitude != null) {
      map['avg_amplitude'] = Variable<double>(avgAmplitude);
    }
    if (!nullToAbsent || avgPeakSpeed != null) {
      map['avg_peak_speed'] = Variable<double>(avgPeakSpeed);
    }
    if (!nullToAbsent || avgSmoothness != null) {
      map['avg_smoothness'] = Variable<double>(avgSmoothness);
    }
    map['fatigued'] = Variable<bool>(fatigued);
    map['duration_sec'] = Variable<int>(durationSec);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['compensated_reps'] = Variable<int>(compensatedReps);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
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
      metricUnit: Value(metricUnit),
      avgAmplitude: avgAmplitude == null && nullToAbsent
          ? const Value.absent()
          : Value(avgAmplitude),
      avgPeakSpeed: avgPeakSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPeakSpeed),
      avgSmoothness: avgSmoothness == null && nullToAbsent
          ? const Value.absent()
          : Value(avgSmoothness),
      fatigued: Value(fatigued),
      durationSec: Value(durationSec),
      startedAt: Value(startedAt),
      compensatedReps: Value(compensatedReps),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
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
      metricUnit: serializer.fromJson<String>(json['metricUnit']),
      avgAmplitude: serializer.fromJson<double?>(json['avgAmplitude']),
      avgPeakSpeed: serializer.fromJson<double?>(json['avgPeakSpeed']),
      avgSmoothness: serializer.fromJson<double?>(json['avgSmoothness']),
      fatigued: serializer.fromJson<bool>(json['fatigued']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      compensatedReps: serializer.fromJson<int>(json['compensatedReps']),
      level: serializer.fromJson<int?>(json['level']),
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
      'metricUnit': serializer.toJson<String>(metricUnit),
      'avgAmplitude': serializer.toJson<double?>(avgAmplitude),
      'avgPeakSpeed': serializer.toJson<double?>(avgPeakSpeed),
      'avgSmoothness': serializer.toJson<double?>(avgSmoothness),
      'fatigued': serializer.toJson<bool>(fatigued),
      'durationSec': serializer.toJson<int>(durationSec),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'compensatedReps': serializer.toJson<int>(compensatedReps),
      'level': serializer.toJson<int?>(level),
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
    String? metricUnit,
    Value<double?> avgAmplitude = const Value.absent(),
    Value<double?> avgPeakSpeed = const Value.absent(),
    Value<double?> avgSmoothness = const Value.absent(),
    bool? fatigued,
    int? durationSec,
    DateTime? startedAt,
    int? compensatedReps,
    Value<int?> level = const Value.absent(),
  }) => ExerciseSessionRow(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    mode: mode ?? this.mode,
    reps: reps ?? this.reps,
    targetReps: targetReps ?? this.targetReps,
    rangeMin: rangeMin.present ? rangeMin.value : this.rangeMin,
    rangeMax: rangeMax.present ? rangeMax.value : this.rangeMax,
    metricUnit: metricUnit ?? this.metricUnit,
    avgAmplitude: avgAmplitude.present ? avgAmplitude.value : this.avgAmplitude,
    avgPeakSpeed: avgPeakSpeed.present ? avgPeakSpeed.value : this.avgPeakSpeed,
    avgSmoothness: avgSmoothness.present
        ? avgSmoothness.value
        : this.avgSmoothness,
    fatigued: fatigued ?? this.fatigued,
    durationSec: durationSec ?? this.durationSec,
    startedAt: startedAt ?? this.startedAt,
    compensatedReps: compensatedReps ?? this.compensatedReps,
    level: level.present ? level.value : this.level,
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
      metricUnit: data.metricUnit.present
          ? data.metricUnit.value
          : this.metricUnit,
      avgAmplitude: data.avgAmplitude.present
          ? data.avgAmplitude.value
          : this.avgAmplitude,
      avgPeakSpeed: data.avgPeakSpeed.present
          ? data.avgPeakSpeed.value
          : this.avgPeakSpeed,
      avgSmoothness: data.avgSmoothness.present
          ? data.avgSmoothness.value
          : this.avgSmoothness,
      fatigued: data.fatigued.present ? data.fatigued.value : this.fatigued,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      compensatedReps: data.compensatedReps.present
          ? data.compensatedReps.value
          : this.compensatedReps,
      level: data.level.present ? data.level.value : this.level,
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
          ..write('metricUnit: $metricUnit, ')
          ..write('avgAmplitude: $avgAmplitude, ')
          ..write('avgPeakSpeed: $avgPeakSpeed, ')
          ..write('avgSmoothness: $avgSmoothness, ')
          ..write('fatigued: $fatigued, ')
          ..write('durationSec: $durationSec, ')
          ..write('startedAt: $startedAt, ')
          ..write('compensatedReps: $compensatedReps, ')
          ..write('level: $level')
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
    metricUnit,
    avgAmplitude,
    avgPeakSpeed,
    avgSmoothness,
    fatigued,
    durationSec,
    startedAt,
    compensatedReps,
    level,
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
          other.metricUnit == this.metricUnit &&
          other.avgAmplitude == this.avgAmplitude &&
          other.avgPeakSpeed == this.avgPeakSpeed &&
          other.avgSmoothness == this.avgSmoothness &&
          other.fatigued == this.fatigued &&
          other.durationSec == this.durationSec &&
          other.startedAt == this.startedAt &&
          other.compensatedReps == this.compensatedReps &&
          other.level == this.level);
}

class ExerciseSessionsCompanion extends UpdateCompanion<ExerciseSessionRow> {
  final Value<int> id;
  final Value<String> exerciseId;
  final Value<String> mode;
  final Value<int> reps;
  final Value<int> targetReps;
  final Value<double?> rangeMin;
  final Value<double?> rangeMax;
  final Value<String> metricUnit;
  final Value<double?> avgAmplitude;
  final Value<double?> avgPeakSpeed;
  final Value<double?> avgSmoothness;
  final Value<bool> fatigued;
  final Value<int> durationSec;
  final Value<DateTime> startedAt;
  final Value<int> compensatedReps;
  final Value<int?> level;
  const ExerciseSessionsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.mode = const Value.absent(),
    this.reps = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.rangeMin = const Value.absent(),
    this.rangeMax = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.avgAmplitude = const Value.absent(),
    this.avgPeakSpeed = const Value.absent(),
    this.avgSmoothness = const Value.absent(),
    this.fatigued = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.compensatedReps = const Value.absent(),
    this.level = const Value.absent(),
  });
  ExerciseSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String exerciseId,
    this.mode = const Value.absent(),
    required int reps,
    required int targetReps,
    this.rangeMin = const Value.absent(),
    this.rangeMax = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.avgAmplitude = const Value.absent(),
    this.avgPeakSpeed = const Value.absent(),
    this.avgSmoothness = const Value.absent(),
    this.fatigued = const Value.absent(),
    required int durationSec,
    required DateTime startedAt,
    this.compensatedReps = const Value.absent(),
    this.level = const Value.absent(),
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
    Expression<String>? metricUnit,
    Expression<double>? avgAmplitude,
    Expression<double>? avgPeakSpeed,
    Expression<double>? avgSmoothness,
    Expression<bool>? fatigued,
    Expression<int>? durationSec,
    Expression<DateTime>? startedAt,
    Expression<int>? compensatedReps,
    Expression<int>? level,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (mode != null) 'mode': mode,
      if (reps != null) 'reps': reps,
      if (targetReps != null) 'target_reps': targetReps,
      if (rangeMin != null) 'range_min': rangeMin,
      if (rangeMax != null) 'range_max': rangeMax,
      if (metricUnit != null) 'metric_unit': metricUnit,
      if (avgAmplitude != null) 'avg_amplitude': avgAmplitude,
      if (avgPeakSpeed != null) 'avg_peak_speed': avgPeakSpeed,
      if (avgSmoothness != null) 'avg_smoothness': avgSmoothness,
      if (fatigued != null) 'fatigued': fatigued,
      if (durationSec != null) 'duration_sec': durationSec,
      if (startedAt != null) 'started_at': startedAt,
      if (compensatedReps != null) 'compensated_reps': compensatedReps,
      if (level != null) 'level': level,
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
    Value<String>? metricUnit,
    Value<double?>? avgAmplitude,
    Value<double?>? avgPeakSpeed,
    Value<double?>? avgSmoothness,
    Value<bool>? fatigued,
    Value<int>? durationSec,
    Value<DateTime>? startedAt,
    Value<int>? compensatedReps,
    Value<int?>? level,
  }) {
    return ExerciseSessionsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      mode: mode ?? this.mode,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      metricUnit: metricUnit ?? this.metricUnit,
      avgAmplitude: avgAmplitude ?? this.avgAmplitude,
      avgPeakSpeed: avgPeakSpeed ?? this.avgPeakSpeed,
      avgSmoothness: avgSmoothness ?? this.avgSmoothness,
      fatigued: fatigued ?? this.fatigued,
      durationSec: durationSec ?? this.durationSec,
      startedAt: startedAt ?? this.startedAt,
      compensatedReps: compensatedReps ?? this.compensatedReps,
      level: level ?? this.level,
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
    if (metricUnit.present) {
      map['metric_unit'] = Variable<String>(metricUnit.value);
    }
    if (avgAmplitude.present) {
      map['avg_amplitude'] = Variable<double>(avgAmplitude.value);
    }
    if (avgPeakSpeed.present) {
      map['avg_peak_speed'] = Variable<double>(avgPeakSpeed.value);
    }
    if (avgSmoothness.present) {
      map['avg_smoothness'] = Variable<double>(avgSmoothness.value);
    }
    if (fatigued.present) {
      map['fatigued'] = Variable<bool>(fatigued.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (compensatedReps.present) {
      map['compensated_reps'] = Variable<int>(compensatedReps.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
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
          ..write('metricUnit: $metricUnit, ')
          ..write('avgAmplitude: $avgAmplitude, ')
          ..write('avgPeakSpeed: $avgPeakSpeed, ')
          ..write('avgSmoothness: $avgSmoothness, ')
          ..write('fatigued: $fatigued, ')
          ..write('durationSec: $durationSec, ')
          ..write('startedAt: $startedAt, ')
          ..write('compensatedReps: $compensatedReps, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }
}

class $AssessmentsTable extends Assessments
    with TableInfo<$AssessmentsTable, AssessmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssessmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _affectedHandMeta = const VerificationMeta(
    'affectedHand',
  );
  @override
  late final GeneratedColumn<String> affectedHand = GeneratedColumn<String>(
    'affected_hand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _affectedOpenMeta = const VerificationMeta(
    'affectedOpen',
  );
  @override
  late final GeneratedColumn<double> affectedOpen = GeneratedColumn<double>(
    'affected_open',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _affectedClosedMeta = const VerificationMeta(
    'affectedClosed',
  );
  @override
  late final GeneratedColumn<double> affectedClosed = GeneratedColumn<double>(
    'affected_closed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherOpenMeta = const VerificationMeta(
    'otherOpen',
  );
  @override
  late final GeneratedColumn<double> otherOpen = GeneratedColumn<double>(
    'other_open',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherClosedMeta = const VerificationMeta(
    'otherClosed',
  );
  @override
  late final GeneratedColumn<double> otherClosed = GeneratedColumn<double>(
    'other_closed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cameraLimitedMeta = const VerificationMeta(
    'cameraLimited',
  );
  @override
  late final GeneratedColumn<bool> cameraLimited = GeneratedColumn<bool>(
    'camera_limited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("camera_limited" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    takenAt,
    affectedHand,
    affectedOpen,
    affectedClosed,
    otherOpen,
    otherClosed,
    level,
    cameraLimited,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssessmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('affected_hand')) {
      context.handle(
        _affectedHandMeta,
        affectedHand.isAcceptableOrUnknown(
          data['affected_hand']!,
          _affectedHandMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_affectedHandMeta);
    }
    if (data.containsKey('affected_open')) {
      context.handle(
        _affectedOpenMeta,
        affectedOpen.isAcceptableOrUnknown(
          data['affected_open']!,
          _affectedOpenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_affectedOpenMeta);
    }
    if (data.containsKey('affected_closed')) {
      context.handle(
        _affectedClosedMeta,
        affectedClosed.isAcceptableOrUnknown(
          data['affected_closed']!,
          _affectedClosedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_affectedClosedMeta);
    }
    if (data.containsKey('other_open')) {
      context.handle(
        _otherOpenMeta,
        otherOpen.isAcceptableOrUnknown(data['other_open']!, _otherOpenMeta),
      );
    }
    if (data.containsKey('other_closed')) {
      context.handle(
        _otherClosedMeta,
        otherClosed.isAcceptableOrUnknown(
          data['other_closed']!,
          _otherClosedMeta,
        ),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('camera_limited')) {
      context.handle(
        _cameraLimitedMeta,
        cameraLimited.isAcceptableOrUnknown(
          data['camera_limited']!,
          _cameraLimitedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cameraLimitedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssessmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssessmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      affectedHand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}affected_hand'],
      )!,
      affectedOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}affected_open'],
      )!,
      affectedClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}affected_closed'],
      )!,
      otherOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}other_open'],
      ),
      otherClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}other_closed'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      cameraLimited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}camera_limited'],
      )!,
    );
  }

  @override
  $AssessmentsTable createAlias(String alias) {
    return $AssessmentsTable(attachedDatabase, alias);
  }
}

class AssessmentRow extends DataClass implements Insertable<AssessmentRow> {
  final int id;
  final DateTime takenAt;

  /// "left" or "right".
  final String affectedHand;
  final double affectedOpen;
  final double affectedClosed;
  final double? otherOpen;
  final double? otherClosed;
  final int level;
  final bool cameraLimited;
  const AssessmentRow({
    required this.id,
    required this.takenAt,
    required this.affectedHand,
    required this.affectedOpen,
    required this.affectedClosed,
    this.otherOpen,
    this.otherClosed,
    required this.level,
    required this.cameraLimited,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['affected_hand'] = Variable<String>(affectedHand);
    map['affected_open'] = Variable<double>(affectedOpen);
    map['affected_closed'] = Variable<double>(affectedClosed);
    if (!nullToAbsent || otherOpen != null) {
      map['other_open'] = Variable<double>(otherOpen);
    }
    if (!nullToAbsent || otherClosed != null) {
      map['other_closed'] = Variable<double>(otherClosed);
    }
    map['level'] = Variable<int>(level);
    map['camera_limited'] = Variable<bool>(cameraLimited);
    return map;
  }

  AssessmentsCompanion toCompanion(bool nullToAbsent) {
    return AssessmentsCompanion(
      id: Value(id),
      takenAt: Value(takenAt),
      affectedHand: Value(affectedHand),
      affectedOpen: Value(affectedOpen),
      affectedClosed: Value(affectedClosed),
      otherOpen: otherOpen == null && nullToAbsent
          ? const Value.absent()
          : Value(otherOpen),
      otherClosed: otherClosed == null && nullToAbsent
          ? const Value.absent()
          : Value(otherClosed),
      level: Value(level),
      cameraLimited: Value(cameraLimited),
    );
  }

  factory AssessmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssessmentRow(
      id: serializer.fromJson<int>(json['id']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      affectedHand: serializer.fromJson<String>(json['affectedHand']),
      affectedOpen: serializer.fromJson<double>(json['affectedOpen']),
      affectedClosed: serializer.fromJson<double>(json['affectedClosed']),
      otherOpen: serializer.fromJson<double?>(json['otherOpen']),
      otherClosed: serializer.fromJson<double?>(json['otherClosed']),
      level: serializer.fromJson<int>(json['level']),
      cameraLimited: serializer.fromJson<bool>(json['cameraLimited']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'affectedHand': serializer.toJson<String>(affectedHand),
      'affectedOpen': serializer.toJson<double>(affectedOpen),
      'affectedClosed': serializer.toJson<double>(affectedClosed),
      'otherOpen': serializer.toJson<double?>(otherOpen),
      'otherClosed': serializer.toJson<double?>(otherClosed),
      'level': serializer.toJson<int>(level),
      'cameraLimited': serializer.toJson<bool>(cameraLimited),
    };
  }

  AssessmentRow copyWith({
    int? id,
    DateTime? takenAt,
    String? affectedHand,
    double? affectedOpen,
    double? affectedClosed,
    Value<double?> otherOpen = const Value.absent(),
    Value<double?> otherClosed = const Value.absent(),
    int? level,
    bool? cameraLimited,
  }) => AssessmentRow(
    id: id ?? this.id,
    takenAt: takenAt ?? this.takenAt,
    affectedHand: affectedHand ?? this.affectedHand,
    affectedOpen: affectedOpen ?? this.affectedOpen,
    affectedClosed: affectedClosed ?? this.affectedClosed,
    otherOpen: otherOpen.present ? otherOpen.value : this.otherOpen,
    otherClosed: otherClosed.present ? otherClosed.value : this.otherClosed,
    level: level ?? this.level,
    cameraLimited: cameraLimited ?? this.cameraLimited,
  );
  AssessmentRow copyWithCompanion(AssessmentsCompanion data) {
    return AssessmentRow(
      id: data.id.present ? data.id.value : this.id,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      affectedHand: data.affectedHand.present
          ? data.affectedHand.value
          : this.affectedHand,
      affectedOpen: data.affectedOpen.present
          ? data.affectedOpen.value
          : this.affectedOpen,
      affectedClosed: data.affectedClosed.present
          ? data.affectedClosed.value
          : this.affectedClosed,
      otherOpen: data.otherOpen.present ? data.otherOpen.value : this.otherOpen,
      otherClosed: data.otherClosed.present
          ? data.otherClosed.value
          : this.otherClosed,
      level: data.level.present ? data.level.value : this.level,
      cameraLimited: data.cameraLimited.present
          ? data.cameraLimited.value
          : this.cameraLimited,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentRow(')
          ..write('id: $id, ')
          ..write('takenAt: $takenAt, ')
          ..write('affectedHand: $affectedHand, ')
          ..write('affectedOpen: $affectedOpen, ')
          ..write('affectedClosed: $affectedClosed, ')
          ..write('otherOpen: $otherOpen, ')
          ..write('otherClosed: $otherClosed, ')
          ..write('level: $level, ')
          ..write('cameraLimited: $cameraLimited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    takenAt,
    affectedHand,
    affectedOpen,
    affectedClosed,
    otherOpen,
    otherClosed,
    level,
    cameraLimited,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssessmentRow &&
          other.id == this.id &&
          other.takenAt == this.takenAt &&
          other.affectedHand == this.affectedHand &&
          other.affectedOpen == this.affectedOpen &&
          other.affectedClosed == this.affectedClosed &&
          other.otherOpen == this.otherOpen &&
          other.otherClosed == this.otherClosed &&
          other.level == this.level &&
          other.cameraLimited == this.cameraLimited);
}

class AssessmentsCompanion extends UpdateCompanion<AssessmentRow> {
  final Value<int> id;
  final Value<DateTime> takenAt;
  final Value<String> affectedHand;
  final Value<double> affectedOpen;
  final Value<double> affectedClosed;
  final Value<double?> otherOpen;
  final Value<double?> otherClosed;
  final Value<int> level;
  final Value<bool> cameraLimited;
  const AssessmentsCompanion({
    this.id = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.affectedHand = const Value.absent(),
    this.affectedOpen = const Value.absent(),
    this.affectedClosed = const Value.absent(),
    this.otherOpen = const Value.absent(),
    this.otherClosed = const Value.absent(),
    this.level = const Value.absent(),
    this.cameraLimited = const Value.absent(),
  });
  AssessmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime takenAt,
    required String affectedHand,
    required double affectedOpen,
    required double affectedClosed,
    this.otherOpen = const Value.absent(),
    this.otherClosed = const Value.absent(),
    required int level,
    required bool cameraLimited,
  }) : takenAt = Value(takenAt),
       affectedHand = Value(affectedHand),
       affectedOpen = Value(affectedOpen),
       affectedClosed = Value(affectedClosed),
       level = Value(level),
       cameraLimited = Value(cameraLimited);
  static Insertable<AssessmentRow> custom({
    Expression<int>? id,
    Expression<DateTime>? takenAt,
    Expression<String>? affectedHand,
    Expression<double>? affectedOpen,
    Expression<double>? affectedClosed,
    Expression<double>? otherOpen,
    Expression<double>? otherClosed,
    Expression<int>? level,
    Expression<bool>? cameraLimited,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (takenAt != null) 'taken_at': takenAt,
      if (affectedHand != null) 'affected_hand': affectedHand,
      if (affectedOpen != null) 'affected_open': affectedOpen,
      if (affectedClosed != null) 'affected_closed': affectedClosed,
      if (otherOpen != null) 'other_open': otherOpen,
      if (otherClosed != null) 'other_closed': otherClosed,
      if (level != null) 'level': level,
      if (cameraLimited != null) 'camera_limited': cameraLimited,
    });
  }

  AssessmentsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? takenAt,
    Value<String>? affectedHand,
    Value<double>? affectedOpen,
    Value<double>? affectedClosed,
    Value<double?>? otherOpen,
    Value<double?>? otherClosed,
    Value<int>? level,
    Value<bool>? cameraLimited,
  }) {
    return AssessmentsCompanion(
      id: id ?? this.id,
      takenAt: takenAt ?? this.takenAt,
      affectedHand: affectedHand ?? this.affectedHand,
      affectedOpen: affectedOpen ?? this.affectedOpen,
      affectedClosed: affectedClosed ?? this.affectedClosed,
      otherOpen: otherOpen ?? this.otherOpen,
      otherClosed: otherClosed ?? this.otherClosed,
      level: level ?? this.level,
      cameraLimited: cameraLimited ?? this.cameraLimited,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (affectedHand.present) {
      map['affected_hand'] = Variable<String>(affectedHand.value);
    }
    if (affectedOpen.present) {
      map['affected_open'] = Variable<double>(affectedOpen.value);
    }
    if (affectedClosed.present) {
      map['affected_closed'] = Variable<double>(affectedClosed.value);
    }
    if (otherOpen.present) {
      map['other_open'] = Variable<double>(otherOpen.value);
    }
    if (otherClosed.present) {
      map['other_closed'] = Variable<double>(otherClosed.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (cameraLimited.present) {
      map['camera_limited'] = Variable<bool>(cameraLimited.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('takenAt: $takenAt, ')
          ..write('affectedHand: $affectedHand, ')
          ..write('affectedOpen: $affectedOpen, ')
          ..write('affectedClosed: $affectedClosed, ')
          ..write('otherOpen: $otherOpen, ')
          ..write('otherClosed: $otherClosed, ')
          ..write('level: $level, ')
          ..write('cameraLimited: $cameraLimited')
          ..write(')'))
        .toString();
  }
}

class $PainChecksTable extends PainChecks
    with TableInfo<$PainChecksTable, PainCheckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PainChecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, phase, score];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pain_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PainCheckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PainCheckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PainCheckRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $PainChecksTable createAlias(String alias) {
    return $PainChecksTable(attachedDatabase, alias);
  }
}

class PainCheckRow extends DataClass implements Insertable<PainCheckRow> {
  final int id;
  final DateTime at;

  /// "before" or "after".
  final String phase;
  final int score;
  const PainCheckRow({
    required this.id,
    required this.at,
    required this.phase,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['phase'] = Variable<String>(phase);
    map['score'] = Variable<int>(score);
    return map;
  }

  PainChecksCompanion toCompanion(bool nullToAbsent) {
    return PainChecksCompanion(
      id: Value(id),
      at: Value(at),
      phase: Value(phase),
      score: Value(score),
    );
  }

  factory PainCheckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PainCheckRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      phase: serializer.fromJson<String>(json['phase']),
      score: serializer.fromJson<int>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'phase': serializer.toJson<String>(phase),
      'score': serializer.toJson<int>(score),
    };
  }

  PainCheckRow copyWith({int? id, DateTime? at, String? phase, int? score}) =>
      PainCheckRow(
        id: id ?? this.id,
        at: at ?? this.at,
        phase: phase ?? this.phase,
        score: score ?? this.score,
      );
  PainCheckRow copyWithCompanion(PainChecksCompanion data) {
    return PainCheckRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      phase: data.phase.present ? data.phase.value : this.phase,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PainCheckRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('phase: $phase, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, phase, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PainCheckRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.phase == this.phase &&
          other.score == this.score);
}

class PainChecksCompanion extends UpdateCompanion<PainCheckRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> phase;
  final Value<int> score;
  const PainChecksCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.phase = const Value.absent(),
    this.score = const Value.absent(),
  });
  PainChecksCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String phase,
    required int score,
  }) : at = Value(at),
       phase = Value(phase),
       score = Value(score);
  static Insertable<PainCheckRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? phase,
    Expression<int>? score,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (phase != null) 'phase': phase,
      if (score != null) 'score': score,
    });
  }

  PainChecksCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? phase,
    Value<int>? score,
  }) {
    return PainChecksCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      phase: phase ?? this.phase,
      score: score ?? this.score,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PainChecksCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('phase: $phase, ')
          ..write('score: $score')
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
  late final $AssessmentsTable assessments = $AssessmentsTable(this);
  late final $PainChecksTable painChecks = $PainChecksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exerciseSessions,
    assessments,
    painChecks,
  ];
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
      Value<String> metricUnit,
      Value<double?> avgAmplitude,
      Value<double?> avgPeakSpeed,
      Value<double?> avgSmoothness,
      Value<bool> fatigued,
      required int durationSec,
      required DateTime startedAt,
      Value<int> compensatedReps,
      Value<int?> level,
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
      Value<String> metricUnit,
      Value<double?> avgAmplitude,
      Value<double?> avgPeakSpeed,
      Value<double?> avgSmoothness,
      Value<bool> fatigued,
      Value<int> durationSec,
      Value<DateTime> startedAt,
      Value<int> compensatedReps,
      Value<int?> level,
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

  ColumnFilters<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgAmplitude => $composableBuilder(
    column: $table.avgAmplitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPeakSpeed => $composableBuilder(
    column: $table.avgPeakSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSmoothness => $composableBuilder(
    column: $table.avgSmoothness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fatigued => $composableBuilder(
    column: $table.fatigued,
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

  ColumnFilters<int> get compensatedReps => $composableBuilder(
    column: $table.compensatedReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
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

  ColumnOrderings<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgAmplitude => $composableBuilder(
    column: $table.avgAmplitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPeakSpeed => $composableBuilder(
    column: $table.avgPeakSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSmoothness => $composableBuilder(
    column: $table.avgSmoothness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fatigued => $composableBuilder(
    column: $table.fatigued,
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

  ColumnOrderings<int> get compensatedReps => $composableBuilder(
    column: $table.compensatedReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
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

  GeneratedColumn<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgAmplitude => $composableBuilder(
    column: $table.avgAmplitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgPeakSpeed => $composableBuilder(
    column: $table.avgPeakSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSmoothness => $composableBuilder(
    column: $table.avgSmoothness,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fatigued =>
      $composableBuilder(column: $table.fatigued, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get compensatedReps => $composableBuilder(
    column: $table.compensatedReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);
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
                Value<String> metricUnit = const Value.absent(),
                Value<double?> avgAmplitude = const Value.absent(),
                Value<double?> avgPeakSpeed = const Value.absent(),
                Value<double?> avgSmoothness = const Value.absent(),
                Value<bool> fatigued = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> compensatedReps = const Value.absent(),
                Value<int?> level = const Value.absent(),
              }) => ExerciseSessionsCompanion(
                id: id,
                exerciseId: exerciseId,
                mode: mode,
                reps: reps,
                targetReps: targetReps,
                rangeMin: rangeMin,
                rangeMax: rangeMax,
                metricUnit: metricUnit,
                avgAmplitude: avgAmplitude,
                avgPeakSpeed: avgPeakSpeed,
                avgSmoothness: avgSmoothness,
                fatigued: fatigued,
                durationSec: durationSec,
                startedAt: startedAt,
                compensatedReps: compensatedReps,
                level: level,
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
                Value<String> metricUnit = const Value.absent(),
                Value<double?> avgAmplitude = const Value.absent(),
                Value<double?> avgPeakSpeed = const Value.absent(),
                Value<double?> avgSmoothness = const Value.absent(),
                Value<bool> fatigued = const Value.absent(),
                required int durationSec,
                required DateTime startedAt,
                Value<int> compensatedReps = const Value.absent(),
                Value<int?> level = const Value.absent(),
              }) => ExerciseSessionsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                mode: mode,
                reps: reps,
                targetReps: targetReps,
                rangeMin: rangeMin,
                rangeMax: rangeMax,
                metricUnit: metricUnit,
                avgAmplitude: avgAmplitude,
                avgPeakSpeed: avgPeakSpeed,
                avgSmoothness: avgSmoothness,
                fatigued: fatigued,
                durationSec: durationSec,
                startedAt: startedAt,
                compensatedReps: compensatedReps,
                level: level,
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
typedef $$AssessmentsTableCreateCompanionBuilder =
    AssessmentsCompanion Function({
      Value<int> id,
      required DateTime takenAt,
      required String affectedHand,
      required double affectedOpen,
      required double affectedClosed,
      Value<double?> otherOpen,
      Value<double?> otherClosed,
      required int level,
      required bool cameraLimited,
    });
typedef $$AssessmentsTableUpdateCompanionBuilder =
    AssessmentsCompanion Function({
      Value<int> id,
      Value<DateTime> takenAt,
      Value<String> affectedHand,
      Value<double> affectedOpen,
      Value<double> affectedClosed,
      Value<double?> otherOpen,
      Value<double?> otherClosed,
      Value<int> level,
      Value<bool> cameraLimited,
    });

class $$AssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableFilterComposer({
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

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get affectedHand => $composableBuilder(
    column: $table.affectedHand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get affectedOpen => $composableBuilder(
    column: $table.affectedOpen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get affectedClosed => $composableBuilder(
    column: $table.affectedClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get otherOpen => $composableBuilder(
    column: $table.otherOpen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get otherClosed => $composableBuilder(
    column: $table.otherClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cameraLimited => $composableBuilder(
    column: $table.cameraLimited,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get affectedHand => $composableBuilder(
    column: $table.affectedHand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get affectedOpen => $composableBuilder(
    column: $table.affectedOpen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get affectedClosed => $composableBuilder(
    column: $table.affectedClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get otherOpen => $composableBuilder(
    column: $table.otherOpen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get otherClosed => $composableBuilder(
    column: $table.otherClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cameraLimited => $composableBuilder(
    column: $table.cameraLimited,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get affectedHand => $composableBuilder(
    column: $table.affectedHand,
    builder: (column) => column,
  );

  GeneratedColumn<double> get affectedOpen => $composableBuilder(
    column: $table.affectedOpen,
    builder: (column) => column,
  );

  GeneratedColumn<double> get affectedClosed => $composableBuilder(
    column: $table.affectedClosed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get otherOpen =>
      $composableBuilder(column: $table.otherOpen, builder: (column) => column);

  GeneratedColumn<double> get otherClosed => $composableBuilder(
    column: $table.otherClosed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get cameraLimited => $composableBuilder(
    column: $table.cameraLimited,
    builder: (column) => column,
  );
}

class $$AssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssessmentsTable,
          AssessmentRow,
          $$AssessmentsTableFilterComposer,
          $$AssessmentsTableOrderingComposer,
          $$AssessmentsTableAnnotationComposer,
          $$AssessmentsTableCreateCompanionBuilder,
          $$AssessmentsTableUpdateCompanionBuilder,
          (
            AssessmentRow,
            BaseReferences<_$AppDatabase, $AssessmentsTable, AssessmentRow>,
          ),
          AssessmentRow,
          PrefetchHooks Function()
        > {
  $$AssessmentsTableTableManager(_$AppDatabase db, $AssessmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssessmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<String> affectedHand = const Value.absent(),
                Value<double> affectedOpen = const Value.absent(),
                Value<double> affectedClosed = const Value.absent(),
                Value<double?> otherOpen = const Value.absent(),
                Value<double?> otherClosed = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> cameraLimited = const Value.absent(),
              }) => AssessmentsCompanion(
                id: id,
                takenAt: takenAt,
                affectedHand: affectedHand,
                affectedOpen: affectedOpen,
                affectedClosed: affectedClosed,
                otherOpen: otherOpen,
                otherClosed: otherClosed,
                level: level,
                cameraLimited: cameraLimited,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime takenAt,
                required String affectedHand,
                required double affectedOpen,
                required double affectedClosed,
                Value<double?> otherOpen = const Value.absent(),
                Value<double?> otherClosed = const Value.absent(),
                required int level,
                required bool cameraLimited,
              }) => AssessmentsCompanion.insert(
                id: id,
                takenAt: takenAt,
                affectedHand: affectedHand,
                affectedOpen: affectedOpen,
                affectedClosed: affectedClosed,
                otherOpen: otherOpen,
                otherClosed: otherClosed,
                level: level,
                cameraLimited: cameraLimited,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssessmentsTable, AssessmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AssessmentsTable,
                    AssessmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssessmentsTable,
      AssessmentRow,
      $$AssessmentsTableFilterComposer,
      $$AssessmentsTableOrderingComposer,
      $$AssessmentsTableAnnotationComposer,
      $$AssessmentsTableCreateCompanionBuilder,
      $$AssessmentsTableUpdateCompanionBuilder,
      (
        AssessmentRow,
        BaseReferences<_$AppDatabase, $AssessmentsTable, AssessmentRow>,
      ),
      AssessmentRow,
      PrefetchHooks Function()
    >;
typedef $$PainChecksTableCreateCompanionBuilder = PainChecksCompanion Function({
  Value<int> id,
  required DateTime at,
  required String phase,
  required int score,
});
typedef $$PainChecksTableUpdateCompanionBuilder = PainChecksCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> phase,
  Value<int> score,
});

class $$PainChecksTableFilterComposer
    extends Composer<_$AppDatabase, $PainChecksTable> {
  $$PainChecksTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PainChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $PainChecksTable> {
  $$PainChecksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PainChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PainChecksTable> {
  $$PainChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$PainChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PainChecksTable,
          PainCheckRow,
          $$PainChecksTableFilterComposer,
          $$PainChecksTableOrderingComposer,
          $$PainChecksTableAnnotationComposer,
          $$PainChecksTableCreateCompanionBuilder,
          $$PainChecksTableUpdateCompanionBuilder,
          (
            PainCheckRow,
            BaseReferences<_$AppDatabase, $PainChecksTable, PainCheckRow>,
          ),
          PainCheckRow,
          PrefetchHooks Function()
        > {
  $$PainChecksTableTableManager(_$AppDatabase db, $PainChecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PainChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PainChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PainChecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> phase = const Value.absent(),
            Value<int> score = const Value.absent(),
          }) => PainChecksCompanion(id: id, at: at, phase: phase, score: score),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String phase,
                required int score,
              }) => PainChecksCompanion.insert(
                id: id,
                at: at,
                phase: phase,
                score: score,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PainChecksTable, PainCheckRow>(table),
                  BaseReferences<_$AppDatabase, $PainChecksTable, PainCheckRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PainChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PainChecksTable,
      PainCheckRow,
      $$PainChecksTableFilterComposer,
      $$PainChecksTableOrderingComposer,
      $$PainChecksTableAnnotationComposer,
      $$PainChecksTableCreateCompanionBuilder,
      $$PainChecksTableUpdateCompanionBuilder,
      (
        PainCheckRow,
        BaseReferences<_$AppDatabase, $PainChecksTable, PainCheckRow>,
      ),
      PainCheckRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExerciseSessionsTableTableManager get exerciseSessions =>
      $$ExerciseSessionsTableTableManager(_db, _db.exerciseSessions);
  $$AssessmentsTableTableManager get assessments =>
      $$AssessmentsTableTableManager(_db, _db.assessments);
  $$PainChecksTableTableManager get painChecks =>
      $$PainChecksTableTableManager(_db, _db.painChecks);
}
