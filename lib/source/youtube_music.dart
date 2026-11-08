// YouTube Music source layer. Pure Dart (no Flutter imports) so it can be
// smoke-tested on a plain Linux runner. Everything YouTube-specific lives
// here: when YouTube changes something, this is the only file to fix.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YtResult {
  const YtResult({
    required this.videoId,
    required this.title,
    required this.artist,
    this.album = '',
    this.durationLabel = '',
    this.thumbnailUrl,
    this.isVideo = false,
  });

  final String videoId;
  final String title;
  final String artist;
  final String album;
  final String durationLabel;
  final String? thumbnailUrl;
  final bool isVideo;

  @override
  String toString() =>
      '$title — $artist${album.isEmpty ? '' : ' ($album)'} [$durationLabel] $videoId';
}

class YouTubeMusic {
  YouTubeMusic({http.Client? client}) : _http = client ?? http.Client();

  static final YouTubeMusic I = YouTubeMusic();

  final http.Client _http;
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, (Uri, DateTime)> _urlCache = {};

  static const _endpoint = 'https://music.youtube.com/youtubei/v1/search?prettyPrint=false';
  static const _clientVersion = '1.20241106.01.00';

  /// "Songs" filter used by YouTube Music's own search page.
  static const _songsParams = 'EgWKAQIIAWoKEAkQBRAKEAMQBA==';

  static const _headers = {
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    'X-YouTube-Client-Name': '67',
    'X-YouTube-Client-Version': _clientVersion,
  };

  /// Search YouTube Music for songs.
  Future<List<YtResult>> searchSongs(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    var results = await _innertubeSearch(q, params: _songsParams);
    if (results.isEmpty) results = await _innertubeSearch(q);
    return results;
  }

  Future<List<YtResult>> _innertubeSearch(String q, {String? params}) async {
    final body = {
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': _clientVersion,
          'hl': 'en',
          'gl': 'US',
        },
      },
      'query': q,
      if (params != null) 'params': params,
    };
    final res = await _http.post(Uri.parse(_endpoint),
        headers: _headers, body: jsonEncode(body));
    if (res.statusCode != 200) {
      throw Exception('YouTube Music search failed (${res.statusCode})');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    final out = <YtResult>[];
    final seen = <String>{};
    for (final r in _findAll(json, 'musicResponsiveListItemRenderer')) {
      final item = _parseItem(r);
      if (item != null && seen.add(item.videoId)) out.add(item);
    }
    return out;
  }

  /// Search all of YouTube (videos). Only the audio is played.
  Future<List<YtResult>> searchVideos(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final list = await _yt.search.search(q);
    return [
      for (final v in list)
        YtResult(
          videoId: v.id.value,
          title: v.title,
          artist: v.author,
          durationLabel: _fmt(v.duration),
          thumbnailUrl: v.thumbnails.highResUrl,
          isVideo: true,
        )
    ];
  }

  /// Resolve a playable audio-only stream URL (AAC/M4A when available,
  /// since iOS plays that natively). URLs expire, so they are cached briefly.
  Future<Uri> audioUrl(String videoId) async {
    final cached = _urlCache[videoId];
    if (cached != null && DateTime.now().difference(cached.$2) < const Duration(hours: 3)) {
      return cached.$1;
    }
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr],
    );
    final audio = manifest.audioOnly;
    if (audio.isEmpty) throw Exception('No audio stream for $videoId');
    final mp4 = audio.where((s) => s.container == StreamContainer.mp4).toList();
    final best = (mp4.isNotEmpty ? mp4 : audio.toList())
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    final url = best.first.url;
    _urlCache[videoId] = (url, DateTime.now());
    return url;
  }

  void dispose() {
    _yt.close();
    _http.close();
  }

  // ---- parsing helpers ----

  static YtResult? _parseItem(Map r) {
    final videoId = (r['playlistItemData'] as Map?)?['videoId'] as String? ??
        _firstValue(r, 'watchEndpoint', 'videoId');
    if (videoId == null) return null;

    final cols = (r['flexColumns'] as List?) ?? const [];
    String colText(int i) {
      if (i >= cols.length) return '';
      final runs = (((cols[i] as Map)['musicResponsiveListItemFlexColumnRenderer']
              as Map?)?['text'] as Map?)?['runs'] as List?;
      return runs == null ? '' : runs.map((e) => (e as Map)['text'] ?? '').join();
    }

    final title = colText(0);
    if (title.isEmpty) return null;

    var parts = colText(1).split(' • ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    var isVideo = false;
    const kinds = {'Song', 'Video', 'Episode', 'Single', 'EP', 'Podcast'};
    if (parts.isNotEmpty && kinds.contains(parts.first)) {
      isVideo = parts.first == 'Video';
      parts = parts.sublist(1);
    }
    final durRe = RegExp(r'^\d{1,2}(:\d{2}){1,2}$');
    var duration = '';
    if (parts.isNotEmpty && durRe.hasMatch(parts.last)) {
      duration = parts.removeLast();
    }
    if (duration.isEmpty) {
      final fixed = _firstValue(r, 'musicResponsiveListItemFixedColumnRenderer', 'text');
      if (fixed is Map) {
        final runs = fixed['runs'] as List?;
        final t = runs == null ? '' : runs.map((e) => (e as Map)['text'] ?? '').join();
        if (durRe.hasMatch(t)) duration = t;
      }
    }
    parts.removeWhere((p) => p.contains(' views') || p.contains(' plays'));
    final artist = parts.isNotEmpty ? parts.first : '';
    final album = parts.length > 1 ? parts[1] : '';

    String? thumb;
    final thumbs = ((((r['thumbnail'] as Map?)?['musicThumbnailRenderer'] as Map?)?['thumbnail']
        as Map?)?['thumbnails']) as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      thumb = (thumbs.last as Map)['url'] as String?;
      if (thumb != null) {
        thumb = thumb.replaceAll(RegExp(r'=w\d+-h\d+'), '=w544-h544');
      }
    }

    return YtResult(
      videoId: videoId,
      title: title,
      artist: artist,
      album: album,
      durationLabel: duration,
      thumbnailUrl: thumb,
      isVideo: isVideo,
    );
  }

  /// All maps stored under [key] anywhere inside [node].
  static Iterable<Map> _findAll(dynamic node, String key) sync* {
    if (node is Map) {
      for (final e in node.entries) {
        if (e.key == key && e.value is Map) {
          yield e.value as Map;
        } else {
          yield* _findAll(e.value, key);
        }
      }
    } else if (node is List) {
      for (final v in node) {
        yield* _findAll(v, key);
      }
    }
  }

  /// First `node[...][outer][inner]` found anywhere inside [node].
  static dynamic _firstValue(dynamic node, String outer, String inner) {
    for (final m in _findAll(node, outer)) {
      if (m[inner] != null) return m[inner];
    }
    return null;
  }

  static String _fmt(Duration? d) {
    if (d == null) return '';
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:$s';
    }
    return '${d.inMinutes}:$s';
  }
}
