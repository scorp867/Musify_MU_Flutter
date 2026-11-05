// This is a generated file - do not edit.
//
// Generated from spotify/metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use dateDescriptor instead')
const Date$json = {
  '1': 'Date',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 17, '10': 'year'},
    {'1': 'month', '3': 2, '4': 1, '5': 17, '10': 'month'},
    {'1': 'day', '3': 3, '4': 1, '5': 17, '10': 'day'},
    {'1': 'hour', '3': 4, '4': 1, '5': 17, '10': 'hour'},
    {'1': 'minute', '3': 5, '4': 1, '5': 17, '10': 'minute'},
  ],
};

/// Descriptor for `Date`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateDescriptor = $convert.base64Decode(
    'CgREYXRlEhIKBHllYXIYASABKBFSBHllYXISFAoFbW9udGgYAiABKBFSBW1vbnRoEhAKA2RheR'
    'gDIAEoEVIDZGF5EhIKBGhvdXIYBCABKBFSBGhvdXISFgoGbWludXRlGAUgASgRUgZtaW51dGU=');

@$core.Deprecated('Use imageDescriptor instead')
const Image$json = {
  '1': 'Image',
  '2': [
    {'1': 'file_id', '3': 1, '4': 1, '5': 12, '10': 'fileId'},
    {
      '1': 'size',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.Image.Size',
      '10': 'size'
    },
    {'1': 'width', '3': 3, '4': 1, '5': 17, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 17, '10': 'height'},
  ],
  '4': [Image_Size$json],
};

@$core.Deprecated('Use imageDescriptor instead')
const Image_Size$json = {
  '1': 'Size',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'SMALL', '2': 1},
    {'1': 'LARGE', '2': 2},
    {'1': 'XLARGE', '2': 3},
  ],
};

/// Descriptor for `Image`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDescriptor = $convert.base64Decode(
    'CgVJbWFnZRIXCgdmaWxlX2lkGAEgASgMUgZmaWxlSWQSMAoEc2l6ZRgCIAEoDjIcLnNwb3RpZn'
    'kubWV0YWRhdGEuSW1hZ2UuU2l6ZVIEc2l6ZRIUCgV3aWR0aBgDIAEoEVIFd2lkdGgSFgoGaGVp'
    'Z2h0GAQgASgRUgZoZWlnaHQiNQoEU2l6ZRILCgdERUZBVUxUEAASCQoFU01BTEwQARIJCgVMQV'
    'JHRRACEgoKBlhMQVJHRRAD');

@$core.Deprecated('Use imageGroupDescriptor instead')
const ImageGroup$json = {
  '1': 'ImageGroup',
  '2': [
    {
      '1': 'image',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Image',
      '10': 'image'
    },
  ],
};

/// Descriptor for `ImageGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageGroupDescriptor = $convert.base64Decode(
    'CgpJbWFnZUdyb3VwEi0KBWltYWdlGAEgAygLMhcuc3BvdGlmeS5tZXRhZGF0YS5JbWFnZVIFaW'
    '1hZ2U=');

@$core.Deprecated('Use externalIdDescriptor instead')
const ExternalId$json = {
  '1': 'ExternalId',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ExternalId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List externalIdDescriptor = $convert.base64Decode(
    'CgpFeHRlcm5hbElkEhIKBHR5cGUYASABKAlSBHR5cGUSDgoCaWQYAiABKAlSAmlk');

@$core.Deprecated('Use restrictionDescriptor instead')
const Restriction$json = {
  '1': 'Restriction',
  '2': [
    {'1': 'catalogue', '3': 1, '4': 3, '5': 17, '10': 'catalogue'},
    {'1': 'type', '3': 4, '4': 1, '5': 17, '10': 'type'},
    {'1': 'catalogue_str', '3': 5, '4': 3, '5': 9, '10': 'catalogueStr'},
  ],
};

/// Descriptor for `Restriction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restrictionDescriptor = $convert.base64Decode(
    'CgtSZXN0cmljdGlvbhIcCgljYXRhbG9ndWUYASADKBFSCWNhdGFsb2d1ZRISCgR0eXBlGAQgAS'
    'gRUgR0eXBlEiMKDWNhdGFsb2d1ZV9zdHIYBSADKAlSDGNhdGFsb2d1ZVN0cg==');

@$core.Deprecated('Use licensorDescriptor instead')
const Licensor$json = {
  '1': 'Licensor',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 12, '10': 'uuid'},
  ],
};

/// Descriptor for `Licensor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List licensorDescriptor =
    $convert.base64Decode('CghMaWNlbnNvchISCgR1dWlkGAEgASgMUgR1dWlk');

@$core.Deprecated('Use audioDescriptor instead')
const Audio$json = {
  '1': 'Audio',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 12, '10': 'uuid'},
    {
      '1': 'format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.Audio.Format',
      '10': 'format'
    },
  ],
  '4': [Audio_Format$json],
};

@$core.Deprecated('Use audioDescriptor instead')
const Audio_Format$json = {
  '1': 'Format',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'DEFAULT', '2': 1},
    {'1': 'PARROT', '2': 2},
  ],
};

/// Descriptor for `Audio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioDescriptor = $convert.base64Decode(
    'CgVBdWRpbxISCgR1dWlkGAEgASgMUgR1dWlkEjYKBmZvcm1hdBgCIAEoDjIeLnNwb3RpZnkubW'
    'V0YWRhdGEuQXVkaW8uRm9ybWF0UgZmb3JtYXQiLgoGRm9ybWF0EgsKB1VOS05PV04QABILCgdE'
    'RUZBVUxUEAESCgoGUEFSUk9UEAI=');

@$core.Deprecated('Use trackAudioFormatDescriptor instead')
const TrackAudioFormat$json = {
  '1': 'TrackAudioFormat',
  '2': [
    {
      '1': 'original_audio',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Audio',
      '10': 'originalAudio'
    },
  ],
};

/// Descriptor for `TrackAudioFormat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackAudioFormatDescriptor = $convert.base64Decode(
    'ChBUcmFja0F1ZGlvRm9ybWF0Ej4KDm9yaWdpbmFsX2F1ZGlvGAEgASgLMhcuc3BvdGlmeS5tZX'
    'RhZGF0YS5BdWRpb1INb3JpZ2luYWxBdWRpbw==');

@$core.Deprecated('Use videoDescriptor instead')
const Video$json = {
  '1': 'Video',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
  ],
};

/// Descriptor for `Video`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoDescriptor =
    $convert.base64Decode('CgVWaWRlbxIQCgNnaWQYASABKAxSA2dpZA==');

@$core.Deprecated('Use contentRatingDescriptor instead')
const ContentRating$json = {
  '1': 'ContentRating',
  '2': [
    {'1': 'country', '3': 1, '4': 1, '5': 9, '10': 'country'},
    {'1': 'tag', '3': 2, '4': 3, '5': 9, '10': 'tag'},
  ],
};

/// Descriptor for `ContentRating`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentRatingDescriptor = $convert.base64Decode(
    'Cg1Db250ZW50UmF0aW5nEhgKB2NvdW50cnkYASABKAlSB2NvdW50cnkSEAoDdGFnGAIgAygJUg'
    'N0YWc=');

@$core.Deprecated('Use artistWithRoleDescriptor instead')
const ArtistWithRole$json = {
  '1': 'ArtistWithRole',
  '2': [
    {'1': 'artist_gid', '3': 1, '4': 1, '5': 12, '10': 'artistGid'},
    {'1': 'artist_name', '3': 2, '4': 1, '5': 9, '10': 'artistName'},
    {
      '1': 'role',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.ArtistWithRole.Role',
      '10': 'role'
    },
  ],
  '4': [ArtistWithRole_Role$json],
};

@$core.Deprecated('Use artistWithRoleDescriptor instead')
const ArtistWithRole_Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'ARTIST_ROLE_UNKNOWN', '2': 0},
    {'1': 'ARTIST_ROLE_MAIN_ARTIST', '2': 1},
    {'1': 'ARTIST_ROLE_FEATURED_ARTIST', '2': 2},
    {'1': 'ARTIST_ROLE_REMIXER', '2': 3},
    {'1': 'ARTIST_ROLE_ACTOR', '2': 4},
    {'1': 'ARTIST_ROLE_COMPOSER', '2': 5},
    {'1': 'ARTIST_ROLE_CONDUCTOR', '2': 6},
    {'1': 'ARTIST_ROLE_ORCHESTRA', '2': 7},
  ],
};

/// Descriptor for `ArtistWithRole`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artistWithRoleDescriptor = $convert.base64Decode(
    'Cg5BcnRpc3RXaXRoUm9sZRIdCgphcnRpc3RfZ2lkGAEgASgMUglhcnRpc3RHaWQSHwoLYXJ0aX'
    'N0X25hbWUYAiABKAlSCmFydGlzdE5hbWUSOQoEcm9sZRgDIAEoDjIlLnNwb3RpZnkubWV0YWRh'
    'dGEuQXJ0aXN0V2l0aFJvbGUuUm9sZVIEcm9sZSLdAQoEUm9sZRIXChNBUlRJU1RfUk9MRV9VTk'
    'tOT1dOEAASGwoXQVJUSVNUX1JPTEVfTUFJTl9BUlRJU1QQARIfChtBUlRJU1RfUk9MRV9GRUFU'
    'VVJFRF9BUlRJU1QQAhIXChNBUlRJU1RfUk9MRV9SRU1JWEVSEAMSFQoRQVJUSVNUX1JPTEVfQU'
    'NUT1IQBBIYChRBUlRJU1RfUk9MRV9DT01QT1NFUhAFEhkKFUFSVElTVF9ST0xFX0NPTkRVQ1RP'
    'UhAGEhkKFUFSVElTVF9ST0xFX09SQ0hFU1RSQRAH');

@$core.Deprecated('Use contentWindowingDescriptor instead')
const ContentWindowing$json = {
  '1': 'ContentWindowing',
};

/// Descriptor for `ContentWindowing`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentWindowingDescriptor =
    $convert.base64Decode('ChBDb250ZW50V2luZG93aW5n');

@$core.Deprecated('Use contentGatedDescriptor instead')
const ContentGated$json = {
  '1': 'ContentGated',
};

/// Descriptor for `ContentGated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentGatedDescriptor =
    $convert.base64Decode('CgxDb250ZW50R2F0ZWQ=');

@$core.Deprecated('Use contentAccessStatusDescriptor instead')
const ContentAccessStatus$json = {
  '1': 'ContentAccessStatus',
  '2': [
    {
      '1': 'content_windowing',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ContentWindowing',
      '9': 0,
      '10': 'contentWindowing'
    },
    {
      '1': 'content_gated',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ContentGated',
      '9': 0,
      '10': 'contentGated'
    },
  ],
  '8': [
    {'1': 'status'},
  ],
};

/// Descriptor for `ContentAccessStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentAccessStatusDescriptor = $convert.base64Decode(
    'ChNDb250ZW50QWNjZXNzU3RhdHVzElEKEWNvbnRlbnRfd2luZG93aW5nGAEgASgLMiIuc3BvdG'
    'lmeS5tZXRhZGF0YS5Db250ZW50V2luZG93aW5nSABSEGNvbnRlbnRXaW5kb3dpbmcSRQoNY29u'
    'dGVudF9nYXRlZBgCIAEoCzIeLnNwb3RpZnkubWV0YWRhdGEuQ29udGVudEdhdGVkSABSDGNvbn'
    'RlbnRHYXRlZEIICgZzdGF0dXM=');

@$core.Deprecated('Use availabilityDescriptor instead')
const Availability$json = {
  '1': 'Availability',
  '2': [
    {'1': 'catalogue_str', '3': 1, '4': 3, '5': 9, '10': 'catalogueStr'},
    {
      '1': 'start',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Date',
      '10': 'start'
    },
  ],
};

/// Descriptor for `Availability`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availabilityDescriptor = $convert.base64Decode(
    'CgxBdmFpbGFiaWxpdHkSIwoNY2F0YWxvZ3VlX3N0chgBIAMoCVIMY2F0YWxvZ3VlU3RyEiwKBX'
    'N0YXJ0GAIgASgLMhYuc3BvdGlmeS5tZXRhZGF0YS5EYXRlUgVzdGFydA==');

@$core.Deprecated('Use salePeriodDescriptor instead')
const SalePeriod$json = {
  '1': 'SalePeriod',
  '2': [
    {
      '1': 'restriction',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Restriction',
      '10': 'restriction'
    },
    {
      '1': 'start',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Date',
      '10': 'start'
    },
    {
      '1': 'end',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Date',
      '10': 'end'
    },
  ],
};

/// Descriptor for `SalePeriod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List salePeriodDescriptor = $convert.base64Decode(
    'CgpTYWxlUGVyaW9kEj8KC3Jlc3RyaWN0aW9uGAEgAygLMh0uc3BvdGlmeS5tZXRhZGF0YS5SZX'
    'N0cmljdGlvblILcmVzdHJpY3Rpb24SLAoFc3RhcnQYAiABKAsyFi5zcG90aWZ5Lm1ldGFkYXRh'
    'LkRhdGVSBXN0YXJ0EigKA2VuZBgDIAEoCzIWLnNwb3RpZnkubWV0YWRhdGEuRGF0ZVIDZW5k');

@$core.Deprecated('Use copyrightDescriptor instead')
const Copyright$json = {
  '1': 'Copyright',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.Copyright.Type',
      '10': 'type'
    },
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
  '4': [Copyright_Type$json],
};

@$core.Deprecated('Use copyrightDescriptor instead')
const Copyright_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'P_COPYRIGHT', '2': 0},
    {'1': 'C_COPYRIGHT', '2': 1},
  ],
};

/// Descriptor for `Copyright`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copyrightDescriptor = $convert.base64Decode(
    'CglDb3B5cmlnaHQSNAoEdHlwZRgBIAEoDjIgLnNwb3RpZnkubWV0YWRhdGEuQ29weXJpZ2h0Ll'
    'R5cGVSBHR5cGUSEgoEdGV4dBgCIAEoCVIEdGV4dCIoCgRUeXBlEg8KC1BfQ09QWVJJR0hUEAAS'
    'DwoLQ19DT1BZUklHSFQQAQ==');

@$core.Deprecated('Use discDescriptor instead')
const Disc$json = {
  '1': 'Disc',
  '2': [
    {'1': 'number', '3': 1, '4': 1, '5': 17, '10': 'number'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'track',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Track',
      '10': 'track'
    },
  ],
};

/// Descriptor for `Disc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discDescriptor = $convert.base64Decode(
    'CgREaXNjEhYKBm51bWJlchgBIAEoEVIGbnVtYmVyEhIKBG5hbWUYAiABKAlSBG5hbWUSLQoFdH'
    'JhY2sYAyADKAsyFy5zcG90aWZ5Lm1ldGFkYXRhLlRyYWNrUgV0cmFjaw==');

@$core.Deprecated('Use activityPeriodDescriptor instead')
const ActivityPeriod$json = {
  '1': 'ActivityPeriod',
  '2': [
    {'1': 'start_year', '3': 1, '4': 1, '5': 17, '10': 'startYear'},
    {'1': 'end_year', '3': 2, '4': 1, '5': 17, '10': 'endYear'},
    {'1': 'decade', '3': 3, '4': 1, '5': 17, '10': 'decade'},
  ],
};

/// Descriptor for `ActivityPeriod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activityPeriodDescriptor = $convert.base64Decode(
    'Cg5BY3Rpdml0eVBlcmlvZBIdCgpzdGFydF95ZWFyGAEgASgRUglzdGFydFllYXISGQoIZW5kX3'
    'llYXIYAiABKBFSB2VuZFllYXISFgoGZGVjYWRlGAMgASgRUgZkZWNhZGU=');

@$core.Deprecated('Use biographyDescriptor instead')
const Biography$json = {
  '1': 'Biography',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'portrait',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Image',
      '10': 'portrait'
    },
    {
      '1': 'portrait_group',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'portraitGroup'
    },
  ],
};

/// Descriptor for `Biography`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List biographyDescriptor = $convert.base64Decode(
    'CglCaW9ncmFwaHkSEgoEdGV4dBgBIAEoCVIEdGV4dBIzCghwb3J0cmFpdBgCIAMoCzIXLnNwb3'
    'RpZnkubWV0YWRhdGEuSW1hZ2VSCHBvcnRyYWl0EkMKDnBvcnRyYWl0X2dyb3VwGAMgAygLMhwu'
    'c3BvdGlmeS5tZXRhZGF0YS5JbWFnZUdyb3VwUg1wb3J0cmFpdEdyb3Vw');

@$core.Deprecated('Use topTracksDescriptor instead')
const TopTracks$json = {
  '1': 'TopTracks',
  '2': [
    {'1': 'country', '3': 1, '4': 1, '5': 9, '10': 'country'},
    {
      '1': 'track',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Track',
      '10': 'track'
    },
  ],
};

/// Descriptor for `TopTracks`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topTracksDescriptor = $convert.base64Decode(
    'CglUb3BUcmFja3MSGAoHY291bnRyeRgBIAEoCVIHY291bnRyeRItCgV0cmFjaxgCIAMoCzIXLn'
    'Nwb3RpZnkubWV0YWRhdGEuVHJhY2tSBXRyYWNr');

@$core.Deprecated('Use albumGroupDescriptor instead')
const AlbumGroup$json = {
  '1': 'AlbumGroup',
  '2': [
    {
      '1': 'album',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Album',
      '10': 'album'
    },
  ],
};

/// Descriptor for `AlbumGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List albumGroupDescriptor = $convert.base64Decode(
    'CgpBbGJ1bUdyb3VwEi0KBWFsYnVtGAEgAygLMhcuc3BvdGlmeS5tZXRhZGF0YS5BbGJ1bVIFYW'
    'xidW0=');

@$core.Deprecated('Use audioFileDescriptor instead')
const AudioFile$json = {
  '1': 'AudioFile',
  '2': [
    {'1': 'file_id', '3': 1, '4': 1, '5': 12, '10': 'fileId'},
    {
      '1': 'format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.AudioFile.Format',
      '10': 'format'
    },
  ],
  '4': [AudioFile_Format$json],
};

@$core.Deprecated('Use audioFileDescriptor instead')
const AudioFile_Format$json = {
  '1': 'Format',
  '2': [
    {'1': 'OGG_VORBIS_96', '2': 0},
    {'1': 'OGG_VORBIS_160', '2': 1},
    {'1': 'OGG_VORBIS_320', '2': 2},
    {'1': 'MP3_256', '2': 3},
    {'1': 'MP3_320', '2': 4},
    {'1': 'MP3_160', '2': 5},
    {'1': 'MP3_96', '2': 6},
    {'1': 'MP3_160_ENC', '2': 7},
    {'1': 'AAC_24', '2': 8},
    {'1': 'AAC_48', '2': 9},
    {'1': 'MP4_128', '2': 10},
    {'1': 'MP4_256', '2': 11},
    {'1': 'MP4_128_DUAL', '2': 12},
    {'1': 'MP4_256_DUAL', '2': 13},
    {'1': 'MP4_128_CBCS', '2': 14},
    {'1': 'MP4_256_CBCS', '2': 15},
    {'1': 'FLAC_FLAC', '2': 16},
    {'1': 'MP4_FLAC', '2': 17},
  ],
};

/// Descriptor for `AudioFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioFileDescriptor = $convert.base64Decode(
    'CglBdWRpb0ZpbGUSFwoHZmlsZV9pZBgBIAEoDFIGZmlsZUlkEjoKBmZvcm1hdBgCIAEoDjIiLn'
    'Nwb3RpZnkubWV0YWRhdGEuQXVkaW9GaWxlLkZvcm1hdFIGZm9ybWF0Ip4CCgZGb3JtYXQSEQoN'
    'T0dHX1ZPUkJJU185NhAAEhIKDk9HR19WT1JCSVNfMTYwEAESEgoOT0dHX1ZPUkJJU18zMjAQAh'
    'ILCgdNUDNfMjU2EAMSCwoHTVAzXzMyMBAEEgsKB01QM18xNjAQBRIKCgZNUDNfOTYQBhIPCgtN'
    'UDNfMTYwX0VOQxAHEgoKBkFBQ18yNBAIEgoKBkFBQ180OBAJEgsKB01QNF8xMjgQChILCgdNUD'
    'RfMjU2EAsSEAoMTVA0XzEyOF9EVUFMEAwSEAoMTVA0XzI1Nl9EVUFMEA0SEAoMTVA0XzEyOF9D'
    'QkNTEA4SEAoMTVA0XzI1Nl9DQkNTEA8SDQoJRkxBQ19GTEFDEBASDAoITVA0X0ZMQUMQEQ==');

@$core.Deprecated('Use artistDescriptor instead')
const Artist$json = {
  '1': 'Artist',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'popularity', '3': 3, '4': 1, '5': 17, '10': 'popularity'},
    {
      '1': 'top_track',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.TopTracks',
      '10': 'topTrack'
    },
    {
      '1': 'album_group',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AlbumGroup',
      '10': 'albumGroup'
    },
    {
      '1': 'single_group',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AlbumGroup',
      '10': 'singleGroup'
    },
    {
      '1': 'compilation_group',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AlbumGroup',
      '10': 'compilationGroup'
    },
    {
      '1': 'appears_on_group',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AlbumGroup',
      '10': 'appearsOnGroup'
    },
    {
      '1': 'external_id',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ExternalId',
      '10': 'externalId'
    },
    {
      '1': 'portrait',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Image',
      '10': 'portrait'
    },
    {
      '1': 'biography',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Biography',
      '10': 'biography'
    },
    {
      '1': 'activity_period',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ActivityPeriod',
      '10': 'activityPeriod'
    },
    {
      '1': 'restriction',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Restriction',
      '10': 'restriction'
    },
    {
      '1': 'related',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Artist',
      '10': 'related'
    },
    {
      '1': 'is_portrait_album_cover',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'isPortraitAlbumCover'
    },
    {
      '1': 'portrait_group',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'portraitGroup'
    },
    {
      '1': 'sale_period',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.SalePeriod',
      '10': 'salePeriod'
    },
    {
      '1': 'availability',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Availability',
      '10': 'availability'
    },
  ],
};

/// Descriptor for `Artist`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artistDescriptor = $convert.base64Decode(
    'CgZBcnRpc3QSEAoDZ2lkGAEgASgMUgNnaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIeCgpwb3B1bG'
    'FyaXR5GAMgASgRUgpwb3B1bGFyaXR5EjgKCXRvcF90cmFjaxgEIAMoCzIbLnNwb3RpZnkubWV0'
    'YWRhdGEuVG9wVHJhY2tzUgh0b3BUcmFjaxI9CgthbGJ1bV9ncm91cBgFIAMoCzIcLnNwb3RpZn'
    'kubWV0YWRhdGEuQWxidW1Hcm91cFIKYWxidW1Hcm91cBI/CgxzaW5nbGVfZ3JvdXAYBiADKAsy'
    'HC5zcG90aWZ5Lm1ldGFkYXRhLkFsYnVtR3JvdXBSC3NpbmdsZUdyb3VwEkkKEWNvbXBpbGF0aW'
    '9uX2dyb3VwGAcgAygLMhwuc3BvdGlmeS5tZXRhZGF0YS5BbGJ1bUdyb3VwUhBjb21waWxhdGlv'
    'bkdyb3VwEkYKEGFwcGVhcnNfb25fZ3JvdXAYCCADKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkFsYn'
    'VtR3JvdXBSDmFwcGVhcnNPbkdyb3VwEj0KC2V4dGVybmFsX2lkGAogAygLMhwuc3BvdGlmeS5t'
    'ZXRhZGF0YS5FeHRlcm5hbElkUgpleHRlcm5hbElkEjMKCHBvcnRyYWl0GAsgAygLMhcuc3BvdG'
    'lmeS5tZXRhZGF0YS5JbWFnZVIIcG9ydHJhaXQSOQoJYmlvZ3JhcGh5GAwgAygLMhsuc3BvdGlm'
    'eS5tZXRhZGF0YS5CaW9ncmFwaHlSCWJpb2dyYXBoeRJJCg9hY3Rpdml0eV9wZXJpb2QYDSADKA'
    'syIC5zcG90aWZ5Lm1ldGFkYXRhLkFjdGl2aXR5UGVyaW9kUg5hY3Rpdml0eVBlcmlvZBI/Cgty'
    'ZXN0cmljdGlvbhgOIAMoCzIdLnNwb3RpZnkubWV0YWRhdGEuUmVzdHJpY3Rpb25SC3Jlc3RyaW'
    'N0aW9uEjIKB3JlbGF0ZWQYDyADKAsyGC5zcG90aWZ5Lm1ldGFkYXRhLkFydGlzdFIHcmVsYXRl'
    'ZBI1Chdpc19wb3J0cmFpdF9hbGJ1bV9jb3ZlchgQIAEoCFIUaXNQb3J0cmFpdEFsYnVtQ292ZX'
    'ISQwoOcG9ydHJhaXRfZ3JvdXAYESABKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkltYWdlR3JvdXBS'
    'DXBvcnRyYWl0R3JvdXASPQoLc2FsZV9wZXJpb2QYEiADKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLl'
    'NhbGVQZXJpb2RSCnNhbGVQZXJpb2QSQgoMYXZhaWxhYmlsaXR5GBQgAygLMh4uc3BvdGlmeS5t'
    'ZXRhZGF0YS5BdmFpbGFiaWxpdHlSDGF2YWlsYWJpbGl0eQ==');

@$core.Deprecated('Use albumDescriptor instead')
const Album$json = {
  '1': 'Album',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'artist',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Artist',
      '10': 'artist'
    },
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.spotify.metadata.Album.Type',
      '10': 'type'
    },
    {'1': 'label', '3': 5, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'date',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Date',
      '10': 'date'
    },
    {'1': 'popularity', '3': 7, '4': 1, '5': 17, '10': 'popularity'},
    {
      '1': 'cover',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Image',
      '10': 'cover'
    },
    {
      '1': 'external_id',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ExternalId',
      '10': 'externalId'
    },
    {
      '1': 'disc',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Disc',
      '10': 'disc'
    },
    {'1': 'review', '3': 12, '4': 3, '5': 9, '10': 'review'},
    {
      '1': 'copyright',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Copyright',
      '10': 'copyright'
    },
    {
      '1': 'restriction',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Restriction',
      '10': 'restriction'
    },
    {
      '1': 'related',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Album',
      '10': 'related'
    },
    {
      '1': 'sale_period',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.SalePeriod',
      '10': 'salePeriod'
    },
    {
      '1': 'cover_group',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'coverGroup'
    },
    {'1': 'original_title', '3': 18, '4': 1, '5': 9, '10': 'originalTitle'},
    {'1': 'version_title', '3': 19, '4': 1, '5': 9, '10': 'versionTitle'},
    {'1': 'type_str', '3': 20, '4': 1, '5': 9, '10': 'typeStr'},
    {
      '1': 'availability',
      '3': 23,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Availability',
      '10': 'availability'
    },
    {
      '1': 'prerelease_end_date',
      '3': 42,
      '4': 1,
      '5': 3,
      '10': 'prereleaseEndDate'
    },
    {
      '1': 'content_access_status',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ContentAccessStatus',
      '10': 'contentAccessStatus'
    },
  ],
  '4': [Album_Type$json],
};

@$core.Deprecated('Use albumDescriptor instead')
const Album_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'ALBUM', '2': 1},
    {'1': 'SINGLE', '2': 2},
    {'1': 'COMPILATION', '2': 3},
    {'1': 'EP', '2': 4},
    {'1': 'AUDIOBOOK', '2': 5},
    {'1': 'PODCAST', '2': 6},
  ],
};

/// Descriptor for `Album`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List albumDescriptor = $convert.base64Decode(
    'CgVBbGJ1bRIQCgNnaWQYASABKAxSA2dpZBISCgRuYW1lGAIgASgJUgRuYW1lEjAKBmFydGlzdB'
    'gDIAMoCzIYLnNwb3RpZnkubWV0YWRhdGEuQXJ0aXN0UgZhcnRpc3QSMAoEdHlwZRgEIAEoDjIc'
    'LnNwb3RpZnkubWV0YWRhdGEuQWxidW0uVHlwZVIEdHlwZRIUCgVsYWJlbBgFIAEoCVIFbGFiZW'
    'wSKgoEZGF0ZRgGIAEoCzIWLnNwb3RpZnkubWV0YWRhdGEuRGF0ZVIEZGF0ZRIeCgpwb3B1bGFy'
    'aXR5GAcgASgRUgpwb3B1bGFyaXR5Ei0KBWNvdmVyGAkgAygLMhcuc3BvdGlmeS5tZXRhZGF0YS'
    '5JbWFnZVIFY292ZXISPQoLZXh0ZXJuYWxfaWQYCiADKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkV4'
    'dGVybmFsSWRSCmV4dGVybmFsSWQSKgoEZGlzYxgLIAMoCzIWLnNwb3RpZnkubWV0YWRhdGEuRG'
    'lzY1IEZGlzYxIWCgZyZXZpZXcYDCADKAlSBnJldmlldxI5Cgljb3B5cmlnaHQYDSADKAsyGy5z'
    'cG90aWZ5Lm1ldGFkYXRhLkNvcHlyaWdodFIJY29weXJpZ2h0Ej8KC3Jlc3RyaWN0aW9uGA4gAy'
    'gLMh0uc3BvdGlmeS5tZXRhZGF0YS5SZXN0cmljdGlvblILcmVzdHJpY3Rpb24SMQoHcmVsYXRl'
    'ZBgPIAMoCzIXLnNwb3RpZnkubWV0YWRhdGEuQWxidW1SB3JlbGF0ZWQSPQoLc2FsZV9wZXJpb2'
    'QYECADKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLlNhbGVQZXJpb2RSCnNhbGVQZXJpb2QSPQoLY292'
    'ZXJfZ3JvdXAYESABKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkltYWdlR3JvdXBSCmNvdmVyR3JvdX'
    'ASJQoOb3JpZ2luYWxfdGl0bGUYEiABKAlSDW9yaWdpbmFsVGl0bGUSIwoNdmVyc2lvbl90aXRs'
    'ZRgTIAEoCVIMdmVyc2lvblRpdGxlEhkKCHR5cGVfc3RyGBQgASgJUgd0eXBlU3RyEkIKDGF2YW'
    'lsYWJpbGl0eRgXIAMoCzIeLnNwb3RpZnkubWV0YWRhdGEuQXZhaWxhYmlsaXR5UgxhdmFpbGFi'
    'aWxpdHkSLgoTcHJlcmVsZWFzZV9lbmRfZGF0ZRgqIAEoA1IRcHJlcmVsZWFzZUVuZERhdGUSWQ'
    'oVY29udGVudF9hY2Nlc3Nfc3RhdHVzGCwgASgLMiUuc3BvdGlmeS5tZXRhZGF0YS5Db250ZW50'
    'QWNjZXNzU3RhdHVzUhNjb250ZW50QWNjZXNzU3RhdHVzIlIKBFR5cGUSCQoFQUxCVU0QARIKCg'
    'ZTSU5HTEUQAhIPCgtDT01QSUxBVElPThADEgYKAkVQEAQSDQoJQVVESU9CT09LEAUSCwoHUE9E'
    'Q0FTVBAG');

@$core.Deprecated('Use trackDescriptor instead')
const Track$json = {
  '1': 'Track',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'album',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Album',
      '10': 'album'
    },
    {
      '1': 'artist',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Artist',
      '10': 'artist'
    },
    {'1': 'number', '3': 5, '4': 1, '5': 17, '10': 'number'},
    {'1': 'disc_number', '3': 6, '4': 1, '5': 17, '10': 'discNumber'},
    {'1': 'duration', '3': 7, '4': 1, '5': 17, '10': 'duration'},
    {'1': 'popularity', '3': 8, '4': 1, '5': 17, '10': 'popularity'},
    {'1': 'explicit', '3': 9, '4': 1, '5': 8, '10': 'explicit'},
    {
      '1': 'external_id',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ExternalId',
      '10': 'externalId'
    },
    {
      '1': 'restriction',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Restriction',
      '10': 'restriction'
    },
    {
      '1': 'file',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AudioFile',
      '10': 'file'
    },
    {
      '1': 'alternative',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Track',
      '10': 'alternative'
    },
    {
      '1': 'sale_period',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.SalePeriod',
      '10': 'salePeriod'
    },
    {
      '1': 'preview',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AudioFile',
      '10': 'preview'
    },
    {'1': 'tags', '3': 16, '4': 3, '5': 9, '10': 'tags'},
    {
      '1': 'earliest_live_timestamp',
      '3': 17,
      '4': 1,
      '5': 3,
      '10': 'earliestLiveTimestamp'
    },
    {'1': 'has_lyrics', '3': 18, '4': 1, '5': 8, '10': 'hasLyrics'},
    {
      '1': 'availability',
      '3': 19,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Availability',
      '10': 'availability'
    },
    {
      '1': 'licensor',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Licensor',
      '10': 'licensor'
    },
    {
      '1': 'language_of_performance',
      '3': 22,
      '4': 3,
      '5': 9,
      '10': 'languageOfPerformance'
    },
    {
      '1': 'original_audio',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Audio',
      '10': 'originalAudio'
    },
    {
      '1': 'content_rating',
      '3': 25,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ContentRating',
      '10': 'contentRating'
    },
    {'1': 'original_title', '3': 27, '4': 1, '5': 9, '10': 'originalTitle'},
    {'1': 'version_title', '3': 28, '4': 1, '5': 9, '10': 'versionTitle'},
    {
      '1': 'artist_with_role',
      '3': 32,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.ArtistWithRole',
      '10': 'artistWithRole'
    },
    {'1': 'canonical_uri', '3': 36, '4': 1, '5': 9, '10': 'canonicalUri'},
    {
      '1': 'original_video',
      '3': 38,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.Video',
      '10': 'originalVideo'
    },
    {
      '1': 'audio_formats',
      '3': 41,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.TrackAudioFormat',
      '10': 'audioFormats'
    },
    {
      '1': 'content_access_status',
      '3': 51,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ContentAccessStatus',
      '10': 'contentAccessStatus'
    },
  ],
};

/// Descriptor for `Track`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackDescriptor = $convert.base64Decode(
    'CgVUcmFjaxIQCgNnaWQYASABKAxSA2dpZBISCgRuYW1lGAIgASgJUgRuYW1lEi0KBWFsYnVtGA'
    'MgASgLMhcuc3BvdGlmeS5tZXRhZGF0YS5BbGJ1bVIFYWxidW0SMAoGYXJ0aXN0GAQgAygLMhgu'
    'c3BvdGlmeS5tZXRhZGF0YS5BcnRpc3RSBmFydGlzdBIWCgZudW1iZXIYBSABKBFSBm51bWJlch'
    'IfCgtkaXNjX251bWJlchgGIAEoEVIKZGlzY051bWJlchIaCghkdXJhdGlvbhgHIAEoEVIIZHVy'
    'YXRpb24SHgoKcG9wdWxhcml0eRgIIAEoEVIKcG9wdWxhcml0eRIaCghleHBsaWNpdBgJIAEoCF'
    'IIZXhwbGljaXQSPQoLZXh0ZXJuYWxfaWQYCiADKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkV4dGVy'
    'bmFsSWRSCmV4dGVybmFsSWQSPwoLcmVzdHJpY3Rpb24YCyADKAsyHS5zcG90aWZ5Lm1ldGFkYX'
    'RhLlJlc3RyaWN0aW9uUgtyZXN0cmljdGlvbhIvCgRmaWxlGAwgAygLMhsuc3BvdGlmeS5tZXRh'
    'ZGF0YS5BdWRpb0ZpbGVSBGZpbGUSOQoLYWx0ZXJuYXRpdmUYDSADKAsyFy5zcG90aWZ5Lm1ldG'
    'FkYXRhLlRyYWNrUgthbHRlcm5hdGl2ZRI9CgtzYWxlX3BlcmlvZBgOIAMoCzIcLnNwb3RpZnku'
    'bWV0YWRhdGEuU2FsZVBlcmlvZFIKc2FsZVBlcmlvZBI1CgdwcmV2aWV3GA8gAygLMhsuc3BvdG'
    'lmeS5tZXRhZGF0YS5BdWRpb0ZpbGVSB3ByZXZpZXcSEgoEdGFncxgQIAMoCVIEdGFncxI2Chdl'
    'YXJsaWVzdF9saXZlX3RpbWVzdGFtcBgRIAEoA1IVZWFybGllc3RMaXZlVGltZXN0YW1wEh0KCm'
    'hhc19seXJpY3MYEiABKAhSCWhhc0x5cmljcxJCCgxhdmFpbGFiaWxpdHkYEyADKAsyHi5zcG90'
    'aWZ5Lm1ldGFkYXRhLkF2YWlsYWJpbGl0eVIMYXZhaWxhYmlsaXR5EjYKCGxpY2Vuc29yGBUgAS'
    'gLMhouc3BvdGlmeS5tZXRhZGF0YS5MaWNlbnNvclIIbGljZW5zb3ISNgoXbGFuZ3VhZ2Vfb2Zf'
    'cGVyZm9ybWFuY2UYFiADKAlSFWxhbmd1YWdlT2ZQZXJmb3JtYW5jZRI+Cg5vcmlnaW5hbF9hdW'
    'RpbxgYIAEoCzIXLnNwb3RpZnkubWV0YWRhdGEuQXVkaW9SDW9yaWdpbmFsQXVkaW8SRgoOY29u'
    'dGVudF9yYXRpbmcYGSADKAsyHy5zcG90aWZ5Lm1ldGFkYXRhLkNvbnRlbnRSYXRpbmdSDWNvbn'
    'RlbnRSYXRpbmcSJQoOb3JpZ2luYWxfdGl0bGUYGyABKAlSDW9yaWdpbmFsVGl0bGUSIwoNdmVy'
    'c2lvbl90aXRsZRgcIAEoCVIMdmVyc2lvblRpdGxlEkoKEGFydGlzdF93aXRoX3JvbGUYICADKA'
    'syIC5zcG90aWZ5Lm1ldGFkYXRhLkFydGlzdFdpdGhSb2xlUg5hcnRpc3RXaXRoUm9sZRIjCg1j'
    'YW5vbmljYWxfdXJpGCQgASgJUgxjYW5vbmljYWxVcmkSPgoOb3JpZ2luYWxfdmlkZW8YJiADKA'
    'syFy5zcG90aWZ5Lm1ldGFkYXRhLlZpZGVvUg1vcmlnaW5hbFZpZGVvEkcKDWF1ZGlvX2Zvcm1h'
    'dHMYKSADKAsyIi5zcG90aWZ5Lm1ldGFkYXRhLlRyYWNrQXVkaW9Gb3JtYXRSDGF1ZGlvRm9ybW'
    'F0cxJZChVjb250ZW50X2FjY2Vzc19zdGF0dXMYMyABKAsyJS5zcG90aWZ5Lm1ldGFkYXRhLkNv'
    'bnRlbnRBY2Nlc3NTdGF0dXNSE2NvbnRlbnRBY2Nlc3NTdGF0dXM=');

@$core.Deprecated('Use showDescriptor instead')
const Show$json = {
  '1': 'Show',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 64, '4': 1, '5': 9, '10': 'description'},
    {'1': 'publisher', '3': 66, '4': 1, '5': 9, '10': 'publisher'},
    {'1': 'language', '3': 67, '4': 1, '5': 9, '10': 'language'},
    {'1': 'explicit', '3': 68, '4': 1, '5': 8, '10': 'explicit'},
    {
      '1': 'cover_image',
      '3': 69,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'coverImage'
    },
    {'1': 'keyword', '3': 73, '4': 3, '5': 9, '10': 'keyword'},
  ],
};

/// Descriptor for `Show`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showDescriptor = $convert.base64Decode(
    'CgRTaG93EhAKA2dpZBgBIAEoDFIDZ2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSIAoLZGVzY3JpcH'
    'Rpb24YQCABKAlSC2Rlc2NyaXB0aW9uEhwKCXB1Ymxpc2hlchhCIAEoCVIJcHVibGlzaGVyEhoK'
    'CGxhbmd1YWdlGEMgASgJUghsYW5ndWFnZRIaCghleHBsaWNpdBhEIAEoCFIIZXhwbGljaXQSPQ'
    'oLY292ZXJfaW1hZ2UYRSABKAsyHC5zcG90aWZ5Lm1ldGFkYXRhLkltYWdlR3JvdXBSCmNvdmVy'
    'SW1hZ2USGAoHa2V5d29yZBhJIAMoCVIHa2V5d29yZA==');

@$core.Deprecated('Use episodeDescriptor instead')
const Episode$json = {
  '1': 'Episode',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'duration', '3': 7, '4': 1, '5': 17, '10': 'duration'},
    {'1': 'description', '3': 64, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'publish_time',
      '3': 66,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Date',
      '10': 'publishTime'
    },
    {
      '1': 'cover_image',
      '3': 68,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'coverImage'
    },
    {'1': 'language', '3': 69, '4': 1, '5': 9, '10': 'language'},
    {'1': 'explicit', '3': 70, '4': 1, '5': 8, '10': 'explicit'},
    {
      '1': 'show',
      '3': 71,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.Show',
      '10': 'show'
    },
  ],
};

/// Descriptor for `Episode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List episodeDescriptor = $convert.base64Decode(
    'CgdFcGlzb2RlEhAKA2dpZBgBIAEoDFIDZ2lkEhIKBG5hbWUYAiABKAlSBG5hbWUSGgoIZHVyYX'
    'Rpb24YByABKBFSCGR1cmF0aW9uEiAKC2Rlc2NyaXB0aW9uGEAgASgJUgtkZXNjcmlwdGlvbhI5'
    'CgxwdWJsaXNoX3RpbWUYQiABKAsyFi5zcG90aWZ5Lm1ldGFkYXRhLkRhdGVSC3B1Ymxpc2hUaW'
    '1lEj0KC2NvdmVyX2ltYWdlGEQgASgLMhwuc3BvdGlmeS5tZXRhZGF0YS5JbWFnZUdyb3VwUgpj'
    'b3ZlckltYWdlEhoKCGxhbmd1YWdlGEUgASgJUghsYW5ndWFnZRIaCghleHBsaWNpdBhGIAEoCF'
    'IIZXhwbGljaXQSKgoEc2hvdxhHIAEoCzIWLnNwb3RpZnkubWV0YWRhdGEuU2hvd1IEc2hvdw==');
