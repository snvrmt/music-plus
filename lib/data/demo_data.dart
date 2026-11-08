import 'package:flutter/material.dart';

import 'models.dart';

/// Demo library so the UI and the player work before YouTube Music is wired
/// in (Phase 3). The audio files are free SoundHelix test tracks.
String _helix(int n) =>
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$n.mp3';

const _indigo = Cover(Color(0xFF1E1B4B), Color(0xFF818CF8), CoverShape.circle);

Track _t(String id, String title, String artist, Cover cover, int n,
        String dur, {String album = ''}) =>
    Track(
      id: id,
      title: title,
      artist: artist,
      album: album.isEmpty ? title : album,
      cover: cover,
      url: _helix(n),
      durationLabel: dur,
    );

final slowTide = _t('slow-tide', 'Slow Tide', 'Marlo Vane', _indigo, 1, '3:06');
final goldenHour = _t('golden-hour', 'Golden Hour', 'The Lowlands',
    const Cover(Color(0xFFB45309), Color(0xFFFEF3C7), CoverShape.sun), 2, '3:41');
final midnightDrive = _t('midnight-drive', 'Midnight Drive', 'Kite & Ember',
    const Cover(Color(0xFF7C2D12), Color(0xFFFDBA74), CoverShape.half), 3, '4:02');
final paperPlanes = _t('paper-planes', 'Paper Planes', 'Orla Finch',
    const Cover(Color(0xFF064E3B), Color(0xFF6EE7B7), CoverShape.diamond), 4, '3:18');
final staticBloom = _t('static-bloom', 'Static Bloom', 'Juno Hale',
    const Cover(Color(0xFF9D174D), Color(0xFFFBCFE8), CoverShape.circle), 5, '3:55');
final neonHarbour = _t('neon-harbour', 'Neon Harbour', 'Kite & Ember',
    const Cover(Color(0xFF581C87), Color(0xFFD8B4FE), CoverShape.diamond), 6, '4:20');
final quietHours = _t('quiet-hours', 'Quiet Hours', 'Aster',
    const Cover(Color(0xFF0E7490), Color(0xFF67E8F9), CoverShape.sun), 7, '2:58');
final lowLight = _t('low-light', 'Low Light', 'Aster',
    const Cover(Color(0xFF1F2937), Color(0xFF9CA3AF), CoverShape.half), 8, '3:33');
final harbourLights = _t('harbour-lights', 'Harbour Lights', 'Marlo Vane',
    _indigo, 9, '3:22', album: 'Slow Tide');
final undertow =
    _t('undertow', 'Undertow', 'Marlo Vane', _indigo, 10, '3:47', album: 'Slow Tide');

final allTracks = <Track>[
  slowTide, goldenHour, midnightDrive, paperPlanes, staticBloom,
  neonHarbour, quietHours, lowLight, harbourLights, undertow,
];

final recentlyPlayed = <Track>[
  goldenHour, staticBloom, lowLight, paperPlanes, midnightDrive,
];

final playlists = <Playlist>[
  Playlist(
    id: 'morning-run',
    title: 'Morning Run',
    cover: const Cover(Color(0xFF7C2D12), Color(0xFFFDBA74), CoverShape.half),
    tracks: [goldenHour, midnightDrive, paperPlanes, staticBloom, neonHarbour, quietHours],
  ),
  Playlist(
    id: 'late-night',
    title: 'Late Night',
    cover: _indigo,
    tracks: [slowTide, lowLight, neonHarbour, harbourLights, undertow],
  ),
  Playlist(
    id: 'focus-flow',
    title: 'Focus Flow',
    cover: const Cover(Color(0xFF064E3B), Color(0xFF6EE7B7), CoverShape.diamond),
    tracks: [quietHours, paperPlanes, lowLight, goldenHour],
  ),
  Playlist(
    id: 'road-trip',
    title: 'Road Trip',
    cover: const Cover(Color(0xFFB45309), Color(0xFFFEF3C7), CoverShape.sun),
    tracks: [midnightDrive, staticBloom, slowTide, goldenHour, neonHarbour],
  ),
];

/// Placeholder lyrics shown until LRCLIB is wired in (Phase 5).
const demoLyrics = [
  'Salt in the air and the evening low',
  'Counting the waves that I used to know',
  'You said the water would carry us home',
  'Slow tide, slow tide, I’m not alone',
  'Lights on the pier going one by one',
  'Holding the last of a golden sun',
];
