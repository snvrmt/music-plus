import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models.dart';
import '../util/log.dart';
import 'audio_cache.dart';

/// One app-wide player. Wraps just_audio; just_audio_background adds
/// background playback plus lock-screen / Control Center controls.
///
/// The queue lives here in Dart. The audio player itself only ever holds
/// songs that are already downloaded: the current one, plus the next one
/// as soon as it's ready (so it follows on without a gap). Handing the
/// player songs that still had to be downloaded made it wait forever.
class Player extends ChangeNotifier {
  Player._() {
    audio.processingStateStream.listen((s) => Log.add('player state: ${s.name}'));
    audio.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) _onQueueEnd();
      notifyListeners();
    });
    audio.currentIndexStream.listen((i) {
      if (i == null) return;
      final pos = _base + i;
      if (pos != index && pos < queue.length) {
        index = pos;
        Library.I.addToHistory(queue[index]);
        _prefetchNext();
      }
      notifyListeners();
    });
    audio.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      Log.add('player error: $e');
      final t = current;
      if (t != null) _fail(t, e);
    });
  }

  static final Player I = Player._();

  final AudioPlayer audio = AudioPlayer();

  /// The whole queue, in play order.
  final List<Track> queue = [];

  /// Position of the current song in [queue].
  int index = -1;

  /// Queue position of the audio player's first item.
  int _base = 0;

  /// How many queue songs (from [_base]) the audio player currently holds.
  int _loaded = 0;

  String fromLabel = '';
  bool _resolving = false;
  int _generation = 0;
  bool _shuffle = false;
  LoopMode _loop = LoopMode.off;
  List<Track>? _unshuffled;

  /// Latest playback problem, shown as a message by the app shell.
  final ValueNotifier<String?> error = ValueNotifier(null);

  Track? get current => (index >= 0 && index < queue.length) ? queue[index] : null;
  bool get playing => audio.playing;
  bool get shuffle => _shuffle;
  LoopMode get loop => _loop;
  bool get loading {
    final s = audio.processingState;
    return _resolving || s == ProcessingState.loading || s == ProcessingState.buffering;
  }

  List<Track> get upNext =>
      index < 0 || index + 1 >= queue.length ? const [] : queue.sublist(index + 1);

  Future<AudioSource> _source(Track t) async {
    final tag = MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      artUri: t.cover.imageUrl == null ? null : Uri.parse(t.cover.imageUrl!),
    );
    if (t.videoId == null) return AudioSource.uri(Uri.parse(t.url), tag: tag);
    final file = await AudioCache.I.get(t.videoId!);
    return AudioSource.file(file.path, tag: tag);
  }

  Future<void> playQueue(List<Track> tracks,
      {int start = 0, String from = '', bool shuffle = false}) async {
    if (tracks.isEmpty) return;
    queue
      ..clear()
      ..addAll(tracks);
    _unshuffled = null;
    _shuffle = false;
    fromLabel = from;
    start = start.clamp(0, queue.length - 1);
    if (shuffle) {
      _shuffle = true;
      _unshuffled = List.of(queue);
      queue.shuffle();
      start = 0;
    }
    await _playAt(start);
  }

  Future<void> playTrack(Track t, {String from = ''}) => playQueue([t], from: from);

  /// Download (if needed) and play queue[pos].
  Future<void> _playAt(int pos) async {
    if (pos < 0 || pos >= queue.length) return;
    final gen = ++_generation;
    index = pos;
    _resolving = true;
    notifyListeners();
    await audio.pause();
    final t = queue[pos];
    Log.add('play #$pos "${t.title}" (${t.videoId ?? t.url})');
    try {
      final source = await _source(t);
      Log.add('source ready: ${source.runtimeType}');
      if (gen != _generation) {
        Log.add('superseded by a newer request');
        return;
      }
      _base = pos;
      _loaded = 1;
      await audio
          .setAudioSources([source], initialIndex: 0)
          .timeout(const Duration(seconds: 20),
              onTimeout: () => throw Exception('The player couldn’t open the file.'));
      Log.add('setAudioSources done, duration ${audio.duration}');
      if (gen != _generation) return;
      await audio.setLoopMode(_loop == LoopMode.one ? LoopMode.one : LoopMode.off);
      _resolving = false;
      Library.I.addToHistory(t);
      notifyListeners();
      audio.play();
      _prefetchNext();
    } catch (e) {
      if (gen != _generation) return;
      _resolving = false;
      _fail(t, e);
    }
  }

  /// Download the next song while this one plays, then hand it to the
  /// audio player so it follows on seamlessly.
  void _prefetchNext() {
    final gen = _generation;
    final nextPos = _base + _loaded;
    if (nextPos != index + 1 || nextPos >= queue.length) return;
    final t = queue[nextPos];
    _source(t).then((s) async {
      if (gen != _generation || _base + _loaded != nextPos) return;
      if (nextPos >= queue.length || queue[nextPos].id != t.id) return;
      _loaded++;
      await audio.addAudioSource(s);
    }).catchError((Object e) {
      debugPrint('Prefetch failed for ${t.title}: $e');
    });
  }

  /// Drop songs the audio player holds after the current one (after the
  /// queue order changed), then fetch the right next song.
  Future<void> _resetAhead() async {
    final keep = index - _base + 1;
    while (_loaded > keep) {
      _loaded--;
      await audio.removeAudioSourceAt(_loaded);
    }
    _prefetchNext();
  }

  void _onQueueEnd() {
    if (index + 1 < queue.length) {
      _playAt(index + 1);
    } else if (_loop == LoopMode.all && queue.isNotEmpty) {
      _playAt(0);
    }
  }

  Future<void> playNext(Track t) async {
    if (current == null) return playTrack(t);
    queue.insert(index + 1, t);
    notifyListeners();
    await _resetAhead();
  }

  Future<void> clearUpNext() async {
    if (index + 1 < queue.length) queue.removeRange(index + 1, queue.length);
    notifyListeners();
    await _resetAhead();
  }

  void _fail(Track t, Object e) {
    Log.add('FAILED "${t.title}": $e');
    final msg = e.toString().replaceFirst('Exception: ', '');
    final short = msg.length > 220 ? '${msg.substring(0, 220)}\u2026' : msg;
    error.value = 'Couldn\u2019t play \u201c${t.title}\u201d.\n$short';
    notifyListeners();
  }

  void togglePlay() => playing ? audio.pause() : audio.play();

  Future<void> next() async {
    if (index + 1 < queue.length) {
      if (_base + _loaded > index + 1) {
        await audio.seekToNext();
      } else {
        await _playAt(index + 1);
      }
    } else if (_loop == LoopMode.all && queue.isNotEmpty) {
      await _playAt(0);
    }
  }

  Future<void> previous() async {
    if (audio.position > const Duration(seconds: 3) || index == 0) {
      await audio.seek(Duration.zero);
    } else {
      await _playAt(index - 1);
    }
  }

  Future<void> seek(Duration d) => audio.seek(d);

  Future<void> toggleShuffle() async {
    if (current == null) return;
    final cur = queue[index];
    if (!_shuffle) {
      _unshuffled = List.of(queue);
      final rest = queue.sublist(index + 1)..shuffle();
      queue.replaceRange(index + 1, queue.length, rest);
      _shuffle = true;
    } else {
      final original = _unshuffled ?? List.of(queue);
      final at = original.indexWhere((t) => t.id == cur.id);
      final after = at < 0 ? <Track>[] : original.sublist(at + 1);
      queue.replaceRange(index + 1, queue.length, after);
      _shuffle = false;
    }
    notifyListeners();
    await _resetAhead();
  }

  Future<void> cycleRepeat() async {
    _loop = switch (_loop) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await audio.setLoopMode(_loop == LoopMode.one ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }
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

