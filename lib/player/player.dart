import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models.dart';
import 'audio_cache.dart';

/// One app-wide player. Wraps just_audio; just_audio_background adds
/// background playback plus lock-screen / Control Center controls.
///
/// YouTube tracks need their stream URL looked up before they can play, so
/// a queue starts with the tapped song and the rest are resolved and added
/// in the background.
class Player extends ChangeNotifier {
  Player._() {
    audio.playerStateStream.listen((_) => notifyListeners());
    audio.currentIndexStream.listen((i) {
      index = i ?? -1;
      final t = current;
      if (t != null) Library.I.addToHistory(t);
      _prefetchNext();
      notifyListeners();
    });
    audio.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      final t = current;
      if (t != null) _fail(t, e);
    });
    audio.shuffleModeEnabledStream.listen((_) => notifyListeners());
    audio.loopModeStream.listen((_) => notifyListeners());
    audio.sequenceStateStream.listen((_) => notifyListeners());
  }

  static final Player I = Player._();

  final AudioPlayer audio = AudioPlayer();

  /// Tracks in the same order as the player's audio sources.
  final List<Track> queue = [];
  int index = -1;
  String fromLabel = '';
  bool _resolving = false;
  int _generation = 0;

  /// Latest playback problem, shown as a message by the app shell.
  final ValueNotifier<String?> error = ValueNotifier(null);

  Track? get current => (index >= 0 && index < queue.length) ? queue[index] : null;
  bool get playing => audio.playing;
  bool get shuffle => audio.shuffleModeEnabled;
  LoopMode get loop => audio.loopMode;
  bool get loading {
    final s = audio.processingState;
    return _resolving || s == ProcessingState.loading || s == ProcessingState.buffering;
  }

  /// Tracks that will play after the current one, in play order.
  List<Track> get upNext {
    if (current == null) return const [];
    // ignore: dead_null_aware_expression
    final order = audio.effectiveIndices ?? List.generate(queue.length, (i) => i);
    final pos = order.indexOf(index);
    if (pos < 0) return const [];
    return [
      for (final i in order.skip(pos + 1))
        if (i < queue.length) queue[i]
    ];
  }

  Future<AudioSource> _source(Track t) async {
    final tag = MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      artUri: t.cover.imageUrl == null ? null : Uri.parse(t.cover.imageUrl!),
    );
    if (t.videoId == null) return AudioSource.uri(Uri.parse(t.url), tag: tag);
    final file = await AudioCache.I.cached(t.videoId!);
    if (file != null) return AudioSource.file(file.path, tag: tag);
    return _YouTubeAudioSource(t.videoId!, tag: tag);
  }

  Future<void> playQueue(List<Track> tracks,
      {int start = 0, String from = '', bool shuffle = false}) async {
    if (tracks.isEmpty) return;
    final gen = ++_generation;
    final list = List.of(tracks);
    if (shuffle) {
      list.shuffle();
      start = 0;
    }
    start = start.clamp(0, list.length - 1);

    queue
      ..clear()
      ..addAll(list);
    index = start;
    fromLabel = from;
    _resolving = true;
    notifyListeners();

    try {
      // Fetch the tapped song first so it plays straight from a file.
      final firstId = list[start].videoId;
      if (firstId != null) await AudioCache.I.get(firstId);
      if (gen != _generation) return;
      final sources = [for (final t in list) await _source(t)];
      if (gen != _generation) return;
      await audio.setShuffleModeEnabled(false);
      await audio.setAudioSources(sources, initialIndex: start);
      if (gen != _generation) return;
      _resolving = false;
      notifyListeners();
      audio.play();
    } catch (e) {
      if (gen != _generation) return;
      _resolving = false;
      _fail(list[start], e);
    }
  }

  /// Download the next song while this one plays, so it starts instantly.
  void _prefetchNext() {
    final order = upNext;
    if (order.isEmpty) return;
    final id = order.first.videoId;
    if (id != null) AudioCache.I.get(id).ignore();
  }

  Future<void> playTrack(Track t, {String from = ''}) => playQueue([t], from: from);

  Future<void> playNext(Track t) async {
    if (current == null) return playTrack(t);
    try {
      final s = await _source(t);
      final at = index + 1;
      queue.insert(at, t);
      await audio.insertAudioSource(at, s);
      notifyListeners();
    } catch (e) {
      _fail(t, e);
    }
  }

  Future<void> clearUpNext() async {
    for (var i = queue.length - 1; i > index; i--) {
      await audio.removeAudioSourceAt(i);
      queue.removeAt(i);
    }
    notifyListeners();
  }

  void _fail(Track t, Object e) {
    debugPrint('Playback error for ${t.title}: $e');
    final msg = e.toString().replaceFirst('Exception: ', '');
    final short = msg.length > 220 ? '${msg.substring(0, 220)}…' : msg;
    error.value = 'Couldn’t play “${t.title}”.\n$short';
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

/// Likes, downloads and history, kept in memory for now
/// (saved to a database in Phase 4).
class Library extends ChangeNotifier {
  Library._();
  static final Library I = Library._();

  final Set<String> liked = {};
  final Set<String> downloaded = {};
  final Map<String, Track> known = {};
  final List<Track> history = [];

  bool isLiked(String id) => liked.contains(id);
  bool isDownloaded(String id) => downloaded.contains(id);

  /// Every track the app has seen (demo + searched), for Liked/Downloaded lists.
  void remember(Track t) => known[t.id] = t;

  void toggleLike(Track t) {
    remember(t);
    liked.contains(t.id) ? liked.remove(t.id) : liked.add(t.id);
    notifyListeners();
  }

  void toggleDownload(String id) {
    downloaded.contains(id) ? downloaded.remove(id) : downloaded.add(id);
    notifyListeners();
  }

  void addToHistory(Track t) {
    remember(t);
    history.removeWhere((h) => h.id == t.id);
    history.insert(0, t);
    if (history.length > 50) history.removeLast();
    notifyListeners();
  }
}

/// A YouTube song that isn't on the phone yet. When the player needs it,
/// it's downloaded and converted by [AudioCache], then served from the file.
class _YouTubeAudioSource extends StreamAudioSource {
  _YouTubeAudioSource(this.videoId, {super.tag});
  final String videoId;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final file = await AudioCache.I.get(videoId);
    final length = await file.length();
    start ??= 0;
    end ??= length;
    return StreamAudioResponse(
      sourceLength: length,
      contentLength: end - start,
      offset: start,
      stream: file.openRead(start, end),
      contentType: file.path.endsWith('.mp4') ? 'video/mp4' : 'audio/mp4',
    );
  }
}
