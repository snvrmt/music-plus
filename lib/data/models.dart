import 'package:flutter/material.dart';

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
    required this.url,
    this.album = '',
    this.durationLabel = '',
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Cover cover;
  final String url;
  final String durationLabel;
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
