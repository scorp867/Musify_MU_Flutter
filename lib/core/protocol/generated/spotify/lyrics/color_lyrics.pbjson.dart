// This is a generated file - do not edit.
//
// Generated from spotify/lyrics/color_lyrics.proto.

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

@$core.Deprecated('Use colorLyricsResponseDescriptor instead')
const ColorLyricsResponse$json = {
  '1': 'ColorLyricsResponse',
  '2': [
    {
      '1': 'lyrics',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.lyrics.v2.LyricsResponse',
      '10': 'lyrics'
    },
    {
      '1': 'colors',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.lyrics.v2.ColorData',
      '10': 'colors'
    },
    {'1': 'has_vocal_removal', '3': 3, '4': 1, '5': 8, '10': 'hasVocalRemoval'},
  ],
};

/// Descriptor for `ColorLyricsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorLyricsResponseDescriptor = $convert.base64Decode(
    'ChNDb2xvckx5cmljc1Jlc3BvbnNlEjkKBmx5cmljcxgBIAEoCzIhLnNwb3RpZnkubHlyaWNzLn'
    'YyLkx5cmljc1Jlc3BvbnNlUgZseXJpY3MSNAoGY29sb3JzGAIgASgLMhwuc3BvdGlmeS5seXJp'
    'Y3MudjIuQ29sb3JEYXRhUgZjb2xvcnMSKgoRaGFzX3ZvY2FsX3JlbW92YWwYAyABKAhSD2hhc1'
    'ZvY2FsUmVtb3ZhbA==');

@$core.Deprecated('Use colorDataDescriptor instead')
const ColorData$json = {
  '1': 'ColorData',
  '2': [
    {'1': 'background', '3': 1, '4': 1, '5': 5, '10': 'background'},
    {'1': 'text', '3': 2, '4': 1, '5': 5, '10': 'text'},
    {'1': 'highlight_text', '3': 3, '4': 1, '5': 5, '10': 'highlightText'},
  ],
};

/// Descriptor for `ColorData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorDataDescriptor = $convert.base64Decode(
    'CglDb2xvckRhdGESHgoKYmFja2dyb3VuZBgBIAEoBVIKYmFja2dyb3VuZBISCgR0ZXh0GAIgAS'
    'gFUgR0ZXh0EiUKDmhpZ2hsaWdodF90ZXh0GAMgASgFUg1oaWdobGlnaHRUZXh0');

@$core.Deprecated('Use syllableDescriptor instead')
const Syllable$json = {
  '1': 'Syllable',
  '2': [
    {'1': 'start_time_ms', '3': 1, '4': 1, '5': 3, '10': 'startTimeMs'},
    {'1': 'num_chars', '3': 2, '4': 1, '5': 3, '10': 'numChars'},
  ],
};

/// Descriptor for `Syllable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syllableDescriptor = $convert.base64Decode(
    'CghTeWxsYWJsZRIiCg1zdGFydF90aW1lX21zGAEgASgDUgtzdGFydFRpbWVNcxIbCgludW1fY2'
    'hhcnMYAiABKANSCG51bUNoYXJz');

@$core.Deprecated('Use lyricsLineDescriptor instead')
const LyricsLine$json = {
  '1': 'LyricsLine',
  '2': [
    {'1': 'start_time_ms', '3': 1, '4': 1, '5': 3, '10': 'startTimeMs'},
    {'1': 'words', '3': 2, '4': 1, '5': 9, '10': 'words'},
    {
      '1': 'syllables',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.lyrics.v2.Syllable',
      '10': 'syllables'
    },
  ],
};

/// Descriptor for `LyricsLine`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lyricsLineDescriptor = $convert.base64Decode(
    'CgpMeXJpY3NMaW5lEiIKDXN0YXJ0X3RpbWVfbXMYASABKANSC3N0YXJ0VGltZU1zEhQKBXdvcm'
    'RzGAIgASgJUgV3b3JkcxI5CglzeWxsYWJsZXMYAyADKAsyGy5zcG90aWZ5Lmx5cmljcy52Mi5T'
    'eWxsYWJsZVIJc3lsbGFibGVz');

@$core.Deprecated('Use alternativeDescriptor instead')
const Alternative$json = {
  '1': 'Alternative',
  '2': [
    {'1': 'language', '3': 1, '4': 1, '5': 9, '10': 'language'},
    {'1': 'lines', '3': 2, '4': 3, '5': 9, '10': 'lines'},
    {'1': 'is_rtl_language', '3': 3, '4': 1, '5': 8, '10': 'isRtlLanguage'},
  ],
};

/// Descriptor for `Alternative`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alternativeDescriptor = $convert.base64Decode(
    'CgtBbHRlcm5hdGl2ZRIaCghsYW5ndWFnZRgBIAEoCVIIbGFuZ3VhZ2USFAoFbGluZXMYAiADKA'
    'lSBWxpbmVzEiYKD2lzX3J0bF9sYW5ndWFnZRgDIAEoCFINaXNSdGxMYW5ndWFnZQ==');

@$core.Deprecated('Use lyricsResponseDescriptor instead')
const LyricsResponse$json = {
  '1': 'LyricsResponse',
  '2': [
    {'1': 'sync_type', '3': 1, '4': 1, '5': 5, '10': 'syncType'},
    {
      '1': 'lines',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.lyrics.v2.LyricsLine',
      '10': 'lines'
    },
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {
      '1': 'provider_lyrics_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'providerLyricsId'
    },
    {
      '1': 'provider_display_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'providerDisplayName'
    },
    {'1': 'sync_lyrics_uri', '3': 7, '4': 1, '5': 9, '10': 'syncLyricsUri'},
    {
      '1': 'alternatives',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.spotify.lyrics.v2.Alternative',
      '10': 'alternatives'
    },
    {'1': 'language', '3': 10, '4': 1, '5': 9, '10': 'language'},
    {'1': 'is_rtl_language', '3': 11, '4': 1, '5': 8, '10': 'isRtlLanguage'},
    {'1': 'cap_status', '3': 14, '4': 1, '5': 5, '10': 'capStatus'},
    {
      '1': 'translation_languages',
      '3': 18,
      '4': 3,
      '5': 9,
      '10': 'translationLanguages'
    },
  ],
};

/// Descriptor for `LyricsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lyricsResponseDescriptor = $convert.base64Decode(
    'Cg5MeXJpY3NSZXNwb25zZRIbCglzeW5jX3R5cGUYASABKAVSCHN5bmNUeXBlEjMKBWxpbmVzGA'
    'IgAygLMh0uc3BvdGlmeS5seXJpY3MudjIuTHlyaWNzTGluZVIFbGluZXMSGgoIcHJvdmlkZXIY'
    'AyABKAlSCHByb3ZpZGVyEiwKEnByb3ZpZGVyX2x5cmljc19pZBgEIAEoCVIQcHJvdmlkZXJMeX'
    'JpY3NJZBIyChVwcm92aWRlcl9kaXNwbGF5X25hbWUYBSABKAlSE3Byb3ZpZGVyRGlzcGxheU5h'
    'bWUSJgoPc3luY19seXJpY3NfdXJpGAcgASgJUg1zeW5jTHlyaWNzVXJpEkIKDGFsdGVybmF0aX'
    'ZlcxgJIAMoCzIeLnNwb3RpZnkubHlyaWNzLnYyLkFsdGVybmF0aXZlUgxhbHRlcm5hdGl2ZXMS'
    'GgoIbGFuZ3VhZ2UYCiABKAlSCGxhbmd1YWdlEiYKD2lzX3J0bF9sYW5ndWFnZRgLIAEoCFINaX'
    'NSdGxMYW5ndWFnZRIdCgpjYXBfc3RhdHVzGA4gASgFUgljYXBTdGF0dXMSMwoVdHJhbnNsYXRp'
    'b25fbGFuZ3VhZ2VzGBIgAygJUhR0cmFuc2xhdGlvbkxhbmd1YWdlcw==');
