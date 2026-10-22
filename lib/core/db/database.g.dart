// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProvidersTable extends Providers
    with TableInfo<$ProvidersTable, ProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvidersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyRefMeta = const VerificationMeta('keyRef');
  @override
  late final GeneratedColumn<String> keyRef = GeneratedColumn<String>(
    'key_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presetCodeMeta = const VerificationMeta(
    'presetCode',
  );
  @override
  late final GeneratedColumn<String> presetCode = GeneratedColumn<String>(
    'preset_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseUrl,
    keyRef,
    presetCode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderRow> instance, {
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
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('key_ref')) {
      context.handle(
        _keyRefMeta,
        keyRef.isAcceptableOrUnknown(data['key_ref']!, _keyRefMeta),
      );
    }
    if (data.containsKey('preset_code')) {
      context.handle(
        _presetCodeMeta,
        presetCode.isAcceptableOrUnknown(data['preset_code']!, _presetCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_presetCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      keyRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_ref'],
      ),
      presetCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProvidersTable createAlias(String alias) {
    return $ProvidersTable(attachedDatabase, alias);
  }
}

class ProviderRow extends DataClass implements Insertable<ProviderRow> {
  final int id;
  final String name;
  final String baseUrl;
  final String? keyRef;
  final String presetCode;
  final DateTime createdAt;
  const ProviderRow({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.keyRef,
    required this.presetCode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || keyRef != null) {
      map['key_ref'] = Variable<String>(keyRef);
    }
    map['preset_code'] = Variable<String>(presetCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProvidersCompanion toCompanion(bool nullToAbsent) {
    return ProvidersCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      keyRef: keyRef == null && nullToAbsent
          ? const Value.absent()
          : Value(keyRef),
      presetCode: Value(presetCode),
      createdAt: Value(createdAt),
    );
  }

  factory ProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      keyRef: serializer.fromJson<String?>(json['keyRef']),
      presetCode: serializer.fromJson<String>(json['presetCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'keyRef': serializer.toJson<String?>(keyRef),
      'presetCode': serializer.toJson<String>(presetCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProviderRow copyWith({
    int? id,
    String? name,
    String? baseUrl,
    Value<String?> keyRef = const Value.absent(),
    String? presetCode,
    DateTime? createdAt,
  }) => ProviderRow(
    id: id ?? this.id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    keyRef: keyRef.present ? keyRef.value : this.keyRef,
    presetCode: presetCode ?? this.presetCode,
    createdAt: createdAt ?? this.createdAt,
  );
  ProviderRow copyWithCompanion(ProvidersCompanion data) {
    return ProviderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      keyRef: data.keyRef.present ? data.keyRef.value : this.keyRef,
      presetCode: data.presetCode.present
          ? data.presetCode.value
          : this.presetCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('keyRef: $keyRef, ')
          ..write('presetCode: $presetCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, baseUrl, keyRef, presetCode, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.keyRef == this.keyRef &&
          other.presetCode == this.presetCode &&
          other.createdAt == this.createdAt);
}

class ProvidersCompanion extends UpdateCompanion<ProviderRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String?> keyRef;
  final Value<String> presetCode;
  final Value<DateTime> createdAt;
  const ProvidersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.keyRef = const Value.absent(),
    this.presetCode = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProvidersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String baseUrl,
    this.keyRef = const Value.absent(),
    required String presetCode,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       baseUrl = Value(baseUrl),
       presetCode = Value(presetCode);
  static Insertable<ProviderRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? keyRef,
    Expression<String>? presetCode,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (keyRef != null) 'key_ref': keyRef,
      if (presetCode != null) 'preset_code': presetCode,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProvidersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? baseUrl,
    Value<String?>? keyRef,
    Value<String>? presetCode,
    Value<DateTime>? createdAt,
  }) {
    return ProvidersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      keyRef: keyRef ?? this.keyRef,
      presetCode: presetCode ?? this.presetCode,
      createdAt: createdAt ?? this.createdAt,
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
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (keyRef.present) {
      map['key_ref'] = Variable<String>(keyRef.value);
    }
    if (presetCode.present) {
      map['preset_code'] = Variable<String>(presetCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvidersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('keyRef: $keyRef, ')
          ..write('presetCode: $presetCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ModelsTable extends Models with TableInfo<$ModelsTable, ModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id)',
    ),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    modelId,
    displayName,
    tags,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, modelId},
  ];
  @override
  ModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ModelsTable createAlias(String alias) {
    return $ModelsTable(attachedDatabase, alias);
  }
}

class ModelRow extends DataClass implements Insertable<ModelRow> {
  final int id;
  final int providerId;
  final String modelId;
  final String displayName;
  final String tags;
  final bool isActive;
  final DateTime updatedAt;
  const ModelRow({
    required this.id,
    required this.providerId,
    required this.modelId,
    required this.displayName,
    required this.tags,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['model_id'] = Variable<String>(modelId);
    map['display_name'] = Variable<String>(displayName);
    map['tags'] = Variable<String>(tags);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ModelsCompanion toCompanion(bool nullToAbsent) {
    return ModelsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      modelId: Value(modelId),
      displayName: Value(displayName),
      tags: Value(tags),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelRow(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      modelId: serializer.fromJson<String>(json['modelId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      tags: serializer.fromJson<String>(json['tags']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'modelId': serializer.toJson<String>(modelId),
      'displayName': serializer.toJson<String>(displayName),
      'tags': serializer.toJson<String>(tags),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ModelRow copyWith({
    int? id,
    int? providerId,
    String? modelId,
    String? displayName,
    String? tags,
    bool? isActive,
    DateTime? updatedAt,
  }) => ModelRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    modelId: modelId ?? this.modelId,
    displayName: displayName ?? this.displayName,
    tags: tags ?? this.tags,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ModelRow copyWithCompanion(ModelsCompanion data) {
    return ModelRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      tags: data.tags.present ? data.tags.value : this.tags,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('displayName: $displayName, ')
          ..write('tags: $tags, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    modelId,
    displayName,
    tags,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.displayName == this.displayName &&
          other.tags == this.tags &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ModelsCompanion extends UpdateCompanion<ModelRow> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<String> modelId;
  final Value<String> displayName;
  final Value<String> tags;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  const ModelsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.tags = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ModelsCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required String modelId,
    required String displayName,
    this.tags = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : providerId = Value(providerId),
       modelId = Value(modelId),
       displayName = Value(displayName);
  static Insertable<ModelRow> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? modelId,
    Expression<String>? displayName,
    Expression<String>? tags,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (displayName != null) 'display_name': displayName,
      if (tags != null) 'tags': tags,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ModelsCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<String>? modelId,
    Value<String>? displayName,
    Value<String>? tags,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
  }) {
    return ModelsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('displayName: $displayName, ')
          ..write('tags: $tags, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IntensityPresetsTable extends IntensityPresets
    with TableInfo<$IntensityPresetsTable, IntensityPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntensityPresetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _paramsMeta = const VerificationMeta('params');
  @override
  late final GeneratedColumn<String> params = GeneratedColumn<String>(
    'params',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, params, isBuiltin];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intensity_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntensityPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('params')) {
      context.handle(
        _paramsMeta,
        params.isAcceptableOrUnknown(data['params']!, _paramsMeta),
      );
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntensityPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntensityPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      params: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
    );
  }

  @override
  $IntensityPresetsTable createAlias(String alias) {
    return $IntensityPresetsTable(attachedDatabase, alias);
  }
}

class IntensityPreset extends DataClass implements Insertable<IntensityPreset> {
  final int id;
  final String code;
  final String name;
  final String params;
  final bool isBuiltin;
  const IntensityPreset({
    required this.id,
    required this.code,
    required this.name,
    required this.params,
    required this.isBuiltin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['params'] = Variable<String>(params);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    return map;
  }

  IntensityPresetsCompanion toCompanion(bool nullToAbsent) {
    return IntensityPresetsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      params: Value(params),
      isBuiltin: Value(isBuiltin),
    );
  }

  factory IntensityPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntensityPreset(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      params: serializer.fromJson<String>(json['params']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'params': serializer.toJson<String>(params),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
    };
  }

  IntensityPreset copyWith({
    int? id,
    String? code,
    String? name,
    String? params,
    bool? isBuiltin,
  }) => IntensityPreset(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    params: params ?? this.params,
    isBuiltin: isBuiltin ?? this.isBuiltin,
  );
  IntensityPreset copyWithCompanion(IntensityPresetsCompanion data) {
    return IntensityPreset(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      params: data.params.present ? data.params.value : this.params,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntensityPreset(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('params: $params, ')
          ..write('isBuiltin: $isBuiltin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, params, isBuiltin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntensityPreset &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.params == this.params &&
          other.isBuiltin == this.isBuiltin);
}

class IntensityPresetsCompanion extends UpdateCompanion<IntensityPreset> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> params;
  final Value<bool> isBuiltin;
  const IntensityPresetsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.params = const Value.absent(),
    this.isBuiltin = const Value.absent(),
  });
  IntensityPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.params = const Value.absent(),
    this.isBuiltin = const Value.absent(),
  }) : code = Value(code),
       name = Value(name);
  static Insertable<IntensityPreset> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? params,
    Expression<bool>? isBuiltin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (params != null) 'params': params,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
    });
  }

  IntensityPresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? params,
    Value<bool>? isBuiltin,
  }) {
    return IntensityPresetsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      params: params ?? this.params,
      isBuiltin: isBuiltin ?? this.isBuiltin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (params.present) {
      map['params'] = Variable<String>(params.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntensityPresetsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('params: $params, ')
          ..write('isBuiltin: $isBuiltin')
          ..write(')'))
        .toString();
  }
}

class $FragmentsTable extends Fragments
    with TableInfo<$FragmentsTable, Fragment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FragmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optimizedJsonMeta = const VerificationMeta(
    'optimizedJson',
  );
  @override
  late final GeneratedColumn<String> optimizedJson = GeneratedColumn<String>(
    'optimized_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FragmentSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FragmentSource>($FragmentsTable.$convertersource);
  static const VerificationMeta _aiMetaMeta = const VerificationMeta('aiMeta');
  @override
  late final GeneratedColumn<String> aiMeta = GeneratedColumn<String>(
    'ai_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FragmentStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => FragmentStatus.raw.name,
      ).withConverter<FragmentStatus>($FragmentsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    optimizedJson,
    title,
    tags,
    source,
    aiMeta,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fragments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fragment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('optimized_json')) {
      context.handle(
        _optimizedJsonMeta,
        optimizedJson.isAcceptableOrUnknown(
          data['optimized_json']!,
          _optimizedJsonMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('ai_meta')) {
      context.handle(
        _aiMetaMeta,
        aiMeta.isAcceptableOrUnknown(data['ai_meta']!, _aiMetaMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fragment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fragment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      optimizedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}optimized_json'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      source: $FragmentsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      aiMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_meta'],
      ),
      status: $FragmentsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FragmentsTable createAlias(String alias) {
    return $FragmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FragmentSource, String, String> $convertersource =
      const EnumNameConverter<FragmentSource>(FragmentSource.values);
  static JsonTypeConverter2<FragmentStatus, String, String> $converterstatus =
      const EnumNameConverter<FragmentStatus>(FragmentStatus.values);
}

class Fragment extends DataClass implements Insertable<Fragment> {
  final int id;
  final String rawText;
  final String? optimizedJson;
  final String title;
  final String tags;
  final FragmentSource source;
  final String? aiMeta;
  final FragmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Fragment({
    required this.id,
    required this.rawText,
    this.optimizedJson,
    required this.title,
    required this.tags,
    required this.source,
    this.aiMeta,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || optimizedJson != null) {
      map['optimized_json'] = Variable<String>(optimizedJson);
    }
    map['title'] = Variable<String>(title);
    map['tags'] = Variable<String>(tags);
    {
      map['source'] = Variable<String>(
        $FragmentsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || aiMeta != null) {
      map['ai_meta'] = Variable<String>(aiMeta);
    }
    {
      map['status'] = Variable<String>(
        $FragmentsTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FragmentsCompanion toCompanion(bool nullToAbsent) {
    return FragmentsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      optimizedJson: optimizedJson == null && nullToAbsent
          ? const Value.absent()
          : Value(optimizedJson),
      title: Value(title),
      tags: Value(tags),
      source: Value(source),
      aiMeta: aiMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(aiMeta),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Fragment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fragment(
      id: serializer.fromJson<int>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      optimizedJson: serializer.fromJson<String?>(json['optimizedJson']),
      title: serializer.fromJson<String>(json['title']),
      tags: serializer.fromJson<String>(json['tags']),
      source: $FragmentsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      aiMeta: serializer.fromJson<String?>(json['aiMeta']),
      status: $FragmentsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawText': serializer.toJson<String>(rawText),
      'optimizedJson': serializer.toJson<String?>(optimizedJson),
      'title': serializer.toJson<String>(title),
      'tags': serializer.toJson<String>(tags),
      'source': serializer.toJson<String>(
        $FragmentsTable.$convertersource.toJson(source),
      ),
      'aiMeta': serializer.toJson<String?>(aiMeta),
      'status': serializer.toJson<String>(
        $FragmentsTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Fragment copyWith({
    int? id,
    String? rawText,
    Value<String?> optimizedJson = const Value.absent(),
    String? title,
    String? tags,
    FragmentSource? source,
    Value<String?> aiMeta = const Value.absent(),
    FragmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Fragment(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    optimizedJson: optimizedJson.present
        ? optimizedJson.value
        : this.optimizedJson,
    title: title ?? this.title,
    tags: tags ?? this.tags,
    source: source ?? this.source,
    aiMeta: aiMeta.present ? aiMeta.value : this.aiMeta,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Fragment copyWithCompanion(FragmentsCompanion data) {
    return Fragment(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      optimizedJson: data.optimizedJson.present
          ? data.optimizedJson.value
          : this.optimizedJson,
      title: data.title.present ? data.title.value : this.title,
      tags: data.tags.present ? data.tags.value : this.tags,
      source: data.source.present ? data.source.value : this.source,
      aiMeta: data.aiMeta.present ? data.aiMeta.value : this.aiMeta,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fragment(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('optimizedJson: $optimizedJson, ')
          ..write('title: $title, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('aiMeta: $aiMeta, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    optimizedJson,
    title,
    tags,
    source,
    aiMeta,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fragment &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.optimizedJson == this.optimizedJson &&
          other.title == this.title &&
          other.tags == this.tags &&
          other.source == this.source &&
          other.aiMeta == this.aiMeta &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FragmentsCompanion extends UpdateCompanion<Fragment> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<String?> optimizedJson;
  final Value<String> title;
  final Value<String> tags;
  final Value<FragmentSource> source;
  final Value<String?> aiMeta;
  final Value<FragmentStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FragmentsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.optimizedJson = const Value.absent(),
    this.title = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.aiMeta = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FragmentsCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    this.optimizedJson = const Value.absent(),
    this.title = const Value.absent(),
    this.tags = const Value.absent(),
    required FragmentSource source,
    this.aiMeta = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : rawText = Value(rawText),
       source = Value(source);
  static Insertable<Fragment> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<String>? optimizedJson,
    Expression<String>? title,
    Expression<String>? tags,
    Expression<String>? source,
    Expression<String>? aiMeta,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (optimizedJson != null) 'optimized_json': optimizedJson,
      if (title != null) 'title': title,
      if (tags != null) 'tags': tags,
      if (source != null) 'source': source,
      if (aiMeta != null) 'ai_meta': aiMeta,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FragmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? rawText,
    Value<String?>? optimizedJson,
    Value<String>? title,
    Value<String>? tags,
    Value<FragmentSource>? source,
    Value<String?>? aiMeta,
    Value<FragmentStatus>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FragmentsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      optimizedJson: optimizedJson ?? this.optimizedJson,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      aiMeta: aiMeta ?? this.aiMeta,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (optimizedJson.present) {
      map['optimized_json'] = Variable<String>(optimizedJson.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $FragmentsTable.$convertersource.toSql(source.value),
      );
    }
    if (aiMeta.present) {
      map['ai_meta'] = Variable<String>(aiMeta.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $FragmentsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FragmentsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('optimizedJson: $optimizedJson, ')
          ..write('title: $title, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('aiMeta: $aiMeta, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PromptsTable extends Prompts with TableInfo<$PromptsTable, Prompt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PromptType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PromptType>($PromptsTable.$convertertype);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variablesMeta = const VerificationMeta(
    'variables',
  );
  @override
  late final GeneratedColumn<String> variables = GeneratedColumn<String>(
    'variables',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentVersionIdMeta = const VerificationMeta(
    'currentVersionId',
  );
  @override
  late final GeneratedColumn<int> currentVersionId = GeneratedColumn<int>(
    'current_version_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    body,
    variables,
    category,
    currentVersionId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prompt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('variables')) {
      context.handle(
        _variablesMeta,
        variables.isAcceptableOrUnknown(data['variables']!, _variablesMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('current_version_id')) {
      context.handle(
        _currentVersionIdMeta,
        currentVersionId.isAcceptableOrUnknown(
          data['current_version_id']!,
          _currentVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prompt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prompt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: $PromptsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      variables: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variables'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      currentVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_version_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PromptsTable createAlias(String alias) {
    return $PromptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PromptType, String, String> $convertertype =
      const EnumNameConverter<PromptType>(PromptType.values);
}

class Prompt extends DataClass implements Insertable<Prompt> {
  final int id;
  final String title;
  final PromptType type;
  final String body;
  final String variables;
  final String? category;
  final int? currentVersionId;
  final DateTime createdAt;
  const Prompt({
    required this.id,
    required this.title,
    required this.type,
    required this.body,
    required this.variables,
    this.category,
    this.currentVersionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    {
      map['type'] = Variable<String>($PromptsTable.$convertertype.toSql(type));
    }
    map['body'] = Variable<String>(body);
    map['variables'] = Variable<String>(variables);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || currentVersionId != null) {
      map['current_version_id'] = Variable<int>(currentVersionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PromptsCompanion toCompanion(bool nullToAbsent) {
    return PromptsCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      body: Value(body),
      variables: Value(variables),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      currentVersionId: currentVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentVersionId),
      createdAt: Value(createdAt),
    );
  }

  factory Prompt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prompt(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: $PromptsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      body: serializer.fromJson<String>(json['body']),
      variables: serializer.fromJson<String>(json['variables']),
      category: serializer.fromJson<String?>(json['category']),
      currentVersionId: serializer.fromJson<int?>(json['currentVersionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(
        $PromptsTable.$convertertype.toJson(type),
      ),
      'body': serializer.toJson<String>(body),
      'variables': serializer.toJson<String>(variables),
      'category': serializer.toJson<String?>(category),
      'currentVersionId': serializer.toJson<int?>(currentVersionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Prompt copyWith({
    int? id,
    String? title,
    PromptType? type,
    String? body,
    String? variables,
    Value<String?> category = const Value.absent(),
    Value<int?> currentVersionId = const Value.absent(),
    DateTime? createdAt,
  }) => Prompt(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    body: body ?? this.body,
    variables: variables ?? this.variables,
    category: category.present ? category.value : this.category,
    currentVersionId: currentVersionId.present
        ? currentVersionId.value
        : this.currentVersionId,
    createdAt: createdAt ?? this.createdAt,
  );
  Prompt copyWithCompanion(PromptsCompanion data) {
    return Prompt(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      body: data.body.present ? data.body.value : this.body,
      variables: data.variables.present ? data.variables.value : this.variables,
      category: data.category.present ? data.category.value : this.category,
      currentVersionId: data.currentVersionId.present
          ? data.currentVersionId.value
          : this.currentVersionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prompt(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('variables: $variables, ')
          ..write('category: $category, ')
          ..write('currentVersionId: $currentVersionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    body,
    variables,
    category,
    currentVersionId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prompt &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.body == this.body &&
          other.variables == this.variables &&
          other.category == this.category &&
          other.currentVersionId == this.currentVersionId &&
          other.createdAt == this.createdAt);
}

class PromptsCompanion extends UpdateCompanion<Prompt> {
  final Value<int> id;
  final Value<String> title;
  final Value<PromptType> type;
  final Value<String> body;
  final Value<String> variables;
  final Value<String?> category;
  final Value<int?> currentVersionId;
  final Value<DateTime> createdAt;
  const PromptsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.body = const Value.absent(),
    this.variables = const Value.absent(),
    this.category = const Value.absent(),
    this.currentVersionId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PromptsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required PromptType type,
    required String body,
    this.variables = const Value.absent(),
    this.category = const Value.absent(),
    this.currentVersionId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       type = Value(type),
       body = Value(body);
  static Insertable<Prompt> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? body,
    Expression<String>? variables,
    Expression<String>? category,
    Expression<int>? currentVersionId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (body != null) 'body': body,
      if (variables != null) 'variables': variables,
      if (category != null) 'category': category,
      if (currentVersionId != null) 'current_version_id': currentVersionId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PromptsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<PromptType>? type,
    Value<String>? body,
    Value<String>? variables,
    Value<String?>? category,
    Value<int?>? currentVersionId,
    Value<DateTime>? createdAt,
  }) {
    return PromptsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      body: body ?? this.body,
      variables: variables ?? this.variables,
      category: category ?? this.category,
      currentVersionId: currentVersionId ?? this.currentVersionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PromptsTable.$convertertype.toSql(type.value),
      );
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (variables.present) {
      map['variables'] = Variable<String>(variables.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (currentVersionId.present) {
      map['current_version_id'] = Variable<int>(currentVersionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('variables: $variables, ')
          ..write('category: $category, ')
          ..write('currentVersionId: $currentVersionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PromptVersionsTable extends PromptVersions
    with TableInfo<$PromptVersionsTable, PromptVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _promptIdMeta = const VerificationMeta(
    'promptId',
  );
  @override
  late final GeneratedColumn<int> promptId = GeneratedColumn<int>(
    'prompt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prompts (id)',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, promptId, body, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompt_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromptVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prompt_id')) {
      context.handle(
        _promptIdMeta,
        promptId.isAcceptableOrUnknown(data['prompt_id']!, _promptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_promptIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromptVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromptVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      promptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PromptVersionsTable createAlias(String alias) {
    return $PromptVersionsTable(attachedDatabase, alias);
  }
}

class PromptVersion extends DataClass implements Insertable<PromptVersion> {
  final int id;
  final int promptId;
  final String body;
  final String? note;
  final DateTime createdAt;
  const PromptVersion({
    required this.id,
    required this.promptId,
    required this.body,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prompt_id'] = Variable<int>(promptId);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PromptVersionsCompanion toCompanion(bool nullToAbsent) {
    return PromptVersionsCompanion(
      id: Value(id),
      promptId: Value(promptId),
      body: Value(body),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory PromptVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromptVersion(
      id: serializer.fromJson<int>(json['id']),
      promptId: serializer.fromJson<int>(json['promptId']),
      body: serializer.fromJson<String>(json['body']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'promptId': serializer.toJson<int>(promptId),
      'body': serializer.toJson<String>(body),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PromptVersion copyWith({
    int? id,
    int? promptId,
    String? body,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => PromptVersion(
    id: id ?? this.id,
    promptId: promptId ?? this.promptId,
    body: body ?? this.body,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  PromptVersion copyWithCompanion(PromptVersionsCompanion data) {
    return PromptVersion(
      id: data.id.present ? data.id.value : this.id,
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      body: data.body.present ? data.body.value : this.body,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromptVersion(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('body: $body, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, promptId, body, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromptVersion &&
          other.id == this.id &&
          other.promptId == this.promptId &&
          other.body == this.body &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PromptVersionsCompanion extends UpdateCompanion<PromptVersion> {
  final Value<int> id;
  final Value<int> promptId;
  final Value<String> body;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const PromptVersionsCompanion({
    this.id = const Value.absent(),
    this.promptId = const Value.absent(),
    this.body = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PromptVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int promptId,
    required String body,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : promptId = Value(promptId),
       body = Value(body);
  static Insertable<PromptVersion> custom({
    Expression<int>? id,
    Expression<int>? promptId,
    Expression<String>? body,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promptId != null) 'prompt_id': promptId,
      if (body != null) 'body': body,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PromptVersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? promptId,
    Value<String>? body,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return PromptVersionsCompanion(
      id: id ?? this.id,
      promptId: promptId ?? this.promptId,
      body: body ?? this.body,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (promptId.present) {
      map['prompt_id'] = Variable<int>(promptId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptVersionsCompanion(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('body: $body, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KbCategoriesTable extends KbCategories
    with TableInfo<$KbCategoriesTable, KbCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_categories (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, parentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $KbCategoriesTable createAlias(String alias) {
    return $KbCategoriesTable(attachedDatabase, alias);
  }
}

class KbCategory extends DataClass implements Insertable<KbCategory> {
  final int id;
  final String path;
  final int? parentId;
  const KbCategory({required this.id, required this.path, this.parentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    return map;
  }

  KbCategoriesCompanion toCompanion(bool nullToAbsent) {
    return KbCategoriesCompanion(
      id: Value(id),
      path: Value(path),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory KbCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbCategory(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      parentId: serializer.fromJson<int?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'parentId': serializer.toJson<int?>(parentId),
    };
  }

  KbCategory copyWith({
    int? id,
    String? path,
    Value<int?> parentId = const Value.absent(),
  }) => KbCategory(
    id: id ?? this.id,
    path: path ?? this.path,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  KbCategory copyWithCompanion(KbCategoriesCompanion data) {
    return KbCategory(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbCategory(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, parentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbCategory &&
          other.id == this.id &&
          other.path == this.path &&
          other.parentId == this.parentId);
}

class KbCategoriesCompanion extends UpdateCompanion<KbCategory> {
  final Value<int> id;
  final Value<String> path;
  final Value<int?> parentId;
  const KbCategoriesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.parentId = const Value.absent(),
  });
  KbCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.parentId = const Value.absent(),
  }) : path = Value(path);
  static Insertable<KbCategory> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<int>? parentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  KbCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<int?>? parentId,
  }) {
    return KbCategoriesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }
}

class $KbEntriesTable extends KbEntries
    with TableInfo<$KbEntriesTable, KbEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entryNameMeta = const VerificationMeta(
    'entryName',
  );
  @override
  late final GeneratedColumn<String> entryName = GeneratedColumn<String>(
    'entry_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryPathMeta = const VerificationMeta(
    'categoryPath',
  );
  @override
  late final GeneratedColumn<String> categoryPath = GeneratedColumn<String>(
    'category_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMdMeta = const VerificationMeta(
    'contentMd',
  );
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
    'content_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _relatedMeta = const VerificationMeta(
    'related',
  );
  @override
  late final GeneratedColumn<String> related = GeneratedColumn<String>(
    'related',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Credibility?, String>
  credibility = GeneratedColumn<String>(
    'credibility',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Credibility?>($KbEntriesTable.$convertercredibilityn);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryName,
    categoryPath,
    tags,
    summary,
    contentMd,
    extra,
    related,
    source,
    credibility,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_name')) {
      context.handle(
        _entryNameMeta,
        entryName.isAcceptableOrUnknown(data['entry_name']!, _entryNameMeta),
      );
    } else if (isInserting) {
      context.missing(_entryNameMeta);
    }
    if (data.containsKey('category_path')) {
      context.handle(
        _categoryPathMeta,
        categoryPath.isAcceptableOrUnknown(
          data['category_path']!,
          _categoryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryPathMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('content_md')) {
      context.handle(
        _contentMdMeta,
        contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta),
      );
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('related')) {
      context.handle(
        _relatedMeta,
        related.isAcceptableOrUnknown(data['related']!, _relatedMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_name'],
      )!,
      categoryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_path'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      contentMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_md'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      )!,
      related: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      credibility: $KbEntriesTable.$convertercredibilityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}credibility'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $KbEntriesTable createAlias(String alias) {
    return $KbEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Credibility, String, String> $convertercredibility =
      const EnumNameConverter<Credibility>(Credibility.values);
  static JsonTypeConverter2<Credibility?, String?, String?>
  $convertercredibilityn = JsonTypeConverter2.asNullable($convertercredibility);
}

class KbEntry extends DataClass implements Insertable<KbEntry> {
  final int id;
  final String entryName;
  final String categoryPath;
  final String tags;
  final String summary;
  final String contentMd;
  final String extra;
  final String related;
  final String? source;
  final Credibility? credibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  const KbEntry({
    required this.id,
    required this.entryName,
    required this.categoryPath,
    required this.tags,
    required this.summary,
    required this.contentMd,
    required this.extra,
    required this.related,
    this.source,
    this.credibility,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_name'] = Variable<String>(entryName);
    map['category_path'] = Variable<String>(categoryPath);
    map['tags'] = Variable<String>(tags);
    map['summary'] = Variable<String>(summary);
    map['content_md'] = Variable<String>(contentMd);
    map['extra'] = Variable<String>(extra);
    map['related'] = Variable<String>(related);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || credibility != null) {
      map['credibility'] = Variable<String>(
        $KbEntriesTable.$convertercredibilityn.toSql(credibility),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KbEntriesCompanion toCompanion(bool nullToAbsent) {
    return KbEntriesCompanion(
      id: Value(id),
      entryName: Value(entryName),
      categoryPath: Value(categoryPath),
      tags: Value(tags),
      summary: Value(summary),
      contentMd: Value(contentMd),
      extra: Value(extra),
      related: Value(related),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      credibility: credibility == null && nullToAbsent
          ? const Value.absent()
          : Value(credibility),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KbEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbEntry(
      id: serializer.fromJson<int>(json['id']),
      entryName: serializer.fromJson<String>(json['entryName']),
      categoryPath: serializer.fromJson<String>(json['categoryPath']),
      tags: serializer.fromJson<String>(json['tags']),
      summary: serializer.fromJson<String>(json['summary']),
      contentMd: serializer.fromJson<String>(json['contentMd']),
      extra: serializer.fromJson<String>(json['extra']),
      related: serializer.fromJson<String>(json['related']),
      source: serializer.fromJson<String?>(json['source']),
      credibility: $KbEntriesTable.$convertercredibilityn.fromJson(
        serializer.fromJson<String?>(json['credibility']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryName': serializer.toJson<String>(entryName),
      'categoryPath': serializer.toJson<String>(categoryPath),
      'tags': serializer.toJson<String>(tags),
      'summary': serializer.toJson<String>(summary),
      'contentMd': serializer.toJson<String>(contentMd),
      'extra': serializer.toJson<String>(extra),
      'related': serializer.toJson<String>(related),
      'source': serializer.toJson<String?>(source),
      'credibility': serializer.toJson<String?>(
        $KbEntriesTable.$convertercredibilityn.toJson(credibility),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KbEntry copyWith({
    int? id,
    String? entryName,
    String? categoryPath,
    String? tags,
    String? summary,
    String? contentMd,
    String? extra,
    String? related,
    Value<String?> source = const Value.absent(),
    Value<Credibility?> credibility = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => KbEntry(
    id: id ?? this.id,
    entryName: entryName ?? this.entryName,
    categoryPath: categoryPath ?? this.categoryPath,
    tags: tags ?? this.tags,
    summary: summary ?? this.summary,
    contentMd: contentMd ?? this.contentMd,
    extra: extra ?? this.extra,
    related: related ?? this.related,
    source: source.present ? source.value : this.source,
    credibility: credibility.present ? credibility.value : this.credibility,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KbEntry copyWithCompanion(KbEntriesCompanion data) {
    return KbEntry(
      id: data.id.present ? data.id.value : this.id,
      entryName: data.entryName.present ? data.entryName.value : this.entryName,
      categoryPath: data.categoryPath.present
          ? data.categoryPath.value
          : this.categoryPath,
      tags: data.tags.present ? data.tags.value : this.tags,
      summary: data.summary.present ? data.summary.value : this.summary,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      extra: data.extra.present ? data.extra.value : this.extra,
      related: data.related.present ? data.related.value : this.related,
      source: data.source.present ? data.source.value : this.source,
      credibility: data.credibility.present
          ? data.credibility.value
          : this.credibility,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbEntry(')
          ..write('id: $id, ')
          ..write('entryName: $entryName, ')
          ..write('categoryPath: $categoryPath, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('contentMd: $contentMd, ')
          ..write('extra: $extra, ')
          ..write('related: $related, ')
          ..write('source: $source, ')
          ..write('credibility: $credibility, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryName,
    categoryPath,
    tags,
    summary,
    contentMd,
    extra,
    related,
    source,
    credibility,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbEntry &&
          other.id == this.id &&
          other.entryName == this.entryName &&
          other.categoryPath == this.categoryPath &&
          other.tags == this.tags &&
          other.summary == this.summary &&
          other.contentMd == this.contentMd &&
          other.extra == this.extra &&
          other.related == this.related &&
          other.source == this.source &&
          other.credibility == this.credibility &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KbEntriesCompanion extends UpdateCompanion<KbEntry> {
  final Value<int> id;
  final Value<String> entryName;
  final Value<String> categoryPath;
  final Value<String> tags;
  final Value<String> summary;
  final Value<String> contentMd;
  final Value<String> extra;
  final Value<String> related;
  final Value<String?> source;
  final Value<Credibility?> credibility;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const KbEntriesCompanion({
    this.id = const Value.absent(),
    this.entryName = const Value.absent(),
    this.categoryPath = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.extra = const Value.absent(),
    this.related = const Value.absent(),
    this.source = const Value.absent(),
    this.credibility = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  KbEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String entryName,
    required String categoryPath,
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.extra = const Value.absent(),
    this.related = const Value.absent(),
    this.source = const Value.absent(),
    this.credibility = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : entryName = Value(entryName),
       categoryPath = Value(categoryPath);
  static Insertable<KbEntry> custom({
    Expression<int>? id,
    Expression<String>? entryName,
    Expression<String>? categoryPath,
    Expression<String>? tags,
    Expression<String>? summary,
    Expression<String>? contentMd,
    Expression<String>? extra,
    Expression<String>? related,
    Expression<String>? source,
    Expression<String>? credibility,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryName != null) 'entry_name': entryName,
      if (categoryPath != null) 'category_path': categoryPath,
      if (tags != null) 'tags': tags,
      if (summary != null) 'summary': summary,
      if (contentMd != null) 'content_md': contentMd,
      if (extra != null) 'extra': extra,
      if (related != null) 'related': related,
      if (source != null) 'source': source,
      if (credibility != null) 'credibility': credibility,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  KbEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? entryName,
    Value<String>? categoryPath,
    Value<String>? tags,
    Value<String>? summary,
    Value<String>? contentMd,
    Value<String>? extra,
    Value<String>? related,
    Value<String?>? source,
    Value<Credibility?>? credibility,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return KbEntriesCompanion(
      id: id ?? this.id,
      entryName: entryName ?? this.entryName,
      categoryPath: categoryPath ?? this.categoryPath,
      tags: tags ?? this.tags,
      summary: summary ?? this.summary,
      contentMd: contentMd ?? this.contentMd,
      extra: extra ?? this.extra,
      related: related ?? this.related,
      source: source ?? this.source,
      credibility: credibility ?? this.credibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryName.present) {
      map['entry_name'] = Variable<String>(entryName.value);
    }
    if (categoryPath.present) {
      map['category_path'] = Variable<String>(categoryPath.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (related.present) {
      map['related'] = Variable<String>(related.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (credibility.present) {
      map['credibility'] = Variable<String>(
        $KbEntriesTable.$convertercredibilityn.toSql(credibility.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entryName: $entryName, ')
          ..write('categoryPath: $categoryPath, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('contentMd: $contentMd, ')
          ..write('extra: $extra, ')
          ..write('related: $related, ')
          ..write('source: $source, ')
          ..write('credibility: $credibility, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $KbRelationsTable extends KbRelations
    with TableInfo<$KbRelationsTable, KbRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbRelationsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES kb_entries (id)',
    ),
  );
  static const VerificationMeta _relatedEntryIdMeta = const VerificationMeta(
    'relatedEntryId',
  );
  @override
  late final GeneratedColumn<int> relatedEntryId = GeneratedColumn<int>(
    'related_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_entries (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, relatedEntryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbRelation> instance, {
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
    if (data.containsKey('related_entry_id')) {
      context.handle(
        _relatedEntryIdMeta,
        relatedEntryId.isAcceptableOrUnknown(
          data['related_entry_id']!,
          _relatedEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedEntryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      relatedEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_entry_id'],
      )!,
    );
  }

  @override
  $KbRelationsTable createAlias(String alias) {
    return $KbRelationsTable(attachedDatabase, alias);
  }
}

class KbRelation extends DataClass implements Insertable<KbRelation> {
  final int id;
  final int entryId;
  final int relatedEntryId;
  const KbRelation({
    required this.id,
    required this.entryId,
    required this.relatedEntryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['related_entry_id'] = Variable<int>(relatedEntryId);
    return map;
  }

  KbRelationsCompanion toCompanion(bool nullToAbsent) {
    return KbRelationsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      relatedEntryId: Value(relatedEntryId),
    );
  }

  factory KbRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbRelation(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      relatedEntryId: serializer.fromJson<int>(json['relatedEntryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'relatedEntryId': serializer.toJson<int>(relatedEntryId),
    };
  }

  KbRelation copyWith({int? id, int? entryId, int? relatedEntryId}) =>
      KbRelation(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        relatedEntryId: relatedEntryId ?? this.relatedEntryId,
      );
  KbRelation copyWithCompanion(KbRelationsCompanion data) {
    return KbRelation(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      relatedEntryId: data.relatedEntryId.present
          ? data.relatedEntryId.value
          : this.relatedEntryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbRelation(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('relatedEntryId: $relatedEntryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, relatedEntryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbRelation &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.relatedEntryId == this.relatedEntryId);
}

class KbRelationsCompanion extends UpdateCompanion<KbRelation> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<int> relatedEntryId;
  const KbRelationsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.relatedEntryId = const Value.absent(),
  });
  KbRelationsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required int relatedEntryId,
  }) : entryId = Value(entryId),
       relatedEntryId = Value(relatedEntryId);
  static Insertable<KbRelation> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<int>? relatedEntryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (relatedEntryId != null) 'related_entry_id': relatedEntryId,
    });
  }

  KbRelationsCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<int>? relatedEntryId,
  }) {
    return KbRelationsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      relatedEntryId: relatedEntryId ?? this.relatedEntryId,
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
    if (relatedEntryId.present) {
      map['related_entry_id'] = Variable<int>(relatedEntryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbRelationsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('relatedEntryId: $relatedEntryId')
          ..write(')'))
        .toString();
  }
}

class $EmbeddingsTable extends Embeddings
    with TableInfo<$EmbeddingsTable, EntryEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_entries (id)',
    ),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dimMeta = const VerificationMeta('dim');
  @override
  late final GeneratedColumn<int> dim = GeneratedColumn<int>(
    'dim',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
    'vector',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, model, dim, vector];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryEmbedding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('dim')) {
      context.handle(
        _dimMeta,
        dim.isAcceptableOrUnknown(data['dim']!, _dimMeta),
      );
    } else if (isInserting) {
      context.missing(_dimMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(
        _vectorMeta,
        vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta),
      );
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  EntryEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryEmbedding(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      dim: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim'],
      )!,
      vector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vector'],
      )!,
    );
  }

  @override
  $EmbeddingsTable createAlias(String alias) {
    return $EmbeddingsTable(attachedDatabase, alias);
  }
}

class EntryEmbedding extends DataClass implements Insertable<EntryEmbedding> {
  final int entryId;
  final String model;
  final int dim;
  final Uint8List vector;
  const EntryEmbedding({
    required this.entryId,
    required this.model,
    required this.dim,
    required this.vector,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['model'] = Variable<String>(model);
    map['dim'] = Variable<int>(dim);
    map['vector'] = Variable<Uint8List>(vector);
    return map;
  }

  EmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return EmbeddingsCompanion(
      entryId: Value(entryId),
      model: Value(model),
      dim: Value(dim),
      vector: Value(vector),
    );
  }

  factory EntryEmbedding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryEmbedding(
      entryId: serializer.fromJson<int>(json['entryId']),
      model: serializer.fromJson<String>(json['model']),
      dim: serializer.fromJson<int>(json['dim']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'model': serializer.toJson<String>(model),
      'dim': serializer.toJson<int>(dim),
      'vector': serializer.toJson<Uint8List>(vector),
    };
  }

  EntryEmbedding copyWith({
    int? entryId,
    String? model,
    int? dim,
    Uint8List? vector,
  }) => EntryEmbedding(
    entryId: entryId ?? this.entryId,
    model: model ?? this.model,
    dim: dim ?? this.dim,
    vector: vector ?? this.vector,
  );
  EntryEmbedding copyWithCompanion(EmbeddingsCompanion data) {
    return EntryEmbedding(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      model: data.model.present ? data.model.value : this.model,
      dim: data.dim.present ? data.dim.value : this.dim,
      vector: data.vector.present ? data.vector.value : this.vector,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryEmbedding(')
          ..write('entryId: $entryId, ')
          ..write('model: $model, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entryId, model, dim, $driftBlobEquality.hash(vector));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryEmbedding &&
          other.entryId == this.entryId &&
          other.model == this.model &&
          other.dim == this.dim &&
          $driftBlobEquality.equals(other.vector, this.vector));
}

class EmbeddingsCompanion extends UpdateCompanion<EntryEmbedding> {
  final Value<int> entryId;
  final Value<String> model;
  final Value<int> dim;
  final Value<Uint8List> vector;
  const EmbeddingsCompanion({
    this.entryId = const Value.absent(),
    this.model = const Value.absent(),
    this.dim = const Value.absent(),
    this.vector = const Value.absent(),
  });
  EmbeddingsCompanion.insert({
    this.entryId = const Value.absent(),
    required String model,
    required int dim,
    required Uint8List vector,
  }) : model = Value(model),
       dim = Value(dim),
       vector = Value(vector);
  static Insertable<EntryEmbedding> custom({
    Expression<int>? entryId,
    Expression<String>? model,
    Expression<int>? dim,
    Expression<Uint8List>? vector,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (model != null) 'model': model,
      if (dim != null) 'dim': dim,
      if (vector != null) 'vector': vector,
    });
  }

  EmbeddingsCompanion copyWith({
    Value<int>? entryId,
    Value<String>? model,
    Value<int>? dim,
    Value<Uint8List>? vector,
  }) {
    return EmbeddingsCompanion(
      entryId: entryId ?? this.entryId,
      model: model ?? this.model,
      dim: dim ?? this.dim,
      vector: vector ?? this.vector,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (dim.present) {
      map['dim'] = Variable<int>(dim.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('model: $model, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector')
          ..write(')'))
        .toString();
  }
}

class $UsageLogsTable extends UsageLogs
    with TableInfo<$UsageLogsTable, UsageLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerNameMeta = const VerificationMeta(
    'providerName',
  );
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
    'provider_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetCodeMeta = const VerificationMeta(
    'presetCode',
  );
  @override
  late final GeneratedColumn<String> presetCode = GeneratedColumn<String>(
    'preset_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costEstimateMeta = const VerificationMeta(
    'costEstimate',
  );
  @override
  late final GeneratedColumn<double> costEstimate = GeneratedColumn<double>(
    'cost_estimate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<UsageStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UsageStatus>($UsageLogsTable.$converterstatus);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ts,
    module,
    taskType,
    providerName,
    model,
    presetCode,
    inputTokens,
    outputTokens,
    costEstimate,
    durationMs,
    status,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerNameMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('preset_code')) {
      context.handle(
        _presetCodeMeta,
        presetCode.isAcceptableOrUnknown(data['preset_code']!, _presetCodeMeta),
      );
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('cost_estimate')) {
      context.handle(
        _costEstimateMeta,
        costEstimate.isAcceptableOrUnknown(
          data['cost_estimate']!,
          _costEstimateMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      taskType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type'],
      )!,
      providerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      presetCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_code'],
      ),
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      costEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_estimate'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      status: $UsageLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $UsageLogsTable createAlias(String alias) {
    return $UsageLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UsageStatus, String, String> $converterstatus =
      const EnumNameConverter<UsageStatus>(UsageStatus.values);
}

class UsageLogEntry extends DataClass implements Insertable<UsageLogEntry> {
  final int id;
  final DateTime ts;
  final String module;
  final String taskType;
  final String providerName;
  final String model;
  final String? presetCode;
  final int inputTokens;
  final int outputTokens;
  final double? costEstimate;
  final int durationMs;
  final UsageStatus status;
  final String? error;
  const UsageLogEntry({
    required this.id,
    required this.ts,
    required this.module,
    required this.taskType,
    required this.providerName,
    required this.model,
    this.presetCode,
    required this.inputTokens,
    required this.outputTokens,
    this.costEstimate,
    required this.durationMs,
    required this.status,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<DateTime>(ts);
    map['module'] = Variable<String>(module);
    map['task_type'] = Variable<String>(taskType);
    map['provider_name'] = Variable<String>(providerName);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || presetCode != null) {
      map['preset_code'] = Variable<String>(presetCode);
    }
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    if (!nullToAbsent || costEstimate != null) {
      map['cost_estimate'] = Variable<double>(costEstimate);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    {
      map['status'] = Variable<String>(
        $UsageLogsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  UsageLogsCompanion toCompanion(bool nullToAbsent) {
    return UsageLogsCompanion(
      id: Value(id),
      ts: Value(ts),
      module: Value(module),
      taskType: Value(taskType),
      providerName: Value(providerName),
      model: Value(model),
      presetCode: presetCode == null && nullToAbsent
          ? const Value.absent()
          : Value(presetCode),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      costEstimate: costEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(costEstimate),
      durationMs: Value(durationMs),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory UsageLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageLogEntry(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      module: serializer.fromJson<String>(json['module']),
      taskType: serializer.fromJson<String>(json['taskType']),
      providerName: serializer.fromJson<String>(json['providerName']),
      model: serializer.fromJson<String>(json['model']),
      presetCode: serializer.fromJson<String?>(json['presetCode']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      costEstimate: serializer.fromJson<double?>(json['costEstimate']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      status: $UsageLogsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<DateTime>(ts),
      'module': serializer.toJson<String>(module),
      'taskType': serializer.toJson<String>(taskType),
      'providerName': serializer.toJson<String>(providerName),
      'model': serializer.toJson<String>(model),
      'presetCode': serializer.toJson<String?>(presetCode),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'costEstimate': serializer.toJson<double?>(costEstimate),
      'durationMs': serializer.toJson<int>(durationMs),
      'status': serializer.toJson<String>(
        $UsageLogsTable.$converterstatus.toJson(status),
      ),
      'error': serializer.toJson<String?>(error),
    };
  }

  UsageLogEntry copyWith({
    int? id,
    DateTime? ts,
    String? module,
    String? taskType,
    String? providerName,
    String? model,
    Value<String?> presetCode = const Value.absent(),
    int? inputTokens,
    int? outputTokens,
    Value<double?> costEstimate = const Value.absent(),
    int? durationMs,
    UsageStatus? status,
    Value<String?> error = const Value.absent(),
  }) => UsageLogEntry(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    module: module ?? this.module,
    taskType: taskType ?? this.taskType,
    providerName: providerName ?? this.providerName,
    model: model ?? this.model,
    presetCode: presetCode.present ? presetCode.value : this.presetCode,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    costEstimate: costEstimate.present ? costEstimate.value : this.costEstimate,
    durationMs: durationMs ?? this.durationMs,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
  );
  UsageLogEntry copyWithCompanion(UsageLogsCompanion data) {
    return UsageLogEntry(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      module: data.module.present ? data.module.value : this.module,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      model: data.model.present ? data.model.value : this.model,
      presetCode: data.presetCode.present
          ? data.presetCode.value
          : this.presetCode,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      costEstimate: data.costEstimate.present
          ? data.costEstimate.value
          : this.costEstimate,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageLogEntry(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('module: $module, ')
          ..write('taskType: $taskType, ')
          ..write('providerName: $providerName, ')
          ..write('model: $model, ')
          ..write('presetCode: $presetCode, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('costEstimate: $costEstimate, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ts,
    module,
    taskType,
    providerName,
    model,
    presetCode,
    inputTokens,
    outputTokens,
    costEstimate,
    durationMs,
    status,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageLogEntry &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.module == this.module &&
          other.taskType == this.taskType &&
          other.providerName == this.providerName &&
          other.model == this.model &&
          other.presetCode == this.presetCode &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.costEstimate == this.costEstimate &&
          other.durationMs == this.durationMs &&
          other.status == this.status &&
          other.error == this.error);
}

class UsageLogsCompanion extends UpdateCompanion<UsageLogEntry> {
  final Value<int> id;
  final Value<DateTime> ts;
  final Value<String> module;
  final Value<String> taskType;
  final Value<String> providerName;
  final Value<String> model;
  final Value<String?> presetCode;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<double?> costEstimate;
  final Value<int> durationMs;
  final Value<UsageStatus> status;
  final Value<String?> error;
  const UsageLogsCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.module = const Value.absent(),
    this.taskType = const Value.absent(),
    this.providerName = const Value.absent(),
    this.model = const Value.absent(),
    this.presetCode = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.costEstimate = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
  });
  UsageLogsCompanion.insert({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    required String module,
    required String taskType,
    required String providerName,
    required String model,
    this.presetCode = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.costEstimate = const Value.absent(),
    this.durationMs = const Value.absent(),
    required UsageStatus status,
    this.error = const Value.absent(),
  }) : module = Value(module),
       taskType = Value(taskType),
       providerName = Value(providerName),
       model = Value(model),
       status = Value(status);
  static Insertable<UsageLogEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? ts,
    Expression<String>? module,
    Expression<String>? taskType,
    Expression<String>? providerName,
    Expression<String>? model,
    Expression<String>? presetCode,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<double>? costEstimate,
    Expression<int>? durationMs,
    Expression<String>? status,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (module != null) 'module': module,
      if (taskType != null) 'task_type': taskType,
      if (providerName != null) 'provider_name': providerName,
      if (model != null) 'model': model,
      if (presetCode != null) 'preset_code': presetCode,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (costEstimate != null) 'cost_estimate': costEstimate,
      if (durationMs != null) 'duration_ms': durationMs,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
    });
  }

  UsageLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? ts,
    Value<String>? module,
    Value<String>? taskType,
    Value<String>? providerName,
    Value<String>? model,
    Value<String?>? presetCode,
    Value<int>? inputTokens,
    Value<int>? outputTokens,
    Value<double?>? costEstimate,
    Value<int>? durationMs,
    Value<UsageStatus>? status,
    Value<String?>? error,
  }) {
    return UsageLogsCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      module: module ?? this.module,
      taskType: taskType ?? this.taskType,
      providerName: providerName ?? this.providerName,
      model: model ?? this.model,
      presetCode: presetCode ?? this.presetCode,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      costEstimate: costEstimate ?? this.costEstimate,
      durationMs: durationMs ?? this.durationMs,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (presetCode.present) {
      map['preset_code'] = Variable<String>(presetCode.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (costEstimate.present) {
      map['cost_estimate'] = Variable<double>(costEstimate.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $UsageLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageLogsCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('module: $module, ')
          ..write('taskType: $taskType, ')
          ..write('providerName: $providerName, ')
          ..write('model: $model, ')
          ..write('presetCode: $presetCode, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('costEstimate: $costEstimate, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $TaskQueueTable extends TaskQueue
    with TableInfo<$TaskQueueTable, TaskQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QueueTaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => QueueTaskStatus.pending.name,
      ).withConverter<QueueTaskStatus>($TaskQueueTable.$converterstatus);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retriesMeta = const VerificationMeta(
    'retries',
  );
  @override
  late final GeneratedColumn<int> retries = GeneratedColumn<int>(
    'retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    module,
    taskType,
    payload,
    status,
    result,
    error,
    retries,
    createdAt,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('retries')) {
      context.handle(
        _retriesMeta,
        retries.isAcceptableOrUnknown(data['retries']!, _retriesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      taskType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: $TaskQueueTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      retries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retries'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $TaskQueueTable createAlias(String alias) {
    return $TaskQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<QueueTaskStatus, String, String> $converterstatus =
      const EnumNameConverter<QueueTaskStatus>(QueueTaskStatus.values);
}

class TaskQueueItem extends DataClass implements Insertable<TaskQueueItem> {
  final int id;
  final String module;
  final String taskType;
  final String payload;
  final QueueTaskStatus status;
  final String? result;
  final String? error;
  final int retries;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  const TaskQueueItem({
    required this.id,
    required this.module,
    required this.taskType,
    required this.payload,
    required this.status,
    this.result,
    this.error,
    required this.retries,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['module'] = Variable<String>(module);
    map['task_type'] = Variable<String>(taskType);
    map['payload'] = Variable<String>(payload);
    {
      map['status'] = Variable<String>(
        $TaskQueueTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(result);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['retries'] = Variable<int>(retries);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  TaskQueueCompanion toCompanion(bool nullToAbsent) {
    return TaskQueueCompanion(
      id: Value(id),
      module: Value(module),
      taskType: Value(taskType),
      payload: Value(payload),
      status: Value(status),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      retries: Value(retries),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory TaskQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskQueueItem(
      id: serializer.fromJson<int>(json['id']),
      module: serializer.fromJson<String>(json['module']),
      taskType: serializer.fromJson<String>(json['taskType']),
      payload: serializer.fromJson<String>(json['payload']),
      status: $TaskQueueTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      result: serializer.fromJson<String?>(json['result']),
      error: serializer.fromJson<String?>(json['error']),
      retries: serializer.fromJson<int>(json['retries']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'module': serializer.toJson<String>(module),
      'taskType': serializer.toJson<String>(taskType),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(
        $TaskQueueTable.$converterstatus.toJson(status),
      ),
      'result': serializer.toJson<String?>(result),
      'error': serializer.toJson<String?>(error),
      'retries': serializer.toJson<int>(retries),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  TaskQueueItem copyWith({
    int? id,
    String? module,
    String? taskType,
    String? payload,
    QueueTaskStatus? status,
    Value<String?> result = const Value.absent(),
    Value<String?> error = const Value.absent(),
    int? retries,
    DateTime? createdAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => TaskQueueItem(
    id: id ?? this.id,
    module: module ?? this.module,
    taskType: taskType ?? this.taskType,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    result: result.present ? result.value : this.result,
    error: error.present ? error.value : this.error,
    retries: retries ?? this.retries,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  TaskQueueItem copyWithCompanion(TaskQueueCompanion data) {
    return TaskQueueItem(
      id: data.id.present ? data.id.value : this.id,
      module: data.module.present ? data.module.value : this.module,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      result: data.result.present ? data.result.value : this.result,
      error: data.error.present ? data.error.value : this.error,
      retries: data.retries.present ? data.retries.value : this.retries,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskQueueItem(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('taskType: $taskType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('error: $error, ')
          ..write('retries: $retries, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    module,
    taskType,
    payload,
    status,
    result,
    error,
    retries,
    createdAt,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskQueueItem &&
          other.id == this.id &&
          other.module == this.module &&
          other.taskType == this.taskType &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.result == this.result &&
          other.error == this.error &&
          other.retries == this.retries &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class TaskQueueCompanion extends UpdateCompanion<TaskQueueItem> {
  final Value<int> id;
  final Value<String> module;
  final Value<String> taskType;
  final Value<String> payload;
  final Value<QueueTaskStatus> status;
  final Value<String?> result;
  final Value<String?> error;
  final Value<int> retries;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  const TaskQueueCompanion({
    this.id = const Value.absent(),
    this.module = const Value.absent(),
    this.taskType = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.result = const Value.absent(),
    this.error = const Value.absent(),
    this.retries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  TaskQueueCompanion.insert({
    this.id = const Value.absent(),
    required String module,
    required String taskType,
    required String payload,
    this.status = const Value.absent(),
    this.result = const Value.absent(),
    this.error = const Value.absent(),
    this.retries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  }) : module = Value(module),
       taskType = Value(taskType),
       payload = Value(payload);
  static Insertable<TaskQueueItem> custom({
    Expression<int>? id,
    Expression<String>? module,
    Expression<String>? taskType,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? result,
    Expression<String>? error,
    Expression<int>? retries,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (module != null) 'module': module,
      if (taskType != null) 'task_type': taskType,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
      if (retries != null) 'retries': retries,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  TaskQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? module,
    Value<String>? taskType,
    Value<String>? payload,
    Value<QueueTaskStatus>? status,
    Value<String?>? result,
    Value<String?>? error,
    Value<int>? retries,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
  }) {
    return TaskQueueCompanion(
      id: id ?? this.id,
      module: module ?? this.module,
      taskType: taskType ?? this.taskType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      retries: retries ?? this.retries,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TaskQueueTable.$converterstatus.toSql(status.value),
      );
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (retries.present) {
      map['retries'] = Variable<int>(retries.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskQueueCompanion(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('taskType: $taskType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('error: $error, ')
          ..write('retries: $retries, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemosTable extends Memos with TableInfo<$MemosTable, MemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemosTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    images,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MemosTable createAlias(String alias) {
    return $MemosTable(attachedDatabase, alias);
  }
}

class MemoRow extends DataClass implements Insertable<MemoRow> {
  final int id;
  final String title;
  final String content;
  final String images;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MemoRow({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['images'] = Variable<String>(images);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MemosCompanion toCompanion(bool nullToAbsent) {
    return MemosCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      images: Value(images),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MemoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      images: serializer.fromJson<String>(json['images']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'images': serializer.toJson<String>(images),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MemoRow copyWith({
    int? id,
    String? title,
    String? content,
    String? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MemoRow(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    images: images ?? this.images,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MemoRow copyWithCompanion(MemosCompanion data) {
    return MemoRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      images: data.images.present ? data.images.value : this.images,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('images: $images, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, images, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.images == this.images &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemosCompanion extends UpdateCompanion<MemoRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> images;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MemosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.images = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MemosCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.images = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<MemoRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? images,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (images != null) 'images': images,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MemosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? images,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MemosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('images: $images, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PasswordEntriesTable extends PasswordEntries
    with TableInfo<$PasswordEntriesTable, PasswordEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PasswordEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldsEncMeta = const VerificationMeta(
    'fieldsEnc',
  );
  @override
  late final GeneratedColumn<String> fieldsEnc = GeneratedColumn<String>(
    'fields_enc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteEncMeta = const VerificationMeta(
    'noteEnc',
  );
  @override
  late final GeneratedColumn<String> noteEnc = GeneratedColumn<String>(
    'note_enc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    fieldsEnc,
    noteEnc,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'password_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PasswordEntryRow> instance, {
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
    if (data.containsKey('fields_enc')) {
      context.handle(
        _fieldsEncMeta,
        fieldsEnc.isAcceptableOrUnknown(data['fields_enc']!, _fieldsEncMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldsEncMeta);
    }
    if (data.containsKey('note_enc')) {
      context.handle(
        _noteEncMeta,
        noteEnc.isAcceptableOrUnknown(data['note_enc']!, _noteEncMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PasswordEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PasswordEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fieldsEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields_enc'],
      )!,
      noteEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_enc'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PasswordEntriesTable createAlias(String alias) {
    return $PasswordEntriesTable(attachedDatabase, alias);
  }
}

class PasswordEntryRow extends DataClass
    implements Insertable<PasswordEntryRow> {
  final int id;
  final String name;
  final String fieldsEnc;
  final String? noteEnc;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PasswordEntryRow({
    required this.id,
    required this.name,
    required this.fieldsEnc,
    this.noteEnc,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['fields_enc'] = Variable<String>(fieldsEnc);
    if (!nullToAbsent || noteEnc != null) {
      map['note_enc'] = Variable<String>(noteEnc);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PasswordEntriesCompanion toCompanion(bool nullToAbsent) {
    return PasswordEntriesCompanion(
      id: Value(id),
      name: Value(name),
      fieldsEnc: Value(fieldsEnc),
      noteEnc: noteEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(noteEnc),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PasswordEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PasswordEntryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fieldsEnc: serializer.fromJson<String>(json['fieldsEnc']),
      noteEnc: serializer.fromJson<String?>(json['noteEnc']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'fieldsEnc': serializer.toJson<String>(fieldsEnc),
      'noteEnc': serializer.toJson<String?>(noteEnc),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PasswordEntryRow copyWith({
    int? id,
    String? name,
    String? fieldsEnc,
    Value<String?> noteEnc = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PasswordEntryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    fieldsEnc: fieldsEnc ?? this.fieldsEnc,
    noteEnc: noteEnc.present ? noteEnc.value : this.noteEnc,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PasswordEntryRow copyWithCompanion(PasswordEntriesCompanion data) {
    return PasswordEntryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fieldsEnc: data.fieldsEnc.present ? data.fieldsEnc.value : this.fieldsEnc,
      noteEnc: data.noteEnc.present ? data.noteEnc.value : this.noteEnc,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PasswordEntryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fieldsEnc: $fieldsEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, fieldsEnc, noteEnc, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordEntryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.fieldsEnc == this.fieldsEnc &&
          other.noteEnc == this.noteEnc &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PasswordEntriesCompanion extends UpdateCompanion<PasswordEntryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> fieldsEnc;
  final Value<String?> noteEnc;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PasswordEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fieldsEnc = const Value.absent(),
    this.noteEnc = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PasswordEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String fieldsEnc,
    this.noteEnc = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       fieldsEnc = Value(fieldsEnc);
  static Insertable<PasswordEntryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? fieldsEnc,
    Expression<String>? noteEnc,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fieldsEnc != null) 'fields_enc': fieldsEnc,
      if (noteEnc != null) 'note_enc': noteEnc,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PasswordEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? fieldsEnc,
    Value<String?>? noteEnc,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PasswordEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fieldsEnc: fieldsEnc ?? this.fieldsEnc,
      noteEnc: noteEnc ?? this.noteEnc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (fieldsEnc.present) {
      map['fields_enc'] = Variable<String>(fieldsEnc.value);
    }
    if (noteEnc.present) {
      map['note_enc'] = Variable<String>(noteEnc.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PasswordEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fieldsEnc: $fieldsEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProvidersTable providers = $ProvidersTable(this);
  late final $ModelsTable models = $ModelsTable(this);
  late final $IntensityPresetsTable intensityPresets = $IntensityPresetsTable(
    this,
  );
  late final $FragmentsTable fragments = $FragmentsTable(this);
  late final $PromptsTable prompts = $PromptsTable(this);
  late final $PromptVersionsTable promptVersions = $PromptVersionsTable(this);
  late final $KbCategoriesTable kbCategories = $KbCategoriesTable(this);
  late final $KbEntriesTable kbEntries = $KbEntriesTable(this);
  late final $KbRelationsTable kbRelations = $KbRelationsTable(this);
  late final $EmbeddingsTable embeddings = $EmbeddingsTable(this);
  late final $UsageLogsTable usageLogs = $UsageLogsTable(this);
  late final $TaskQueueTable taskQueue = $TaskQueueTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MemosTable memos = $MemosTable(this);
  late final $PasswordEntriesTable passwordEntries = $PasswordEntriesTable(
    this,
  );
  late final Index idxModelsProvider = Index(
    'idx_models_provider',
    'CREATE INDEX idx_models_provider ON models (provider_id)',
  );
  late final Index idxFragmentsCreated = Index(
    'idx_fragments_created',
    'CREATE INDEX idx_fragments_created ON fragments (created_at)',
  );
  late final Index idxKbEntriesCategory = Index(
    'idx_kb_entries_category',
    'CREATE INDEX idx_kb_entries_category ON kb_entries (category_path)',
  );
  late final Index idxKbRelationsEntry = Index(
    'idx_kb_relations_entry',
    'CREATE INDEX idx_kb_relations_entry ON kb_relations (entry_id)',
  );
  late final Index idxKbRelationsRelated = Index(
    'idx_kb_relations_related',
    'CREATE INDEX idx_kb_relations_related ON kb_relations (related_entry_id)',
  );
  late final Index idxUsageLogTs = Index(
    'idx_usage_log_ts',
    'CREATE INDEX idx_usage_log_ts ON usage_log (ts)',
  );
  late final ProvidersDao providersDao = ProvidersDao(this as AppDatabase);
  late final ModelsDao modelsDao = ModelsDao(this as AppDatabase);
  late final IntensityPresetsDao intensityPresetsDao = IntensityPresetsDao(
    this as AppDatabase,
  );
  late final FragmentsDao fragmentsDao = FragmentsDao(this as AppDatabase);
  late final PromptsDao promptsDao = PromptsDao(this as AppDatabase);
  late final PromptVersionsDao promptVersionsDao = PromptVersionsDao(
    this as AppDatabase,
  );
  late final KbCategoriesDao kbCategoriesDao = KbCategoriesDao(
    this as AppDatabase,
  );
  late final KbEntriesDao kbEntriesDao = KbEntriesDao(this as AppDatabase);
  late final KbRelationsDao kbRelationsDao = KbRelationsDao(
    this as AppDatabase,
  );
  late final EmbeddingsDao embeddingsDao = EmbeddingsDao(this as AppDatabase);
  late final UsageLogDao usageLogDao = UsageLogDao(this as AppDatabase);
  late final TaskQueueDao taskQueueDao = TaskQueueDao(this as AppDatabase);
  late final AppSettingsDao appSettingsDao = AppSettingsDao(
    this as AppDatabase,
  );
  late final MemosDao memosDao = MemosDao(this as AppDatabase);
  late final PasswordEntriesDao passwordEntriesDao = PasswordEntriesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providers,
    models,
    intensityPresets,
    fragments,
    prompts,
    promptVersions,
    kbCategories,
    kbEntries,
    kbRelations,
    embeddings,
    usageLogs,
    taskQueue,
    appSettings,
    memos,
    passwordEntries,
    idxModelsProvider,
    idxFragmentsCreated,
    idxKbEntriesCategory,
    idxKbRelationsEntry,
    idxKbRelationsRelated,
    idxUsageLogTs,
  ];
}

typedef $$ProvidersTableCreateCompanionBuilder = ProvidersCompanion Function({
  Value<int> id,
  required String name,
  required String baseUrl,
  Value<String?> keyRef,
  required String presetCode,
  Value<DateTime> createdAt,
});
typedef $$ProvidersTableUpdateCompanionBuilder = ProvidersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> baseUrl,
  Value<String?> keyRef,
  Value<String> presetCode,
  Value<DateTime> createdAt,
});

final class $$ProvidersTableReferences
    extends BaseReferences<_$AppDatabase, $ProvidersTable, ProviderRow> {
  $$ProvidersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ModelsTable, List<ModelRow>> _modelsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.models,
    aliasName: 'providers__id__models__provider_id',
  );

  $$ModelsTableProcessedTableManager get modelsRefs {
    final manager = $$ModelsTableTableManager(
      $_db,
      $_db.models,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_modelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableFilterComposer({
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

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyRef => $composableBuilder(
    column: $table.keyRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> modelsRefs(
    Expression<bool> Function($$ModelsTableFilterComposer f) f,
  ) {
    final $$ModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.models,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelsTableFilterComposer(
            $db: $db,
            $table: $db.models,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableOrderingComposer({
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

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyRef => $composableBuilder(
    column: $table.keyRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableAnnotationComposer({
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

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get keyRef =>
      $composableBuilder(column: $table.keyRef, builder: (column) => column);

  GeneratedColumn<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> modelsRefs<T extends Object>(
    Expression<T> Function($$ModelsTableAnnotationComposer a) f,
  ) {
    final $$ModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.models,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.models,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProvidersTable,
          ProviderRow,
          $$ProvidersTableFilterComposer,
          $$ProvidersTableOrderingComposer,
          $$ProvidersTableAnnotationComposer,
          $$ProvidersTableCreateCompanionBuilder,
          $$ProvidersTableUpdateCompanionBuilder,
          (ProviderRow, $$ProvidersTableReferences),
          ProviderRow,
          PrefetchHooks Function({bool modelsRefs})
        > {
  $$ProvidersTableTableManager(_$AppDatabase db, $ProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String?> keyRef = const Value.absent(),
                Value<String> presetCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProvidersCompanion(
                id: id,
                name: name,
                baseUrl: baseUrl,
                keyRef: keyRef,
                presetCode: presetCode,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String baseUrl,
                Value<String?> keyRef = const Value.absent(),
                required String presetCode,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProvidersCompanion.insert(
                id: id,
                name: name,
                baseUrl: baseUrl,
                keyRef: keyRef,
                presetCode: presetCode,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProvidersTable, ProviderRow>(table),
                  $$ProvidersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({modelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (modelsRefs) db.models],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (modelsRefs)
                    await $_getPrefetchedData<
                      ProviderRow,
                      $ProvidersTable,
                      ModelRow
                    >(
                      currentTable: table,
                      referencedTable: $$ProvidersTableReferences
                          ._modelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProvidersTableReferences(db, table, p0).modelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.providerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProvidersTable,
      ProviderRow,
      $$ProvidersTableFilterComposer,
      $$ProvidersTableOrderingComposer,
      $$ProvidersTableAnnotationComposer,
      $$ProvidersTableCreateCompanionBuilder,
      $$ProvidersTableUpdateCompanionBuilder,
      (ProviderRow, $$ProvidersTableReferences),
      ProviderRow,
      PrefetchHooks Function({bool modelsRefs})
    >;
typedef $$ModelsTableCreateCompanionBuilder = ModelsCompanion Function({
  Value<int> id,
  required int providerId,
  required String modelId,
  required String displayName,
  Value<String> tags,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
});
typedef $$ModelsTableUpdateCompanionBuilder = ModelsCompanion Function({
  Value<int> id,
  Value<int> providerId,
  Value<String> modelId,
  Value<String> displayName,
  Value<String> tags,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
});

final class $$ModelsTableReferences
    extends BaseReferences<_$AppDatabase, $ModelsTable, ModelRow> {
  $$ModelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$AppDatabase db) =>
      db.providers.createAlias('models__provider_id__providers__id');

  $$ProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<int>('provider_id')!;

    final manager = $$ProvidersTableTableManager(
      $_db,
      $_db.providers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ModelsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelsTable> {
  $$ModelsTableFilterComposer({
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

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProvidersTableFilterComposer get providerId {
    final $$ProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableFilterComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelsTable> {
  $$ModelsTableOrderingComposer({
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

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProvidersTableOrderingComposer get providerId {
    final $$ProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelsTable> {
  $$ModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProvidersTableAnnotationComposer get providerId {
    final $$ProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelsTable,
          ModelRow,
          $$ModelsTableFilterComposer,
          $$ModelsTableOrderingComposer,
          $$ModelsTableAnnotationComposer,
          $$ModelsTableCreateCompanionBuilder,
          $$ModelsTableUpdateCompanionBuilder,
          (ModelRow, $$ModelsTableReferences),
          ModelRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$ModelsTableTableManager(_$AppDatabase db, $ModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ModelsCompanion(
                id: id,
                providerId: providerId,
                modelId: modelId,
                displayName: displayName,
                tags: tags,
                isActive: isActive,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required String modelId,
                required String displayName,
                Value<String> tags = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ModelsCompanion.insert(
                id: id,
                providerId: providerId,
                modelId: modelId,
                displayName: displayName,
                tags: tags,
                isActive: isActive,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ModelsTable, ModelRow>(table),
                  $$ModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.providerId,
                        referencedTable: $$ModelsTableReferences
                            ._providerIdTable(db),
                        referencedColumn: $$ModelsTableReferences
                            ._providerIdTable(db)
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

typedef $$ModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelsTable,
      ModelRow,
      $$ModelsTableFilterComposer,
      $$ModelsTableOrderingComposer,
      $$ModelsTableAnnotationComposer,
      $$ModelsTableCreateCompanionBuilder,
      $$ModelsTableUpdateCompanionBuilder,
      (ModelRow, $$ModelsTableReferences),
      ModelRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$IntensityPresetsTableCreateCompanionBuilder =
    IntensityPresetsCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      Value<String> params,
      Value<bool> isBuiltin,
    });
typedef $$IntensityPresetsTableUpdateCompanionBuilder =
    IntensityPresetsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String> params,
      Value<bool> isBuiltin,
    });

class $$IntensityPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $IntensityPresetsTable> {
  $$IntensityPresetsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get params => $composableBuilder(
    column: $table.params,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntensityPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntensityPresetsTable> {
  $$IntensityPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get params => $composableBuilder(
    column: $table.params,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntensityPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntensityPresetsTable> {
  $$IntensityPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get params =>
      $composableBuilder(column: $table.params, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);
}

class $$IntensityPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntensityPresetsTable,
          IntensityPreset,
          $$IntensityPresetsTableFilterComposer,
          $$IntensityPresetsTableOrderingComposer,
          $$IntensityPresetsTableAnnotationComposer,
          $$IntensityPresetsTableCreateCompanionBuilder,
          $$IntensityPresetsTableUpdateCompanionBuilder,
          (
            IntensityPreset,
            BaseReferences<
              _$AppDatabase,
              $IntensityPresetsTable,
              IntensityPreset
            >,
          ),
          IntensityPreset,
          PrefetchHooks Function()
        > {
  $$IntensityPresetsTableTableManager(
    _$AppDatabase db,
    $IntensityPresetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntensityPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntensityPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntensityPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> params = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
              }) => IntensityPresetsCompanion(
                id: id,
                code: code,
                name: name,
                params: params,
                isBuiltin: isBuiltin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                Value<String> params = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
              }) => IntensityPresetsCompanion.insert(
                id: id,
                code: code,
                name: name,
                params: params,
                isBuiltin: isBuiltin,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IntensityPresetsTable, IntensityPreset>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IntensityPresetsTable,
                    IntensityPreset
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntensityPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntensityPresetsTable,
      IntensityPreset,
      $$IntensityPresetsTableFilterComposer,
      $$IntensityPresetsTableOrderingComposer,
      $$IntensityPresetsTableAnnotationComposer,
      $$IntensityPresetsTableCreateCompanionBuilder,
      $$IntensityPresetsTableUpdateCompanionBuilder,
      (
        IntensityPreset,
        BaseReferences<_$AppDatabase, $IntensityPresetsTable, IntensityPreset>,
      ),
      IntensityPreset,
      PrefetchHooks Function()
    >;
typedef $$FragmentsTableCreateCompanionBuilder = FragmentsCompanion Function({
  Value<int> id,
  required String rawText,
  Value<String?> optimizedJson,
  Value<String> title,
  Value<String> tags,
  required FragmentSource source,
  Value<String?> aiMeta,
  Value<FragmentStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FragmentsTableUpdateCompanionBuilder = FragmentsCompanion Function({
  Value<int> id,
  Value<String> rawText,
  Value<String?> optimizedJson,
  Value<String> title,
  Value<String> tags,
  Value<FragmentSource> source,
  Value<String?> aiMeta,
  Value<FragmentStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$FragmentsTableFilterComposer
    extends Composer<_$AppDatabase, $FragmentsTable> {
  $$FragmentsTableFilterComposer({
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

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optimizedJson => $composableBuilder(
    column: $table.optimizedJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FragmentSource, FragmentSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get aiMeta => $composableBuilder(
    column: $table.aiMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FragmentStatus, FragmentStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FragmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $FragmentsTable> {
  $$FragmentsTableOrderingComposer({
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

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optimizedJson => $composableBuilder(
    column: $table.optimizedJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiMeta => $composableBuilder(
    column: $table.aiMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FragmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FragmentsTable> {
  $$FragmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get optimizedJson => $composableBuilder(
    column: $table.optimizedJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FragmentSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get aiMeta =>
      $composableBuilder(column: $table.aiMeta, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FragmentStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FragmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FragmentsTable,
          Fragment,
          $$FragmentsTableFilterComposer,
          $$FragmentsTableOrderingComposer,
          $$FragmentsTableAnnotationComposer,
          $$FragmentsTableCreateCompanionBuilder,
          $$FragmentsTableUpdateCompanionBuilder,
          (Fragment, BaseReferences<_$AppDatabase, $FragmentsTable, Fragment>),
          Fragment,
          PrefetchHooks Function()
        > {
  $$FragmentsTableTableManager(_$AppDatabase db, $FragmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FragmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FragmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FragmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> optimizedJson = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<FragmentSource> source = const Value.absent(),
                Value<String?> aiMeta = const Value.absent(),
                Value<FragmentStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FragmentsCompanion(
                id: id,
                rawText: rawText,
                optimizedJson: optimizedJson,
                title: title,
                tags: tags,
                source: source,
                aiMeta: aiMeta,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String rawText,
                Value<String?> optimizedJson = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> tags = const Value.absent(),
                required FragmentSource source,
                Value<String?> aiMeta = const Value.absent(),
                Value<FragmentStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FragmentsCompanion.insert(
                id: id,
                rawText: rawText,
                optimizedJson: optimizedJson,
                title: title,
                tags: tags,
                source: source,
                aiMeta: aiMeta,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FragmentsTable, Fragment>(table),
                  BaseReferences<_$AppDatabase, $FragmentsTable, Fragment>(
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

typedef $$FragmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FragmentsTable,
      Fragment,
      $$FragmentsTableFilterComposer,
      $$FragmentsTableOrderingComposer,
      $$FragmentsTableAnnotationComposer,
      $$FragmentsTableCreateCompanionBuilder,
      $$FragmentsTableUpdateCompanionBuilder,
      (Fragment, BaseReferences<_$AppDatabase, $FragmentsTable, Fragment>),
      Fragment,
      PrefetchHooks Function()
    >;
typedef $$PromptsTableCreateCompanionBuilder = PromptsCompanion Function({
  Value<int> id,
  required String title,
  required PromptType type,
  required String body,
  Value<String> variables,
  Value<String?> category,
  Value<int?> currentVersionId,
  Value<DateTime> createdAt,
});
typedef $$PromptsTableUpdateCompanionBuilder = PromptsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<PromptType> type,
  Value<String> body,
  Value<String> variables,
  Value<String?> category,
  Value<int?> currentVersionId,
  Value<DateTime> createdAt,
});

final class $$PromptsTableReferences
    extends BaseReferences<_$AppDatabase, $PromptsTable, Prompt> {
  $$PromptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PromptVersionsTable, List<PromptVersion>>
  _promptVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.promptVersions,
    aliasName: 'prompts__id__prompt_versions__prompt_id',
  );

  $$PromptVersionsTableProcessedTableManager get promptVersionsRefs {
    final manager = $$PromptVersionsTableTableManager(
      $_db,
      $_db.promptVersions,
    ).filter((f) => f.promptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_promptVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PromptsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PromptType, PromptType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variables => $composableBuilder(
    column: $table.variables,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> promptVersionsRefs(
    Expression<bool> Function($$PromptVersionsTableFilterComposer f) f,
  ) {
    final $$PromptVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promptVersions,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptVersionsTableFilterComposer(
            $db: $db,
            $table: $db.promptVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variables => $composableBuilder(
    column: $table.variables,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PromptType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get variables =>
      $composableBuilder(column: $table.variables, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get currentVersionId => $composableBuilder(
    column: $table.currentVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> promptVersionsRefs<T extends Object>(
    Expression<T> Function($$PromptVersionsTableAnnotationComposer a) f,
  ) {
    final $$PromptVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promptVersions,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.promptVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptsTable,
          Prompt,
          $$PromptsTableFilterComposer,
          $$PromptsTableOrderingComposer,
          $$PromptsTableAnnotationComposer,
          $$PromptsTableCreateCompanionBuilder,
          $$PromptsTableUpdateCompanionBuilder,
          (Prompt, $$PromptsTableReferences),
          Prompt,
          PrefetchHooks Function({bool promptVersionsRefs})
        > {
  $$PromptsTableTableManager(_$AppDatabase db, $PromptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<PromptType> type = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> variables = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> currentVersionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PromptsCompanion(
                id: id,
                title: title,
                type: type,
                body: body,
                variables: variables,
                category: category,
                currentVersionId: currentVersionId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required PromptType type,
                required String body,
                Value<String> variables = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> currentVersionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PromptsCompanion.insert(
                id: id,
                title: title,
                type: type,
                body: body,
                variables: variables,
                category: category,
                currentVersionId: currentVersionId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PromptsTable, Prompt>(table),
                  $$PromptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promptVersionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (promptVersionsRefs) db.promptVersions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (promptVersionsRefs)
                    await $_getPrefetchedData<
                      Prompt,
                      $PromptsTable,
                      PromptVersion
                    >(
                      currentTable: table,
                      referencedTable: $$PromptsTableReferences
                          ._promptVersionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PromptsTableReferences(
                        db,
                        table,
                        p0,
                      ).promptVersionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.promptId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptsTable,
      Prompt,
      $$PromptsTableFilterComposer,
      $$PromptsTableOrderingComposer,
      $$PromptsTableAnnotationComposer,
      $$PromptsTableCreateCompanionBuilder,
      $$PromptsTableUpdateCompanionBuilder,
      (Prompt, $$PromptsTableReferences),
      Prompt,
      PrefetchHooks Function({bool promptVersionsRefs})
    >;
typedef $$PromptVersionsTableCreateCompanionBuilder =
    PromptVersionsCompanion Function({
      Value<int> id,
      required int promptId,
      required String body,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$PromptVersionsTableUpdateCompanionBuilder =
    PromptVersionsCompanion Function({
      Value<int> id,
      Value<int> promptId,
      Value<String> body,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$PromptVersionsTableReferences
    extends BaseReferences<_$AppDatabase, $PromptVersionsTable, PromptVersion> {
  $$PromptVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PromptsTable _promptIdTable(_$AppDatabase db) =>
      db.prompts.createAlias('prompt_versions__prompt_id__prompts__id');

  $$PromptsTableProcessedTableManager get promptId {
    final $_column = $_itemColumn<int>('prompt_id')!;

    final manager = $$PromptsTableTableManager(
      $_db,
      $_db.prompts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_promptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PromptVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptVersionsTable> {
  $$PromptVersionsTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PromptsTableFilterComposer get promptId {
    final $$PromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableFilterComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptVersionsTable> {
  $$PromptVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PromptsTableOrderingComposer get promptId {
    final $$PromptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableOrderingComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptVersionsTable> {
  $$PromptVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PromptsTableAnnotationComposer get promptId {
    final $$PromptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableAnnotationComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptVersionsTable,
          PromptVersion,
          $$PromptVersionsTableFilterComposer,
          $$PromptVersionsTableOrderingComposer,
          $$PromptVersionsTableAnnotationComposer,
          $$PromptVersionsTableCreateCompanionBuilder,
          $$PromptVersionsTableUpdateCompanionBuilder,
          (PromptVersion, $$PromptVersionsTableReferences),
          PromptVersion,
          PrefetchHooks Function({bool promptId})
        > {
  $$PromptVersionsTableTableManager(
    _$AppDatabase db,
    $PromptVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> promptId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PromptVersionsCompanion(
                id: id,
                promptId: promptId,
                body: body,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int promptId,
                required String body,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PromptVersionsCompanion.insert(
                id: id,
                promptId: promptId,
                body: body,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PromptVersionsTable, PromptVersion>(table),
                  $$PromptVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promptId = false}) {
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
                    if (promptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.promptId,
                        referencedTable: $$PromptVersionsTableReferences
                            ._promptIdTable(db),
                        referencedColumn: $$PromptVersionsTableReferences
                            ._promptIdTable(db)
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

typedef $$PromptVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptVersionsTable,
      PromptVersion,
      $$PromptVersionsTableFilterComposer,
      $$PromptVersionsTableOrderingComposer,
      $$PromptVersionsTableAnnotationComposer,
      $$PromptVersionsTableCreateCompanionBuilder,
      $$PromptVersionsTableUpdateCompanionBuilder,
      (PromptVersion, $$PromptVersionsTableReferences),
      PromptVersion,
      PrefetchHooks Function({bool promptId})
    >;
typedef $$KbCategoriesTableCreateCompanionBuilder =
    KbCategoriesCompanion Function({
      Value<int> id,
      required String path,
      Value<int?> parentId,
    });
typedef $$KbCategoriesTableUpdateCompanionBuilder =
    KbCategoriesCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<int?> parentId,
    });

final class $$KbCategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $KbCategoriesTable, KbCategory> {
  $$KbCategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbCategoriesTable _parentIdTable(_$AppDatabase db) => db.kbCategories
      .createAlias('kb_categories__parent_id__kb_categories__id');

  $$KbCategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$KbCategoriesTableTableManager(
      $_db,
      $_db.kbCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KbCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $KbCategoriesTable> {
  $$KbCategoriesTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  $$KbCategoriesTableFilterComposer get parentId {
    final $$KbCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.kbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.kbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KbCategoriesTable> {
  $$KbCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  $$KbCategoriesTableOrderingComposer get parentId {
    final $$KbCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.kbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.kbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KbCategoriesTable> {
  $$KbCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  $$KbCategoriesTableAnnotationComposer get parentId {
    final $$KbCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.kbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.kbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KbCategoriesTable,
          KbCategory,
          $$KbCategoriesTableFilterComposer,
          $$KbCategoriesTableOrderingComposer,
          $$KbCategoriesTableAnnotationComposer,
          $$KbCategoriesTableCreateCompanionBuilder,
          $$KbCategoriesTableUpdateCompanionBuilder,
          (KbCategory, $$KbCategoriesTableReferences),
          KbCategory,
          PrefetchHooks Function({bool parentId})
        > {
  $$KbCategoriesTableTableManager(_$AppDatabase db, $KbCategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
          }) => KbCategoriesCompanion(id: id, path: path, parentId: parentId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<int?> parentId = const Value.absent(),
              }) => KbCategoriesCompanion.insert(
                id: id,
                path: path,
                parentId: parentId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KbCategoriesTable, KbCategory>(table),
                  $$KbCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false}) {
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
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$KbCategoriesTableReferences
                            ._parentIdTable(db),
                        referencedColumn: $$KbCategoriesTableReferences
                            ._parentIdTable(db)
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

typedef $$KbCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KbCategoriesTable,
      KbCategory,
      $$KbCategoriesTableFilterComposer,
      $$KbCategoriesTableOrderingComposer,
      $$KbCategoriesTableAnnotationComposer,
      $$KbCategoriesTableCreateCompanionBuilder,
      $$KbCategoriesTableUpdateCompanionBuilder,
      (KbCategory, $$KbCategoriesTableReferences),
      KbCategory,
      PrefetchHooks Function({bool parentId})
    >;
typedef $$KbEntriesTableCreateCompanionBuilder = KbEntriesCompanion Function({
  Value<int> id,
  required String entryName,
  required String categoryPath,
  Value<String> tags,
  Value<String> summary,
  Value<String> contentMd,
  Value<String> extra,
  Value<String> related,
  Value<String?> source,
  Value<Credibility?> credibility,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$KbEntriesTableUpdateCompanionBuilder = KbEntriesCompanion Function({
  Value<int> id,
  Value<String> entryName,
  Value<String> categoryPath,
  Value<String> tags,
  Value<String> summary,
  Value<String> contentMd,
  Value<String> extra,
  Value<String> related,
  Value<String?> source,
  Value<Credibility?> credibility,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$KbEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $KbEntriesTable, KbEntry> {
  $$KbEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$KbRelationsTable, List<KbRelation>>
  _relationsAsEntryTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.kbRelations,
    aliasName: 'kb_entries__id__kb_relations__entry_id',
  );

  $$KbRelationsTableProcessedTableManager get relationsAsEntry {
    final manager = $$KbRelationsTableTableManager(
      $_db,
      $_db.kbRelations,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_relationsAsEntryTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KbRelationsTable, List<KbRelation>>
  _relationsAsRelatedTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.kbRelations,
    aliasName: 'kb_entries__id__kb_relations__related_entry_id',
  );

  $$KbRelationsTableProcessedTableManager get relationsAsRelated {
    final manager = $$KbRelationsTableTableManager(
      $_db,
      $_db.kbRelations,
    ).filter((f) => f.relatedEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_relationsAsRelatedTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EmbeddingsTable, List<EntryEmbedding>>
  _embeddingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.embeddings,
    aliasName: 'kb_entries__id__embeddings__entry_id',
  );

  $$EmbeddingsTableProcessedTableManager get embeddingsRefs {
    final manager = $$EmbeddingsTableTableManager(
      $_db,
      $_db.embeddings,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_embeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KbEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KbEntriesTable> {
  $$KbEntriesTableFilterComposer({
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

  ColumnFilters<String> get entryName => $composableBuilder(
    column: $table.entryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryPath => $composableBuilder(
    column: $table.categoryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get related => $composableBuilder(
    column: $table.related,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Credibility?, Credibility, String>
  get credibility => $composableBuilder(
    column: $table.credibility,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> relationsAsEntry(
    Expression<bool> Function($$KbRelationsTableFilterComposer f) f,
  ) {
    final $$KbRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbRelations,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbRelationsTableFilterComposer(
            $db: $db,
            $table: $db.kbRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> relationsAsRelated(
    Expression<bool> Function($$KbRelationsTableFilterComposer f) f,
  ) {
    final $$KbRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbRelations,
      getReferencedColumn: (t) => t.relatedEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbRelationsTableFilterComposer(
            $db: $db,
            $table: $db.kbRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> embeddingsRefs(
    Expression<bool> Function($$EmbeddingsTableFilterComposer f) f,
  ) {
    final $$EmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.embeddings,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.embeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KbEntriesTable> {
  $$KbEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get entryName => $composableBuilder(
    column: $table.entryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryPath => $composableBuilder(
    column: $table.categoryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentMd => $composableBuilder(
    column: $table.contentMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get related => $composableBuilder(
    column: $table.related,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credibility => $composableBuilder(
    column: $table.credibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KbEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KbEntriesTable> {
  $$KbEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryName =>
      $composableBuilder(column: $table.entryName, builder: (column) => column);

  GeneratedColumn<String> get categoryPath => $composableBuilder(
    column: $table.categoryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<String> get related =>
      $composableBuilder(column: $table.related, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Credibility?, String> get credibility =>
      $composableBuilder(
        column: $table.credibility,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> relationsAsEntry<T extends Object>(
    Expression<T> Function($$KbRelationsTableAnnotationComposer a) f,
  ) {
    final $$KbRelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbRelations,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbRelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.kbRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> relationsAsRelated<T extends Object>(
    Expression<T> Function($$KbRelationsTableAnnotationComposer a) f,
  ) {
    final $$KbRelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbRelations,
      getReferencedColumn: (t) => t.relatedEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbRelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.kbRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> embeddingsRefs<T extends Object>(
    Expression<T> Function($$EmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$EmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.embeddings,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.embeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KbEntriesTable,
          KbEntry,
          $$KbEntriesTableFilterComposer,
          $$KbEntriesTableOrderingComposer,
          $$KbEntriesTableAnnotationComposer,
          $$KbEntriesTableCreateCompanionBuilder,
          $$KbEntriesTableUpdateCompanionBuilder,
          (KbEntry, $$KbEntriesTableReferences),
          KbEntry,
          PrefetchHooks Function({
            bool relationsAsEntry,
            bool relationsAsRelated,
            bool embeddingsRefs,
          })
        > {
  $$KbEntriesTableTableManager(_$AppDatabase db, $KbEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entryName = const Value.absent(),
                Value<String> categoryPath = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> contentMd = const Value.absent(),
                Value<String> extra = const Value.absent(),
                Value<String> related = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<Credibility?> credibility = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => KbEntriesCompanion(
                id: id,
                entryName: entryName,
                categoryPath: categoryPath,
                tags: tags,
                summary: summary,
                contentMd: contentMd,
                extra: extra,
                related: related,
                source: source,
                credibility: credibility,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entryName,
                required String categoryPath,
                Value<String> tags = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> contentMd = const Value.absent(),
                Value<String> extra = const Value.absent(),
                Value<String> related = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<Credibility?> credibility = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => KbEntriesCompanion.insert(
                id: id,
                entryName: entryName,
                categoryPath: categoryPath,
                tags: tags,
                summary: summary,
                contentMd: contentMd,
                extra: extra,
                related: related,
                source: source,
                credibility: credibility,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KbEntriesTable, KbEntry>(table),
                  $$KbEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                relationsAsEntry = false,
                relationsAsRelated = false,
                embeddingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (relationsAsEntry) db.kbRelations,
                    if (relationsAsRelated) db.kbRelations,
                    if (embeddingsRefs) db.embeddings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (relationsAsEntry)
                        await $_getPrefetchedData<
                          KbEntry,
                          $KbEntriesTable,
                          KbRelation
                        >(
                          currentTable: table,
                          referencedTable: $$KbEntriesTableReferences
                              ._relationsAsEntryTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KbEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).relationsAsEntry,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (relationsAsRelated)
                        await $_getPrefetchedData<
                          KbEntry,
                          $KbEntriesTable,
                          KbRelation
                        >(
                          currentTable: table,
                          referencedTable: $$KbEntriesTableReferences
                              ._relationsAsRelatedTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KbEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).relationsAsRelated,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.relatedEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (embeddingsRefs)
                        await $_getPrefetchedData<
                          KbEntry,
                          $KbEntriesTable,
                          EntryEmbedding
                        >(
                          currentTable: table,
                          referencedTable: $$KbEntriesTableReferences
                              ._embeddingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KbEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).embeddingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$KbEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KbEntriesTable,
      KbEntry,
      $$KbEntriesTableFilterComposer,
      $$KbEntriesTableOrderingComposer,
      $$KbEntriesTableAnnotationComposer,
      $$KbEntriesTableCreateCompanionBuilder,
      $$KbEntriesTableUpdateCompanionBuilder,
      (KbEntry, $$KbEntriesTableReferences),
      KbEntry,
      PrefetchHooks Function({
        bool relationsAsEntry,
        bool relationsAsRelated,
        bool embeddingsRefs,
      })
    >;
typedef $$KbRelationsTableCreateCompanionBuilder =
    KbRelationsCompanion Function({
      Value<int> id,
      required int entryId,
      required int relatedEntryId,
    });
typedef $$KbRelationsTableUpdateCompanionBuilder =
    KbRelationsCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<int> relatedEntryId,
    });

final class $$KbRelationsTableReferences
    extends BaseReferences<_$AppDatabase, $KbRelationsTable, KbRelation> {
  $$KbRelationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.kbEntries.createAlias('kb_relations__entry_id__kb_entries__id');

  $$KbEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$KbEntriesTableTableManager(
      $_db,
      $_db.kbEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $KbEntriesTable _relatedEntryIdTable(_$AppDatabase db) => db.kbEntries
      .createAlias('kb_relations__related_entry_id__kb_entries__id');

  $$KbEntriesTableProcessedTableManager get relatedEntryId {
    final $_column = $_itemColumn<int>('related_entry_id')!;

    final manager = $$KbEntriesTableTableManager(
      $_db,
      $_db.kbEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relatedEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KbRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $KbRelationsTable> {
  $$KbRelationsTableFilterComposer({
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

  $$KbEntriesTableFilterComposer get entryId {
    final $$KbEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableFilterComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KbEntriesTableFilterComposer get relatedEntryId {
    final $$KbEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEntryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableFilterComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $KbRelationsTable> {
  $$KbRelationsTableOrderingComposer({
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

  $$KbEntriesTableOrderingComposer get entryId {
    final $$KbEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KbEntriesTableOrderingComposer get relatedEntryId {
    final $$KbEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEntryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KbRelationsTable> {
  $$KbRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$KbEntriesTableAnnotationComposer get entryId {
    final $$KbEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KbEntriesTableAnnotationComposer get relatedEntryId {
    final $$KbEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEntryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KbRelationsTable,
          KbRelation,
          $$KbRelationsTableFilterComposer,
          $$KbRelationsTableOrderingComposer,
          $$KbRelationsTableAnnotationComposer,
          $$KbRelationsTableCreateCompanionBuilder,
          $$KbRelationsTableUpdateCompanionBuilder,
          (KbRelation, $$KbRelationsTableReferences),
          KbRelation,
          PrefetchHooks Function({bool entryId, bool relatedEntryId})
        > {
  $$KbRelationsTableTableManager(_$AppDatabase db, $KbRelationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<int> relatedEntryId = const Value.absent(),
              }) => KbRelationsCompanion(
                id: id,
                entryId: entryId,
                relatedEntryId: relatedEntryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required int relatedEntryId,
              }) => KbRelationsCompanion.insert(
                id: id,
                entryId: entryId,
                relatedEntryId: relatedEntryId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KbRelationsTable, KbRelation>(table),
                  $$KbRelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, relatedEntryId = false}) {
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
                        referencedTable: $$KbRelationsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$KbRelationsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (relatedEntryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.relatedEntryId,
                        referencedTable: $$KbRelationsTableReferences
                            ._relatedEntryIdTable(db),
                        referencedColumn: $$KbRelationsTableReferences
                            ._relatedEntryIdTable(db)
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

typedef $$KbRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KbRelationsTable,
      KbRelation,
      $$KbRelationsTableFilterComposer,
      $$KbRelationsTableOrderingComposer,
      $$KbRelationsTableAnnotationComposer,
      $$KbRelationsTableCreateCompanionBuilder,
      $$KbRelationsTableUpdateCompanionBuilder,
      (KbRelation, $$KbRelationsTableReferences),
      KbRelation,
      PrefetchHooks Function({bool entryId, bool relatedEntryId})
    >;
typedef $$EmbeddingsTableCreateCompanionBuilder = EmbeddingsCompanion Function({
  Value<int> entryId,
  required String model,
  required int dim,
  required Uint8List vector,
});
typedef $$EmbeddingsTableUpdateCompanionBuilder = EmbeddingsCompanion Function({
  Value<int> entryId,
  Value<String> model,
  Value<int> dim,
  Value<Uint8List> vector,
});

final class $$EmbeddingsTableReferences
    extends BaseReferences<_$AppDatabase, $EmbeddingsTable, EntryEmbedding> {
  $$EmbeddingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.kbEntries.createAlias('embeddings__entry_id__kb_entries__id');

  $$KbEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$KbEntriesTableTableManager(
      $_db,
      $_db.kbEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnFilters(column),
  );

  $$KbEntriesTableFilterComposer get entryId {
    final $$KbEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableFilterComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnOrderings(column),
  );

  $$KbEntriesTableOrderingComposer get entryId {
    final $$KbEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get dim =>
      $composableBuilder(column: $table.dim, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  $$KbEntriesTableAnnotationComposer get entryId {
    final $$KbEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.kbEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.kbEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmbeddingsTable,
          EntryEmbedding,
          $$EmbeddingsTableFilterComposer,
          $$EmbeddingsTableOrderingComposer,
          $$EmbeddingsTableAnnotationComposer,
          $$EmbeddingsTableCreateCompanionBuilder,
          $$EmbeddingsTableUpdateCompanionBuilder,
          (EntryEmbedding, $$EmbeddingsTableReferences),
          EntryEmbedding,
          PrefetchHooks Function({bool entryId})
        > {
  $$EmbeddingsTableTableManager(_$AppDatabase db, $EmbeddingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> dim = const Value.absent(),
                Value<Uint8List> vector = const Value.absent(),
              }) => EmbeddingsCompanion(
                entryId: entryId,
                model: model,
                dim: dim,
                vector: vector,
              ),
          createCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                required String model,
                required int dim,
                required Uint8List vector,
              }) => EmbeddingsCompanion.insert(
                entryId: entryId,
                model: model,
                dim: dim,
                vector: vector,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmbeddingsTable, EntryEmbedding>(table),
                  $$EmbeddingsTableReferences(db, table, e),
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
                        referencedTable: $$EmbeddingsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$EmbeddingsTableReferences
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

typedef $$EmbeddingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmbeddingsTable,
      EntryEmbedding,
      $$EmbeddingsTableFilterComposer,
      $$EmbeddingsTableOrderingComposer,
      $$EmbeddingsTableAnnotationComposer,
      $$EmbeddingsTableCreateCompanionBuilder,
      $$EmbeddingsTableUpdateCompanionBuilder,
      (EntryEmbedding, $$EmbeddingsTableReferences),
      EntryEmbedding,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$UsageLogsTableCreateCompanionBuilder = UsageLogsCompanion Function({
  Value<int> id,
  Value<DateTime> ts,
  required String module,
  required String taskType,
  required String providerName,
  required String model,
  Value<String?> presetCode,
  Value<int> inputTokens,
  Value<int> outputTokens,
  Value<double?> costEstimate,
  Value<int> durationMs,
  required UsageStatus status,
  Value<String?> error,
});
typedef $$UsageLogsTableUpdateCompanionBuilder = UsageLogsCompanion Function({
  Value<int> id,
  Value<DateTime> ts,
  Value<String> module,
  Value<String> taskType,
  Value<String> providerName,
  Value<String> model,
  Value<String?> presetCode,
  Value<int> inputTokens,
  Value<int> outputTokens,
  Value<double?> costEstimate,
  Value<int> durationMs,
  Value<UsageStatus> status,
  Value<String?> error,
});

class $$UsageLogsTableFilterComposer
    extends Composer<_$AppDatabase, $UsageLogsTable> {
  $$UsageLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UsageStatus, UsageStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsageLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageLogsTable> {
  $$UsageLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsageLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageLogsTable> {
  $$UsageLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get presetCode => $composableBuilder(
    column: $table.presetCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<UsageStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$UsageLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageLogsTable,
          UsageLogEntry,
          $$UsageLogsTableFilterComposer,
          $$UsageLogsTableOrderingComposer,
          $$UsageLogsTableAnnotationComposer,
          $$UsageLogsTableCreateCompanionBuilder,
          $$UsageLogsTableUpdateCompanionBuilder,
          (
            UsageLogEntry,
            BaseReferences<_$AppDatabase, $UsageLogsTable, UsageLogEntry>,
          ),
          UsageLogEntry,
          PrefetchHooks Function()
        > {
  $$UsageLogsTableTableManager(_$AppDatabase db, $UsageLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> providerName = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> presetCode = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<double?> costEstimate = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<UsageStatus> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => UsageLogsCompanion(
                id: id,
                ts: ts,
                module: module,
                taskType: taskType,
                providerName: providerName,
                model: model,
                presetCode: presetCode,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                costEstimate: costEstimate,
                durationMs: durationMs,
                status: status,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                required String module,
                required String taskType,
                required String providerName,
                required String model,
                Value<String?> presetCode = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<double?> costEstimate = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required UsageStatus status,
                Value<String?> error = const Value.absent(),
              }) => UsageLogsCompanion.insert(
                id: id,
                ts: ts,
                module: module,
                taskType: taskType,
                providerName: providerName,
                model: model,
                presetCode: presetCode,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                costEstimate: costEstimate,
                durationMs: durationMs,
                status: status,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsageLogsTable, UsageLogEntry>(table),
                  BaseReferences<_$AppDatabase, $UsageLogsTable, UsageLogEntry>(
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

typedef $$UsageLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageLogsTable,
      UsageLogEntry,
      $$UsageLogsTableFilterComposer,
      $$UsageLogsTableOrderingComposer,
      $$UsageLogsTableAnnotationComposer,
      $$UsageLogsTableCreateCompanionBuilder,
      $$UsageLogsTableUpdateCompanionBuilder,
      (
        UsageLogEntry,
        BaseReferences<_$AppDatabase, $UsageLogsTable, UsageLogEntry>,
      ),
      UsageLogEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskQueueTableCreateCompanionBuilder = TaskQueueCompanion Function({
  Value<int> id,
  required String module,
  required String taskType,
  required String payload,
  Value<QueueTaskStatus> status,
  Value<String?> result,
  Value<String?> error,
  Value<int> retries,
  Value<DateTime> createdAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> finishedAt,
});
typedef $$TaskQueueTableUpdateCompanionBuilder = TaskQueueCompanion Function({
  Value<int> id,
  Value<String> module,
  Value<String> taskType,
  Value<String> payload,
  Value<QueueTaskStatus> status,
  Value<String?> result,
  Value<String?> error,
  Value<int> retries,
  Value<DateTime> createdAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> finishedAt,
});

class $$TaskQueueTableFilterComposer
    extends Composer<_$AppDatabase, $TaskQueueTable> {
  $$TaskQueueTableFilterComposer({
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

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QueueTaskStatus, QueueTaskStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retries => $composableBuilder(
    column: $table.retries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskQueueTable> {
  $$TaskQueueTableOrderingComposer({
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

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retries => $composableBuilder(
    column: $table.retries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskQueueTable> {
  $$TaskQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QueueTaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get retries =>
      $composableBuilder(column: $table.retries, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$TaskQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskQueueTable,
          TaskQueueItem,
          $$TaskQueueTableFilterComposer,
          $$TaskQueueTableOrderingComposer,
          $$TaskQueueTableAnnotationComposer,
          $$TaskQueueTableCreateCompanionBuilder,
          $$TaskQueueTableUpdateCompanionBuilder,
          (
            TaskQueueItem,
            BaseReferences<_$AppDatabase, $TaskQueueTable, TaskQueueItem>,
          ),
          TaskQueueItem,
          PrefetchHooks Function()
        > {
  $$TaskQueueTableTableManager(_$AppDatabase db, $TaskQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<QueueTaskStatus> status = const Value.absent(),
                Value<String?> result = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> retries = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => TaskQueueCompanion(
                id: id,
                module: module,
                taskType: taskType,
                payload: payload,
                status: status,
                result: result,
                error: error,
                retries: retries,
                createdAt: createdAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String module,
                required String taskType,
                required String payload,
                Value<QueueTaskStatus> status = const Value.absent(),
                Value<String?> result = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> retries = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => TaskQueueCompanion.insert(
                id: id,
                module: module,
                taskType: taskType,
                payload: payload,
                status: status,
                result: result,
                error: error,
                retries: retries,
                createdAt: createdAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskQueueTable, TaskQueueItem>(table),
                  BaseReferences<_$AppDatabase, $TaskQueueTable, TaskQueueItem>(
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

typedef $$TaskQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskQueueTable,
      TaskQueueItem,
      $$TaskQueueTableFilterComposer,
      $$TaskQueueTableOrderingComposer,
      $$TaskQueueTableAnnotationComposer,
      $$TaskQueueTableCreateCompanionBuilder,
      $$TaskQueueTableUpdateCompanionBuilder,
      (
        TaskQueueItem,
        BaseReferences<_$AppDatabase, $TaskQueueTable, TaskQueueItem>,
      ),
      TaskQueueItem,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$MemosTableCreateCompanionBuilder = MemosCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<String> images,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MemosTableUpdateCompanionBuilder = MemosCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<String> images,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MemosTableFilterComposer extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemosTableOrderingComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemosTable,
          MemoRow,
          $$MemosTableFilterComposer,
          $$MemosTableOrderingComposer,
          $$MemosTableAnnotationComposer,
          $$MemosTableCreateCompanionBuilder,
          $$MemosTableUpdateCompanionBuilder,
          (MemoRow, BaseReferences<_$AppDatabase, $MemosTable, MemoRow>),
          MemoRow,
          PrefetchHooks Function()
        > {
  $$MemosTableTableManager(_$AppDatabase db, $MemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MemosCompanion(
                id: id,
                title: title,
                content: content,
                images: images,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MemosCompanion.insert(
                id: id,
                title: title,
                content: content,
                images: images,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemosTable, MemoRow>(table),
                  BaseReferences<_$AppDatabase, $MemosTable, MemoRow>(
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

typedef $$MemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemosTable,
      MemoRow,
      $$MemosTableFilterComposer,
      $$MemosTableOrderingComposer,
      $$MemosTableAnnotationComposer,
      $$MemosTableCreateCompanionBuilder,
      $$MemosTableUpdateCompanionBuilder,
      (MemoRow, BaseReferences<_$AppDatabase, $MemosTable, MemoRow>),
      MemoRow,
      PrefetchHooks Function()
    >;
typedef $$PasswordEntriesTableCreateCompanionBuilder =
    PasswordEntriesCompanion Function({
      Value<int> id,
      required String name,
      required String fieldsEnc,
      Value<String?> noteEnc,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PasswordEntriesTableUpdateCompanionBuilder =
    PasswordEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> fieldsEnc,
      Value<String?> noteEnc,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PasswordEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PasswordEntriesTable> {
  $$PasswordEntriesTableFilterComposer({
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

  ColumnFilters<String> get fieldsEnc => $composableBuilder(
    column: $table.fieldsEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteEnc => $composableBuilder(
    column: $table.noteEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PasswordEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PasswordEntriesTable> {
  $$PasswordEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get fieldsEnc => $composableBuilder(
    column: $table.fieldsEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteEnc => $composableBuilder(
    column: $table.noteEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PasswordEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PasswordEntriesTable> {
  $$PasswordEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get fieldsEnc =>
      $composableBuilder(column: $table.fieldsEnc, builder: (column) => column);

  GeneratedColumn<String> get noteEnc =>
      $composableBuilder(column: $table.noteEnc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PasswordEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PasswordEntriesTable,
          PasswordEntryRow,
          $$PasswordEntriesTableFilterComposer,
          $$PasswordEntriesTableOrderingComposer,
          $$PasswordEntriesTableAnnotationComposer,
          $$PasswordEntriesTableCreateCompanionBuilder,
          $$PasswordEntriesTableUpdateCompanionBuilder,
          (
            PasswordEntryRow,
            BaseReferences<
              _$AppDatabase,
              $PasswordEntriesTable,
              PasswordEntryRow
            >,
          ),
          PasswordEntryRow,
          PrefetchHooks Function()
        > {
  $$PasswordEntriesTableTableManager(
    _$AppDatabase db,
    $PasswordEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PasswordEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PasswordEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PasswordEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fieldsEnc = const Value.absent(),
                Value<String?> noteEnc = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PasswordEntriesCompanion(
                id: id,
                name: name,
                fieldsEnc: fieldsEnc,
                noteEnc: noteEnc,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String fieldsEnc,
                Value<String?> noteEnc = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PasswordEntriesCompanion.insert(
                id: id,
                name: name,
                fieldsEnc: fieldsEnc,
                noteEnc: noteEnc,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PasswordEntriesTable, PasswordEntryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PasswordEntriesTable,
                    PasswordEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PasswordEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PasswordEntriesTable,
      PasswordEntryRow,
      $$PasswordEntriesTableFilterComposer,
      $$PasswordEntriesTableOrderingComposer,
      $$PasswordEntriesTableAnnotationComposer,
      $$PasswordEntriesTableCreateCompanionBuilder,
      $$PasswordEntriesTableUpdateCompanionBuilder,
      (
        PasswordEntryRow,
        BaseReferences<_$AppDatabase, $PasswordEntriesTable, PasswordEntryRow>,
      ),
      PasswordEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db, _db.providers);
  $$ModelsTableTableManager get models =>
      $$ModelsTableTableManager(_db, _db.models);
  $$IntensityPresetsTableTableManager get intensityPresets =>
      $$IntensityPresetsTableTableManager(_db, _db.intensityPresets);
  $$FragmentsTableTableManager get fragments =>
      $$FragmentsTableTableManager(_db, _db.fragments);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db, _db.prompts);
  $$PromptVersionsTableTableManager get promptVersions =>
      $$PromptVersionsTableTableManager(_db, _db.promptVersions);
  $$KbCategoriesTableTableManager get kbCategories =>
      $$KbCategoriesTableTableManager(_db, _db.kbCategories);
  $$KbEntriesTableTableManager get kbEntries =>
      $$KbEntriesTableTableManager(_db, _db.kbEntries);
  $$KbRelationsTableTableManager get kbRelations =>
      $$KbRelationsTableTableManager(_db, _db.kbRelations);
  $$EmbeddingsTableTableManager get embeddings =>
      $$EmbeddingsTableTableManager(_db, _db.embeddings);
  $$UsageLogsTableTableManager get usageLogs =>
      $$UsageLogsTableTableManager(_db, _db.usageLogs);
  $$TaskQueueTableTableManager get taskQueue =>
      $$TaskQueueTableTableManager(_db, _db.taskQueue);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db, _db.memos);
  $$PasswordEntriesTableTableManager get passwordEntries =>
      $$PasswordEntriesTableTableManager(_db, _db.passwordEntries);
}

mixin _$ProvidersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProvidersTable get providers => attachedDatabase.providers;
  ProvidersDaoManager get managers => ProvidersDaoManager(this);
}

class ProvidersDaoManager {
  final _$ProvidersDaoMixin _db;
  ProvidersDaoManager(this._db);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db.attachedDatabase, _db.providers);
}

mixin _$ModelsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProvidersTable get providers => attachedDatabase.providers;
  $ModelsTable get models => attachedDatabase.models;
  ModelsDaoManager get managers => ModelsDaoManager(this);
}

class ModelsDaoManager {
  final _$ModelsDaoMixin _db;
  ModelsDaoManager(this._db);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db.attachedDatabase, _db.providers);
  $$ModelsTableTableManager get models =>
      $$ModelsTableTableManager(_db.attachedDatabase, _db.models);
}

mixin _$IntensityPresetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $IntensityPresetsTable get intensityPresets =>
      attachedDatabase.intensityPresets;
  IntensityPresetsDaoManager get managers => IntensityPresetsDaoManager(this);
}

class IntensityPresetsDaoManager {
  final _$IntensityPresetsDaoMixin _db;
  IntensityPresetsDaoManager(this._db);
  $$IntensityPresetsTableTableManager get intensityPresets =>
      $$IntensityPresetsTableTableManager(
        _db.attachedDatabase,
        _db.intensityPresets,
      );
}

mixin _$FragmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FragmentsTable get fragments => attachedDatabase.fragments;
  FragmentsDaoManager get managers => FragmentsDaoManager(this);
}

class FragmentsDaoManager {
  final _$FragmentsDaoMixin _db;
  FragmentsDaoManager(this._db);
  $$FragmentsTableTableManager get fragments =>
      $$FragmentsTableTableManager(_db.attachedDatabase, _db.fragments);
}

mixin _$PromptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptsTable get prompts => attachedDatabase.prompts;
  PromptsDaoManager get managers => PromptsDaoManager(this);
}

class PromptsDaoManager {
  final _$PromptsDaoMixin _db;
  PromptsDaoManager(this._db);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db.attachedDatabase, _db.prompts);
}

mixin _$PromptVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptsTable get prompts => attachedDatabase.prompts;
  $PromptVersionsTable get promptVersions => attachedDatabase.promptVersions;
  PromptVersionsDaoManager get managers => PromptVersionsDaoManager(this);
}

class PromptVersionsDaoManager {
  final _$PromptVersionsDaoMixin _db;
  PromptVersionsDaoManager(this._db);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db.attachedDatabase, _db.prompts);
  $$PromptVersionsTableTableManager get promptVersions =>
      $$PromptVersionsTableTableManager(
        _db.attachedDatabase,
        _db.promptVersions,
      );
}

mixin _$KbCategoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $KbCategoriesTable get kbCategories => attachedDatabase.kbCategories;
  KbCategoriesDaoManager get managers => KbCategoriesDaoManager(this);
}

class KbCategoriesDaoManager {
  final _$KbCategoriesDaoMixin _db;
  KbCategoriesDaoManager(this._db);
  $$KbCategoriesTableTableManager get kbCategories =>
      $$KbCategoriesTableTableManager(_db.attachedDatabase, _db.kbCategories);
}

mixin _$KbEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $KbEntriesTable get kbEntries => attachedDatabase.kbEntries;
  KbEntriesDaoManager get managers => KbEntriesDaoManager(this);
}

class KbEntriesDaoManager {
  final _$KbEntriesDaoMixin _db;
  KbEntriesDaoManager(this._db);
  $$KbEntriesTableTableManager get kbEntries =>
      $$KbEntriesTableTableManager(_db.attachedDatabase, _db.kbEntries);
}

mixin _$KbRelationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $KbEntriesTable get kbEntries => attachedDatabase.kbEntries;
  $KbRelationsTable get kbRelations => attachedDatabase.kbRelations;
  KbRelationsDaoManager get managers => KbRelationsDaoManager(this);
}

class KbRelationsDaoManager {
  final _$KbRelationsDaoMixin _db;
  KbRelationsDaoManager(this._db);
  $$KbEntriesTableTableManager get kbEntries =>
      $$KbEntriesTableTableManager(_db.attachedDatabase, _db.kbEntries);
  $$KbRelationsTableTableManager get kbRelations =>
      $$KbRelationsTableTableManager(_db.attachedDatabase, _db.kbRelations);
}

mixin _$EmbeddingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $KbEntriesTable get kbEntries => attachedDatabase.kbEntries;
  $EmbeddingsTable get embeddings => attachedDatabase.embeddings;
  EmbeddingsDaoManager get managers => EmbeddingsDaoManager(this);
}

class EmbeddingsDaoManager {
  final _$EmbeddingsDaoMixin _db;
  EmbeddingsDaoManager(this._db);
  $$KbEntriesTableTableManager get kbEntries =>
      $$KbEntriesTableTableManager(_db.attachedDatabase, _db.kbEntries);
  $$EmbeddingsTableTableManager get embeddings =>
      $$EmbeddingsTableTableManager(_db.attachedDatabase, _db.embeddings);
}

mixin _$UsageLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsageLogsTable get usageLogs => attachedDatabase.usageLogs;
  UsageLogDaoManager get managers => UsageLogDaoManager(this);
}

class UsageLogDaoManager {
  final _$UsageLogDaoMixin _db;
  UsageLogDaoManager(this._db);
  $$UsageLogsTableTableManager get usageLogs =>
      $$UsageLogsTableTableManager(_db.attachedDatabase, _db.usageLogs);
}

mixin _$TaskQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskQueueTable get taskQueue => attachedDatabase.taskQueue;
  TaskQueueDaoManager get managers => TaskQueueDaoManager(this);
}

class TaskQueueDaoManager {
  final _$TaskQueueDaoMixin _db;
  TaskQueueDaoManager(this._db);
  $$TaskQueueTableTableManager get taskQueue =>
      $$TaskQueueTableTableManager(_db.attachedDatabase, _db.taskQueue);
}

mixin _$AppSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  AppSettingsDaoManager get managers => AppSettingsDaoManager(this);
}

class AppSettingsDaoManager {
  final _$AppSettingsDaoMixin _db;
  AppSettingsDaoManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
}

mixin _$MemosDaoMixin on DatabaseAccessor<AppDatabase> {
  $MemosTable get memos => attachedDatabase.memos;
  MemosDaoManager get managers => MemosDaoManager(this);
}

class MemosDaoManager {
  final _$MemosDaoMixin _db;
  MemosDaoManager(this._db);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db.attachedDatabase, _db.memos);
}

mixin _$PasswordEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PasswordEntriesTable get passwordEntries => attachedDatabase.passwordEntries;
  PasswordEntriesDaoManager get managers => PasswordEntriesDaoManager(this);
}

class PasswordEntriesDaoManager {
  final _$PasswordEntriesDaoMixin _db;
  PasswordEntriesDaoManager(this._db);
  $$PasswordEntriesTableTableManager get passwordEntries =>
      $$PasswordEntriesTableTableManager(
        _db.attachedDatabase,
        _db.passwordEntries,
      );
}
