import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../player/player.dart';
import '../source/youtube_music.dart';
import '../theme.dart';
import '../ui/cover_art.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

enum _Mode { music, youtube, podcasts }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  _Mode _mode = _Mode.music;
  final _query = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _requestId = 0;

  bool _loading = false;
  String? _error;
  List<Track> _results = const [];
  String _resultsFor = '';

  /// Songs you picked from search, newest first.
  static final List<Track> _recent = [];

  static const _info = {
    _Mode.music: ('Music', 'Songs, artists and albums',
        'Search songs, artists and albums from YouTube Music.'),
    _Mode.youtube: ('YouTube', 'Search YouTube',
        'Search all of YouTube. Only the audio plays.'),
    _Mode.podcasts:
        ('Podcasts', 'Shows and channels', 'Search shows and channels or paste a link.'),
  };

  @override
  void initState() {
    super.initState();
    _query.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _query.text.trim();
    if (q == _resultsFor && !_loading) {
      setState(() {});
      return;
    }
    _debounce?.cancel();
    if (q.isEmpty) {
      _requestId++;
      setState(() {
        _results = const [];
        _resultsFor = '';
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (_mode == _Mode.podcasts) {
      setState(() => _loading = false);
      return;
    }
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = _mode == _Mode.music
          ? await YouTubeMusic.I.searchSongs(q)
          : await YouTubeMusic.I.searchVideos(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = raw.map(Track.fromYt).toList();
        _resultsFor = q;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = 'Search didn’t work. Check your connection and try again.';
      });
    }
  }

  void _setMode(_Mode m) {
    if (m == _mode) return;
    setState(() {
      _mode = m;
      _results = const [];
      _resultsFor = '';
    });
    final q = _query.text.trim();
    if (q.isNotEmpty) _search(q);
  }

  void _play(int i) {
    _focus.unfocus();
    final t = _results[i];
    _recent.removeWhere((r) => r.id == t.id);
    _recent.insert(0, t);
    if (_recent.length > 12) _recent.removeLast();
    // Play the tapped song, with the rest of the results queued after it.
    Player.I.playQueue(_results.sublist(i), from: 'Search');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _query.text.trim();
    final searching = q.isNotEmpty;
    final info = _info[_mode]!;

    final List<Widget> body;
    if (_mode == _Mode.podcasts) {
      body = [_note(c, 'Podcast search arrives in a later phase.')];
    } else if (!searching) {
      body = _recent.isEmpty
          ? [_note(c, 'Search for a song, artist or album.')]
          : [
              for (final t in _recent)
                _ResultRow(
                  track: t,
                  onTap: () => Player.I.playTrack(t, from: 'Search'),
                  trailing: CircleIconButton(MIcons.close,
                      iconSize: 16,
                      color: c.sub,
                      label: 'Remove ${t.title} from recent searches',
                      onTap: () => setState(() => _recent.remove(t))),
                ),
            ];
    } else if (_error != null) {
      body = [_note(c, _error!)];
    } else if (_loading && _results.isEmpty) {
      body = [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: kRed))),
        )
      ];
    } else if (_results.isEmpty) {
      body = [_note(c, 'No results for “$q”')];
    } else {
      body = [
        for (var i = 0; i < _results.length; i++)
          _ResultRow(track: _results[i], onTap: () => _play(i)),
      ];
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const LargeTitle('Search'),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              MIcon(MIcons.search, size: 20, color: c.sub),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _query,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    if (v.trim().isNotEmpty) _search(v.trim());
                  },
                  style: TextStyle(fontSize: 16, color: c.text),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: info.$2,
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              ),
              if (searching)
                Tap(
                  onTap: _query.clear,
                  semantics: 'Clear search',
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: MIcon(MIcons.close, size: 16, color: c.sub),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final m in _Mode.values) ...[
              Tap(
                onTap: () => _setMode(m),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == _mode ? kRed : c.chip,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(_info[m]!.$1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: m == _mode ? Colors.white : c.text,
                      )),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(info.$3, style: TextStyle(fontSize: 13, height: 18 / 13, color: c.sub)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: SizedBox(
            height: 44,
            child: Row(children: [
              Expanded(
                  child: Text(searching ? 'Top Results' : 'Recent Searches', style: T.section)),
              if (searching && _loading && _results.isNotEmpty)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kRed)),
              if (!searching && _recent.isNotEmpty && _mode != _Mode.podcasts)
                Tap(
                  onTap: () => setState(_recent.clear),
                  child: Text('Clear',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.link)),
                ),
            ]),
          ),
        ),
        ...body,
      ],
    );
  }

  Widget _note(AppColors c, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: Text(text,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.sub)),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.track, required this.onTap, this.trailing});
  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sub = [
      track.isVideo ? 'Video' : 'Song',
      if (track.artist.isNotEmpty) track.artist,
      if (track.durationLabel.isNotEmpty) track.durationLabel,
    ].join(' · ');
    return TrackRow(
      track: track,
      subtitle: sub,
      onTap: onTap,
      trailing: trailing,
      leading: track.isVideo
          ? Stack(alignment: Alignment.center, children: [
              CoverArt(track.cover, size: 54, width: 96),
              Container(
                width: 26,
                height: 26,
                decoration:
                    const BoxDecoration(color: Color(0x8C000000), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const MIcon(MIcons.play, size: 12, color: Colors.white),
              ),
            ])
          : null,
    );
  }
}
