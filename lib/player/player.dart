import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models.dart';

/// One app-wide player. Wraps just_audio; just_audio_background adds
/// background playback plus lock-screen / Control Center controls.
class Player extends ChangeNotifier {
  Player._() {
    audio.playerStateStream.listen((_) => notifyListeners());
    audio.currentIndexStream.listen((i) {
      index = i ?? -1;
      notifyListeners();
    });
    audio.shuffleModeEnabledStream.listen((_) => notifyListeners());
    audio.loopModeStream.listen((_) => notifyListeners());
    audio.sequenceStateStream.listen((_) => notifyListeners());
  }

  static final Player I = Player._();

  final AudioPlayer audio = AudioPlayer();
  final List<Track> queue = [];
  int index = -1;
  String fromLabel = '';

  Track? get current =>
      (index >= 0 && index < queue.length) ? queue[index] : null;
  bool get playing => audio.playing;
  bool get shuffle => audio.shuffleModeEnabled;
  LoopMode get loop => audio.loopMode;
  bool get loading {
    final s = audio.processingState;
    return s == ProcessingState.loading || s == ProcessingState.buffering;
  }

  /// Tracks that will play after the current one, in play order.
  List<Track> get upNext {
    if (current == null) return const [];
    final order = audio.effectiveIndices ?? List.generate(queue.length, (i) => i);
    final pos = order.indexOf(index);
    if (pos < 0) return const [];
    return [
      for (final i in order.skip(pos + 1))
        if (i < queue.length) queue[i]
    ];
  }

  AudioSource _source(Track t) => AudioSource.uri(
        Uri.parse(t.url),
        tag: MediaItem(
          id: t.id,
          title: t.title,
          artist: t.artist,
          album: t.album,
          artUri: t.cover.imageUrl == null ? null : Uri.parse(t.cover.imageUrl!),
        ),
      );

  Future<void> playQueue(List<Track> tracks,
      {int start = 0, String from = '', bool shuffle = false}) async {
    if (tracks.isEmpty) return;
    queue
      ..clear()
      ..addAll(tracks);
    index = start;
    fromLabel = from;
    notifyListeners();
    try {
      await audio.setShuffleModeEnabled(shuffle);
      await audio.setAudioSources(
        [for (final t in tracks) _source(t)],
        initialIndex: shuffle ? null : start,
      );
      if (shuffle) await audio.shuffle();
      audio.play();
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  Future<void> playTrack(Track t, {String from = ''}) =>
      playQueue([t], from: from);

  Future<void> playNext(Track t) async {
    if (current == null) return playTrack(t);
    final at = index + 1;
    queue.insert(at, t);
    notifyListeners();
    await audio.insertAudioSource(at, _source(t));
  }

  Future<void> clearUpNext() async {
    for (var i = queue.length - 1; i > index; i--) {
      queue.removeAt(i);
      await audio.removeAudioSourceAt(i);
    }
    notifyListeners();
  }

  void togglePlay() => playing ? audio.pause() : audio.play();

  Future<void> next() => audio.seekToNext();

  Future<void> previous() async {
    if (audio.position > const Duration(seconds: 3) || !audio.hasPrevious) {
      await audio.seek(Duration.zero);
    } else {
      await audio.seekToPrevious();
    }
  }

  Future<void> seek(Duration d) => audio.seek(d);

  Future<void> toggleShuffle() async {
    final on = !shuffle;
    if (on) await audio.shuffle();
    await audio.setShuffleModeEnabled(on);
  }

  Future<void> cycleRepeat() => audio.setLoopMode(switch (loop) {
        LoopMode.off => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.off,
      });
}

/// Likes and downloads, kept in memory for now (saved to a database in Phase 4).
class Library extends ChangeNotifier {
  Library._();
  static final Library I = Library._();

  final Set<String> liked = {};
  final Set<String> downloaded = {};

  bool isLiked(String id) => liked.contains(id);
  bool isDownloaded(String id) => downloaded.contains(id);

  void toggleLike(String id) {
    liked.contains(id) ? liked.remove(id) : liked.add(id);
    notifyListeners();
  }

  void toggleDownload(String id) {
    downloaded.contains(id) ? downloaded.remove(id) : downloaded.add(id);
    notifyListeners();
  }
}
