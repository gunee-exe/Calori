// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_db.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<Sex, String> sex =
      GeneratedColumn<String>(
        'sex',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Sex>($ProfilesTable.$convertersex);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, String>
  activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ActivityLevel>($ProfilesTable.$converteractivityLevel);
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyKcalMeta = const VerificationMeta(
    'dailyKcal',
  );
  @override
  late final GeneratedColumn<int> dailyKcal = GeneratedColumn<int>(
    'daily_kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyProteinGMeta = const VerificationMeta(
    'dailyProteinG',
  );
  @override
  late final GeneratedColumn<int> dailyProteinG = GeneratedColumn<int>(
    'daily_protein_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyCarbsGMeta = const VerificationMeta(
    'dailyCarbsG',
  );
  @override
  late final GeneratedColumn<int> dailyCarbsG = GeneratedColumn<int>(
    'daily_carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyFatGMeta = const VerificationMeta(
    'dailyFatG',
  );
  @override
  late final GeneratedColumn<int> dailyFatG = GeneratedColumn<int>(
    'daily_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    age,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    targetDate,
    dailyKcal,
    dailyProteinG,
    dailyCarbsG,
    dailyFatG,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetWeightKgMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('daily_kcal')) {
      context.handle(
        _dailyKcalMeta,
        dailyKcal.isAcceptableOrUnknown(data['daily_kcal']!, _dailyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyKcalMeta);
    }
    if (data.containsKey('daily_protein_g')) {
      context.handle(
        _dailyProteinGMeta,
        dailyProteinG.isAcceptableOrUnknown(
          data['daily_protein_g']!,
          _dailyProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyProteinGMeta);
    }
    if (data.containsKey('daily_carbs_g')) {
      context.handle(
        _dailyCarbsGMeta,
        dailyCarbsG.isAcceptableOrUnknown(
          data['daily_carbs_g']!,
          _dailyCarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyCarbsGMeta);
    }
    if (data.containsKey('daily_fat_g')) {
      context.handle(
        _dailyFatGMeta,
        dailyFatG.isAcceptableOrUnknown(data['daily_fat_g']!, _dailyFatGMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyFatGMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sex: $ProfilesTable.$convertersex.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sex'],
        )!,
      ),
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      )!,
      activityLevel: $ProfilesTable.$converteractivityLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}activity_level'],
        )!,
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      dailyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_kcal'],
      )!,
      dailyProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_protein_g'],
      )!,
      dailyCarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_carbs_g'],
      )!,
      dailyFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_fat_g'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, String, String> $convertersex =
      const EnumNameConverter<Sex>(Sex.values);
  static JsonTypeConverter2<ActivityLevel, String, String>
  $converteractivityLevel = const EnumNameConverter<ActivityLevel>(
    ActivityLevel.values,
  );
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;

  /// The honest achievable date, after the goal engine's clamps. Null for a
  /// maintenance goal, which has no end date.
  final DateTime? targetDate;
  final int dailyKcal;
  final int dailyProteinG;
  final int dailyCarbsG;
  final int dailyFatG;
  final DateTime updatedAt;
  const Profile({
    required this.id,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    this.targetDate,
    required this.dailyKcal,
    required this.dailyProteinG,
    required this.dailyCarbsG,
    required this.dailyFatG,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['sex'] = Variable<String>($ProfilesTable.$convertersex.toSql(sex));
    }
    map['age'] = Variable<int>(age);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    map['target_weight_kg'] = Variable<double>(targetWeightKg);
    {
      map['activity_level'] = Variable<String>(
        $ProfilesTable.$converteractivityLevel.toSql(activityLevel),
      );
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['daily_kcal'] = Variable<int>(dailyKcal);
    map['daily_protein_g'] = Variable<int>(dailyProteinG);
    map['daily_carbs_g'] = Variable<int>(dailyCarbsG);
    map['daily_fat_g'] = Variable<int>(dailyFatG);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      sex: Value(sex),
      age: Value(age),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      targetWeightKg: Value(targetWeightKg),
      activityLevel: Value(activityLevel),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      dailyKcal: Value(dailyKcal),
      dailyProteinG: Value(dailyProteinG),
      dailyCarbsG: Value(dailyCarbsG),
      dailyFatG: Value(dailyFatG),
      updatedAt: Value(updatedAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      sex: $ProfilesTable.$convertersex.fromJson(
        serializer.fromJson<String>(json['sex']),
      ),
      age: serializer.fromJson<int>(json['age']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      activityLevel: $ProfilesTable.$converteractivityLevel.fromJson(
        serializer.fromJson<String>(json['activityLevel']),
      ),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      dailyKcal: serializer.fromJson<int>(json['dailyKcal']),
      dailyProteinG: serializer.fromJson<int>(json['dailyProteinG']),
      dailyCarbsG: serializer.fromJson<int>(json['dailyCarbsG']),
      dailyFatG: serializer.fromJson<int>(json['dailyFatG']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<String>(
        $ProfilesTable.$convertersex.toJson(sex),
      ),
      'age': serializer.toJson<int>(age),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'activityLevel': serializer.toJson<String>(
        $ProfilesTable.$converteractivityLevel.toJson(activityLevel),
      ),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'dailyKcal': serializer.toJson<int>(dailyKcal),
      'dailyProteinG': serializer.toJson<int>(dailyProteinG),
      'dailyCarbsG': serializer.toJson<int>(dailyCarbsG),
      'dailyFatG': serializer.toJson<int>(dailyFatG),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith({
    int? id,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    Value<DateTime?> targetDate = const Value.absent(),
    int? dailyKcal,
    int? dailyProteinG,
    int? dailyCarbsG,
    int? dailyFatG,
    DateTime? updatedAt,
  }) => Profile(
    id: id ?? this.id,
    sex: sex ?? this.sex,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    dailyKcal: dailyKcal ?? this.dailyKcal,
    dailyProteinG: dailyProteinG ?? this.dailyProteinG,
    dailyCarbsG: dailyCarbsG ?? this.dailyCarbsG,
    dailyFatG: dailyFatG ?? this.dailyFatG,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      age: data.age.present ? data.age.value : this.age,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      dailyKcal: data.dailyKcal.present ? data.dailyKcal.value : this.dailyKcal,
      dailyProteinG: data.dailyProteinG.present
          ? data.dailyProteinG.value
          : this.dailyProteinG,
      dailyCarbsG: data.dailyCarbsG.present
          ? data.dailyCarbsG.value
          : this.dailyCarbsG,
      dailyFatG: data.dailyFatG.present ? data.dailyFatG.value : this.dailyFatG,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('targetDate: $targetDate, ')
          ..write('dailyKcal: $dailyKcal, ')
          ..write('dailyProteinG: $dailyProteinG, ')
          ..write('dailyCarbsG: $dailyCarbsG, ')
          ..write('dailyFatG: $dailyFatG, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    age,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    targetDate,
    dailyKcal,
    dailyProteinG,
    dailyCarbsG,
    dailyFatG,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.age == this.age &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.targetWeightKg == this.targetWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.targetDate == this.targetDate &&
          other.dailyKcal == this.dailyKcal &&
          other.dailyProteinG == this.dailyProteinG &&
          other.dailyCarbsG == this.dailyCarbsG &&
          other.dailyFatG == this.dailyFatG &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<Sex> sex;
  final Value<int> age;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<double> targetWeightKg;
  final Value<ActivityLevel> activityLevel;
  final Value<DateTime?> targetDate;
  final Value<int> dailyKcal;
  final Value<int> dailyProteinG;
  final Value<int> dailyCarbsG;
  final Value<int> dailyFatG;
  final Value<DateTime> updatedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.dailyKcal = const Value.absent(),
    this.dailyProteinG = const Value.absent(),
    this.dailyCarbsG = const Value.absent(),
    this.dailyFatG = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required ActivityLevel activityLevel,
    this.targetDate = const Value.absent(),
    required int dailyKcal,
    required int dailyProteinG,
    required int dailyCarbsG,
    required int dailyFatG,
    required DateTime updatedAt,
  }) : sex = Value(sex),
       age = Value(age),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       targetWeightKg = Value(targetWeightKg),
       activityLevel = Value(activityLevel),
       dailyKcal = Value(dailyKcal),
       dailyProteinG = Value(dailyProteinG),
       dailyCarbsG = Value(dailyCarbsG),
       dailyFatG = Value(dailyFatG),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? sex,
    Expression<int>? age,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<double>? targetWeightKg,
    Expression<String>? activityLevel,
    Expression<DateTime>? targetDate,
    Expression<int>? dailyKcal,
    Expression<int>? dailyProteinG,
    Expression<int>? dailyCarbsG,
    Expression<int>? dailyFatG,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (targetDate != null) 'target_date': targetDate,
      if (dailyKcal != null) 'daily_kcal': dailyKcal,
      if (dailyProteinG != null) 'daily_protein_g': dailyProteinG,
      if (dailyCarbsG != null) 'daily_carbs_g': dailyCarbsG,
      if (dailyFatG != null) 'daily_fat_g': dailyFatG,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<Sex>? sex,
    Value<int>? age,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<double>? targetWeightKg,
    Value<ActivityLevel>? activityLevel,
    Value<DateTime?>? targetDate,
    Value<int>? dailyKcal,
    Value<int>? dailyProteinG,
    Value<int>? dailyCarbsG,
    Value<int>? dailyFatG,
    Value<DateTime>? updatedAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      targetDate: targetDate ?? this.targetDate,
      dailyKcal: dailyKcal ?? this.dailyKcal,
      dailyProteinG: dailyProteinG ?? this.dailyProteinG,
      dailyCarbsG: dailyCarbsG ?? this.dailyCarbsG,
      dailyFatG: dailyFatG ?? this.dailyFatG,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(
        $ProfilesTable.$convertersex.toSql(sex.value),
      );
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(
        $ProfilesTable.$converteractivityLevel.toSql(activityLevel.value),
      );
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (dailyKcal.present) {
      map['daily_kcal'] = Variable<int>(dailyKcal.value);
    }
    if (dailyProteinG.present) {
      map['daily_protein_g'] = Variable<int>(dailyProteinG.value);
    }
    if (dailyCarbsG.present) {
      map['daily_carbs_g'] = Variable<int>(dailyCarbsG.value);
    }
    if (dailyFatG.present) {
      map['daily_fat_g'] = Variable<int>(dailyFatG.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('targetDate: $targetDate, ')
          ..write('dailyKcal: $dailyKcal, ')
          ..write('dailyProteinG: $dailyProteinG, ')
          ..write('dailyCarbsG: $dailyCarbsG, ')
          ..write('dailyFatG: $dailyFatG, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, String> mealType =
      GeneratedColumn<String>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MealType>($EntriesTable.$convertermealType);
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemSource>($EntriesTable.$convertersource);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayKey,
    loggedAt,
    mealType,
    photoPath,
    source,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      mealType: $EntriesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      source: $EntriesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, String, String> $convertermealType =
      const EnumNameConverter<MealType>(MealType.values);
  static JsonTypeConverter2<ItemSource, String, String> $convertersource =
      const EnumNameConverter<ItemSource>(ItemSource.values);
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;

  /// The civil day as `yyyymmdd` (e.g. 20260826).
  ///
  /// Deliberately not a `DateTime`. Days are a calendar concept, not an
  /// instant: storing a timestamp makes "which day is this entry on" depend on
  /// the device time zone and on DST, so an entry logged at 00:30 can silently
  /// move to the previous day after travel. An integer civil date sorts
  /// correctly, indexes cheaply, and makes the calendar's month query a plain
  /// `BETWEEN`.
  final int dayKey;

  /// The actual instant of logging, for ordering within a day.
  final DateTime loggedAt;
  final MealType mealType;

  /// Path to the retained photo, if this entry came from the camera. Retained
  /// even on failure so a retry costs nothing (UC-11).
  final String? photoPath;
  final ItemSource source;
  final String? note;
  const Entry({
    required this.id,
    required this.dayKey,
    required this.loggedAt,
    required this.mealType,
    this.photoPath,
    required this.source,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_key'] = Variable<int>(dayKey);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    {
      map['meal_type'] = Variable<String>(
        $EntriesTable.$convertermealType.toSql(mealType),
      );
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    {
      map['source'] = Variable<String>(
        $EntriesTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      dayKey: Value(dayKey),
      loggedAt: Value(loggedAt),
      mealType: Value(mealType),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      mealType: $EntriesTable.$convertermealType.fromJson(
        serializer.fromJson<String>(json['mealType']),
      ),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      source: $EntriesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayKey': serializer.toJson<int>(dayKey),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'mealType': serializer.toJson<String>(
        $EntriesTable.$convertermealType.toJson(mealType),
      ),
      'photoPath': serializer.toJson<String?>(photoPath),
      'source': serializer.toJson<String>(
        $EntriesTable.$convertersource.toJson(source),
      ),
      'note': serializer.toJson<String?>(note),
    };
  }

  Entry copyWith({
    int? id,
    int? dayKey,
    DateTime? loggedAt,
    MealType? mealType,
    Value<String?> photoPath = const Value.absent(),
    ItemSource? source,
    Value<String?> note = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    dayKey: dayKey ?? this.dayKey,
    loggedAt: loggedAt ?? this.loggedAt,
    mealType: mealType ?? this.mealType,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('mealType: $mealType, ')
          ..write('photoPath: $photoPath, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dayKey, loggedAt, mealType, photoPath, source, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.dayKey == this.dayKey &&
          other.loggedAt == this.loggedAt &&
          other.mealType == this.mealType &&
          other.photoPath == this.photoPath &&
          other.source == this.source &&
          other.note == this.note);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<int> dayKey;
  final Value<DateTime> loggedAt;
  final Value<MealType> mealType;
  final Value<String?> photoPath;
  final Value<ItemSource> source;
  final Value<String?> note;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.mealType = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required int dayKey,
    required DateTime loggedAt,
    required MealType mealType,
    this.photoPath = const Value.absent(),
    required ItemSource source,
    this.note = const Value.absent(),
  }) : dayKey = Value(dayKey),
       loggedAt = Value(loggedAt),
       mealType = Value(mealType),
       source = Value(source);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<int>? dayKey,
    Expression<DateTime>? loggedAt,
    Expression<String>? mealType,
    Expression<String>? photoPath,
    Expression<String>? source,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayKey != null) 'day_key': dayKey,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (mealType != null) 'meal_type': mealType,
      if (photoPath != null) 'photo_path': photoPath,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayKey,
    Value<DateTime>? loggedAt,
    Value<MealType>? mealType,
    Value<String?>? photoPath,
    Value<ItemSource>? source,
    Value<String?>? note,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      photoPath: photoPath ?? this.photoPath,
      source: source ?? this.source,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(
        $EntriesTable.$convertermealType.toSql(mealType.value),
      );
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $EntriesTable.$convertersource.toSql(source.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('mealType: $mealType, ')
          ..write('photoPath: $photoPath, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $EntryItemsTable extends EntryItems
    with TableInfo<$EntryItemsTable, EntryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameNormalisedMeta = const VerificationMeta(
    'nameNormalised',
  );
  @override
  late final GeneratedColumn<String> nameNormalised = GeneratedColumn<String>(
    'name_normalised',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portionDescMeta = const VerificationMeta(
    'portionDesc',
  );
  @override
  late final GeneratedColumn<String> portionDesc = GeneratedColumn<String>(
    'portion_desc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Confidence?, String> confidence =
      GeneratedColumn<String>(
        'confidence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Confidence?>($EntryItemsTable.$converterconfidencen);
  static const VerificationMeta _confidenceReasonMeta = const VerificationMeta(
    'confidenceReason',
  );
  @override
  late final GeneratedColumn<String> confidenceReason = GeneratedColumn<String>(
    'confidence_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemSource>($EntryItemsTable.$convertersource);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    name,
    nameNormalised,
    portionDesc,
    grams,
    kcal,
    proteinG,
    carbsG,
    fatG,
    confidence,
    confidenceReason,
    source,
    foodId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_normalised')) {
      context.handle(
        _nameNormalisedMeta,
        nameNormalised.isAcceptableOrUnknown(
          data['name_normalised']!,
          _nameNormalisedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameNormalisedMeta);
    }
    if (data.containsKey('portion_desc')) {
      context.handle(
        _portionDescMeta,
        portionDesc.isAcceptableOrUnknown(
          data['portion_desc']!,
          _portionDescMeta,
        ),
      );
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('confidence_reason')) {
      context.handle(
        _confidenceReasonMeta,
        confidenceReason.isAcceptableOrUnknown(
          data['confidence_reason']!,
          _confidenceReasonMeta,
        ),
      );
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameNormalised: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_normalised'],
      )!,
      portionDesc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_desc'],
      ),
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      confidence: $EntryItemsTable.$converterconfidencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}confidence'],
        ),
      ),
      confidenceReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_reason'],
      ),
      source: $EntryItemsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      ),
    );
  }

  @override
  $EntryItemsTable createAlias(String alias) {
    return $EntryItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Confidence, String, String> $converterconfidence =
      const EnumNameConverter<Confidence>(Confidence.values);
  static JsonTypeConverter2<Confidence?, String?, String?>
  $converterconfidencen = JsonTypeConverter2.asNullable($converterconfidence);
  static JsonTypeConverter2<ItemSource, String, String> $convertersource =
      const EnumNameConverter<ItemSource>(ItemSource.values);
}

class EntryItem extends DataClass implements Insertable<EntryItem> {
  final int id;
  final int entryId;
  final String name;

  /// Normalised name, used as the `food_cache` key so a repeat meal resolves to
  /// the value the user already accepted.
  final String nameNormalised;

  /// Human-readable portion, e.g. "1 plate", "2 tbsp".
  final String? portionDesc;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Only set for AI-proposed items.
  final Confidence? confidence;
  final String? confidenceReason;
  final ItemSource source;

  /// The `foods.id` this came from, when it came from the bundled database.
  ///
  /// **Not a foreign key.** `foods` lives in a separate database file that is
  /// never attached, so this cannot be enforced and must never be joined on.
  /// It exists for provenance — answering "where did this number come from" on
  /// the Sources screen — and nothing else.
  final int? foodId;
  const EntryItem({
    required this.id,
    required this.entryId,
    required this.name,
    required this.nameNormalised,
    this.portionDesc,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.confidence,
    this.confidenceReason,
    required this.source,
    this.foodId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['name'] = Variable<String>(name);
    map['name_normalised'] = Variable<String>(nameNormalised);
    if (!nullToAbsent || portionDesc != null) {
      map['portion_desc'] = Variable<String>(portionDesc);
    }
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<String>(
        $EntryItemsTable.$converterconfidencen.toSql(confidence),
      );
    }
    if (!nullToAbsent || confidenceReason != null) {
      map['confidence_reason'] = Variable<String>(confidenceReason);
    }
    {
      map['source'] = Variable<String>(
        $EntryItemsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    return map;
  }

  EntryItemsCompanion toCompanion(bool nullToAbsent) {
    return EntryItemsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      name: Value(name),
      nameNormalised: Value(nameNormalised),
      portionDesc: portionDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(portionDesc),
      grams: Value(grams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      confidenceReason: confidenceReason == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceReason),
      source: Value(source),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
    );
  }

  factory EntryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryItem(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      name: serializer.fromJson<String>(json['name']),
      nameNormalised: serializer.fromJson<String>(json['nameNormalised']),
      portionDesc: serializer.fromJson<String?>(json['portionDesc']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      confidence: $EntryItemsTable.$converterconfidencen.fromJson(
        serializer.fromJson<String?>(json['confidence']),
      ),
      confidenceReason: serializer.fromJson<String?>(json['confidenceReason']),
      source: $EntryItemsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      foodId: serializer.fromJson<int?>(json['foodId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'name': serializer.toJson<String>(name),
      'nameNormalised': serializer.toJson<String>(nameNormalised),
      'portionDesc': serializer.toJson<String?>(portionDesc),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'confidence': serializer.toJson<String?>(
        $EntryItemsTable.$converterconfidencen.toJson(confidence),
      ),
      'confidenceReason': serializer.toJson<String?>(confidenceReason),
      'source': serializer.toJson<String>(
        $EntryItemsTable.$convertersource.toJson(source),
      ),
      'foodId': serializer.toJson<int?>(foodId),
    };
  }

  EntryItem copyWith({
    int? id,
    int? entryId,
    String? name,
    String? nameNormalised,
    Value<String?> portionDesc = const Value.absent(),
    double? grams,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    Value<Confidence?> confidence = const Value.absent(),
    Value<String?> confidenceReason = const Value.absent(),
    ItemSource? source,
    Value<int?> foodId = const Value.absent(),
  }) => EntryItem(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    name: name ?? this.name,
    nameNormalised: nameNormalised ?? this.nameNormalised,
    portionDesc: portionDesc.present ? portionDesc.value : this.portionDesc,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    confidence: confidence.present ? confidence.value : this.confidence,
    confidenceReason: confidenceReason.present
        ? confidenceReason.value
        : this.confidenceReason,
    source: source ?? this.source,
    foodId: foodId.present ? foodId.value : this.foodId,
  );
  EntryItem copyWithCompanion(EntryItemsCompanion data) {
    return EntryItem(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      name: data.name.present ? data.name.value : this.name,
      nameNormalised: data.nameNormalised.present
          ? data.nameNormalised.value
          : this.nameNormalised,
      portionDesc: data.portionDesc.present
          ? data.portionDesc.value
          : this.portionDesc,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      confidenceReason: data.confidenceReason.present
          ? data.confidenceReason.value
          : this.confidenceReason,
      source: data.source.present ? data.source.value : this.source,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryItem(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('portionDesc: $portionDesc, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('confidenceReason: $confidenceReason, ')
          ..write('source: $source, ')
          ..write('foodId: $foodId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    name,
    nameNormalised,
    portionDesc,
    grams,
    kcal,
    proteinG,
    carbsG,
    fatG,
    confidence,
    confidenceReason,
    source,
    foodId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryItem &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.name == this.name &&
          other.nameNormalised == this.nameNormalised &&
          other.portionDesc == this.portionDesc &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.confidence == this.confidence &&
          other.confidenceReason == this.confidenceReason &&
          other.source == this.source &&
          other.foodId == this.foodId);
}

class EntryItemsCompanion extends UpdateCompanion<EntryItem> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> name;
  final Value<String> nameNormalised;
  final Value<String?> portionDesc;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<Confidence?> confidence;
  final Value<String?> confidenceReason;
  final Value<ItemSource> source;
  final Value<int?> foodId;
  const EntryItemsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNormalised = const Value.absent(),
    this.portionDesc = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidence = const Value.absent(),
    this.confidenceReason = const Value.absent(),
    this.source = const Value.absent(),
    this.foodId = const Value.absent(),
  });
  EntryItemsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String name,
    required String nameNormalised,
    this.portionDesc = const Value.absent(),
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.confidence = const Value.absent(),
    this.confidenceReason = const Value.absent(),
    required ItemSource source,
    this.foodId = const Value.absent(),
  }) : entryId = Value(entryId),
       name = Value(name),
       nameNormalised = Value(nameNormalised),
       grams = Value(grams),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       source = Value(source);
  static Insertable<EntryItem> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? name,
    Expression<String>? nameNormalised,
    Expression<String>? portionDesc,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? confidence,
    Expression<String>? confidenceReason,
    Expression<String>? source,
    Expression<int>? foodId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (name != null) 'name': name,
      if (nameNormalised != null) 'name_normalised': nameNormalised,
      if (portionDesc != null) 'portion_desc': portionDesc,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (confidence != null) 'confidence': confidence,
      if (confidenceReason != null) 'confidence_reason': confidenceReason,
      if (source != null) 'source': source,
      if (foodId != null) 'food_id': foodId,
    });
  }

  EntryItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<String>? name,
    Value<String>? nameNormalised,
    Value<String?>? portionDesc,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<Confidence?>? confidence,
    Value<String?>? confidenceReason,
    Value<ItemSource>? source,
    Value<int?>? foodId,
  }) {
    return EntryItemsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      nameNormalised: nameNormalised ?? this.nameNormalised,
      portionDesc: portionDesc ?? this.portionDesc,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidence: confidence ?? this.confidence,
      confidenceReason: confidenceReason ?? this.confidenceReason,
      source: source ?? this.source,
      foodId: foodId ?? this.foodId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNormalised.present) {
      map['name_normalised'] = Variable<String>(nameNormalised.value);
    }
    if (portionDesc.present) {
      map['portion_desc'] = Variable<String>(portionDesc.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(
        $EntryItemsTable.$converterconfidencen.toSql(confidence.value),
      );
    }
    if (confidenceReason.present) {
      map['confidence_reason'] = Variable<String>(confidenceReason.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $EntryItemsTable.$convertersource.toSql(source.value),
      );
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryItemsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('portionDesc: $portionDesc, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('confidenceReason: $confidenceReason, ')
          ..write('source: $source, ')
          ..write('foodId: $foodId')
          ..write(')'))
        .toString();
  }
}

class $FoodCacheEntriesTable extends FoodCacheEntries
    with TableInfo<$FoodCacheEntriesTable, FoodCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameNormalisedMeta = const VerificationMeta(
    'nameNormalised',
  );
  @override
  late final GeneratedColumn<String> nameNormalised = GeneratedColumn<String>(
    'name_normalised',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcal100gMeta = const VerificationMeta(
    'kcal100g',
  );
  @override
  late final GeneratedColumn<double> kcal100g = GeneratedColumn<double>(
    'kcal100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100gMeta = const VerificationMeta(
    'protein100g',
  );
  @override
  late final GeneratedColumn<double> protein100g = GeneratedColumn<double>(
    'protein100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbs100gMeta = const VerificationMeta(
    'carbs100g',
  );
  @override
  late final GeneratedColumn<double> carbs100g = GeneratedColumn<double>(
    'carbs100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fat100gMeta = const VerificationMeta(
    'fat100g',
  );
  @override
  late final GeneratedColumn<double> fat100g = GeneratedColumn<double>(
    'fat100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    nameNormalised,
    kcal100g,
    protein100g,
    carbs100g,
    fat100g,
    lastUsedAt,
    useCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name_normalised')) {
      context.handle(
        _nameNormalisedMeta,
        nameNormalised.isAcceptableOrUnknown(
          data['name_normalised']!,
          _nameNormalisedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameNormalisedMeta);
    }
    if (data.containsKey('kcal100g')) {
      context.handle(
        _kcal100gMeta,
        kcal100g.isAcceptableOrUnknown(data['kcal100g']!, _kcal100gMeta),
      );
    } else if (isInserting) {
      context.missing(_kcal100gMeta);
    }
    if (data.containsKey('protein100g')) {
      context.handle(
        _protein100gMeta,
        protein100g.isAcceptableOrUnknown(
          data['protein100g']!,
          _protein100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protein100gMeta);
    }
    if (data.containsKey('carbs100g')) {
      context.handle(
        _carbs100gMeta,
        carbs100g.isAcceptableOrUnknown(data['carbs100g']!, _carbs100gMeta),
      );
    } else if (isInserting) {
      context.missing(_carbs100gMeta);
    }
    if (data.containsKey('fat100g')) {
      context.handle(
        _fat100gMeta,
        fat100g.isAcceptableOrUnknown(data['fat100g']!, _fat100gMeta),
      );
    } else if (isInserting) {
      context.missing(_fat100gMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nameNormalised};
  @override
  FoodCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodCacheEntry(
      nameNormalised: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_normalised'],
      )!,
      kcal100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100g'],
      )!,
      protein100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100g'],
      )!,
      carbs100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs100g'],
      )!,
      fat100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100g'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
    );
  }

  @override
  $FoodCacheEntriesTable createAlias(String alias) {
    return $FoodCacheEntriesTable(attachedDatabase, alias);
  }
}

class FoodCacheEntry extends DataClass implements Insertable<FoodCacheEntry> {
  final String nameNormalised;
  final double kcal100g;
  final double protein100g;
  final double carbs100g;
  final double fat100g;

  /// Drives the "recent" suggestions shown before the user types (UC-05).
  final DateTime lastUsedAt;

  /// How many times this value has been accepted. Drives "frequent".
  final int useCount;
  const FoodCacheEntry({
    required this.nameNormalised,
    required this.kcal100g,
    required this.protein100g,
    required this.carbs100g,
    required this.fat100g,
    required this.lastUsedAt,
    required this.useCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name_normalised'] = Variable<String>(nameNormalised);
    map['kcal100g'] = Variable<double>(kcal100g);
    map['protein100g'] = Variable<double>(protein100g);
    map['carbs100g'] = Variable<double>(carbs100g);
    map['fat100g'] = Variable<double>(fat100g);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['use_count'] = Variable<int>(useCount);
    return map;
  }

  FoodCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodCacheEntriesCompanion(
      nameNormalised: Value(nameNormalised),
      kcal100g: Value(kcal100g),
      protein100g: Value(protein100g),
      carbs100g: Value(carbs100g),
      fat100g: Value(fat100g),
      lastUsedAt: Value(lastUsedAt),
      useCount: Value(useCount),
    );
  }

  factory FoodCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodCacheEntry(
      nameNormalised: serializer.fromJson<String>(json['nameNormalised']),
      kcal100g: serializer.fromJson<double>(json['kcal100g']),
      protein100g: serializer.fromJson<double>(json['protein100g']),
      carbs100g: serializer.fromJson<double>(json['carbs100g']),
      fat100g: serializer.fromJson<double>(json['fat100g']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      useCount: serializer.fromJson<int>(json['useCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nameNormalised': serializer.toJson<String>(nameNormalised),
      'kcal100g': serializer.toJson<double>(kcal100g),
      'protein100g': serializer.toJson<double>(protein100g),
      'carbs100g': serializer.toJson<double>(carbs100g),
      'fat100g': serializer.toJson<double>(fat100g),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'useCount': serializer.toJson<int>(useCount),
    };
  }

  FoodCacheEntry copyWith({
    String? nameNormalised,
    double? kcal100g,
    double? protein100g,
    double? carbs100g,
    double? fat100g,
    DateTime? lastUsedAt,
    int? useCount,
  }) => FoodCacheEntry(
    nameNormalised: nameNormalised ?? this.nameNormalised,
    kcal100g: kcal100g ?? this.kcal100g,
    protein100g: protein100g ?? this.protein100g,
    carbs100g: carbs100g ?? this.carbs100g,
    fat100g: fat100g ?? this.fat100g,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    useCount: useCount ?? this.useCount,
  );
  FoodCacheEntry copyWithCompanion(FoodCacheEntriesCompanion data) {
    return FoodCacheEntry(
      nameNormalised: data.nameNormalised.present
          ? data.nameNormalised.value
          : this.nameNormalised,
      kcal100g: data.kcal100g.present ? data.kcal100g.value : this.kcal100g,
      protein100g: data.protein100g.present
          ? data.protein100g.value
          : this.protein100g,
      carbs100g: data.carbs100g.present ? data.carbs100g.value : this.carbs100g,
      fat100g: data.fat100g.present ? data.fat100g.value : this.fat100g,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodCacheEntry(')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carbs100g: $carbs100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('useCount: $useCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    nameNormalised,
    kcal100g,
    protein100g,
    carbs100g,
    fat100g,
    lastUsedAt,
    useCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodCacheEntry &&
          other.nameNormalised == this.nameNormalised &&
          other.kcal100g == this.kcal100g &&
          other.protein100g == this.protein100g &&
          other.carbs100g == this.carbs100g &&
          other.fat100g == this.fat100g &&
          other.lastUsedAt == this.lastUsedAt &&
          other.useCount == this.useCount);
}

class FoodCacheEntriesCompanion extends UpdateCompanion<FoodCacheEntry> {
  final Value<String> nameNormalised;
  final Value<double> kcal100g;
  final Value<double> protein100g;
  final Value<double> carbs100g;
  final Value<double> fat100g;
  final Value<DateTime> lastUsedAt;
  final Value<int> useCount;
  final Value<int> rowid;
  const FoodCacheEntriesCompanion({
    this.nameNormalised = const Value.absent(),
    this.kcal100g = const Value.absent(),
    this.protein100g = const Value.absent(),
    this.carbs100g = const Value.absent(),
    this.fat100g = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.useCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodCacheEntriesCompanion.insert({
    required String nameNormalised,
    required double kcal100g,
    required double protein100g,
    required double carbs100g,
    required double fat100g,
    required DateTime lastUsedAt,
    this.useCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nameNormalised = Value(nameNormalised),
       kcal100g = Value(kcal100g),
       protein100g = Value(protein100g),
       carbs100g = Value(carbs100g),
       fat100g = Value(fat100g),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<FoodCacheEntry> custom({
    Expression<String>? nameNormalised,
    Expression<double>? kcal100g,
    Expression<double>? protein100g,
    Expression<double>? carbs100g,
    Expression<double>? fat100g,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? useCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nameNormalised != null) 'name_normalised': nameNormalised,
      if (kcal100g != null) 'kcal100g': kcal100g,
      if (protein100g != null) 'protein100g': protein100g,
      if (carbs100g != null) 'carbs100g': carbs100g,
      if (fat100g != null) 'fat100g': fat100g,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (useCount != null) 'use_count': useCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodCacheEntriesCompanion copyWith({
    Value<String>? nameNormalised,
    Value<double>? kcal100g,
    Value<double>? protein100g,
    Value<double>? carbs100g,
    Value<double>? fat100g,
    Value<DateTime>? lastUsedAt,
    Value<int>? useCount,
    Value<int>? rowid,
  }) {
    return FoodCacheEntriesCompanion(
      nameNormalised: nameNormalised ?? this.nameNormalised,
      kcal100g: kcal100g ?? this.kcal100g,
      protein100g: protein100g ?? this.protein100g,
      carbs100g: carbs100g ?? this.carbs100g,
      fat100g: fat100g ?? this.fat100g,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nameNormalised.present) {
      map['name_normalised'] = Variable<String>(nameNormalised.value);
    }
    if (kcal100g.present) {
      map['kcal100g'] = Variable<double>(kcal100g.value);
    }
    if (protein100g.present) {
      map['protein100g'] = Variable<double>(protein100g.value);
    }
    if (carbs100g.present) {
      map['carbs100g'] = Variable<double>(carbs100g.value);
    }
    if (fat100g.present) {
      map['fat100g'] = Variable<double>(fat100g.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodCacheEntriesCompanion(')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carbs100g: $carbs100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('useCount: $useCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DiaryDb extends GeneratedDatabase {
  _$DiaryDb(QueryExecutor e) : super(e);
  $DiaryDbManager get managers => $DiaryDbManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $EntryItemsTable entryItems = $EntryItemsTable(this);
  late final $FoodCacheEntriesTable foodCacheEntries = $FoodCacheEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    entries,
    entryItems,
    foodCacheEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required Sex sex,
  required int age,
  required double heightCm,
  required double weightKg,
  required double targetWeightKg,
  required ActivityLevel activityLevel,
  Value<DateTime?> targetDate,
  required int dailyKcal,
  required int dailyProteinG,
  required int dailyCarbsG,
  required int dailyFatG,
  required DateTime updatedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<Sex> sex,
  Value<int> age,
  Value<double> heightCm,
  Value<double> weightKg,
  Value<double> targetWeightKg,
  Value<ActivityLevel> activityLevel,
  Value<DateTime?> targetDate,
  Value<int> dailyKcal,
  Value<int> dailyProteinG,
  Value<int> dailyCarbsG,
  Value<int> dailyFatG,
  Value<DateTime> updatedAt,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$DiaryDb, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<Sex, Sex, String> get sex =>
      $composableBuilder(
        column: $table.sex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, String>
  get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyKcal => $composableBuilder(
    column: $table.dailyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyProteinG => $composableBuilder(
    column: $table.dailyProteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCarbsG => $composableBuilder(
    column: $table.dailyCarbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyFatG => $composableBuilder(
    column: $table.dailyFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$DiaryDb, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyKcal => $composableBuilder(
    column: $table.dailyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyProteinG => $composableBuilder(
    column: $table.dailyProteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCarbsG => $composableBuilder(
    column: $table.dailyCarbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyFatG => $composableBuilder(
    column: $table.dailyFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$DiaryDb, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sex, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ActivityLevel, String> get activityLevel =>
      $composableBuilder(
        column: $table.activityLevel,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyKcal =>
      $composableBuilder(column: $table.dailyKcal, builder: (column) => column);

  GeneratedColumn<int> get dailyProteinG => $composableBuilder(
    column: $table.dailyProteinG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyCarbsG => $composableBuilder(
    column: $table.dailyCarbsG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyFatG =>
      $composableBuilder(column: $table.dailyFatG, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$DiaryDb,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$DiaryDb, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$DiaryDb db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Sex> sex = const Value.absent(),
                Value<int> age = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double> targetWeightKg = const Value.absent(),
                Value<ActivityLevel> activityLevel = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int> dailyKcal = const Value.absent(),
                Value<int> dailyProteinG = const Value.absent(),
                Value<int> dailyCarbsG = const Value.absent(),
                Value<int> dailyFatG = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                sex: sex,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                targetDate: targetDate,
                dailyKcal: dailyKcal,
                dailyProteinG: dailyProteinG,
                dailyCarbsG: dailyCarbsG,
                dailyFatG: dailyFatG,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Sex sex,
                required int age,
                required double heightCm,
                required double weightKg,
                required double targetWeightKg,
                required ActivityLevel activityLevel,
                Value<DateTime?> targetDate = const Value.absent(),
                required int dailyKcal,
                required int dailyProteinG,
                required int dailyCarbsG,
                required int dailyFatG,
                required DateTime updatedAt,
              }) => ProfilesCompanion.insert(
                id: id,
                sex: sex,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                targetDate: targetDate,
                dailyKcal: dailyKcal,
                dailyProteinG: dailyProteinG,
                dailyCarbsG: dailyCarbsG,
                dailyFatG: dailyFatG,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$DiaryDb,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$DiaryDb, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required int dayKey,
  required DateTime loggedAt,
  required MealType mealType,
  Value<String?> photoPath,
  required ItemSource source,
  Value<String?> note,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<int> dayKey,
  Value<DateTime> loggedAt,
  Value<MealType> mealType,
  Value<String?> photoPath,
  Value<ItemSource> source,
  Value<String?> note,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$DiaryDb, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntryItemsTable, List<EntryItem>>
  _entryItemsRefsTable(_$DiaryDb db) => MultiTypedResultKey.fromTable(
    db.entryItems,
    aliasName: 'entries__id__entry_items__entry_id',
  );

  $$EntryItemsTableProcessedTableManager get entryItemsRefs {
    final manager = $$EntryItemsTableTableManager(
      $_db,
      $_db.entryItems,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer extends Composer<_$DiaryDb, $EntriesTable> {
  $$EntriesTableFilterComposer({
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

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, String> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemSource, ItemSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entryItemsRefs(
    Expression<bool> Function($$EntryItemsTableFilterComposer f) f,
  ) {
    final $$EntryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItems,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryItemsTableFilterComposer(
            $db: $db,
            $table: $db.entryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$DiaryDb, $EntriesTable> {
  $$EntriesTableOrderingComposer({
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

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$DiaryDb, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> entryItemsRefs<T extends Object>(
    Expression<T> Function($$EntryItemsTableAnnotationComposer a) f,
  ) {
    final $$EntryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItems,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.entryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$DiaryDb,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool entryItemsRefs})
        > {
  $$EntriesTableTableManager(_$DiaryDb db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<MealType> mealType = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<ItemSource> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                dayKey: dayKey,
                loggedAt: loggedAt,
                mealType: mealType,
                photoPath: photoPath,
                source: source,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayKey,
                required DateTime loggedAt,
                required MealType mealType,
                Value<String?> photoPath = const Value.absent(),
                required ItemSource source,
                Value<String?> note = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                dayKey: dayKey,
                loggedAt: loggedAt,
                mealType: mealType,
                photoPath: photoPath,
                source: source,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entryItemsRefs) db.entryItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entryItemsRefs)
                    await $_getPrefetchedData<Entry, $EntriesTable, EntryItem>(
                      currentTable: table,
                      referencedTable: $$EntriesTableReferences
                          ._entryItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$EntriesTableReferences(
                        db,
                        table,
                        p0,
                      ).entryItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.entryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$DiaryDb,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool entryItemsRefs})
    >;
typedef $$EntryItemsTableCreateCompanionBuilder = EntryItemsCompanion Function({
  Value<int> id,
  required int entryId,
  required String name,
  required String nameNormalised,
  Value<String?> portionDesc,
  required double grams,
  required double kcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
  Value<Confidence?> confidence,
  Value<String?> confidenceReason,
  required ItemSource source,
  Value<int?> foodId,
});
typedef $$EntryItemsTableUpdateCompanionBuilder = EntryItemsCompanion Function({
  Value<int> id,
  Value<int> entryId,
  Value<String> name,
  Value<String> nameNormalised,
  Value<String?> portionDesc,
  Value<double> grams,
  Value<double> kcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<Confidence?> confidence,
  Value<String?> confidenceReason,
  Value<ItemSource> source,
  Value<int?> foodId,
});

final class $$EntryItemsTableReferences
    extends BaseReferences<_$DiaryDb, $EntryItemsTable, EntryItem> {
  $$EntryItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$DiaryDb db) =>
      db.entries.createAlias('entry_items__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryItemsTableFilterComposer
    extends Composer<_$DiaryDb, $EntryItemsTable> {
  $$EntryItemsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionDesc => $composableBuilder(
    column: $table.portionDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Confidence?, Confidence, String>
  get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get confidenceReason => $composableBuilder(
    column: $table.confidenceReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemSource, ItemSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryItemsTableOrderingComposer
    extends Composer<_$DiaryDb, $EntryItemsTable> {
  $$EntryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionDesc => $composableBuilder(
    column: $table.portionDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidenceReason => $composableBuilder(
    column: $table.confidenceReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryItemsTableAnnotationComposer
    extends Composer<_$DiaryDb, $EntryItemsTable> {
  $$EntryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionDesc => $composableBuilder(
    column: $table.portionDesc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Confidence?, String> get confidence =>
      $composableBuilder(
        column: $table.confidence,
        builder: (column) => column,
      );

  GeneratedColumn<String> get confidenceReason => $composableBuilder(
    column: $table.confidenceReason,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ItemSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryItemsTableTableManager
    extends
        RootTableManager<
          _$DiaryDb,
          $EntryItemsTable,
          EntryItem,
          $$EntryItemsTableFilterComposer,
          $$EntryItemsTableOrderingComposer,
          $$EntryItemsTableAnnotationComposer,
          $$EntryItemsTableCreateCompanionBuilder,
          $$EntryItemsTableUpdateCompanionBuilder,
          (EntryItem, $$EntryItemsTableReferences),
          EntryItem,
          PrefetchHooks Function({bool entryId})
        > {
  $$EntryItemsTableTableManager(_$DiaryDb db, $EntryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameNormalised = const Value.absent(),
                Value<String?> portionDesc = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<Confidence?> confidence = const Value.absent(),
                Value<String?> confidenceReason = const Value.absent(),
                Value<ItemSource> source = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
              }) => EntryItemsCompanion(
                id: id,
                entryId: entryId,
                name: name,
                nameNormalised: nameNormalised,
                portionDesc: portionDesc,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                confidence: confidence,
                confidenceReason: confidenceReason,
                source: source,
                foodId: foodId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required String name,
                required String nameNormalised,
                Value<String?> portionDesc = const Value.absent(),
                required double grams,
                required double kcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<Confidence?> confidence = const Value.absent(),
                Value<String?> confidenceReason = const Value.absent(),
                required ItemSource source,
                Value<int?> foodId = const Value.absent(),
              }) => EntryItemsCompanion.insert(
                id: id,
                entryId: entryId,
                name: name,
                nameNormalised: nameNormalised,
                portionDesc: portionDesc,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                confidence: confidence,
                confidenceReason: confidenceReason,
                source: source,
                foodId: foodId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$EntryItemsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$EntryItemsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$DiaryDb,
      $EntryItemsTable,
      EntryItem,
      $$EntryItemsTableFilterComposer,
      $$EntryItemsTableOrderingComposer,
      $$EntryItemsTableAnnotationComposer,
      $$EntryItemsTableCreateCompanionBuilder,
      $$EntryItemsTableUpdateCompanionBuilder,
      (EntryItem, $$EntryItemsTableReferences),
      EntryItem,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$FoodCacheEntriesTableCreateCompanionBuilder =
    FoodCacheEntriesCompanion Function({
      required String nameNormalised,
      required double kcal100g,
      required double protein100g,
      required double carbs100g,
      required double fat100g,
      required DateTime lastUsedAt,
      Value<int> useCount,
      Value<int> rowid,
    });
typedef $$FoodCacheEntriesTableUpdateCompanionBuilder =
    FoodCacheEntriesCompanion Function({
      Value<String> nameNormalised,
      Value<double> kcal100g,
      Value<double> protein100g,
      Value<double> carbs100g,
      Value<double> fat100g,
      Value<DateTime> lastUsedAt,
      Value<int> useCount,
      Value<int> rowid,
    });

class $$FoodCacheEntriesTableFilterComposer
    extends Composer<_$DiaryDb, $FoodCacheEntriesTable> {
  $$FoodCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100g => $composableBuilder(
    column: $table.kcal100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100g => $composableBuilder(
    column: $table.protein100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs100g => $composableBuilder(
    column: $table.carbs100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100g => $composableBuilder(
    column: $table.fat100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodCacheEntriesTableOrderingComposer
    extends Composer<_$DiaryDb, $FoodCacheEntriesTable> {
  $$FoodCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100g => $composableBuilder(
    column: $table.kcal100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100g => $composableBuilder(
    column: $table.protein100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs100g => $composableBuilder(
    column: $table.carbs100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100g => $composableBuilder(
    column: $table.fat100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodCacheEntriesTableAnnotationComposer
    extends Composer<_$DiaryDb, $FoodCacheEntriesTable> {
  $$FoodCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nameNormalised => $composableBuilder(
    column: $table.nameNormalised,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kcal100g =>
      $composableBuilder(column: $table.kcal100g, builder: (column) => column);

  GeneratedColumn<double> get protein100g => $composableBuilder(
    column: $table.protein100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbs100g =>
      $composableBuilder(column: $table.carbs100g, builder: (column) => column);

  GeneratedColumn<double> get fat100g =>
      $composableBuilder(column: $table.fat100g, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);
}

class $$FoodCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$DiaryDb,
          $FoodCacheEntriesTable,
          FoodCacheEntry,
          $$FoodCacheEntriesTableFilterComposer,
          $$FoodCacheEntriesTableOrderingComposer,
          $$FoodCacheEntriesTableAnnotationComposer,
          $$FoodCacheEntriesTableCreateCompanionBuilder,
          $$FoodCacheEntriesTableUpdateCompanionBuilder,
          (
            FoodCacheEntry,
            BaseReferences<_$DiaryDb, $FoodCacheEntriesTable, FoodCacheEntry>,
          ),
          FoodCacheEntry,
          PrefetchHooks Function()
        > {
  $$FoodCacheEntriesTableTableManager(
    _$DiaryDb db,
    $FoodCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodCacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nameNormalised = const Value.absent(),
                Value<double> kcal100g = const Value.absent(),
                Value<double> protein100g = const Value.absent(),
                Value<double> carbs100g = const Value.absent(),
                Value<double> fat100g = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodCacheEntriesCompanion(
                nameNormalised: nameNormalised,
                kcal100g: kcal100g,
                protein100g: protein100g,
                carbs100g: carbs100g,
                fat100g: fat100g,
                lastUsedAt: lastUsedAt,
                useCount: useCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nameNormalised,
                required double kcal100g,
                required double protein100g,
                required double carbs100g,
                required double fat100g,
                required DateTime lastUsedAt,
                Value<int> useCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodCacheEntriesCompanion.insert(
                nameNormalised: nameNormalised,
                kcal100g: kcal100g,
                protein100g: protein100g,
                carbs100g: carbs100g,
                fat100g: fat100g,
                lastUsedAt: lastUsedAt,
                useCount: useCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$DiaryDb,
      $FoodCacheEntriesTable,
      FoodCacheEntry,
      $$FoodCacheEntriesTableFilterComposer,
      $$FoodCacheEntriesTableOrderingComposer,
      $$FoodCacheEntriesTableAnnotationComposer,
      $$FoodCacheEntriesTableCreateCompanionBuilder,
      $$FoodCacheEntriesTableUpdateCompanionBuilder,
      (
        FoodCacheEntry,
        BaseReferences<_$DiaryDb, $FoodCacheEntriesTable, FoodCacheEntry>,
      ),
      FoodCacheEntry,
      PrefetchHooks Function()
    >;

class $DiaryDbManager {
  final _$DiaryDb _db;
  $DiaryDbManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$EntryItemsTableTableManager get entryItems =>
      $$EntryItemsTableTableManager(_db, _db.entryItems);
  $$FoodCacheEntriesTableTableManager get foodCacheEntries =>
      $$FoodCacheEntriesTableTableManager(_db, _db.foodCacheEntries);
}
