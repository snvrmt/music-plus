// Run on CI: checks YouTube Music search and stream resolution end to end.
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:music_player/source/youtube_music.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main(List<String> args) async {
  final query = args.isEmpty ? 'Daft Punk Get Lucky' : args.join(' ');
  final yt = YouTubeMusic();
  var failed = false;

  stdout.writeln('== Songs search: "$query"');
  final songs = await yt.searchSongs(query);
  for (final s in songs.take(8)) {
    stdout.writeln('  $s\n     thumb: ${s.thumbnailUrl}');
  }
  if (songs.isEmpty) failed = true;

  stdout.writeln('== Video search');
  try {
    final vids = await yt.searchVideos(query);
    for (final v in vids.take(3)) {
      stdout.writeln('  $v');
    }
  } catch (e) {
    stdout.writeln('  video search error: $e');
    failed = true;
  }

  final ids = [if (songs.isNotEmpty) songs.first.videoId, 'Rgrt_8mXrK8', '5NV6Rdv1a3I'];
  final combos = <String, List<YoutubeApiClient>?>{
    'androidVr': [YoutubeApiClient.androidVr],
    'safari': [YoutubeApiClient.safari],
    'tv': [YoutubeApiClient.tv],
    'mweb': [YoutubeApiClient.mweb],
    'android': [YoutubeApiClient.android],
  };
  for (final id in ids) {
    for (final e in combos.entries) {
      try {
        final url = await YouTubeMusic().audioUrl(id, using: e.value);
        final res = await http.get(url, headers: {'Range': 'bytes=0-1023'});
        stdout.writeln('  $id ${e.key}: OK itag=${url.queryParameters['itag']} range=${res.statusCode}');
      } catch (err) {
        stdout.writeln('  $id ${e.key}: FAIL ${err.toString().split('\n').first}');
      }
    }
  }

  if (songs.isNotEmpty) {
    stdout.writeln('== Stream for ${songs.first.videoId}');
    try {
      final url = await yt.audioUrl(songs.first.videoId);
      stdout.writeln('  url host: ${url.host}  itag: ${url.queryParameters['itag']}  mime: ${url.queryParameters['mime']}');
      final res = await http.get(url, headers: {'Range': 'bytes=0-1023'});
      stdout.writeln('  range GET -> ${res.statusCode}, ${res.bodyBytes.length} bytes, ${res.headers['content-type']}');
      if (res.statusCode != 206 && res.statusCode != 200) failed = true;
    } catch (e) {
      stdout.writeln('  stream error: $e');
      failed = true;
    }
  }
  yt.dispose();
  exit(failed ? 1 : 0);
}
