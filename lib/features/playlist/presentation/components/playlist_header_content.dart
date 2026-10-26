library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_metadata.dart';

/// 1:1 replica of Spotify's playlist image header content (`image_header_content.xml`, `lr40.java`, `kp71.java`).
/// Displays centered album art with soft drop-shadow, bold typography, owner avatar, and metadata telemetry line.
class PlaylistHeaderContent extends StatelessWidget {
  final PlaylistMetadata metadata;
  final int trackCount;

  const PlaylistHeaderContent({
    super.key,
    required this.metadata,
    required this.trackCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Centered Album Art / Mosaic with Encore Elevation & Shadow
          Center(
            child: Container(
              width: 216,
              height: 216,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: metadata.picture.isNotEmpty
                  ? Image.network(
                      metadata.picture,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Playlist Title (Encore Headline / TitleMedium, 24sp, Extra Bold)
          Text(
            metadata.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),

          // 3. Playlist Description (Encore BodySmall, 13sp subdued)
          if (metadata.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              metadata.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: -0.1,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // 4. Creator / Owner Avatar and Name Row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF333333),
                ),
                clipBehavior: Clip.antiAlias,
                child: metadata.ownerAvatarUrl.isNotEmpty
                    ? Image.network(
                        metadata.ownerAvatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person,
                          size: 15,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 15,
                        color: Colors.white70,
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                metadata.ownerName.isNotEmpty
                    ? metadata.ownerName
                    : (metadata.ownerUsername.isNotEmpty
                        ? metadata.ownerUsername
                        : 'Spotify'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 5. Metadata Telemetry Line (saves • songs, duration)
          Text(
            _buildTelemetryString(),
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return const Center(
      child: Icon(
        Icons.music_note,
        size: 72,
        color: Color(0xFF535353),
      ),
    );
  }

  String _buildTelemetryString() {
    final parts = <String>[];

    if (metadata.followersCount > 0) {
      parts.add('${_formatCount(metadata.followersCount)} saves');
    }

    final songsPart = '$trackCount ${trackCount == 1 ? 'song' : 'songs'}';
    if (metadata.totalDurationMs > 0) {
      final durationStr = _formatDuration(metadata.totalDurationMs);
      parts.add('$songsPart, $durationStr');
    } else if (trackCount > 0) {
      parts.add(songsPart);
    }

    return parts.join(' • ');
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      final val = (count / 1000000).toStringAsFixed(1);
      return val.endsWith('.0') ? '${val.substring(0, val.length - 2)}M' : '${val}M';
    }
    if (count >= 1000) {
      final val = (count / 1000).toStringAsFixed(1);
      return val.endsWith('.0') ? '${val.substring(0, val.length - 2)}K' : '${val}K';
    }
    return count.toString();
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }
}
