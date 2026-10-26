// Protobuf binary wire format for Spotify Playlist Esperanto services:
// - spotify.playlist_esperanto.proto.PlaylistDataService (Subscribe, Get)
// - spotify.playlist_esperanto.proto.PlaylistService (Modify)
// - spotify.playlist_esperanto.proto.PlaylistPlayService (Play)

library;
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;
import '../../../player/data/esperanto/proto/spotify_esperanto_proto.dart' as $player;

const $core.bool _omitFieldNames = false;
const $core.bool _omitMessageNames = false;

/// Range specification for pagination in PlaylistQuery.
class PlaylistRange extends $pb.GeneratedMessage {
  factory PlaylistRange({
    $core.int? start,
    $core.int? length,
  }) {
    final result = PlaylistRange._();
    if (start != null) result.start = start;
    if (length != null) result.length = length;
    return result;
  }

  PlaylistRange._();

  factory PlaylistRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistRange()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistRange',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistRange.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'start')
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistRange clone() => deepCopy();

  @$core.override
  PlaylistRange createEmptyInstance() => PlaylistRange._();

  static PlaylistRange create() => PlaylistRange._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistRange._();

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int value) => $_setSignedInt32(0, value);

  @$pb.TagNumber(2)
  $core.int get length => $_getIZ(1);
  @$pb.TagNumber(2)
  set length($core.int value) => $_setSignedInt32(1, value);
}

/// Query filters and sort parameters for Playlist requests.
class PlaylistQuery extends $pb.GeneratedMessage {
  factory PlaylistQuery({
    $core.String? textFilter,
    $core.String? sortBy,
    PlaylistRange? range,
    $core.int? updateThrottlingMs,
    $core.bool? group,
    $core.String? providedSortInternalId,
  }) {
    final result = PlaylistQuery._();
    if (textFilter != null) result.textFilter = textFilter;
    if (sortBy != null) result.sortBy = sortBy;
    if (range != null) result.range = range;
    if (updateThrottlingMs != null) result.updateThrottlingMs = updateThrottlingMs;
    if (group != null) result.group = group;
    if (providedSortInternalId != null) {
      result.providedSortInternalId = providedSortInternalId;
    }
    return result;
  }

  PlaylistQuery._();

  factory PlaylistQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistQuery()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistQuery',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistQuery.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'textFilter')
    ..aOS(3, _omitFieldNames ? '' : 'sortBy')
    ..aOM<PlaylistRange>(4, _omitFieldNames ? '' : 'range',
        subBuilder: PlaylistRange.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'updateThrottlingMs')
    ..aOB(6, _omitFieldNames ? '' : 'group')
    ..aOS(19, _omitFieldNames ? '' : 'providedSortInternalId')
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistQuery clone() => deepCopy();

  @$core.override
  PlaylistQuery createEmptyInstance() => PlaylistQuery._();

  static PlaylistQuery create() => PlaylistQuery._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistQuery._();

  @$pb.TagNumber(2)
  $core.String get textFilter => $_getSZ(0);
  @$pb.TagNumber(2)
  set textFilter($core.String value) => $_setString(0, value);

  @$pb.TagNumber(3)
  $core.String get sortBy => $_getSZ(1);
  @$pb.TagNumber(3)
  set sortBy($core.String value) => $_setString(1, value);

  @$pb.TagNumber(4)
  PlaylistRange get range => $_getN(2);
  @$pb.TagNumber(4)
  set range(PlaylistRange value) => $_setField(4, value);

  @$pb.TagNumber(5)
  $core.int get updateThrottlingMs => $_getIZ(3);
  @$pb.TagNumber(5)
  set updateThrottlingMs($core.int value) => $_setSignedInt32(3, value);

  @$pb.TagNumber(6)
  $core.bool get group => $_getBF(4);
  @$pb.TagNumber(6)
  set group($core.bool value) => $_setBool(4, value);

  @$pb.TagNumber(19)
  $core.String get providedSortInternalId => $_getSZ(5);
  @$pb.TagNumber(19)
  set providedSortInternalId($core.String value) => $_setString(5, value);
}

/// Request message for `spotify.playlist_esperanto.proto.PlaylistDataService/Subscribe` and `Get`.
class PlaylistGetRequest extends $pb.GeneratedMessage {
  factory PlaylistGetRequest({
    $core.String? uri,
    PlaylistQuery? query,
  }) {
    final result = PlaylistGetRequest._();
    if (uri != null) result.uri = uri;
    if (query != null) result.query = query;
    return result;
  }

  PlaylistGetRequest._();

  factory PlaylistGetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistGetRequest()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistGetRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistGetRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOM<PlaylistQuery>(2, _omitFieldNames ? '' : 'query',
        subBuilder: PlaylistQuery.$_createMessage)
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistGetRequest clone() => deepCopy();

  @$core.override
  PlaylistGetRequest createEmptyInstance() => PlaylistGetRequest._();

  static PlaylistGetRequest create() => PlaylistGetRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistGetRequest._();

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);

  @$pb.TagNumber(2)
  PlaylistQuery get query => $_getN(1);
  @$pb.TagNumber(2)
  set query(PlaylistQuery value) => $_setField(2, value);
}

/// Response message for `spotify.playlist_esperanto.proto.PlaylistDataService/Subscribe`.
class PlaylistGetResponse extends $pb.GeneratedMessage {
  factory PlaylistGetResponse({
    $core.int? status,
    $core.List<$core.int>? dataPayload,
    PlaylistQuery? query,
  }) {
    final result = PlaylistGetResponse._();
    if (status != null) result.status = status;
    if (dataPayload != null) result.dataPayload = dataPayload;
    if (query != null) result.query = query;
    return result;
  }

  PlaylistGetResponse._();

  factory PlaylistGetResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistGetResponse()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistGetResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistGetResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'status')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'dataPayload', $pb.PbFieldType.OY)
    ..aOM<PlaylistQuery>(3, _omitFieldNames ? '' : 'query',
        subBuilder: PlaylistQuery.$_createMessage)
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistGetResponse clone() => deepCopy();

  @$core.override
  PlaylistGetResponse createEmptyInstance() => PlaylistGetResponse._();

  static PlaylistGetResponse create() => PlaylistGetResponse._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistGetResponse._();

  @$pb.TagNumber(1)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(1)
  set status($core.int value) => $_setSignedInt32(0, value);

  @$pb.TagNumber(2)
  $core.List<$core.int> get dataPayload => $_getN(1);
  @$pb.TagNumber(2)
  set dataPayload($core.List<$core.int> value) => $_setBytes(1, value);

  @$pb.TagNumber(3)
  PlaylistQuery get query => $_getN(2);
  @$pb.TagNumber(3)
  set query(PlaylistQuery value) => $_setField(2, value);
}

/// Modification operation types.
enum ModificationOp {
  add,
  remove,
  move,
}

/// Request for `spotify.playlist_esperanto.proto.PlaylistService/Modify`.
class PlaylistModificationRequest extends $pb.GeneratedMessage {
  factory PlaylistModificationRequest({
    $core.String? uri,
    $core.Iterable<$core.String>? addUris,
    $core.Iterable<$core.String>? removeUris,
    $core.int? insertPosition,
  }) {
    final result = PlaylistModificationRequest._();
    if (uri != null) result.uri = uri;
    if (addUris != null) result.addUris.addAll(addUris);
    if (removeUris != null) result.removeUris.addAll(removeUris);
    if (insertPosition != null) result.insertPosition = insertPosition;
    return result;
  }

  PlaylistModificationRequest._();

  factory PlaylistModificationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistModificationRequest()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistModificationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistModificationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..pPS(2, _omitFieldNames ? '' : 'addUris')
    ..pPS(3, _omitFieldNames ? '' : 'removeUris')
    ..aI(4, _omitFieldNames ? '' : 'insertPosition')
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistModificationRequest clone() => deepCopy();

  @$core.override
  PlaylistModificationRequest createEmptyInstance() => PlaylistModificationRequest._();

  static PlaylistModificationRequest create() => PlaylistModificationRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistModificationRequest._();

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);

  @$pb.TagNumber(2)
  $core.List<$core.String> get addUris => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get removeUris => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get insertPosition => $_getIZ(3);
  @$pb.TagNumber(4)
  set insertPosition($core.int value) => $_setSignedInt32(3, value);
}

/// Response for `spotify.playlist_esperanto.proto.PlaylistService/Modify`.
class PlaylistModificationResponse extends $pb.GeneratedMessage {
  factory PlaylistModificationResponse({
    $core.int? status,
    $core.String? revision,
  }) {
    final result = PlaylistModificationResponse._();
    if (status != null) result.status = status;
    if (revision != null) result.revision = revision;
    return result;
  }

  PlaylistModificationResponse._();

  factory PlaylistModificationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistModificationResponse()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistModificationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistModificationResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'status')
    ..aOS(2, _omitFieldNames ? '' : 'revision')
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistModificationResponse clone() => deepCopy();

  @$core.override
  PlaylistModificationResponse createEmptyInstance() => PlaylistModificationResponse._();

  static PlaylistModificationResponse create() => PlaylistModificationResponse._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistModificationResponse._();

  @$pb.TagNumber(1)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(1)
  set status($core.int value) => $_setSignedInt32(0, value);

  @$pb.TagNumber(2)
  $core.String get revision => $_getSZ(1);
  @$pb.TagNumber(2)
  set revision($core.String value) => $_setString(1, value);
}

/// Request for `spotify.playlist_esperanto.proto.PlaylistPlayService/Play`.
class PlaylistPlayRequest extends $pb.GeneratedMessage {
  factory PlaylistPlayRequest({
    PlaylistQuery? playlistQuery,
    $player.Context? context,
    $player.PlayOptions? playOptions,
    $player.PlayOrigin? playOrigin,
  }) {
    final result = PlaylistPlayRequest._();
    if (playlistQuery != null) result.playlistQuery = playlistQuery;
    if (context != null) result.context = context;
    if (playOptions != null) result.playOptions = playOptions;
    if (playOrigin != null) result.playOrigin = playOrigin;
    return result;
  }

  PlaylistPlayRequest._();

  factory PlaylistPlayRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistPlayRequest()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistPlayRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistPlayRequest.$_createMessage)
    ..aOM<PlaylistQuery>(1, _omitFieldNames ? '' : 'playlistQuery',
        subBuilder: PlaylistQuery.$_createMessage)
    ..aOM<$player.Context>(2, _omitFieldNames ? '' : 'context',
        subBuilder: $player.Context.$_createMessage)
    ..aOM<$player.PlayOptions>(3, _omitFieldNames ? '' : 'playOptions',
        subBuilder: $player.PlayOptions.$_createMessage)
    ..aOM<$player.PlayOrigin>(6, _omitFieldNames ? '' : 'playOrigin',
        subBuilder: $player.PlayOrigin.$_createMessage)
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistPlayRequest clone() => deepCopy();

  @$core.override
  PlaylistPlayRequest createEmptyInstance() => PlaylistPlayRequest._();

  static PlaylistPlayRequest create() => PlaylistPlayRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistPlayRequest._();

  @$pb.TagNumber(1)
  PlaylistQuery get playlistQuery => $_getN(0);
  @$pb.TagNumber(1)
  set playlistQuery(PlaylistQuery value) => $_setField(1, value);

  @$pb.TagNumber(2)
  $player.Context get context => $_getN(1);
  @$pb.TagNumber(2)
  set context($player.Context value) => $_setField(2, value);

  @$pb.TagNumber(3)
  $player.PlayOptions get playOptions => $_getN(2);
  @$pb.TagNumber(3)
  set playOptions($player.PlayOptions value) => $_setField(3, value);

  @$pb.TagNumber(6)
  $player.PlayOrigin get playOrigin => $_getN(3);
  @$pb.TagNumber(6)
  set playOrigin($player.PlayOrigin value) => $_setField(6, value);
}

/// Response for `spotify.playlist_esperanto.proto.PlaylistPlayService/Play`.
class PlaylistPlayResponse extends $pb.GeneratedMessage {
  factory PlaylistPlayResponse({
    $core.int? status,
  }) {
    final result = PlaylistPlayResponse._();
    if (status != null) result.status = status;
    return result;
  }

  PlaylistPlayResponse._();

  factory PlaylistPlayResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistPlayResponse()..mergeFromBuffer(data, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistPlayResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.playlist.esperanto.proto'),
      createEmptyInstance: PlaylistPlayResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.override
  PlaylistPlayResponse clone() => deepCopy();

  @$core.override
  PlaylistPlayResponse createEmptyInstance() => PlaylistPlayResponse._();

  static PlaylistPlayResponse create() => PlaylistPlayResponse._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistPlayResponse._();

  @$pb.TagNumber(1)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(1)
  set status($core.int value) => $_setSignedInt32(0, value);
}
