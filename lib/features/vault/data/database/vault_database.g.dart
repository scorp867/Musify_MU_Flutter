// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_database.dart';

// ignore_for_file: type=lint
class $VaultPlaylistsTableTable extends VaultPlaylistsTable
    with TableInfo<$VaultPlaylistsTableTable, VaultPlaylistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultPlaylistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedTitleMeta = const VerificationMeta(
    'encryptedTitle',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedTitle =
      GeneratedColumn<Uint8List>(
        'encrypted_title',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedDescriptionMeta =
      const VerificationMeta('encryptedDescription');
  @override
  late final GeneratedColumn<Uint8List> encryptedDescription =
      GeneratedColumn<Uint8List>(
        'encrypted_description',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedCoverPathMeta =
      const VerificationMeta('encryptedCoverPath');
  @override
  late final GeneratedColumn<Uint8List> encryptedCoverPath =
      GeneratedColumn<Uint8List>(
        'encrypted_cover_path',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    encryptedTitle,
    encryptedDescription,
    encryptedCoverPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultPlaylistEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encrypted_title')) {
      context.handle(
        _encryptedTitleMeta,
        encryptedTitle.isAcceptableOrUnknown(
          data['encrypted_title']!,
          _encryptedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedTitleMeta);
    }
    if (data.containsKey('encrypted_description')) {
      context.handle(
        _encryptedDescriptionMeta,
        encryptedDescription.isAcceptableOrUnknown(
          data['encrypted_description']!,
          _encryptedDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedDescriptionMeta);
    }
    if (data.containsKey('encrypted_cover_path')) {
      context.handle(
        _encryptedCoverPathMeta,
        encryptedCoverPath.isAcceptableOrUnknown(
          data['encrypted_cover_path']!,
          _encryptedCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  VaultPlaylistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultPlaylistEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encryptedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_title'],
      )!,
      encryptedDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_description'],
      )!,
      encryptedCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_cover_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultPlaylistsTableTable createAlias(String alias) {
    return $VaultPlaylistsTableTable(attachedDatabase, alias);
  }
}

class VaultPlaylistEntry extends DataClass
    implements Insertable<VaultPlaylistEntry> {
  /// Primary key UUID string.
  final String id;

  /// AES-256-GCM encrypted playlist title payload.
  final Uint8List encryptedTitle;

  /// AES-256-GCM encrypted playlist description payload.
  final Uint8List encryptedDescription;

  /// Optional AES-256-GCM encrypted cover artwork URI payload.
  final Uint8List? encryptedCoverPath;

  /// Creation epoch timestamp in milliseconds.
  final int createdAt;

  /// Last modification epoch timestamp in milliseconds.
  final int updatedAt;
  const VaultPlaylistEntry({
    required this.id,
    required this.encryptedTitle,
    required this.encryptedDescription,
    this.encryptedCoverPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encrypted_title'] = Variable<Uint8List>(encryptedTitle);
    map['encrypted_description'] = Variable<Uint8List>(encryptedDescription);
    if (!nullToAbsent || encryptedCoverPath != null) {
      map['encrypted_cover_path'] = Variable<Uint8List>(encryptedCoverPath);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultPlaylistsTableCompanion toCompanion(bool nullToAbsent) {
    return VaultPlaylistsTableCompanion(
      id: Value(id),
      encryptedTitle: Value(encryptedTitle),
      encryptedDescription: Value(encryptedDescription),
      encryptedCoverPath: encryptedCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedCoverPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultPlaylistEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultPlaylistEntry(
      id: serializer.fromJson<String>(json['id']),
      encryptedTitle: serializer.fromJson<Uint8List>(json['encryptedTitle']),
      encryptedDescription: serializer.fromJson<Uint8List>(
        json['encryptedDescription'],
      ),
      encryptedCoverPath: serializer.fromJson<Uint8List?>(
        json['encryptedCoverPath'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encryptedTitle': serializer.toJson<Uint8List>(encryptedTitle),
      'encryptedDescription': serializer.toJson<Uint8List>(
        encryptedDescription,
      ),
      'encryptedCoverPath': serializer.toJson<Uint8List?>(encryptedCoverPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultPlaylistEntry copyWith({
    String? id,
    Uint8List? encryptedTitle,
    Uint8List? encryptedDescription,
    Value<Uint8List?> encryptedCoverPath = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => VaultPlaylistEntry(
    id: id ?? this.id,
    encryptedTitle: encryptedTitle ?? this.encryptedTitle,
    encryptedDescription: encryptedDescription ?? this.encryptedDescription,
    encryptedCoverPath: encryptedCoverPath.present
        ? encryptedCoverPath.value
        : this.encryptedCoverPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultPlaylistEntry copyWithCompanion(VaultPlaylistsTableCompanion data) {
    return VaultPlaylistEntry(
      id: data.id.present ? data.id.value : this.id,
      encryptedTitle: data.encryptedTitle.present
          ? data.encryptedTitle.value
          : this.encryptedTitle,
      encryptedDescription: data.encryptedDescription.present
          ? data.encryptedDescription.value
          : this.encryptedDescription,
      encryptedCoverPath: data.encryptedCoverPath.present
          ? data.encryptedCoverPath.value
          : this.encryptedCoverPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultPlaylistEntry(')
          ..write('id: $id, ')
          ..write('encryptedTitle: $encryptedTitle, ')
          ..write('encryptedDescription: $encryptedDescription, ')
          ..write('encryptedCoverPath: $encryptedCoverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(encryptedTitle),
    $driftBlobEquality.hash(encryptedDescription),
    $driftBlobEquality.hash(encryptedCoverPath),
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultPlaylistEntry &&
          other.id == this.id &&
          $driftBlobEquality.equals(
            other.encryptedTitle,
            this.encryptedTitle,
          ) &&
          $driftBlobEquality.equals(
            other.encryptedDescription,
            this.encryptedDescription,
          ) &&
          $driftBlobEquality.equals(
            other.encryptedCoverPath,
            this.encryptedCoverPath,
          ) &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VaultPlaylistsTableCompanion extends UpdateCompanion<VaultPlaylistEntry> {
  final Value<String> id;
  final Value<Uint8List> encryptedTitle;
  final Value<Uint8List> encryptedDescription;
  final Value<Uint8List?> encryptedCoverPath;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultPlaylistsTableCompanion({
    this.id = const Value.absent(),
    this.encryptedTitle = const Value.absent(),
    this.encryptedDescription = const Value.absent(),
    this.encryptedCoverPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultPlaylistsTableCompanion.insert({
    required String id,
    required Uint8List encryptedTitle,
    required Uint8List encryptedDescription,
    this.encryptedCoverPath = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encryptedTitle = Value(encryptedTitle),
       encryptedDescription = Value(encryptedDescription),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VaultPlaylistEntry> custom({
    Expression<String>? id,
    Expression<Uint8List>? encryptedTitle,
    Expression<Uint8List>? encryptedDescription,
    Expression<Uint8List>? encryptedCoverPath,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encryptedTitle != null) 'encrypted_title': encryptedTitle,
      if (encryptedDescription != null)
        'encrypted_description': encryptedDescription,
      if (encryptedCoverPath != null)
        'encrypted_cover_path': encryptedCoverPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultPlaylistsTableCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? encryptedTitle,
    Value<Uint8List>? encryptedDescription,
    Value<Uint8List?>? encryptedCoverPath,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultPlaylistsTableCompanion(
      id: id ?? this.id,
      encryptedTitle: encryptedTitle ?? this.encryptedTitle,
      encryptedDescription: encryptedDescription ?? this.encryptedDescription,
      encryptedCoverPath: encryptedCoverPath ?? this.encryptedCoverPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encryptedTitle.present) {
      map['encrypted_title'] = Variable<Uint8List>(encryptedTitle.value);
    }
    if (encryptedDescription.present) {
      map['encrypted_description'] = Variable<Uint8List>(
        encryptedDescription.value,
      );
    }
    if (encryptedCoverPath.present) {
      map['encrypted_cover_path'] = Variable<Uint8List>(
        encryptedCoverPath.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultPlaylistsTableCompanion(')
          ..write('id: $id, ')
          ..write('encryptedTitle: $encryptedTitle, ')
          ..write('encryptedDescription: $encryptedDescription, ')
          ..write('encryptedCoverPath: $encryptedCoverPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultTrackRefsTableTable extends VaultTrackRefsTable
    with TableInfo<$VaultTrackRefsTableTable, VaultTrackRefEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultTrackRefsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vault_playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackIndexMeta = const VerificationMeta(
    'trackIndex',
  );
  @override
  late final GeneratedColumn<int> trackIndex = GeneratedColumn<int>(
    'track_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedTrackMetadataMeta =
      const VerificationMeta('encryptedTrackMetadata');
  @override
  late final GeneratedColumn<Uint8List> encryptedTrackMetadata =
      GeneratedColumn<Uint8List>(
        'encrypted_track_metadata',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isolatedMediaFileNameMeta =
      const VerificationMeta('isolatedMediaFileName');
  @override
  late final GeneratedColumn<String> isolatedMediaFileName =
      GeneratedColumn<String>(
        'isolated_media_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _encryptedTitleMeta = const VerificationMeta(
    'encryptedTitle',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedTitle =
      GeneratedColumn<Uint8List>(
        'encrypted_title',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedArtistMeta = const VerificationMeta(
    'encryptedArtist',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedArtist =
      GeneratedColumn<Uint8List>(
        'encrypted_artist',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedAlbumMeta = const VerificationMeta(
    'encryptedAlbum',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedAlbum =
      GeneratedColumn<Uint8List>(
        'encrypted_album',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    trackIndex,
    encryptedTrackMetadata,
    isolatedMediaFileName,
    encryptedTitle,
    encryptedArtist,
    encryptedAlbum,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_track_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultTrackRefEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_index')) {
      context.handle(
        _trackIndexMeta,
        trackIndex.isAcceptableOrUnknown(data['track_index']!, _trackIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIndexMeta);
    }
    if (data.containsKey('encrypted_track_metadata')) {
      context.handle(
        _encryptedTrackMetadataMeta,
        encryptedTrackMetadata.isAcceptableOrUnknown(
          data['encrypted_track_metadata']!,
          _encryptedTrackMetadataMeta,
        ),
      );
    }
    if (data.containsKey('isolated_media_file_name')) {
      context.handle(
        _isolatedMediaFileNameMeta,
        isolatedMediaFileName.isAcceptableOrUnknown(
          data['isolated_media_file_name']!,
          _isolatedMediaFileNameMeta,
        ),
      );
    }
    if (data.containsKey('encrypted_title')) {
      context.handle(
        _encryptedTitleMeta,
        encryptedTitle.isAcceptableOrUnknown(
          data['encrypted_title']!,
          _encryptedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedTitleMeta);
    }
    if (data.containsKey('encrypted_artist')) {
      context.handle(
        _encryptedArtistMeta,
        encryptedArtist.isAcceptableOrUnknown(
          data['encrypted_artist']!,
          _encryptedArtistMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedArtistMeta);
    }
    if (data.containsKey('encrypted_album')) {
      context.handle(
        _encryptedAlbumMeta,
        encryptedAlbum.isAcceptableOrUnknown(
          data['encrypted_album']!,
          _encryptedAlbumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedAlbumMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultTrackRefEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultTrackRefEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_index'],
      )!,
      encryptedTrackMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_track_metadata'],
      ),
      isolatedMediaFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isolated_media_file_name'],
      ),
      encryptedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_title'],
      )!,
      encryptedArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_artist'],
      )!,
      encryptedAlbum: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_album'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
    );
  }

  @override
  $VaultTrackRefsTableTable createAlias(String alias) {
    return $VaultTrackRefsTableTable(attachedDatabase, alias);
  }
}

class VaultTrackRefEntry extends DataClass
    implements Insertable<VaultTrackRefEntry> {
  /// Unique track reference identifier.
  final String id;

  /// Foreign key referencing the parent playlist with cascade delete.
  final String playlistId;

  /// Zero-based contiguous sequence index within the playlist.
  final int trackIndex;

  /// Encrypted JSON payload holding auxiliary metadata (trackUri, sourceType, addedAtEpochMs).
  final Uint8List? encryptedTrackMetadata;

  /// Sandbox relative file path for isolated local tracks (e.g. vault_media/.nomedia/<track_id>.mp3).
  final String? isolatedMediaFileName;

  /// AES-256-GCM encrypted track title.
  final Uint8List encryptedTitle;

  /// AES-256-GCM encrypted artist name.
  final Uint8List encryptedArtist;

  /// AES-256-GCM encrypted album title.
  final Uint8List encryptedAlbum;

  /// Unencrypted track duration in milliseconds.
  final int durationMs;
  const VaultTrackRefEntry({
    required this.id,
    required this.playlistId,
    required this.trackIndex,
    this.encryptedTrackMetadata,
    this.isolatedMediaFileName,
    required this.encryptedTitle,
    required this.encryptedArtist,
    required this.encryptedAlbum,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_index'] = Variable<int>(trackIndex);
    if (!nullToAbsent || encryptedTrackMetadata != null) {
      map['encrypted_track_metadata'] = Variable<Uint8List>(
        encryptedTrackMetadata,
      );
    }
    if (!nullToAbsent || isolatedMediaFileName != null) {
      map['isolated_media_file_name'] = Variable<String>(isolatedMediaFileName);
    }
    map['encrypted_title'] = Variable<Uint8List>(encryptedTitle);
    map['encrypted_artist'] = Variable<Uint8List>(encryptedArtist);
    map['encrypted_album'] = Variable<Uint8List>(encryptedAlbum);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  VaultTrackRefsTableCompanion toCompanion(bool nullToAbsent) {
    return VaultTrackRefsTableCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      trackIndex: Value(trackIndex),
      encryptedTrackMetadata: encryptedTrackMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedTrackMetadata),
      isolatedMediaFileName: isolatedMediaFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(isolatedMediaFileName),
      encryptedTitle: Value(encryptedTitle),
      encryptedArtist: Value(encryptedArtist),
      encryptedAlbum: Value(encryptedAlbum),
      durationMs: Value(durationMs),
    );
  }

  factory VaultTrackRefEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultTrackRefEntry(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackIndex: serializer.fromJson<int>(json['trackIndex']),
      encryptedTrackMetadata: serializer.fromJson<Uint8List?>(
        json['encryptedTrackMetadata'],
      ),
      isolatedMediaFileName: serializer.fromJson<String?>(
        json['isolatedMediaFileName'],
      ),
      encryptedTitle: serializer.fromJson<Uint8List>(json['encryptedTitle']),
      encryptedArtist: serializer.fromJson<Uint8List>(json['encryptedArtist']),
      encryptedAlbum: serializer.fromJson<Uint8List>(json['encryptedAlbum']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'trackIndex': serializer.toJson<int>(trackIndex),
      'encryptedTrackMetadata': serializer.toJson<Uint8List?>(
        encryptedTrackMetadata,
      ),
      'isolatedMediaFileName': serializer.toJson<String?>(
        isolatedMediaFileName,
      ),
      'encryptedTitle': serializer.toJson<Uint8List>(encryptedTitle),
      'encryptedArtist': serializer.toJson<Uint8List>(encryptedArtist),
      'encryptedAlbum': serializer.toJson<Uint8List>(encryptedAlbum),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  VaultTrackRefEntry copyWith({
    String? id,
    String? playlistId,
    int? trackIndex,
    Value<Uint8List?> encryptedTrackMetadata = const Value.absent(),
    Value<String?> isolatedMediaFileName = const Value.absent(),
    Uint8List? encryptedTitle,
    Uint8List? encryptedArtist,
    Uint8List? encryptedAlbum,
    int? durationMs,
  }) => VaultTrackRefEntry(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    trackIndex: trackIndex ?? this.trackIndex,
    encryptedTrackMetadata: encryptedTrackMetadata.present
        ? encryptedTrackMetadata.value
        : this.encryptedTrackMetadata,
    isolatedMediaFileName: isolatedMediaFileName.present
        ? isolatedMediaFileName.value
        : this.isolatedMediaFileName,
    encryptedTitle: encryptedTitle ?? this.encryptedTitle,
    encryptedArtist: encryptedArtist ?? this.encryptedArtist,
    encryptedAlbum: encryptedAlbum ?? this.encryptedAlbum,
    durationMs: durationMs ?? this.durationMs,
  );
  VaultTrackRefEntry copyWithCompanion(VaultTrackRefsTableCompanion data) {
    return VaultTrackRefEntry(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackIndex: data.trackIndex.present
          ? data.trackIndex.value
          : this.trackIndex,
      encryptedTrackMetadata: data.encryptedTrackMetadata.present
          ? data.encryptedTrackMetadata.value
          : this.encryptedTrackMetadata,
      isolatedMediaFileName: data.isolatedMediaFileName.present
          ? data.isolatedMediaFileName.value
          : this.isolatedMediaFileName,
      encryptedTitle: data.encryptedTitle.present
          ? data.encryptedTitle.value
          : this.encryptedTitle,
      encryptedArtist: data.encryptedArtist.present
          ? data.encryptedArtist.value
          : this.encryptedArtist,
      encryptedAlbum: data.encryptedAlbum.present
          ? data.encryptedAlbum.value
          : this.encryptedAlbum,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultTrackRefEntry(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('encryptedTrackMetadata: $encryptedTrackMetadata, ')
          ..write('isolatedMediaFileName: $isolatedMediaFileName, ')
          ..write('encryptedTitle: $encryptedTitle, ')
          ..write('encryptedArtist: $encryptedArtist, ')
          ..write('encryptedAlbum: $encryptedAlbum, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    trackIndex,
    $driftBlobEquality.hash(encryptedTrackMetadata),
    isolatedMediaFileName,
    $driftBlobEquality.hash(encryptedTitle),
    $driftBlobEquality.hash(encryptedArtist),
    $driftBlobEquality.hash(encryptedAlbum),
    durationMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultTrackRefEntry &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.trackIndex == this.trackIndex &&
          $driftBlobEquality.equals(
            other.encryptedTrackMetadata,
            this.encryptedTrackMetadata,
          ) &&
          other.isolatedMediaFileName == this.isolatedMediaFileName &&
          $driftBlobEquality.equals(
            other.encryptedTitle,
            this.encryptedTitle,
          ) &&
          $driftBlobEquality.equals(
            other.encryptedArtist,
            this.encryptedArtist,
          ) &&
          $driftBlobEquality.equals(
            other.encryptedAlbum,
            this.encryptedAlbum,
          ) &&
          other.durationMs == this.durationMs);
}

class VaultTrackRefsTableCompanion extends UpdateCompanion<VaultTrackRefEntry> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<int> trackIndex;
  final Value<Uint8List?> encryptedTrackMetadata;
  final Value<String?> isolatedMediaFileName;
  final Value<Uint8List> encryptedTitle;
  final Value<Uint8List> encryptedArtist;
  final Value<Uint8List> encryptedAlbum;
  final Value<int> durationMs;
  final Value<int> rowid;
  const VaultTrackRefsTableCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.encryptedTrackMetadata = const Value.absent(),
    this.isolatedMediaFileName = const Value.absent(),
    this.encryptedTitle = const Value.absent(),
    this.encryptedArtist = const Value.absent(),
    this.encryptedAlbum = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultTrackRefsTableCompanion.insert({
    required String id,
    required String playlistId,
    required int trackIndex,
    this.encryptedTrackMetadata = const Value.absent(),
    this.isolatedMediaFileName = const Value.absent(),
    required Uint8List encryptedTitle,
    required Uint8List encryptedArtist,
    required Uint8List encryptedAlbum,
    required int durationMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       playlistId = Value(playlistId),
       trackIndex = Value(trackIndex),
       encryptedTitle = Value(encryptedTitle),
       encryptedArtist = Value(encryptedArtist),
       encryptedAlbum = Value(encryptedAlbum),
       durationMs = Value(durationMs);
  static Insertable<VaultTrackRefEntry> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<int>? trackIndex,
    Expression<Uint8List>? encryptedTrackMetadata,
    Expression<String>? isolatedMediaFileName,
    Expression<Uint8List>? encryptedTitle,
    Expression<Uint8List>? encryptedArtist,
    Expression<Uint8List>? encryptedAlbum,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackIndex != null) 'track_index': trackIndex,
      if (encryptedTrackMetadata != null)
        'encrypted_track_metadata': encryptedTrackMetadata,
      if (isolatedMediaFileName != null)
        'isolated_media_file_name': isolatedMediaFileName,
      if (encryptedTitle != null) 'encrypted_title': encryptedTitle,
      if (encryptedArtist != null) 'encrypted_artist': encryptedArtist,
      if (encryptedAlbum != null) 'encrypted_album': encryptedAlbum,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultTrackRefsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? playlistId,
    Value<int>? trackIndex,
    Value<Uint8List?>? encryptedTrackMetadata,
    Value<String?>? isolatedMediaFileName,
    Value<Uint8List>? encryptedTitle,
    Value<Uint8List>? encryptedArtist,
    Value<Uint8List>? encryptedAlbum,
    Value<int>? durationMs,
    Value<int>? rowid,
  }) {
    return VaultTrackRefsTableCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      trackIndex: trackIndex ?? this.trackIndex,
      encryptedTrackMetadata:
          encryptedTrackMetadata ?? this.encryptedTrackMetadata,
      isolatedMediaFileName:
          isolatedMediaFileName ?? this.isolatedMediaFileName,
      encryptedTitle: encryptedTitle ?? this.encryptedTitle,
      encryptedArtist: encryptedArtist ?? this.encryptedArtist,
      encryptedAlbum: encryptedAlbum ?? this.encryptedAlbum,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackIndex.present) {
      map['track_index'] = Variable<int>(trackIndex.value);
    }
    if (encryptedTrackMetadata.present) {
      map['encrypted_track_metadata'] = Variable<Uint8List>(
        encryptedTrackMetadata.value,
      );
    }
    if (isolatedMediaFileName.present) {
      map['isolated_media_file_name'] = Variable<String>(
        isolatedMediaFileName.value,
      );
    }
    if (encryptedTitle.present) {
      map['encrypted_title'] = Variable<Uint8List>(encryptedTitle.value);
    }
    if (encryptedArtist.present) {
      map['encrypted_artist'] = Variable<Uint8List>(encryptedArtist.value);
    }
    if (encryptedAlbum.present) {
      map['encrypted_album'] = Variable<Uint8List>(encryptedAlbum.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultTrackRefsTableCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('encryptedTrackMetadata: $encryptedTrackMetadata, ')
          ..write('isolatedMediaFileName: $isolatedMediaFileName, ')
          ..write('encryptedTitle: $encryptedTitle, ')
          ..write('encryptedArtist: $encryptedArtist, ')
          ..write('encryptedAlbum: $encryptedAlbum, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultConfigTableTable extends VaultConfigTable
    with TableInfo<$VaultConfigTableTable, VaultConfigEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultConfigTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedPayload =
      GeneratedColumn<Uint8List>(
        'encrypted_payload',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, encryptedPayload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultConfigEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
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
  VaultConfigEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultConfigEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultConfigTableTable createAlias(String alias) {
    return $VaultConfigTableTable(attachedDatabase, alias);
  }
}

class VaultConfigEntry extends DataClass
    implements Insertable<VaultConfigEntry> {
  /// Singleton identifier (canonical key: 'vault_config').
  final String id;

  /// AES-256-GCM encrypted JSON payload of all policy enum IDs and decoy persona fields.
  final Uint8List encryptedPayload;

  /// Last modification epoch timestamp in milliseconds.
  final int updatedAt;
  const VaultConfigEntry({
    required this.id,
    required this.encryptedPayload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultConfigTableCompanion toCompanion(bool nullToAbsent) {
    return VaultConfigTableCompanion(
      id: Value(id),
      encryptedPayload: Value(encryptedPayload),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultConfigEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultConfigEntry(
      id: serializer.fromJson<String>(json['id']),
      encryptedPayload: serializer.fromJson<Uint8List>(
        json['encryptedPayload'],
      ),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encryptedPayload': serializer.toJson<Uint8List>(encryptedPayload),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultConfigEntry copyWith({
    String? id,
    Uint8List? encryptedPayload,
    int? updatedAt,
  }) => VaultConfigEntry(
    id: id ?? this.id,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultConfigEntry copyWithCompanion(VaultConfigTableCompanion data) {
    return VaultConfigEntry(
      id: data.id.present ? data.id.value : this.id,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultConfigEntry(')
          ..write('id: $id, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, $driftBlobEquality.hash(encryptedPayload), updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultConfigEntry &&
          other.id == this.id &&
          $driftBlobEquality.equals(
            other.encryptedPayload,
            this.encryptedPayload,
          ) &&
          other.updatedAt == this.updatedAt);
}

class VaultConfigTableCompanion extends UpdateCompanion<VaultConfigEntry> {
  final Value<String> id;
  final Value<Uint8List> encryptedPayload;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultConfigTableCompanion({
    this.id = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultConfigTableCompanion.insert({
    required String id,
    required Uint8List encryptedPayload,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encryptedPayload = Value(encryptedPayload),
       updatedAt = Value(updatedAt);
  static Insertable<VaultConfigEntry> custom({
    Expression<String>? id,
    Expression<Uint8List>? encryptedPayload,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultConfigTableCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? encryptedPayload,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultConfigTableCompanion(
      id: id ?? this.id,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultConfigTableCompanion(')
          ..write('id: $id, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultGestureTemplatesTableTable extends VaultGestureTemplatesTable
    with
        TableInfo<$VaultGestureTemplatesTableTable, VaultGestureTemplateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultGestureTemplatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPoints64Meta = const VerificationMeta(
    'encryptedPoints64',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedPoints64 =
      GeneratedColumn<Uint8List>(
        'encrypted_points64',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedRubine7dMeta = const VerificationMeta(
    'encryptedRubine7d',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedRubine7d =
      GeneratedColumn<Uint8List>(
        'encrypted_rubine7d',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    encryptedPoints64,
    encryptedRubine7d,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_gesture_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultGestureTemplateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encrypted_points64')) {
      context.handle(
        _encryptedPoints64Meta,
        encryptedPoints64.isAcceptableOrUnknown(
          data['encrypted_points64']!,
          _encryptedPoints64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPoints64Meta);
    }
    if (data.containsKey('encrypted_rubine7d')) {
      context.handle(
        _encryptedRubine7dMeta,
        encryptedRubine7d.isAcceptableOrUnknown(
          data['encrypted_rubine7d']!,
          _encryptedRubine7dMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedRubine7dMeta);
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
  VaultGestureTemplateEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultGestureTemplateEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encryptedPoints64: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_points64'],
      )!,
      encryptedRubine7d: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_rubine7d'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultGestureTemplatesTableTable createAlias(String alias) {
    return $VaultGestureTemplatesTableTable(attachedDatabase, alias);
  }
}

class VaultGestureTemplateEntry extends DataClass
    implements Insertable<VaultGestureTemplateEntry> {
  /// Singleton identifier (canonical key: 'master_gesture').
  final String id;

  /// AES-256-GCM encrypted JSON array of exactly 64 normalized coordinates.
  final Uint8List encryptedPoints64;

  /// AES-256-GCM encrypted JSON array of exactly 7 normalized Rubine features.
  final Uint8List encryptedRubine7d;

  /// Synthesis epoch timestamp in milliseconds.
  final int updatedAt;
  const VaultGestureTemplateEntry({
    required this.id,
    required this.encryptedPoints64,
    required this.encryptedRubine7d,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encrypted_points64'] = Variable<Uint8List>(encryptedPoints64);
    map['encrypted_rubine7d'] = Variable<Uint8List>(encryptedRubine7d);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultGestureTemplatesTableCompanion toCompanion(bool nullToAbsent) {
    return VaultGestureTemplatesTableCompanion(
      id: Value(id),
      encryptedPoints64: Value(encryptedPoints64),
      encryptedRubine7d: Value(encryptedRubine7d),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultGestureTemplateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultGestureTemplateEntry(
      id: serializer.fromJson<String>(json['id']),
      encryptedPoints64: serializer.fromJson<Uint8List>(
        json['encryptedPoints64'],
      ),
      encryptedRubine7d: serializer.fromJson<Uint8List>(
        json['encryptedRubine7d'],
      ),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encryptedPoints64': serializer.toJson<Uint8List>(encryptedPoints64),
      'encryptedRubine7d': serializer.toJson<Uint8List>(encryptedRubine7d),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultGestureTemplateEntry copyWith({
    String? id,
    Uint8List? encryptedPoints64,
    Uint8List? encryptedRubine7d,
    int? updatedAt,
  }) => VaultGestureTemplateEntry(
    id: id ?? this.id,
    encryptedPoints64: encryptedPoints64 ?? this.encryptedPoints64,
    encryptedRubine7d: encryptedRubine7d ?? this.encryptedRubine7d,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultGestureTemplateEntry copyWithCompanion(
    VaultGestureTemplatesTableCompanion data,
  ) {
    return VaultGestureTemplateEntry(
      id: data.id.present ? data.id.value : this.id,
      encryptedPoints64: data.encryptedPoints64.present
          ? data.encryptedPoints64.value
          : this.encryptedPoints64,
      encryptedRubine7d: data.encryptedRubine7d.present
          ? data.encryptedRubine7d.value
          : this.encryptedRubine7d,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultGestureTemplateEntry(')
          ..write('id: $id, ')
          ..write('encryptedPoints64: $encryptedPoints64, ')
          ..write('encryptedRubine7d: $encryptedRubine7d, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(encryptedPoints64),
    $driftBlobEquality.hash(encryptedRubine7d),
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultGestureTemplateEntry &&
          other.id == this.id &&
          $driftBlobEquality.equals(
            other.encryptedPoints64,
            this.encryptedPoints64,
          ) &&
          $driftBlobEquality.equals(
            other.encryptedRubine7d,
            this.encryptedRubine7d,
          ) &&
          other.updatedAt == this.updatedAt);
}

class VaultGestureTemplatesTableCompanion
    extends UpdateCompanion<VaultGestureTemplateEntry> {
  final Value<String> id;
  final Value<Uint8List> encryptedPoints64;
  final Value<Uint8List> encryptedRubine7d;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultGestureTemplatesTableCompanion({
    this.id = const Value.absent(),
    this.encryptedPoints64 = const Value.absent(),
    this.encryptedRubine7d = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultGestureTemplatesTableCompanion.insert({
    required String id,
    required Uint8List encryptedPoints64,
    required Uint8List encryptedRubine7d,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encryptedPoints64 = Value(encryptedPoints64),
       encryptedRubine7d = Value(encryptedRubine7d),
       updatedAt = Value(updatedAt);
  static Insertable<VaultGestureTemplateEntry> custom({
    Expression<String>? id,
    Expression<Uint8List>? encryptedPoints64,
    Expression<Uint8List>? encryptedRubine7d,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encryptedPoints64 != null) 'encrypted_points64': encryptedPoints64,
      if (encryptedRubine7d != null) 'encrypted_rubine7d': encryptedRubine7d,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultGestureTemplatesTableCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? encryptedPoints64,
    Value<Uint8List>? encryptedRubine7d,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultGestureTemplatesTableCompanion(
      id: id ?? this.id,
      encryptedPoints64: encryptedPoints64 ?? this.encryptedPoints64,
      encryptedRubine7d: encryptedRubine7d ?? this.encryptedRubine7d,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encryptedPoints64.present) {
      map['encrypted_points64'] = Variable<Uint8List>(encryptedPoints64.value);
    }
    if (encryptedRubine7d.present) {
      map['encrypted_rubine7d'] = Variable<Uint8List>(encryptedRubine7d.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultGestureTemplatesTableCompanion(')
          ..write('id: $id, ')
          ..write('encryptedPoints64: $encryptedPoints64, ')
          ..write('encryptedRubine7d: $encryptedRubine7d, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultLockoutDeadlineTableTable extends VaultLockoutDeadlineTable
    with TableInfo<$VaultLockoutDeadlineTableTable, VaultLockoutDeadlineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultLockoutDeadlineTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMonotonicMsMeta =
      const VerificationMeta('deadlineMonotonicMs');
  @override
  late final GeneratedColumn<int> deadlineMonotonicMs = GeneratedColumn<int>(
    'deadline_monotonic_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deadlineMonotonicMs,
    failedAttempts,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_lockout_deadline';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultLockoutDeadlineEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deadline_monotonic_ms')) {
      context.handle(
        _deadlineMonotonicMsMeta,
        deadlineMonotonicMs.isAcceptableOrUnknown(
          data['deadline_monotonic_ms']!,
          _deadlineMonotonicMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deadlineMonotonicMsMeta);
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_failedAttemptsMeta);
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
  VaultLockoutDeadlineEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultLockoutDeadlineEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deadlineMonotonicMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deadline_monotonic_ms'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultLockoutDeadlineTableTable createAlias(String alias) {
    return $VaultLockoutDeadlineTableTable(attachedDatabase, alias);
  }
}

class VaultLockoutDeadlineEntry extends DataClass
    implements Insertable<VaultLockoutDeadlineEntry> {
  /// Singleton identifier (canonical key: 'lockout_deadline').
  final String id;

  /// Monotonic clock deadline timestamp in milliseconds.
  final int deadlineMonotonicMs;

  /// Consecutive failed PIN attempts recorded.
  final int failedAttempts;

  /// Epoch timestamp in milliseconds when this record was persisted or updated.
  final int updatedAt;
  const VaultLockoutDeadlineEntry({
    required this.id,
    required this.deadlineMonotonicMs,
    required this.failedAttempts,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deadline_monotonic_ms'] = Variable<int>(deadlineMonotonicMs);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultLockoutDeadlineTableCompanion toCompanion(bool nullToAbsent) {
    return VaultLockoutDeadlineTableCompanion(
      id: Value(id),
      deadlineMonotonicMs: Value(deadlineMonotonicMs),
      failedAttempts: Value(failedAttempts),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultLockoutDeadlineEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultLockoutDeadlineEntry(
      id: serializer.fromJson<String>(json['id']),
      deadlineMonotonicMs: serializer.fromJson<int>(
        json['deadlineMonotonicMs'],
      ),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deadlineMonotonicMs': serializer.toJson<int>(deadlineMonotonicMs),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultLockoutDeadlineEntry copyWith({
    String? id,
    int? deadlineMonotonicMs,
    int? failedAttempts,
    int? updatedAt,
  }) => VaultLockoutDeadlineEntry(
    id: id ?? this.id,
    deadlineMonotonicMs: deadlineMonotonicMs ?? this.deadlineMonotonicMs,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultLockoutDeadlineEntry copyWithCompanion(
    VaultLockoutDeadlineTableCompanion data,
  ) {
    return VaultLockoutDeadlineEntry(
      id: data.id.present ? data.id.value : this.id,
      deadlineMonotonicMs: data.deadlineMonotonicMs.present
          ? data.deadlineMonotonicMs.value
          : this.deadlineMonotonicMs,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultLockoutDeadlineEntry(')
          ..write('id: $id, ')
          ..write('deadlineMonotonicMs: $deadlineMonotonicMs, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deadlineMonotonicMs, failedAttempts, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultLockoutDeadlineEntry &&
          other.id == this.id &&
          other.deadlineMonotonicMs == this.deadlineMonotonicMs &&
          other.failedAttempts == this.failedAttempts &&
          other.updatedAt == this.updatedAt);
}

class VaultLockoutDeadlineTableCompanion
    extends UpdateCompanion<VaultLockoutDeadlineEntry> {
  final Value<String> id;
  final Value<int> deadlineMonotonicMs;
  final Value<int> failedAttempts;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultLockoutDeadlineTableCompanion({
    this.id = const Value.absent(),
    this.deadlineMonotonicMs = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultLockoutDeadlineTableCompanion.insert({
    required String id,
    required int deadlineMonotonicMs,
    required int failedAttempts,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deadlineMonotonicMs = Value(deadlineMonotonicMs),
       failedAttempts = Value(failedAttempts),
       updatedAt = Value(updatedAt);
  static Insertable<VaultLockoutDeadlineEntry> custom({
    Expression<String>? id,
    Expression<int>? deadlineMonotonicMs,
    Expression<int>? failedAttempts,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deadlineMonotonicMs != null)
        'deadline_monotonic_ms': deadlineMonotonicMs,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultLockoutDeadlineTableCompanion copyWith({
    Value<String>? id,
    Value<int>? deadlineMonotonicMs,
    Value<int>? failedAttempts,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultLockoutDeadlineTableCompanion(
      id: id ?? this.id,
      deadlineMonotonicMs: deadlineMonotonicMs ?? this.deadlineMonotonicMs,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deadlineMonotonicMs.present) {
      map['deadline_monotonic_ms'] = Variable<int>(deadlineMonotonicMs.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultLockoutDeadlineTableCompanion(')
          ..write('id: $id, ')
          ..write('deadlineMonotonicMs: $deadlineMonotonicMs, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VaultDatabase extends GeneratedDatabase {
  _$VaultDatabase(QueryExecutor e) : super(e);
  $VaultDatabaseManager get managers => $VaultDatabaseManager(this);
  late final $VaultPlaylistsTableTable vaultPlaylistsTable =
      $VaultPlaylistsTableTable(this);
  late final $VaultTrackRefsTableTable vaultTrackRefsTable =
      $VaultTrackRefsTableTable(this);
  late final $VaultConfigTableTable vaultConfigTable = $VaultConfigTableTable(
    this,
  );
  late final $VaultGestureTemplatesTableTable vaultGestureTemplatesTable =
      $VaultGestureTemplatesTableTable(this);
  late final $VaultLockoutDeadlineTableTable vaultLockoutDeadlineTable =
      $VaultLockoutDeadlineTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vaultPlaylistsTable,
    vaultTrackRefsTable,
    vaultConfigTable,
    vaultGestureTemplatesTable,
    vaultLockoutDeadlineTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vault_playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vault_track_refs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$VaultPlaylistsTableTableCreateCompanionBuilder =
    VaultPlaylistsTableCompanion Function({
      required String id,
      required Uint8List encryptedTitle,
      required Uint8List encryptedDescription,
      Value<Uint8List?> encryptedCoverPath,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultPlaylistsTableTableUpdateCompanionBuilder =
    VaultPlaylistsTableCompanion Function({
      Value<String> id,
      Value<Uint8List> encryptedTitle,
      Value<Uint8List> encryptedDescription,
      Value<Uint8List?> encryptedCoverPath,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$VaultPlaylistsTableTableReferences
    extends
        BaseReferences<
          _$VaultDatabase,
          $VaultPlaylistsTableTable,
          VaultPlaylistEntry
        > {
  $$VaultPlaylistsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $VaultTrackRefsTableTable,
    List<VaultTrackRefEntry>
  >
  _vaultTrackRefsTableRefsTable(_$VaultDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vaultTrackRefsTable,
        aliasName: 'vault_playlists__id__vault_track_refs__playlist_id',
      );

  $$VaultTrackRefsTableTableProcessedTableManager get vaultTrackRefsTableRefs {
    final manager = $$VaultTrackRefsTableTableTableManager(
      $_db,
      $_db.vaultTrackRefsTable,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vaultTrackRefsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VaultPlaylistsTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultPlaylistsTableTable> {
  $$VaultPlaylistsTableTableFilterComposer({
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

  ColumnFilters<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedDescription => $composableBuilder(
    column: $table.encryptedDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedCoverPath => $composableBuilder(
    column: $table.encryptedCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> vaultTrackRefsTableRefs(
    Expression<bool> Function($$VaultTrackRefsTableTableFilterComposer f) f,
  ) {
    final $$VaultTrackRefsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vaultTrackRefsTable,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultTrackRefsTableTableFilterComposer(
            $db: $db,
            $table: $db.vaultTrackRefsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VaultPlaylistsTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultPlaylistsTableTable> {
  $$VaultPlaylistsTableTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedDescription => $composableBuilder(
    column: $table.encryptedDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedCoverPath => $composableBuilder(
    column: $table.encryptedCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultPlaylistsTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultPlaylistsTableTable> {
  $$VaultPlaylistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedDescription => $composableBuilder(
    column: $table.encryptedDescription,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedCoverPath => $composableBuilder(
    column: $table.encryptedCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> vaultTrackRefsTableRefs<T extends Object>(
    Expression<T> Function($$VaultTrackRefsTableTableAnnotationComposer a) f,
  ) {
    final $$VaultTrackRefsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vaultTrackRefsTable,
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VaultTrackRefsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.vaultTrackRefsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VaultPlaylistsTableTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultPlaylistsTableTable,
          VaultPlaylistEntry,
          $$VaultPlaylistsTableTableFilterComposer,
          $$VaultPlaylistsTableTableOrderingComposer,
          $$VaultPlaylistsTableTableAnnotationComposer,
          $$VaultPlaylistsTableTableCreateCompanionBuilder,
          $$VaultPlaylistsTableTableUpdateCompanionBuilder,
          (VaultPlaylistEntry, $$VaultPlaylistsTableTableReferences),
          VaultPlaylistEntry,
          PrefetchHooks Function({bool vaultTrackRefsTableRefs})
        > {
  $$VaultPlaylistsTableTableTableManager(
    _$VaultDatabase db,
    $VaultPlaylistsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultPlaylistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultPlaylistsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaultPlaylistsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> encryptedTitle = const Value.absent(),
                Value<Uint8List> encryptedDescription = const Value.absent(),
                Value<Uint8List?> encryptedCoverPath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultPlaylistsTableCompanion(
                id: id,
                encryptedTitle: encryptedTitle,
                encryptedDescription: encryptedDescription,
                encryptedCoverPath: encryptedCoverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List encryptedTitle,
                required Uint8List encryptedDescription,
                Value<Uint8List?> encryptedCoverPath = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultPlaylistsTableCompanion.insert(
                id: id,
                encryptedTitle: encryptedTitle,
                encryptedDescription: encryptedDescription,
                encryptedCoverPath: encryptedCoverPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultPlaylistsTableTable, VaultPlaylistEntry>(
                    table,
                  ),
                  $$VaultPlaylistsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vaultTrackRefsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vaultTrackRefsTableRefs) db.vaultTrackRefsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vaultTrackRefsTableRefs)
                    await $_getPrefetchedData<
                      VaultPlaylistEntry,
                      $VaultPlaylistsTableTable,
                      VaultTrackRefEntry
                    >(
                      currentTable: table,
                      referencedTable: $$VaultPlaylistsTableTableReferences
                          ._vaultTrackRefsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VaultPlaylistsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).vaultTrackRefsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VaultPlaylistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultPlaylistsTableTable,
      VaultPlaylistEntry,
      $$VaultPlaylistsTableTableFilterComposer,
      $$VaultPlaylistsTableTableOrderingComposer,
      $$VaultPlaylistsTableTableAnnotationComposer,
      $$VaultPlaylistsTableTableCreateCompanionBuilder,
      $$VaultPlaylistsTableTableUpdateCompanionBuilder,
      (VaultPlaylistEntry, $$VaultPlaylistsTableTableReferences),
      VaultPlaylistEntry,
      PrefetchHooks Function({bool vaultTrackRefsTableRefs})
    >;
typedef $$VaultTrackRefsTableTableCreateCompanionBuilder =
    VaultTrackRefsTableCompanion Function({
      required String id,
      required String playlistId,
      required int trackIndex,
      Value<Uint8List?> encryptedTrackMetadata,
      Value<String?> isolatedMediaFileName,
      required Uint8List encryptedTitle,
      required Uint8List encryptedArtist,
      required Uint8List encryptedAlbum,
      required int durationMs,
      Value<int> rowid,
    });
typedef $$VaultTrackRefsTableTableUpdateCompanionBuilder =
    VaultTrackRefsTableCompanion Function({
      Value<String> id,
      Value<String> playlistId,
      Value<int> trackIndex,
      Value<Uint8List?> encryptedTrackMetadata,
      Value<String?> isolatedMediaFileName,
      Value<Uint8List> encryptedTitle,
      Value<Uint8List> encryptedArtist,
      Value<Uint8List> encryptedAlbum,
      Value<int> durationMs,
      Value<int> rowid,
    });

final class $$VaultTrackRefsTableTableReferences
    extends
        BaseReferences<
          _$VaultDatabase,
          $VaultTrackRefsTableTable,
          VaultTrackRefEntry
        > {
  $$VaultTrackRefsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VaultPlaylistsTableTable _playlistIdTable(_$VaultDatabase db) => db
      .vaultPlaylistsTable
      .createAlias('vault_track_refs__playlist_id__vault_playlists__id');

  $$VaultPlaylistsTableTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$VaultPlaylistsTableTableTableManager(
      $_db,
      $_db.vaultPlaylistsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VaultTrackRefsTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultTrackRefsTableTable> {
  $$VaultTrackRefsTableTableFilterComposer({
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

  ColumnFilters<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedTrackMetadata => $composableBuilder(
    column: $table.encryptedTrackMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isolatedMediaFileName => $composableBuilder(
    column: $table.isolatedMediaFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedArtist => $composableBuilder(
    column: $table.encryptedArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedAlbum => $composableBuilder(
    column: $table.encryptedAlbum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  $$VaultPlaylistsTableTableFilterComposer get playlistId {
    final $$VaultPlaylistsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.vaultPlaylistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultPlaylistsTableTableFilterComposer(
            $db: $db,
            $table: $db.vaultPlaylistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaultTrackRefsTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultTrackRefsTableTable> {
  $$VaultTrackRefsTableTableOrderingComposer({
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

  ColumnOrderings<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedTrackMetadata => $composableBuilder(
    column: $table.encryptedTrackMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isolatedMediaFileName => $composableBuilder(
    column: $table.isolatedMediaFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedArtist => $composableBuilder(
    column: $table.encryptedArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedAlbum => $composableBuilder(
    column: $table.encryptedAlbum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$VaultPlaylistsTableTableOrderingComposer get playlistId {
    final $$VaultPlaylistsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.playlistId,
          referencedTable: $db.vaultPlaylistsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VaultPlaylistsTableTableOrderingComposer(
                $db: $db,
                $table: $db.vaultPlaylistsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$VaultTrackRefsTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultTrackRefsTableTable> {
  $$VaultTrackRefsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedTrackMetadata => $composableBuilder(
    column: $table.encryptedTrackMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isolatedMediaFileName => $composableBuilder(
    column: $table.isolatedMediaFileName,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedTitle => $composableBuilder(
    column: $table.encryptedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedArtist => $composableBuilder(
    column: $table.encryptedArtist,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedAlbum => $composableBuilder(
    column: $table.encryptedAlbum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  $$VaultPlaylistsTableTableAnnotationComposer get playlistId {
    final $$VaultPlaylistsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.playlistId,
          referencedTable: $db.vaultPlaylistsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VaultPlaylistsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.vaultPlaylistsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$VaultTrackRefsTableTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultTrackRefsTableTable,
          VaultTrackRefEntry,
          $$VaultTrackRefsTableTableFilterComposer,
          $$VaultTrackRefsTableTableOrderingComposer,
          $$VaultTrackRefsTableTableAnnotationComposer,
          $$VaultTrackRefsTableTableCreateCompanionBuilder,
          $$VaultTrackRefsTableTableUpdateCompanionBuilder,
          (VaultTrackRefEntry, $$VaultTrackRefsTableTableReferences),
          VaultTrackRefEntry,
          PrefetchHooks Function({bool playlistId})
        > {
  $$VaultTrackRefsTableTableTableManager(
    _$VaultDatabase db,
    $VaultTrackRefsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultTrackRefsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultTrackRefsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaultTrackRefsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<int> trackIndex = const Value.absent(),
                Value<Uint8List?> encryptedTrackMetadata = const Value.absent(),
                Value<String?> isolatedMediaFileName = const Value.absent(),
                Value<Uint8List> encryptedTitle = const Value.absent(),
                Value<Uint8List> encryptedArtist = const Value.absent(),
                Value<Uint8List> encryptedAlbum = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultTrackRefsTableCompanion(
                id: id,
                playlistId: playlistId,
                trackIndex: trackIndex,
                encryptedTrackMetadata: encryptedTrackMetadata,
                isolatedMediaFileName: isolatedMediaFileName,
                encryptedTitle: encryptedTitle,
                encryptedArtist: encryptedArtist,
                encryptedAlbum: encryptedAlbum,
                durationMs: durationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String playlistId,
                required int trackIndex,
                Value<Uint8List?> encryptedTrackMetadata = const Value.absent(),
                Value<String?> isolatedMediaFileName = const Value.absent(),
                required Uint8List encryptedTitle,
                required Uint8List encryptedArtist,
                required Uint8List encryptedAlbum,
                required int durationMs,
                Value<int> rowid = const Value.absent(),
              }) => VaultTrackRefsTableCompanion.insert(
                id: id,
                playlistId: playlistId,
                trackIndex: trackIndex,
                encryptedTrackMetadata: encryptedTrackMetadata,
                isolatedMediaFileName: isolatedMediaFileName,
                encryptedTitle: encryptedTitle,
                encryptedArtist: encryptedArtist,
                encryptedAlbum: encryptedAlbum,
                durationMs: durationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultTrackRefsTableTable, VaultTrackRefEntry>(
                    table,
                  ),
                  $$VaultTrackRefsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
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
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$VaultTrackRefsTableTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$VaultTrackRefsTableTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$VaultTrackRefsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultTrackRefsTableTable,
      VaultTrackRefEntry,
      $$VaultTrackRefsTableTableFilterComposer,
      $$VaultTrackRefsTableTableOrderingComposer,
      $$VaultTrackRefsTableTableAnnotationComposer,
      $$VaultTrackRefsTableTableCreateCompanionBuilder,
      $$VaultTrackRefsTableTableUpdateCompanionBuilder,
      (VaultTrackRefEntry, $$VaultTrackRefsTableTableReferences),
      VaultTrackRefEntry,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$VaultConfigTableTableCreateCompanionBuilder =
    VaultConfigTableCompanion Function({
      required String id,
      required Uint8List encryptedPayload,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultConfigTableTableUpdateCompanionBuilder =
    VaultConfigTableCompanion Function({
      Value<String> id,
      Value<Uint8List> encryptedPayload,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$VaultConfigTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultConfigTableTable> {
  $$VaultConfigTableTableFilterComposer({
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

  ColumnFilters<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultConfigTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultConfigTableTable> {
  $$VaultConfigTableTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultConfigTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultConfigTableTable> {
  $$VaultConfigTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VaultConfigTableTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultConfigTableTable,
          VaultConfigEntry,
          $$VaultConfigTableTableFilterComposer,
          $$VaultConfigTableTableOrderingComposer,
          $$VaultConfigTableTableAnnotationComposer,
          $$VaultConfigTableTableCreateCompanionBuilder,
          $$VaultConfigTableTableUpdateCompanionBuilder,
          (
            VaultConfigEntry,
            BaseReferences<
              _$VaultDatabase,
              $VaultConfigTableTable,
              VaultConfigEntry
            >,
          ),
          VaultConfigEntry,
          PrefetchHooks Function()
        > {
  $$VaultConfigTableTableTableManager(
    _$VaultDatabase db,
    $VaultConfigTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultConfigTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultConfigTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultConfigTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> encryptedPayload = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultConfigTableCompanion(
                id: id,
                encryptedPayload: encryptedPayload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List encryptedPayload,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultConfigTableCompanion.insert(
                id: id,
                encryptedPayload: encryptedPayload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VaultConfigTableTable, VaultConfigEntry>(table),
                  BaseReferences<
                    _$VaultDatabase,
                    $VaultConfigTableTable,
                    VaultConfigEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultConfigTableTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultConfigTableTable,
      VaultConfigEntry,
      $$VaultConfigTableTableFilterComposer,
      $$VaultConfigTableTableOrderingComposer,
      $$VaultConfigTableTableAnnotationComposer,
      $$VaultConfigTableTableCreateCompanionBuilder,
      $$VaultConfigTableTableUpdateCompanionBuilder,
      (
        VaultConfigEntry,
        BaseReferences<
          _$VaultDatabase,
          $VaultConfigTableTable,
          VaultConfigEntry
        >,
      ),
      VaultConfigEntry,
      PrefetchHooks Function()
    >;
typedef $$VaultGestureTemplatesTableTableCreateCompanionBuilder =
    VaultGestureTemplatesTableCompanion Function({
      required String id,
      required Uint8List encryptedPoints64,
      required Uint8List encryptedRubine7d,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultGestureTemplatesTableTableUpdateCompanionBuilder =
    VaultGestureTemplatesTableCompanion Function({
      Value<String> id,
      Value<Uint8List> encryptedPoints64,
      Value<Uint8List> encryptedRubine7d,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$VaultGestureTemplatesTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultGestureTemplatesTableTable> {
  $$VaultGestureTemplatesTableTableFilterComposer({
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

  ColumnFilters<Uint8List> get encryptedPoints64 => $composableBuilder(
    column: $table.encryptedPoints64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedRubine7d => $composableBuilder(
    column: $table.encryptedRubine7d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultGestureTemplatesTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultGestureTemplatesTableTable> {
  $$VaultGestureTemplatesTableTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get encryptedPoints64 => $composableBuilder(
    column: $table.encryptedPoints64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedRubine7d => $composableBuilder(
    column: $table.encryptedRubine7d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultGestureTemplatesTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultGestureTemplatesTableTable> {
  $$VaultGestureTemplatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPoints64 => $composableBuilder(
    column: $table.encryptedPoints64,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedRubine7d => $composableBuilder(
    column: $table.encryptedRubine7d,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VaultGestureTemplatesTableTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultGestureTemplatesTableTable,
          VaultGestureTemplateEntry,
          $$VaultGestureTemplatesTableTableFilterComposer,
          $$VaultGestureTemplatesTableTableOrderingComposer,
          $$VaultGestureTemplatesTableTableAnnotationComposer,
          $$VaultGestureTemplatesTableTableCreateCompanionBuilder,
          $$VaultGestureTemplatesTableTableUpdateCompanionBuilder,
          (
            VaultGestureTemplateEntry,
            BaseReferences<
              _$VaultDatabase,
              $VaultGestureTemplatesTableTable,
              VaultGestureTemplateEntry
            >,
          ),
          VaultGestureTemplateEntry,
          PrefetchHooks Function()
        > {
  $$VaultGestureTemplatesTableTableTableManager(
    _$VaultDatabase db,
    $VaultGestureTemplatesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultGestureTemplatesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$VaultGestureTemplatesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaultGestureTemplatesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> encryptedPoints64 = const Value.absent(),
                Value<Uint8List> encryptedRubine7d = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultGestureTemplatesTableCompanion(
                id: id,
                encryptedPoints64: encryptedPoints64,
                encryptedRubine7d: encryptedRubine7d,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List encryptedPoints64,
                required Uint8List encryptedRubine7d,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultGestureTemplatesTableCompanion.insert(
                id: id,
                encryptedPoints64: encryptedPoints64,
                encryptedRubine7d: encryptedRubine7d,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $VaultGestureTemplatesTableTable,
                    VaultGestureTemplateEntry
                  >(table),
                  BaseReferences<
                    _$VaultDatabase,
                    $VaultGestureTemplatesTableTable,
                    VaultGestureTemplateEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultGestureTemplatesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultGestureTemplatesTableTable,
      VaultGestureTemplateEntry,
      $$VaultGestureTemplatesTableTableFilterComposer,
      $$VaultGestureTemplatesTableTableOrderingComposer,
      $$VaultGestureTemplatesTableTableAnnotationComposer,
      $$VaultGestureTemplatesTableTableCreateCompanionBuilder,
      $$VaultGestureTemplatesTableTableUpdateCompanionBuilder,
      (
        VaultGestureTemplateEntry,
        BaseReferences<
          _$VaultDatabase,
          $VaultGestureTemplatesTableTable,
          VaultGestureTemplateEntry
        >,
      ),
      VaultGestureTemplateEntry,
      PrefetchHooks Function()
    >;
typedef $$VaultLockoutDeadlineTableTableCreateCompanionBuilder =
    VaultLockoutDeadlineTableCompanion Function({
      required String id,
      required int deadlineMonotonicMs,
      required int failedAttempts,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultLockoutDeadlineTableTableUpdateCompanionBuilder =
    VaultLockoutDeadlineTableCompanion Function({
      Value<String> id,
      Value<int> deadlineMonotonicMs,
      Value<int> failedAttempts,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$VaultLockoutDeadlineTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultLockoutDeadlineTableTable> {
  $$VaultLockoutDeadlineTableTableFilterComposer({
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

  ColumnFilters<int> get deadlineMonotonicMs => $composableBuilder(
    column: $table.deadlineMonotonicMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultLockoutDeadlineTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultLockoutDeadlineTableTable> {
  $$VaultLockoutDeadlineTableTableOrderingComposer({
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

  ColumnOrderings<int> get deadlineMonotonicMs => $composableBuilder(
    column: $table.deadlineMonotonicMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultLockoutDeadlineTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultLockoutDeadlineTableTable> {
  $$VaultLockoutDeadlineTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get deadlineMonotonicMs => $composableBuilder(
    column: $table.deadlineMonotonicMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VaultLockoutDeadlineTableTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $VaultLockoutDeadlineTableTable,
          VaultLockoutDeadlineEntry,
          $$VaultLockoutDeadlineTableTableFilterComposer,
          $$VaultLockoutDeadlineTableTableOrderingComposer,
          $$VaultLockoutDeadlineTableTableAnnotationComposer,
          $$VaultLockoutDeadlineTableTableCreateCompanionBuilder,
          $$VaultLockoutDeadlineTableTableUpdateCompanionBuilder,
          (
            VaultLockoutDeadlineEntry,
            BaseReferences<
              _$VaultDatabase,
              $VaultLockoutDeadlineTableTable,
              VaultLockoutDeadlineEntry
            >,
          ),
          VaultLockoutDeadlineEntry,
          PrefetchHooks Function()
        > {
  $$VaultLockoutDeadlineTableTableTableManager(
    _$VaultDatabase db,
    $VaultLockoutDeadlineTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultLockoutDeadlineTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$VaultLockoutDeadlineTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaultLockoutDeadlineTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> deadlineMonotonicMs = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultLockoutDeadlineTableCompanion(
                id: id,
                deadlineMonotonicMs: deadlineMonotonicMs,
                failedAttempts: failedAttempts,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int deadlineMonotonicMs,
                required int failedAttempts,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultLockoutDeadlineTableCompanion.insert(
                id: id,
                deadlineMonotonicMs: deadlineMonotonicMs,
                failedAttempts: failedAttempts,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $VaultLockoutDeadlineTableTable,
                    VaultLockoutDeadlineEntry
                  >(table),
                  BaseReferences<
                    _$VaultDatabase,
                    $VaultLockoutDeadlineTableTable,
                    VaultLockoutDeadlineEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultLockoutDeadlineTableTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $VaultLockoutDeadlineTableTable,
      VaultLockoutDeadlineEntry,
      $$VaultLockoutDeadlineTableTableFilterComposer,
      $$VaultLockoutDeadlineTableTableOrderingComposer,
      $$VaultLockoutDeadlineTableTableAnnotationComposer,
      $$VaultLockoutDeadlineTableTableCreateCompanionBuilder,
      $$VaultLockoutDeadlineTableTableUpdateCompanionBuilder,
      (
        VaultLockoutDeadlineEntry,
        BaseReferences<
          _$VaultDatabase,
          $VaultLockoutDeadlineTableTable,
          VaultLockoutDeadlineEntry
        >,
      ),
      VaultLockoutDeadlineEntry,
      PrefetchHooks Function()
    >;

class $VaultDatabaseManager {
  final _$VaultDatabase _db;
  $VaultDatabaseManager(this._db);
  $$VaultPlaylistsTableTableTableManager get vaultPlaylistsTable =>
      $$VaultPlaylistsTableTableTableManager(_db, _db.vaultPlaylistsTable);
  $$VaultTrackRefsTableTableTableManager get vaultTrackRefsTable =>
      $$VaultTrackRefsTableTableTableManager(_db, _db.vaultTrackRefsTable);
  $$VaultConfigTableTableTableManager get vaultConfigTable =>
      $$VaultConfigTableTableTableManager(_db, _db.vaultConfigTable);
  $$VaultGestureTemplatesTableTableTableManager
  get vaultGestureTemplatesTable =>
      $$VaultGestureTemplatesTableTableTableManager(
        _db,
        _db.vaultGestureTemplatesTable,
      );
  $$VaultLockoutDeadlineTableTableTableManager get vaultLockoutDeadlineTable =>
      $$VaultLockoutDeadlineTableTableTableManager(
        _db,
        _db.vaultLockoutDeadlineTable,
      );
}
