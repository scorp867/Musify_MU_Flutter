import 'dart:typed_data';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Trait decoder plugin contract for Spotify Extended Metadata extensions.
/// Direct 1:1 equivalent to Spotify Android's `p.b2w` (`ExtendedMetadataPlugin`).
abstract interface class ExtendedMetadataPlugin<T extends Trait> {
  /// The Dart Type representing the domain Trait model.
  Type get traitType;

  /// The integer value of the protobuf ExtensionKind (e.g. 97 for SIMPLE_TRAIT).
  int get extensionKindValue;

  /// The protobuf ExtensionKind enum value.
  ExtensionKind? get extensionKind;

  /// Parses binary protobuf payload bytes into the typed domain Trait.
  T parse(Uint8List payload);
}
