// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foods_db.dart';

// ignore_for_file: type=lint
class Foods extends Table with TableInfo<Foods, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Foods(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameNormalisedMeta = const VerificationMeta(
    'nameNormalised',
  );
  late final GeneratedColumn<String> nameNormalised = GeneratedColumn<String>(
    'name_normalised',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _localeHintMeta = const VerificationMeta(
    'localeHint',
  );
  late final GeneratedColumn<String> localeHint = GeneratedColumn<String>(
    'locale_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _kcal100gMeta = const VerificationMeta(
    'kcal100g',
  );
  late final GeneratedColumn<double> kcal100g = GeneratedColumn<double>(
    'kcal_100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _protein100gMeta = const VerificationMeta(
    'protein100g',
  );
  late final GeneratedColumn<double> protein100g = GeneratedColumn<double>(
    'protein_100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _carbs100gMeta = const VerificationMeta(
    'carbs100g',
  );
  late final GeneratedColumn<double> carbs100g = GeneratedColumn<double>(
    'carbs_100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fat100gMeta = const VerificationMeta(
    'fat100g',
  );
  late final GeneratedColumn<double> fat100g = GeneratedColumn<double>(
    'fat_100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameNormalised,
    source,
    sourceId,
    localeHint,
    kcal100g,
    protein100g,
    carbs100g,
    fat100g,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('locale_hint')) {
      context.handle(
        _localeHintMeta,
        localeHint.isAcceptableOrUnknown(data['locale_hint']!, _localeHintMeta),
      );
    }
    if (data.containsKey('kcal_100g')) {
      context.handle(
        _kcal100gMeta,
        kcal100g.isAcceptableOrUnknown(data['kcal_100g']!, _kcal100gMeta),
      );
    } else if (isInserting) {
      context.missing(_kcal100gMeta);
    }
    if (data.containsKey('protein_100g')) {
      context.handle(
        _protein100gMeta,
        protein100g.isAcceptableOrUnknown(
          data['protein_100g']!,
          _protein100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protein100gMeta);
    }
    if (data.containsKey('carbs_100g')) {
      context.handle(
        _carbs100gMeta,
        carbs100g.isAcceptableOrUnknown(data['carbs_100g']!, _carbs100gMeta),
      );
    } else if (isInserting) {
      context.missing(_carbs100gMeta);
    }
    if (data.containsKey('fat_100g')) {
      context.handle(
        _fat100gMeta,
        fat100g.isAcceptableOrUnknown(data['fat_100g']!, _fat100gMeta),
      );
    } else if (isInserting) {
      context.missing(_fat100gMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameNormalised: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_normalised'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      localeHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_hint'],
      ),
      kcal100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_100g'],
      )!,
      protein100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_100g'],
      )!,
      carbs100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_100g'],
      )!,
      fat100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_100g'],
      )!,
    );
  }

  @override
  Foods createAlias(String alias) {
    return Foods(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Food extends DataClass implements Insertable<Food> {
  final int id;
  final String name;
  final String nameNormalised;

  /// 'usda_sr' | 'usda_foundation' | 'usda_fndds' | 'cofid' | 'ciqual'
  /// | 'cnf' | 'frida' | 'indb' | 'pakistan_fct'
  final String source;

  /// The key in the originating dataset, so any row can be traced back.
  final String? sourceId;

  /// 'IN' | 'PK' | 'GB' | 'FR' | 'CA' | 'DK' | 'US'. A ranking bias only —
  /// never a filter. Nobody's search results get narrowed by their locale.
  final String? localeHint;
  final double kcal100g;
  final double protein100g;
  final double carbs100g;
  final double fat100g;
  const Food({
    required this.id,
    required this.name,
    required this.nameNormalised,
    required this.source,
    this.sourceId,
    this.localeHint,
    required this.kcal100g,
    required this.protein100g,
    required this.carbs100g,
    required this.fat100g,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['name_normalised'] = Variable<String>(nameNormalised);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || localeHint != null) {
      map['locale_hint'] = Variable<String>(localeHint);
    }
    map['kcal_100g'] = Variable<double>(kcal100g);
    map['protein_100g'] = Variable<double>(protein100g);
    map['carbs_100g'] = Variable<double>(carbs100g);
    map['fat_100g'] = Variable<double>(fat100g);
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      nameNormalised: Value(nameNormalised),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      localeHint: localeHint == null && nullToAbsent
          ? const Value.absent()
          : Value(localeHint),
      kcal100g: Value(kcal100g),
      protein100g: Value(protein100g),
      carbs100g: Value(carbs100g),
      fat100g: Value(fat100g),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameNormalised: serializer.fromJson<String>(json['name_normalised']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['source_id']),
      localeHint: serializer.fromJson<String?>(json['locale_hint']),
      kcal100g: serializer.fromJson<double>(json['kcal_100g']),
      protein100g: serializer.fromJson<double>(json['protein_100g']),
      carbs100g: serializer.fromJson<double>(json['carbs_100g']),
      fat100g: serializer.fromJson<double>(json['fat_100g']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'name_normalised': serializer.toJson<String>(nameNormalised),
      'source': serializer.toJson<String>(source),
      'source_id': serializer.toJson<String?>(sourceId),
      'locale_hint': serializer.toJson<String?>(localeHint),
      'kcal_100g': serializer.toJson<double>(kcal100g),
      'protein_100g': serializer.toJson<double>(protein100g),
      'carbs_100g': serializer.toJson<double>(carbs100g),
      'fat_100g': serializer.toJson<double>(fat100g),
    };
  }

  Food copyWith({
    int? id,
    String? name,
    String? nameNormalised,
    String? source,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> localeHint = const Value.absent(),
    double? kcal100g,
    double? protein100g,
    double? carbs100g,
    double? fat100g,
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    nameNormalised: nameNormalised ?? this.nameNormalised,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    localeHint: localeHint.present ? localeHint.value : this.localeHint,
    kcal100g: kcal100g ?? this.kcal100g,
    protein100g: protein100g ?? this.protein100g,
    carbs100g: carbs100g ?? this.carbs100g,
    fat100g: fat100g ?? this.fat100g,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameNormalised: data.nameNormalised.present
          ? data.nameNormalised.value
          : this.nameNormalised,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      localeHint: data.localeHint.present
          ? data.localeHint.value
          : this.localeHint,
      kcal100g: data.kcal100g.present ? data.kcal100g.value : this.kcal100g,
      protein100g: data.protein100g.present
          ? data.protein100g.value
          : this.protein100g,
      carbs100g: data.carbs100g.present ? data.carbs100g.value : this.carbs100g,
      fat100g: data.fat100g.present ? data.fat100g.value : this.fat100g,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('localeHint: $localeHint, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carbs100g: $carbs100g, ')
          ..write('fat100g: $fat100g')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameNormalised,
    source,
    sourceId,
    localeHint,
    kcal100g,
    protein100g,
    carbs100g,
    fat100g,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameNormalised == this.nameNormalised &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.localeHint == this.localeHint &&
          other.kcal100g == this.kcal100g &&
          other.protein100g == this.protein100g &&
          other.carbs100g == this.carbs100g &&
          other.fat100g == this.fat100g);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> nameNormalised;
  final Value<String> source;
  final Value<String?> sourceId;
  final Value<String?> localeHint;
  final Value<double> kcal100g;
  final Value<double> protein100g;
  final Value<double> carbs100g;
  final Value<double> fat100g;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNormalised = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.localeHint = const Value.absent(),
    this.kcal100g = const Value.absent(),
    this.protein100g = const Value.absent(),
    this.carbs100g = const Value.absent(),
    this.fat100g = const Value.absent(),
  });
  FoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String nameNormalised,
    required String source,
    this.sourceId = const Value.absent(),
    this.localeHint = const Value.absent(),
    required double kcal100g,
    required double protein100g,
    required double carbs100g,
    required double fat100g,
  }) : name = Value(name),
       nameNormalised = Value(nameNormalised),
       source = Value(source),
       kcal100g = Value(kcal100g),
       protein100g = Value(protein100g),
       carbs100g = Value(carbs100g),
       fat100g = Value(fat100g);
  static Insertable<Food> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameNormalised,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? localeHint,
    Expression<double>? kcal100g,
    Expression<double>? protein100g,
    Expression<double>? carbs100g,
    Expression<double>? fat100g,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameNormalised != null) 'name_normalised': nameNormalised,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (localeHint != null) 'locale_hint': localeHint,
      if (kcal100g != null) 'kcal_100g': kcal100g,
      if (protein100g != null) 'protein_100g': protein100g,
      if (carbs100g != null) 'carbs_100g': carbs100g,
      if (fat100g != null) 'fat_100g': fat100g,
    });
  }

  FoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? nameNormalised,
    Value<String>? source,
    Value<String?>? sourceId,
    Value<String?>? localeHint,
    Value<double>? kcal100g,
    Value<double>? protein100g,
    Value<double>? carbs100g,
    Value<double>? fat100g,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameNormalised: nameNormalised ?? this.nameNormalised,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      localeHint: localeHint ?? this.localeHint,
      kcal100g: kcal100g ?? this.kcal100g,
      protein100g: protein100g ?? this.protein100g,
      carbs100g: carbs100g ?? this.carbs100g,
      fat100g: fat100g ?? this.fat100g,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNormalised.present) {
      map['name_normalised'] = Variable<String>(nameNormalised.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (localeHint.present) {
      map['locale_hint'] = Variable<String>(localeHint.value);
    }
    if (kcal100g.present) {
      map['kcal_100g'] = Variable<double>(kcal100g.value);
    }
    if (protein100g.present) {
      map['protein_100g'] = Variable<double>(protein100g.value);
    }
    if (carbs100g.present) {
      map['carbs_100g'] = Variable<double>(carbs100g.value);
    }
    if (fat100g.present) {
      map['fat_100g'] = Variable<double>(fat100g.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameNormalised: $nameNormalised, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('localeHint: $localeHint, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carbs100g: $carbs100g, ')
          ..write('fat100g: $fat100g')
          ..write(')'))
        .toString();
  }
}

class FoodPortions extends Table with TableInfo<FoodPortions, FoodPortion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FoodPortions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES foods(id)',
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  late final GeneratedColumn<int> isDefault = GeneratedColumn<int>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, foodId, label, grams, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_portions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodPortion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodPortion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodPortion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  FoodPortions createAlias(String alias) {
    return FoodPortions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FoodPortion extends DataClass implements Insertable<FoodPortion> {
  final int id;
  final int foodId;
  final String label;
  final double grams;
  final int isDefault;
  const FoodPortion({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['food_id'] = Variable<int>(foodId);
    map['label'] = Variable<String>(label);
    map['grams'] = Variable<double>(grams);
    map['is_default'] = Variable<int>(isDefault);
    return map;
  }

  FoodPortionsCompanion toCompanion(bool nullToAbsent) {
    return FoodPortionsCompanion(
      id: Value(id),
      foodId: Value(foodId),
      label: Value(label),
      grams: Value(grams),
      isDefault: Value(isDefault),
    );
  }

  factory FoodPortion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodPortion(
      id: serializer.fromJson<int>(json['id']),
      foodId: serializer.fromJson<int>(json['food_id']),
      label: serializer.fromJson<String>(json['label']),
      grams: serializer.fromJson<double>(json['grams']),
      isDefault: serializer.fromJson<int>(json['is_default']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'food_id': serializer.toJson<int>(foodId),
      'label': serializer.toJson<String>(label),
      'grams': serializer.toJson<double>(grams),
      'is_default': serializer.toJson<int>(isDefault),
    };
  }

  FoodPortion copyWith({
    int? id,
    int? foodId,
    String? label,
    double? grams,
    int? isDefault,
  }) => FoodPortion(
    id: id ?? this.id,
    foodId: foodId ?? this.foodId,
    label: label ?? this.label,
    grams: grams ?? this.grams,
    isDefault: isDefault ?? this.isDefault,
  );
  FoodPortion copyWithCompanion(FoodPortionsCompanion data) {
    return FoodPortion(
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      label: data.label.present ? data.label.value : this.label,
      grams: data.grams.present ? data.grams.value : this.grams,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodPortion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, foodId, label, grams, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPortion &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.label == this.label &&
          other.grams == this.grams &&
          other.isDefault == this.isDefault);
}

class FoodPortionsCompanion extends UpdateCompanion<FoodPortion> {
  final Value<int> id;
  final Value<int> foodId;
  final Value<String> label;
  final Value<double> grams;
  final Value<int> isDefault;
  const FoodPortionsCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.label = const Value.absent(),
    this.grams = const Value.absent(),
    this.isDefault = const Value.absent(),
  });
  FoodPortionsCompanion.insert({
    this.id = const Value.absent(),
    required int foodId,
    required String label,
    required double grams,
    this.isDefault = const Value.absent(),
  }) : foodId = Value(foodId),
       label = Value(label),
       grams = Value(grams);
  static Insertable<FoodPortion> custom({
    Expression<int>? id,
    Expression<int>? foodId,
    Expression<String>? label,
    Expression<double>? grams,
    Expression<int>? isDefault,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (label != null) 'label': label,
      if (grams != null) 'grams': grams,
      if (isDefault != null) 'is_default': isDefault,
    });
  }

  FoodPortionsCompanion copyWith({
    Value<int>? id,
    Value<int>? foodId,
    Value<String>? label,
    Value<double>? grams,
    Value<int>? isDefault,
  }) {
    return FoodPortionsCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      label: label ?? this.label,
      grams: grams ?? this.grams,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodPortionsCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }
}

class FoodsFts extends Table
    with TableInfo<FoodsFts, FoodsFt>, VirtualTableInfo<FoodsFts, FoodsFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FoodsFts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodsFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  FoodsFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodsFt(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  FoodsFts createAlias(String alias) {
    return FoodsFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(name, content = foods, content_rowid = id, tokenize = "unicode61 remove_diacritics 2")';
}

class FoodsFt extends DataClass implements Insertable<FoodsFt> {
  final String name;
  const FoodsFt({required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    return map;
  }

  FoodsFtsCompanion toCompanion(bool nullToAbsent) {
    return FoodsFtsCompanion(name: Value(name));
  }

  factory FoodsFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodsFt(name: serializer.fromJson<String>(json['name']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'name': serializer.toJson<String>(name)};
  }

  FoodsFt copyWith({String? name}) => FoodsFt(name: name ?? this.name);
  FoodsFt copyWithCompanion(FoodsFtsCompanion data) {
    return FoodsFt(name: data.name.present ? data.name.value : this.name);
  }

  @override
  String toString() {
    return (StringBuffer('FoodsFt(')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => name.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FoodsFt && other.name == this.name);
}

class FoodsFtsCompanion extends UpdateCompanion<FoodsFt> {
  final Value<String> name;
  final Value<int> rowid;
  const FoodsFtsCompanion({
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodsFtsCompanion.insert({
    required String name,
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FoodsFt> custom({
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodsFtsCompanion copyWith({Value<String>? name, Value<int>? rowid}) {
    return FoodsFtsCompanion(
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsFtsCompanion(')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Meta extends Table with TableInfo<Meta, MetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Meta(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  MetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  Meta createAlias(String alias) {
    return Meta(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MetaData extends DataClass implements Insertable<MetaData> {
  final String name;
  final String value;
  const MetaData({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(name: Value(name), value: Value(value));
  }

  factory MetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaData copyWith({String? name, String? value}) =>
      MetaData(name: name ?? this.name, value: value ?? this.value);
  MetaData copyWithCompanion(MetaCompanion data) {
    return MetaData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaData &&
          other.name == this.name &&
          other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaData> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<MetaData> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FoodsDb extends GeneratedDatabase {
  _$FoodsDb(QueryExecutor e) : super(e);
  $FoodsDbManager get managers => $FoodsDbManager(this);
  late final Foods foods = Foods(this);
  late final FoodPortions foodPortions = FoodPortions(this);
  late final Index idxFoodPortionsFood = Index(
    'idx_food_portions_food',
    'CREATE INDEX idx_food_portions_food ON food_portions (food_id)',
  );
  late final FoodsFts foodsFts = FoodsFts(this);
  late final Meta meta = Meta(this);
  Selectable<SearchFoodsResult> searchFoods({
    required String query,
    required String prefix,
    required int lim,
  }) {
    return customSelect(
      'SELECT"f"."id" AS "nested_0.id", "f"."name" AS "nested_0.name", "f"."name_normalised" AS "nested_0.name_normalised", "f"."source" AS "nested_0.source", "f"."source_id" AS "nested_0.source_id", "f"."locale_hint" AS "nested_0.locale_hint", "f"."kcal_100g" AS "nested_0.kcal_100g", "f"."protein_100g" AS "nested_0.protein_100g", "f"."carbs_100g" AS "nested_0.carbs_100g", "f"."fat_100g" AS "nested_0.fat_100g", bm25(foods_fts) AS score FROM foods_fts JOIN foods AS f ON f.id = foods_fts."rowid" WHERE foods_fts MATCH ?1 ORDER BY(CASE WHEN f.name_normalised = ?2 THEN 0 WHEN f.name_normalised LIKE ?2 || \' %\' THEN 1 WHEN f.name_normalised LIKE ?2 || \'%\' THEN 2 ELSE 3 END), score, length(f.name) LIMIT ?3',
      variables: [
        Variable<String>(query),
        Variable<String>(prefix),
        Variable<int>(lim),
      ],
      readsFrom: {foodsFts, foods},
    ).asyncMap(
      (QueryRow row) async => SearchFoodsResult(
        f: await foods.mapFromRow(row, tablePrefix: 'nested_0'),
        score: row.read<double>('score'),
      ),
    );
  }

  Selectable<Food> foodById({required int id}) {
    return customSelect(
      'SELECT * FROM foods WHERE id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {foods},
    ).asyncMap(foods.mapFromRow);
  }

  Selectable<FoodPortion> portionsForFood({required int foodId}) {
    return customSelect(
      'SELECT * FROM food_portions WHERE food_id = ?1 ORDER BY is_default DESC, grams ASC',
      variables: [Variable<int>(foodId)],
      readsFrom: {foodPortions},
    ).asyncMap(foodPortions.mapFromRow);
  }

  Selectable<MetaData> allMeta() {
    return customSelect(
      'SELECT * FROM meta ORDER BY name',
      variables: [],
      readsFrom: {meta},
    ).asyncMap(meta.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foods,
    foodPortions,
    idxFoodPortionsFood,
    foodsFts,
    meta,
  ];
}

typedef $FoodsCreateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  required String name,
  required String nameNormalised,
  required String source,
  Value<String?> sourceId,
  Value<String?> localeHint,
  required double kcal100g,
  required double protein100g,
  required double carbs100g,
  required double fat100g,
});
typedef $FoodsUpdateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> nameNormalised,
  Value<String> source,
  Value<String?> sourceId,
  Value<String?> localeHint,
  Value<double> kcal100g,
  Value<double> protein100g,
  Value<double> carbs100g,
  Value<double> fat100g,
});

final class $FoodsReferences extends BaseReferences<_$FoodsDb, Foods, Food> {
  $FoodsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<FoodPortions, List<FoodPortion>>
  _foodPortionsRefsTable(_$FoodsDb db) => MultiTypedResultKey.fromTable(
    db.foodPortions,
    aliasName: 'foods__id__food_portions__food_id',
  );

  $FoodPortionsProcessedTableManager get foodPortionsRefs {
    final manager = $FoodPortionsTableManager(
      $_db,
      $_db.foodPortions,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodPortionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $FoodsFilterComposer extends Composer<_$FoodsDb, Foods> {
  $FoodsFilterComposer({
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeHint => $composableBuilder(
    column: $table.localeHint,
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

  Expression<bool> foodPortionsRefs(
    Expression<bool> Function($FoodPortionsFilterComposer f) f,
  ) {
    final $FoodPortionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodPortions,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FoodPortionsFilterComposer(
            $db: $db,
            $table: $db.foodPortions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FoodsOrderingComposer extends Composer<_$FoodsDb, Foods> {
  $FoodsOrderingComposer({
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeHint => $composableBuilder(
    column: $table.localeHint,
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
}

class $FoodsAnnotationComposer extends Composer<_$FoodsDb, Foods> {
  $FoodsAnnotationComposer({
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get localeHint => $composableBuilder(
    column: $table.localeHint,
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

  Expression<T> foodPortionsRefs<T extends Object>(
    Expression<T> Function($FoodPortionsAnnotationComposer a) f,
  ) {
    final $FoodPortionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodPortions,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FoodPortionsAnnotationComposer(
            $db: $db,
            $table: $db.foodPortions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FoodsTableManager
    extends
        RootTableManager<
          _$FoodsDb,
          Foods,
          Food,
          $FoodsFilterComposer,
          $FoodsOrderingComposer,
          $FoodsAnnotationComposer,
          $FoodsCreateCompanionBuilder,
          $FoodsUpdateCompanionBuilder,
          (Food, $FoodsReferences),
          Food,
          PrefetchHooks Function({bool foodPortionsRefs})
        > {
  $FoodsTableManager(_$FoodsDb db, Foods table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FoodsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FoodsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FoodsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameNormalised = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> localeHint = const Value.absent(),
                Value<double> kcal100g = const Value.absent(),
                Value<double> protein100g = const Value.absent(),
                Value<double> carbs100g = const Value.absent(),
                Value<double> fat100g = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                nameNormalised: nameNormalised,
                source: source,
                sourceId: sourceId,
                localeHint: localeHint,
                kcal100g: kcal100g,
                protein100g: protein100g,
                carbs100g: carbs100g,
                fat100g: fat100g,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String nameNormalised,
                required String source,
                Value<String?> sourceId = const Value.absent(),
                Value<String?> localeHint = const Value.absent(),
                required double kcal100g,
                required double protein100g,
                required double carbs100g,
                required double fat100g,
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                nameNormalised: nameNormalised,
                source: source,
                sourceId: sourceId,
                localeHint: localeHint,
                kcal100g: kcal100g,
                protein100g: protein100g,
                carbs100g: carbs100g,
                fat100g: fat100g,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $FoodsReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({foodPortionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (foodPortionsRefs) db.foodPortions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (foodPortionsRefs)
                    await $_getPrefetchedData<Food, Foods, FoodPortion>(
                      currentTable: table,
                      referencedTable: $FoodsReferences._foodPortionsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $FoodsReferences(db, table, p0).foodPortionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.foodId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $FoodsProcessedTableManager =
    ProcessedTableManager<
      _$FoodsDb,
      Foods,
      Food,
      $FoodsFilterComposer,
      $FoodsOrderingComposer,
      $FoodsAnnotationComposer,
      $FoodsCreateCompanionBuilder,
      $FoodsUpdateCompanionBuilder,
      (Food, $FoodsReferences),
      Food,
      PrefetchHooks Function({bool foodPortionsRefs})
    >;
typedef $FoodPortionsCreateCompanionBuilder = FoodPortionsCompanion Function({
  Value<int> id,
  required int foodId,
  required String label,
  required double grams,
  Value<int> isDefault,
});
typedef $FoodPortionsUpdateCompanionBuilder = FoodPortionsCompanion Function({
  Value<int> id,
  Value<int> foodId,
  Value<String> label,
  Value<double> grams,
  Value<int> isDefault,
});

final class $FoodPortionsReferences
    extends BaseReferences<_$FoodsDb, FoodPortions, FoodPortion> {
  $FoodPortionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Foods _foodIdTable(_$FoodsDb db) =>
      db.foods.createAlias('food_portions__food_id__foods__id');

  $FoodsProcessedTableManager get foodId {
    final $_column = $_itemColumn<int>('food_id')!;

    final manager = $FoodsTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $FoodPortionsFilterComposer extends Composer<_$FoodsDb, FoodPortions> {
  $FoodPortionsFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  $FoodsFilterComposer get foodId {
    final $FoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FoodsFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FoodPortionsOrderingComposer extends Composer<_$FoodsDb, FoodPortions> {
  $FoodPortionsOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $FoodsOrderingComposer get foodId {
    final $FoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FoodsOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FoodPortionsAnnotationComposer
    extends Composer<_$FoodsDb, FoodPortions> {
  $FoodPortionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<int> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  $FoodsAnnotationComposer get foodId {
    final $FoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FoodsAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FoodPortionsTableManager
    extends
        RootTableManager<
          _$FoodsDb,
          FoodPortions,
          FoodPortion,
          $FoodPortionsFilterComposer,
          $FoodPortionsOrderingComposer,
          $FoodPortionsAnnotationComposer,
          $FoodPortionsCreateCompanionBuilder,
          $FoodPortionsUpdateCompanionBuilder,
          (FoodPortion, $FoodPortionsReferences),
          FoodPortion,
          PrefetchHooks Function({bool foodId})
        > {
  $FoodPortionsTableManager(_$FoodsDb db, FoodPortions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FoodPortionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FoodPortionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FoodPortionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<int> isDefault = const Value.absent(),
              }) => FoodPortionsCompanion(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int foodId,
                required String label,
                required double grams,
                Value<int> isDefault = const Value.absent(),
              }) => FoodPortionsCompanion.insert(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $FoodPortionsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
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
                    if (foodId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.foodId,
                        referencedTable: $FoodPortionsReferences._foodIdTable(
                          db,
                        ),
                        referencedColumn: $FoodPortionsReferences
                            ._foodIdTable(db)
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

typedef $FoodPortionsProcessedTableManager =
    ProcessedTableManager<
      _$FoodsDb,
      FoodPortions,
      FoodPortion,
      $FoodPortionsFilterComposer,
      $FoodPortionsOrderingComposer,
      $FoodPortionsAnnotationComposer,
      $FoodPortionsCreateCompanionBuilder,
      $FoodPortionsUpdateCompanionBuilder,
      (FoodPortion, $FoodPortionsReferences),
      FoodPortion,
      PrefetchHooks Function({bool foodId})
    >;
typedef $FoodsFtsCreateCompanionBuilder = FoodsFtsCompanion Function({
  required String name,
  Value<int> rowid,
});
typedef $FoodsFtsUpdateCompanionBuilder = FoodsFtsCompanion Function({
  Value<String> name,
  Value<int> rowid,
});

class $FoodsFtsFilterComposer extends Composer<_$FoodsDb, FoodsFts> {
  $FoodsFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $FoodsFtsOrderingComposer extends Composer<_$FoodsDb, FoodsFts> {
  $FoodsFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FoodsFtsAnnotationComposer extends Composer<_$FoodsDb, FoodsFts> {
  $FoodsFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $FoodsFtsTableManager
    extends
        RootTableManager<
          _$FoodsDb,
          FoodsFts,
          FoodsFt,
          $FoodsFtsFilterComposer,
          $FoodsFtsOrderingComposer,
          $FoodsFtsAnnotationComposer,
          $FoodsFtsCreateCompanionBuilder,
          $FoodsFtsUpdateCompanionBuilder,
          (FoodsFt, BaseReferences<_$FoodsDb, FoodsFts, FoodsFt>),
          FoodsFt,
          PrefetchHooks Function()
        > {
  $FoodsFtsTableManager(_$FoodsDb db, FoodsFts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FoodsFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FoodsFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FoodsFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => FoodsFtsCompanion(name: name, rowid: rowid),
          createCompanionCallback: ({
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => FoodsFtsCompanion.insert(name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FoodsFtsProcessedTableManager =
    ProcessedTableManager<
      _$FoodsDb,
      FoodsFts,
      FoodsFt,
      $FoodsFtsFilterComposer,
      $FoodsFtsOrderingComposer,
      $FoodsFtsAnnotationComposer,
      $FoodsFtsCreateCompanionBuilder,
      $FoodsFtsUpdateCompanionBuilder,
      (FoodsFt, BaseReferences<_$FoodsDb, FoodsFts, FoodsFt>),
      FoodsFt,
      PrefetchHooks Function()
    >;
typedef $MetaCreateCompanionBuilder = MetaCompanion Function({
  required String name,
  required String value,
  Value<int> rowid,
});
typedef $MetaUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> name,
  Value<String> value,
  Value<int> rowid,
});

class $MetaFilterComposer extends Composer<_$FoodsDb, Meta> {
  $MetaFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $MetaOrderingComposer extends Composer<_$FoodsDb, Meta> {
  $MetaOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MetaAnnotationComposer extends Composer<_$FoodsDb, Meta> {
  $MetaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $MetaTableManager
    extends
        RootTableManager<
          _$FoodsDb,
          Meta,
          MetaData,
          $MetaFilterComposer,
          $MetaOrderingComposer,
          $MetaAnnotationComposer,
          $MetaCreateCompanionBuilder,
          $MetaUpdateCompanionBuilder,
          (MetaData, BaseReferences<_$FoodsDb, Meta, MetaData>),
          MetaData,
          PrefetchHooks Function()
        > {
  $MetaTableManager(_$FoodsDb db, Meta table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MetaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MetaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MetaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String name,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion.insert(name: name, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MetaProcessedTableManager =
    ProcessedTableManager<
      _$FoodsDb,
      Meta,
      MetaData,
      $MetaFilterComposer,
      $MetaOrderingComposer,
      $MetaAnnotationComposer,
      $MetaCreateCompanionBuilder,
      $MetaUpdateCompanionBuilder,
      (MetaData, BaseReferences<_$FoodsDb, Meta, MetaData>),
      MetaData,
      PrefetchHooks Function()
    >;

class $FoodsDbManager {
  final _$FoodsDb _db;
  $FoodsDbManager(this._db);
  $FoodsTableManager get foods => $FoodsTableManager(_db, _db.foods);
  $FoodPortionsTableManager get foodPortions =>
      $FoodPortionsTableManager(_db, _db.foodPortions);
  $FoodsFtsTableManager get foodsFts =>
      $FoodsFtsTableManager(_db, _db.foodsFts);
  $MetaTableManager get meta => $MetaTableManager(_db, _db.meta);
}

class SearchFoodsResult {
  final Food f;
  final double score;
  SearchFoodsResult({required this.f, required this.score});
}
