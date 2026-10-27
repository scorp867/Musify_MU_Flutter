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

@$core.Deprecated('Use artistDescriptor instead')
const Artist$json = {
  '1': 'Artist',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 12, '10': 'gid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'popularity', '3': 3, '4': 1, '5': 17, '10': 'popularity'},
    {
      '1': 'portrait_group',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'portraitGroup'
    },
  ],
};

/// Descriptor for `Artist`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artistDescriptor = $convert.base64Decode(
    'CgZBcnRpc3QSEAoDZ2lkGAEgASgMUgNnaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIeCgpwb3B1bG'
    'FyaXR5GAMgASgRUgpwb3B1bGFyaXR5EkMKDnBvcnRyYWl0X2dyb3VwGBEgASgLMhwuc3BvdGlm'
    'eS5tZXRhZGF0YS5JbWFnZUdyb3VwUg1wb3J0cmFpdEdyb3Vw');

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
      '1': 'cover_group',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.metadata.ImageGroup',
      '10': 'coverGroup'
    },
    {'1': 'type_str', '3': 20, '4': 1, '5': 9, '10': 'typeStr'},
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
    'aXR5GAcgASgRUgpwb3B1bGFyaXR5Ej0KC2NvdmVyX2dyb3VwGBEgASgLMhwuc3BvdGlmeS5tZX'
    'RhZGF0YS5JbWFnZUdyb3VwUgpjb3Zlckdyb3VwEhkKCHR5cGVfc3RyGBQgASgJUgd0eXBlU3Ry'
    'IlIKBFR5cGUSCQoFQUxCVU0QARIKCgZTSU5HTEUQAhIPCgtDT01QSUxBVElPThADEgYKAkVQEA'
    'QSDQoJQVVESU9CT09LEAUSCwoHUE9EQ0FTVBAG');

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
    {'1': 'MP4_128', '2': 8},
    {'1': 'MP4_192', '2': 9},
    {'1': 'MP4_256', '2': 10},
    {'1': 'MP4_320', '2': 11},
    {'1': 'MP4_96', '2': 12},
    {'1': 'MP4_BAM', '2': 13},
    {'1': 'FLAC_FLAC', '2': 16},
    {'1': 'XHE_AAC_24', '2': 22},
  ],
};

/// Descriptor for `AudioFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioFileDescriptor = $convert.base64Decode(
    'CglBdWRpb0ZpbGUSFwoHZmlsZV9pZBgBIAEoDFIGZmlsZUlkEjoKBmZvcm1hdBgCIAEoDjIiLn'
    'Nwb3RpZnkubWV0YWRhdGEuQXVkaW9GaWxlLkZvcm1hdFIGZm9ybWF0IvMBCgZGb3JtYXQSEQoN'
    'T0dHX1ZPUkJJU185NhAAEhIKDk9HR19WT1JCSVNfMTYwEAESEgoOT0dHX1ZPUkJJU18zMjAQAh'
    'ILCgdNUDNfMjU2EAMSCwoHTVAzXzMyMBAEEgsKB01QM18xNjAQBRIKCgZNUDNfOTYQBhIPCgtN'
    'UDNfMTYwX0VOQxAHEgsKB01QNF8xMjgQCBILCgdNUDRfMTkyEAkSCwoHTVA0XzI1NhAKEgsKB0'
    '1QNF8zMjAQCxIKCgZNUDRfOTYQDBILCgdNUDRfQkFNEA0SDQoJRkxBQ19GTEFDEBASDgoKWEhF'
    'X0FBQ18yNBAW');

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
      '1': 'file',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AudioFile',
      '10': 'file'
    },
    {
      '1': 'preview',
      '3': 17,
      '4': 3,
      '5': 11,
      '6': '.spotify.metadata.AudioFile',
      '10': 'preview'
    },
    {'1': 'canonical_uri', '3': 36, '4': 1, '5': 9, '10': 'canonicalUri'},
  ],
};

/// Descriptor for `Track`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackDescriptor = $convert.base64Decode(
    'CgVUcmFjaxIQCgNnaWQYASABKAxSA2dpZBISCgRuYW1lGAIgASgJUgRuYW1lEi0KBWFsYnVtGA'
    'MgASgLMhcuc3BvdGlmeS5tZXRhZGF0YS5BbGJ1bVIFYWxidW0SMAoGYXJ0aXN0GAQgAygLMhgu'
    'c3BvdGlmeS5tZXRhZGF0YS5BcnRpc3RSBmFydGlzdBIWCgZudW1iZXIYBSABKBFSBm51bWJlch'
    'IfCgtkaXNjX251bWJlchgGIAEoEVIKZGlzY051bWJlchIaCghkdXJhdGlvbhgHIAEoEVIIZHVy'
    'YXRpb24SHgoKcG9wdWxhcml0eRgIIAEoEVIKcG9wdWxhcml0eRIaCghleHBsaWNpdBgJIAEoCF'
    'IIZXhwbGljaXQSLwoEZmlsZRgOIAMoCzIbLnNwb3RpZnkubWV0YWRhdGEuQXVkaW9GaWxlUgRm'
    'aWxlEjUKB3ByZXZpZXcYESADKAsyGy5zcG90aWZ5Lm1ldGFkYXRhLkF1ZGlvRmlsZVIHcHJldm'
    'lldxIjCg1jYW5vbmljYWxfdXJpGCQgASgJUgxjYW5vbmljYWxVcmk=');

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

@$core.Deprecated('Use dateDescriptor instead')
const Date$json = {
  '1': 'Date',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 17, '10': 'year'},
    {'1': 'month', '3': 2, '4': 1, '5': 17, '10': 'month'},
    {'1': 'day', '3': 3, '4': 1, '5': 17, '10': 'day'},
  ],
};

/// Descriptor for `Date`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateDescriptor = $convert.base64Decode(
    'CgREYXRlEhIKBHllYXIYASABKBFSBHllYXISFAoFbW9udGgYAiABKBFSBW1vbnRoEhAKA2RheR'
    'gDIAEoEVIDZGF5');

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
