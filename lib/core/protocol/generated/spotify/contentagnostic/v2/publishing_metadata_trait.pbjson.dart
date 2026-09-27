// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/publishing_metadata_trait.proto.

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

@$core.Deprecated('Use publishingMetadataTraitDescriptor instead')
const PublishingMetadataTrait$json = {
  '1': 'PublishingMetadataTrait',
  '2': [
    {
      '1': 'first_published_at',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.TimestampOfVaryingGranularity',
      '10': 'firstPublishedAt'
    },
    {
      '1': 'published_on_spotify_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'publishedOnSpotifyAt'
    },
    {
      '1': 'last_modified_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastModifiedAt'
    },
    {
      '1': 'copyright_information',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.CopyrightInformation',
      '10': 'copyrightInformation'
    },
  ],
};

/// Descriptor for `PublishingMetadataTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishingMetadataTraitDescriptor = $convert.base64Decode(
    'ChdQdWJsaXNoaW5nTWV0YWRhdGFUcmFpdBJnChJmaXJzdF9wdWJsaXNoZWRfYXQYASABKAsyOS'
    '5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5UaW1lc3RhbXBPZlZhcnlpbmdHcmFudWxhcml0'
    'eVIQZmlyc3RQdWJsaXNoZWRBdBJRChdwdWJsaXNoZWRfb25fc3BvdGlmeV9hdBgCIAEoCzIaLm'
    'dvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFHB1Ymxpc2hlZE9uU3BvdGlmeUF0EkQKEGxhc3Rf'
    'bW9kaWZpZWRfYXQYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg5sYXN0TW9kaW'
    'ZpZWRBdBJlChVjb3B5cmlnaHRfaW5mb3JtYXRpb24YBCADKAsyMC5zcG90aWZ5LmNvbnRlbnRh'
    'Z25vc3RpYy52Mi5Db3B5cmlnaHRJbmZvcm1hdGlvblIUY29weXJpZ2h0SW5mb3JtYXRpb24=');

@$core.Deprecated('Use timestampOfVaryingGranularityDescriptor instead')
const TimestampOfVaryingGranularity$json = {
  '1': 'TimestampOfVaryingGranularity',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 5, '10': 'year'},
    {
      '1': 'year_and_month',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.YearAndMonth',
      '10': 'yearAndMonth'
    },
    {
      '1': 'year_month_and_day',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.YearMonthAndDay',
      '10': 'yearMonthAndDay'
    },
  ],
};

/// Descriptor for `TimestampOfVaryingGranularity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timestampOfVaryingGranularityDescriptor = $convert.base64Decode(
    'Ch1UaW1lc3RhbXBPZlZhcnlpbmdHcmFudWxhcml0eRISCgR5ZWFyGAEgASgFUgR5ZWFyEk4KDn'
    'llYXJfYW5kX21vbnRoGAIgASgLMiguc3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuWWVhckFu'
    'ZE1vbnRoUgx5ZWFyQW5kTW9udGgSWAoSeWVhcl9tb250aF9hbmRfZGF5GAMgASgLMisuc3BvdG'
    'lmeS5jb250ZW50YWdub3N0aWMudjIuWWVhck1vbnRoQW5kRGF5Ug95ZWFyTW9udGhBbmREYXk=');

@$core.Deprecated('Use yearAndMonthDescriptor instead')
const YearAndMonth$json = {
  '1': 'YearAndMonth',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 5, '10': 'year'},
    {'1': 'month', '3': 2, '4': 1, '5': 5, '10': 'month'},
  ],
};

/// Descriptor for `YearAndMonth`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List yearAndMonthDescriptor = $convert.base64Decode(
    'CgxZZWFyQW5kTW9udGgSEgoEeWVhchgBIAEoBVIEeWVhchIUCgVtb250aBgCIAEoBVIFbW9udG'
    'g=');

@$core.Deprecated('Use yearMonthAndDayDescriptor instead')
const YearMonthAndDay$json = {
  '1': 'YearMonthAndDay',
  '2': [
    {'1': 'year', '3': 1, '4': 1, '5': 5, '10': 'year'},
    {'1': 'month', '3': 2, '4': 1, '5': 5, '10': 'month'},
    {'1': 'day', '3': 3, '4': 1, '5': 5, '10': 'day'},
  ],
};

/// Descriptor for `YearMonthAndDay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List yearMonthAndDayDescriptor = $convert.base64Decode(
    'Cg9ZZWFyTW9udGhBbmREYXkSEgoEeWVhchgBIAEoBVIEeWVhchIUCgVtb250aBgCIAEoBVIFbW'
    '9udGgSEAoDZGF5GAMgASgFUgNkYXk=');

@$core.Deprecated('Use copyrightInformationDescriptor instead')
const CopyrightInformation$json = {
  '1': 'CopyrightInformation',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `CopyrightInformation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copyrightInformationDescriptor = $convert.base64Decode(
    'ChRDb3B5cmlnaHRJbmZvcm1hdGlvbhISCgR0eXBlGAEgASgJUgR0eXBlEhIKBHRleHQYAiABKA'
    'lSBHRleHQ=');
