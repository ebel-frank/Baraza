// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CasesTable extends Cases with TableInfo<$CasesTable, Case> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseTypeMeta = const VerificationMeta(
    'caseType',
  );
  @override
  late final GeneratedColumn<String> caseType = GeneratedColumn<String>(
    'case_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partiesJsonMeta = const VerificationMeta(
    'partiesJson',
  );
  @override
  late final GeneratedColumn<String> partiesJson = GeneratedColumn<String>(
    'parties_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceNoteRefsJsonMeta = const VerificationMeta(
    'voiceNoteRefsJson',
  );
  @override
  late final GeneratedColumn<String> voiceNoteRefsJson =
      GeneratedColumn<String>(
        'voice_note_refs_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referralFlagMeta = const VerificationMeta(
    'referralFlag',
  );
  @override
  late final GeneratedColumn<bool> referralFlag = GeneratedColumn<bool>(
    'referral_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("referral_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _referralReasonMeta = const VerificationMeta(
    'referralReason',
  );
  @override
  late final GeneratedColumn<String> referralReason = GeneratedColumn<String>(
    'referral_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _advisoryResponseJsonMeta =
      const VerificationMeta('advisoryResponseJson');
  @override
  late final GeneratedColumn<String> advisoryResponseJson =
      GeneratedColumn<String>(
        'advisory_response_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseType,
    partiesJson,
    description,
    voiceNoteRefsJson,
    location,
    createdAt,
    syncedAt,
    referralFlag,
    referralReason,
    advisoryResponseJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Case> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_type')) {
      context.handle(
        _caseTypeMeta,
        caseType.isAcceptableOrUnknown(data['case_type']!, _caseTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_caseTypeMeta);
    }
    if (data.containsKey('parties_json')) {
      context.handle(
        _partiesJsonMeta,
        partiesJson.isAcceptableOrUnknown(
          data['parties_json']!,
          _partiesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partiesJsonMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('voice_note_refs_json')) {
      context.handle(
        _voiceNoteRefsJsonMeta,
        voiceNoteRefsJson.isAcceptableOrUnknown(
          data['voice_note_refs_json']!,
          _voiceNoteRefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('referral_flag')) {
      context.handle(
        _referralFlagMeta,
        referralFlag.isAcceptableOrUnknown(
          data['referral_flag']!,
          _referralFlagMeta,
        ),
      );
    }
    if (data.containsKey('referral_reason')) {
      context.handle(
        _referralReasonMeta,
        referralReason.isAcceptableOrUnknown(
          data['referral_reason']!,
          _referralReasonMeta,
        ),
      );
    }
    if (data.containsKey('advisory_response_json')) {
      context.handle(
        _advisoryResponseJsonMeta,
        advisoryResponseJson.isAcceptableOrUnknown(
          data['advisory_response_json']!,
          _advisoryResponseJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Case map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Case(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_type'],
      )!,
      partiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parties_json'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      voiceNoteRefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_note_refs_json'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      referralFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}referral_flag'],
      )!,
      referralReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referral_reason'],
      ),
      advisoryResponseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advisory_response_json'],
      ),
    );
  }

  @override
  $CasesTable createAlias(String alias) {
    return $CasesTable(attachedDatabase, alias);
  }
}

class Case extends DataClass implements Insertable<Case> {
  final String id;
  final String caseType;
  final String partiesJson;
  final String description;
  final String? voiceNoteRefsJson;
  final String location;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool referralFlag;
  final String? referralReason;
  final String? advisoryResponseJson;
  const Case({
    required this.id,
    required this.caseType,
    required this.partiesJson,
    required this.description,
    this.voiceNoteRefsJson,
    required this.location,
    required this.createdAt,
    this.syncedAt,
    required this.referralFlag,
    this.referralReason,
    this.advisoryResponseJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_type'] = Variable<String>(caseType);
    map['parties_json'] = Variable<String>(partiesJson);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || voiceNoteRefsJson != null) {
      map['voice_note_refs_json'] = Variable<String>(voiceNoteRefsJson);
    }
    map['location'] = Variable<String>(location);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['referral_flag'] = Variable<bool>(referralFlag);
    if (!nullToAbsent || referralReason != null) {
      map['referral_reason'] = Variable<String>(referralReason);
    }
    if (!nullToAbsent || advisoryResponseJson != null) {
      map['advisory_response_json'] = Variable<String>(advisoryResponseJson);
    }
    return map;
  }

  CasesCompanion toCompanion(bool nullToAbsent) {
    return CasesCompanion(
      id: Value(id),
      caseType: Value(caseType),
      partiesJson: Value(partiesJson),
      description: Value(description),
      voiceNoteRefsJson: voiceNoteRefsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNoteRefsJson),
      location: Value(location),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      referralFlag: Value(referralFlag),
      referralReason: referralReason == null && nullToAbsent
          ? const Value.absent()
          : Value(referralReason),
      advisoryResponseJson: advisoryResponseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(advisoryResponseJson),
    );
  }

  factory Case.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Case(
      id: serializer.fromJson<String>(json['id']),
      caseType: serializer.fromJson<String>(json['caseType']),
      partiesJson: serializer.fromJson<String>(json['partiesJson']),
      description: serializer.fromJson<String>(json['description']),
      voiceNoteRefsJson: serializer.fromJson<String?>(
        json['voiceNoteRefsJson'],
      ),
      location: serializer.fromJson<String>(json['location']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      referralFlag: serializer.fromJson<bool>(json['referralFlag']),
      referralReason: serializer.fromJson<String?>(json['referralReason']),
      advisoryResponseJson: serializer.fromJson<String?>(
        json['advisoryResponseJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseType': serializer.toJson<String>(caseType),
      'partiesJson': serializer.toJson<String>(partiesJson),
      'description': serializer.toJson<String>(description),
      'voiceNoteRefsJson': serializer.toJson<String?>(voiceNoteRefsJson),
      'location': serializer.toJson<String>(location),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'referralFlag': serializer.toJson<bool>(referralFlag),
      'referralReason': serializer.toJson<String?>(referralReason),
      'advisoryResponseJson': serializer.toJson<String?>(advisoryResponseJson),
    };
  }

  Case copyWith({
    String? id,
    String? caseType,
    String? partiesJson,
    String? description,
    Value<String?> voiceNoteRefsJson = const Value.absent(),
    String? location,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    bool? referralFlag,
    Value<String?> referralReason = const Value.absent(),
    Value<String?> advisoryResponseJson = const Value.absent(),
  }) => Case(
    id: id ?? this.id,
    caseType: caseType ?? this.caseType,
    partiesJson: partiesJson ?? this.partiesJson,
    description: description ?? this.description,
    voiceNoteRefsJson: voiceNoteRefsJson.present
        ? voiceNoteRefsJson.value
        : this.voiceNoteRefsJson,
    location: location ?? this.location,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    referralFlag: referralFlag ?? this.referralFlag,
    referralReason: referralReason.present
        ? referralReason.value
        : this.referralReason,
    advisoryResponseJson: advisoryResponseJson.present
        ? advisoryResponseJson.value
        : this.advisoryResponseJson,
  );
  Case copyWithCompanion(CasesCompanion data) {
    return Case(
      id: data.id.present ? data.id.value : this.id,
      caseType: data.caseType.present ? data.caseType.value : this.caseType,
      partiesJson: data.partiesJson.present
          ? data.partiesJson.value
          : this.partiesJson,
      description: data.description.present
          ? data.description.value
          : this.description,
      voiceNoteRefsJson: data.voiceNoteRefsJson.present
          ? data.voiceNoteRefsJson.value
          : this.voiceNoteRefsJson,
      location: data.location.present ? data.location.value : this.location,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      referralFlag: data.referralFlag.present
          ? data.referralFlag.value
          : this.referralFlag,
      referralReason: data.referralReason.present
          ? data.referralReason.value
          : this.referralReason,
      advisoryResponseJson: data.advisoryResponseJson.present
          ? data.advisoryResponseJson.value
          : this.advisoryResponseJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Case(')
          ..write('id: $id, ')
          ..write('caseType: $caseType, ')
          ..write('partiesJson: $partiesJson, ')
          ..write('description: $description, ')
          ..write('voiceNoteRefsJson: $voiceNoteRefsJson, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('referralFlag: $referralFlag, ')
          ..write('referralReason: $referralReason, ')
          ..write('advisoryResponseJson: $advisoryResponseJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseType,
    partiesJson,
    description,
    voiceNoteRefsJson,
    location,
    createdAt,
    syncedAt,
    referralFlag,
    referralReason,
    advisoryResponseJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Case &&
          other.id == this.id &&
          other.caseType == this.caseType &&
          other.partiesJson == this.partiesJson &&
          other.description == this.description &&
          other.voiceNoteRefsJson == this.voiceNoteRefsJson &&
          other.location == this.location &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.referralFlag == this.referralFlag &&
          other.referralReason == this.referralReason &&
          other.advisoryResponseJson == this.advisoryResponseJson);
}

class CasesCompanion extends UpdateCompanion<Case> {
  final Value<String> id;
  final Value<String> caseType;
  final Value<String> partiesJson;
  final Value<String> description;
  final Value<String?> voiceNoteRefsJson;
  final Value<String> location;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<bool> referralFlag;
  final Value<String?> referralReason;
  final Value<String?> advisoryResponseJson;
  final Value<int> rowid;
  const CasesCompanion({
    this.id = const Value.absent(),
    this.caseType = const Value.absent(),
    this.partiesJson = const Value.absent(),
    this.description = const Value.absent(),
    this.voiceNoteRefsJson = const Value.absent(),
    this.location = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.referralFlag = const Value.absent(),
    this.referralReason = const Value.absent(),
    this.advisoryResponseJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CasesCompanion.insert({
    required String id,
    required String caseType,
    required String partiesJson,
    required String description,
    this.voiceNoteRefsJson = const Value.absent(),
    required String location,
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.referralFlag = const Value.absent(),
    this.referralReason = const Value.absent(),
    this.advisoryResponseJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseType = Value(caseType),
       partiesJson = Value(partiesJson),
       description = Value(description),
       location = Value(location),
       createdAt = Value(createdAt);
  static Insertable<Case> custom({
    Expression<String>? id,
    Expression<String>? caseType,
    Expression<String>? partiesJson,
    Expression<String>? description,
    Expression<String>? voiceNoteRefsJson,
    Expression<String>? location,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<bool>? referralFlag,
    Expression<String>? referralReason,
    Expression<String>? advisoryResponseJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseType != null) 'case_type': caseType,
      if (partiesJson != null) 'parties_json': partiesJson,
      if (description != null) 'description': description,
      if (voiceNoteRefsJson != null) 'voice_note_refs_json': voiceNoteRefsJson,
      if (location != null) 'location': location,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (referralFlag != null) 'referral_flag': referralFlag,
      if (referralReason != null) 'referral_reason': referralReason,
      if (advisoryResponseJson != null)
        'advisory_response_json': advisoryResponseJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CasesCompanion copyWith({
    Value<String>? id,
    Value<String>? caseType,
    Value<String>? partiesJson,
    Value<String>? description,
    Value<String?>? voiceNoteRefsJson,
    Value<String>? location,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<bool>? referralFlag,
    Value<String?>? referralReason,
    Value<String?>? advisoryResponseJson,
    Value<int>? rowid,
  }) {
    return CasesCompanion(
      id: id ?? this.id,
      caseType: caseType ?? this.caseType,
      partiesJson: partiesJson ?? this.partiesJson,
      description: description ?? this.description,
      voiceNoteRefsJson: voiceNoteRefsJson ?? this.voiceNoteRefsJson,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      referralFlag: referralFlag ?? this.referralFlag,
      referralReason: referralReason ?? this.referralReason,
      advisoryResponseJson: advisoryResponseJson ?? this.advisoryResponseJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseType.present) {
      map['case_type'] = Variable<String>(caseType.value);
    }
    if (partiesJson.present) {
      map['parties_json'] = Variable<String>(partiesJson.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (voiceNoteRefsJson.present) {
      map['voice_note_refs_json'] = Variable<String>(voiceNoteRefsJson.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (referralFlag.present) {
      map['referral_flag'] = Variable<bool>(referralFlag.value);
    }
    if (referralReason.present) {
      map['referral_reason'] = Variable<String>(referralReason.value);
    }
    if (advisoryResponseJson.present) {
      map['advisory_response_json'] = Variable<String>(
        advisoryResponseJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasesCompanion(')
          ..write('id: $id, ')
          ..write('caseType: $caseType, ')
          ..write('partiesJson: $partiesJson, ')
          ..write('description: $description, ')
          ..write('voiceNoteRefsJson: $voiceNoteRefsJson, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('referralFlag: $referralFlag, ')
          ..write('referralReason: $referralReason, ')
          ..write('advisoryResponseJson: $advisoryResponseJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CasesTable cases = $CasesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cases];
}

typedef $$CasesTableCreateCompanionBuilder =
    CasesCompanion Function({
      required String id,
      required String caseType,
      required String partiesJson,
      required String description,
      Value<String?> voiceNoteRefsJson,
      required String location,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<bool> referralFlag,
      Value<String?> referralReason,
      Value<String?> advisoryResponseJson,
      Value<int> rowid,
    });
typedef $$CasesTableUpdateCompanionBuilder =
    CasesCompanion Function({
      Value<String> id,
      Value<String> caseType,
      Value<String> partiesJson,
      Value<String> description,
      Value<String?> voiceNoteRefsJson,
      Value<String> location,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<bool> referralFlag,
      Value<String?> referralReason,
      Value<String?> advisoryResponseJson,
      Value<int> rowid,
    });

class $$CasesTableFilterComposer extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseType => $composableBuilder(
    column: $table.caseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partiesJson => $composableBuilder(
    column: $table.partiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceNoteRefsJson => $composableBuilder(
    column: $table.voiceNoteRefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get referralFlag => $composableBuilder(
    column: $table.referralFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referralReason => $composableBuilder(
    column: $table.referralReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advisoryResponseJson => $composableBuilder(
    column: $table.advisoryResponseJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseType => $composableBuilder(
    column: $table.caseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partiesJson => $composableBuilder(
    column: $table.partiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceNoteRefsJson => $composableBuilder(
    column: $table.voiceNoteRefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get referralFlag => $composableBuilder(
    column: $table.referralFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referralReason => $composableBuilder(
    column: $table.referralReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advisoryResponseJson => $composableBuilder(
    column: $table.advisoryResponseJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get caseType =>
      $composableBuilder(column: $table.caseType, builder: (column) => column);

  GeneratedColumn<String> get partiesJson => $composableBuilder(
    column: $table.partiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceNoteRefsJson => $composableBuilder(
    column: $table.voiceNoteRefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<bool> get referralFlag => $composableBuilder(
    column: $table.referralFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referralReason => $composableBuilder(
    column: $table.referralReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advisoryResponseJson => $composableBuilder(
    column: $table.advisoryResponseJson,
    builder: (column) => column,
  );
}

class $$CasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CasesTable,
          Case,
          $$CasesTableFilterComposer,
          $$CasesTableOrderingComposer,
          $$CasesTableAnnotationComposer,
          $$CasesTableCreateCompanionBuilder,
          $$CasesTableUpdateCompanionBuilder,
          (Case, BaseReferences<_$AppDatabase, $CasesTable, Case>),
          Case,
          PrefetchHooks Function()
        > {
  $$CasesTableTableManager(_$AppDatabase db, $CasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> caseType = const Value.absent(),
                Value<String> partiesJson = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> voiceNoteRefsJson = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<bool> referralFlag = const Value.absent(),
                Value<String?> referralReason = const Value.absent(),
                Value<String?> advisoryResponseJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CasesCompanion(
                id: id,
                caseType: caseType,
                partiesJson: partiesJson,
                description: description,
                voiceNoteRefsJson: voiceNoteRefsJson,
                location: location,
                createdAt: createdAt,
                syncedAt: syncedAt,
                referralFlag: referralFlag,
                referralReason: referralReason,
                advisoryResponseJson: advisoryResponseJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String caseType,
                required String partiesJson,
                required String description,
                Value<String?> voiceNoteRefsJson = const Value.absent(),
                required String location,
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<bool> referralFlag = const Value.absent(),
                Value<String?> referralReason = const Value.absent(),
                Value<String?> advisoryResponseJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CasesCompanion.insert(
                id: id,
                caseType: caseType,
                partiesJson: partiesJson,
                description: description,
                voiceNoteRefsJson: voiceNoteRefsJson,
                location: location,
                createdAt: createdAt,
                syncedAt: syncedAt,
                referralFlag: referralFlag,
                referralReason: referralReason,
                advisoryResponseJson: advisoryResponseJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CasesTable, Case>(table),
                  BaseReferences<_$AppDatabase, $CasesTable, Case>(
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

typedef $$CasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CasesTable,
      Case,
      $$CasesTableFilterComposer,
      $$CasesTableOrderingComposer,
      $$CasesTableAnnotationComposer,
      $$CasesTableCreateCompanionBuilder,
      $$CasesTableUpdateCompanionBuilder,
      (Case, BaseReferences<_$AppDatabase, $CasesTable, Case>),
      Case,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CasesTableTableManager get cases =>
      $$CasesTableTableManager(_db, _db.cases);
}
