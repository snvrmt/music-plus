import 'package:flutter/material.dart';

import '../source/youtube_music.dart';

enum CoverShape { circle, half, diamond, sun }

/// Placeholder artwork from the design: a colour block with one shape.
/// Real album art (network images) replaces this in Phase 3.
class Cover {
  const Cover(this.bg, this.fg, this.shape, {this.imageUrl});
  final Color bg;
  final Color fg;
  final CoverShape shape;
  final String? imageUrl;
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    this.url = '',
    this.videoId,
    this.album = '',
    this.durationLabel = '',
    this.isVideo = false,
  });

  /// A song found on YouTube Music / YouTube.
  factory Track.fromYt(YtResult r) {
    final palette = _palettes[r.videoId.hashCode.abs() % _palettes.length];
    return Track(
      id: 'yt:${r.videoId}',
      videoId: r.videoId,
      title: r.title,
      artist: r.artist,
      album: r.album,
      durationLabel: r.durationLabel,
      isVideo: r.isVideo,
      cover: Cover(palette.$1, palette.$2, CoverShape.values[r.videoId.length % 4],
          imageUrl: r.thumbnailUrl),
    );
  }

  static const _palettes = [
    (Color(0xFF1E1B4B), Color(0xFF818CF8)),
    (Color(0xFF7C2D12), Color(0xFFFDBA74)),
    (Color(0xFF064E3B), Color(0xFF6EE7B7)),
    (Color(0xFF9D174D), Color(0xFFFBCFE8)),
    (Color(0xFFB45309), Color(0xFFFEF3C7)),
    (Color(0xFF0E7490), Color(0xFF67E8F9)),
  ];

  final String id;
  final String title;
  final String artist;
  final String album;
  final Cover cover;

  /// Direct audio URL (demo tracks). YouTube tracks resolve theirs at play time.
  final String url;
  final String? videoId;
  final String durationLabel;
  final bool isVideo;
}

class Playlist {
  const Playlist({
    required this.id,
    required this.title,
    required this.cover,
    required this.tracks,
    this.subtitle = 'Playlist',
  });

  final String id;
  final String title;
  final String subtitle;
  final Cover cover;
  final List<Track> tracks;
}
