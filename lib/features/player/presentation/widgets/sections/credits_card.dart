import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/credits_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';

/// Spotify-identical Track Credits card (`ScrollCardType.TRACK_CREDITS`).
///
/// 1:1 replica of decompiled Spotify Android layout (`w5i.java` + `fhb1.java`).
///
/// Features:
/// - 16dp rounded corners
/// - Surface color #242424
/// - Header: "Credits" on left, "Show all" in Spotify Green (#1DB954) on right
/// - Contributor rows with artist name, combined roles ("Main Artist • Composer"),
///   and native "Follow" stadium button.
class PlayerCreditsSection extends StatefulWidget {
  const PlayerCreditsSection({
    super.key,
    required this.item,
    this.dataPool,
    this.trackUri,
    this.contributorUris = const [],
    this.onShowAll,
  });

  final MediaItem item;
  final DataPool? dataPool;
  final String? trackUri;
  final List<String> contributorUris;
  final VoidCallback? onShowAll;

  @override
  State<PlayerCreditsSection> createState() => _PlayerCreditsSectionState();
}

class _PlayerCreditsSectionState extends State<PlayerCreditsSection> {
  final Set<String> _followingContributors = {};

  @override
  Widget build(BuildContext context) {
    final contributors = _resolveContributors();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Credits" + "Show all" in Spotify Green
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Credits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onShowAll,
                child: const Text(
                  'Show all',
                  style: TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < contributors.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildContributorRow(contributors[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildContributorRow(_ContributorData contributor) {
    final isFollowing = _followingContributors.contains(contributor.name);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contributor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                contributor.roles,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () {
            setState(() {
              if (isFollowing) {
                _followingContributors.remove(contributor.name);
              } else {
                _followingContributors.add(contributor.name);
              }
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: isFollowing ? const Color(0xFF1DB954) : Colors.white54,
              width: 1.0,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              color: isFollowing ? const Color(0xFF1DB954) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  List<_ContributorData> _resolveContributors() {
    final list = <_ContributorData>[];

    // 1. Try CreditsTrait from DataPool (provides real names + roles)
    if (widget.dataPool != null && widget.trackUri != null) {
      final credits =
          widget.dataPool!.getTrait<CreditsTrait>(widget.trackUri!);
      if (credits != null && credits.contributors.isNotEmpty) {
        // Group contributors by name so we can combine their roles
        final byName = <String, List<String>>{};
        final uriByName = <String, String>{};
        for (final c in credits.contributors) {
          if (c.name.isEmpty) continue;
          byName.putIfAbsent(c.name, () => []);
          if (c.role.isNotEmpty) {
            byName[c.name]!.add(c.role);
          }
          if (c.uri.isNotEmpty) {
            uriByName.putIfAbsent(c.name, () => c.uri);
          }
        }
        for (final entry in byName.entries) {
          final roles =
              entry.value.isNotEmpty ? entry.value.join(' \u2022 ') : 'Artist';
          list.add(_ContributorData(
            name: entry.key,
            roles: roles,
            uri: uriByName[entry.key],
          ));
        }
      }
    }

    if (list.isNotEmpty) return list;

    // 2. Fallback: resolve from DataPool using contributor URIs + IdentityTrait
    if (widget.dataPool != null && widget.contributorUris.isNotEmpty) {
      for (final uri in widget.contributorUris) {
        final identity = widget.dataPool!.getTrait<IdentityTrait>(uri);
        if (identity != null && identity.name.isNotEmpty) {
          list.add(_ContributorData(
            name: identity.name,
            roles: 'Artist',
            uri: uri,
          ));
        }
      }
    }

    if (list.isNotEmpty) return list;

    // 3. Last resort: parse from MediaItem.artist
    final rawArtists = widget.item.artist;
    if (rawArtists != null && rawArtists.isNotEmpty) {
      final names = rawArtists
          .split(RegExp(r',\s*|\s*&\s*|\s+feat\.\s+|\s+ft\.\s+'))
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();

      for (final name in names) {
        list.add(_ContributorData(name: name, roles: 'Artist'));
      }
    }

    if (list.isEmpty) {
      list.add(const _ContributorData(name: 'Artist', roles: 'Artist'));
    }

    return list;
  }
}

class _ContributorData {
  final String name;
  final String roles;
  final String? uri;

  const _ContributorData({
    required this.name,
    required this.roles,
    this.uri,
  });
}
