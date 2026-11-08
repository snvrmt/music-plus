import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../source/mp4_defrag.dart';
import '../source/youtube_music.dart';

/// Downloads YouTube audio to the phone, converts YouTube's fragmented
/// MP4 into a normal one (the iPhone player stops after the first ~10 s
/// fragment otherwise) and keeps it, so replays and offline play are free.
class AudioCache {
  AudioCache._();
  static final AudioCache I = AudioCache._();

  final Map<String, Future<File>> _inflight = {};
  Directory? _dir;

  Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/audio');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  /// The saved file for [videoId], if it's already on the phone.
  Future<File?> cached(String videoId) async {
    final dir = await _folder();
    for (final ext in const ['m4a', 'mp4']) {
      final f = File('${dir.path}/$videoId.$ext');
      if (await f.exists()) return f;
    }
    return null;
  }

  bool isFetching(String videoId) => _inflight.containsKey(videoId);

  /// The saved file for [videoId], downloading it first if needed.
  Future<File> get(String videoId) {
    return _inflight[videoId] ??=
        _fetch(videoId).whenComplete(() => _inflight.remove(videoId));
  }

  Future<File> _fetch(String videoId) async {
    final existing = await cached(videoId);
    if (existing != null) return existing;

    final stream = await YouTubeMusic.I.resolve(videoId);
    final buf = BytesBuilder(copy: false);
    await for (final chunk in YouTubeMusic.I.download(stream)) {
      buf.add(chunk);
    }
    Uint8List bytes = buf.takeBytes();
    if (bytes.length < stream.length) {
      throw Exception('Download stopped early (${bytes.length}/${stream.length} bytes)');
    }

    final audioOnly = stream.mimeType == 'audio/mp4';
    if (audioOnly) {
      final input = bytes;
      final fixed = await Isolate.run(() => defragmentMp4(input));
      if (fixed != null) bytes = fixed;
    }

    final dir = await _folder();
    final path = '${dir.path}/$videoId.${audioOnly ? 'm4a' : 'mp4'}';
    final tmp = File('$path.part');
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.rename(path);
  }
}
