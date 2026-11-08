import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
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
  final _recent = [slowTide, midnightDrive, staticBloom, quietHours];

  static const _info = {
    _Mode.music: ('Music', 'Songs, artists and albums',
        'Search songs, artists and albums from YouTube Music.'),
    _Mode.youtube: ('YouTube', 'Search YouTube',
        'Search all of YouTube or paste a link. Only the audio plays.'),
    _Mode.podcasts:
        ('Podcasts', 'Shows and channels', 'Search shows and channels or paste a link.'),
  };

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _query.text.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final info = _info[_mode]!;
    final List<Track> results = _mode != _Mode.music
        ? const <Track>[]
        : searching
            ? allTracks
                .where((t) =>
                    t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q))
                .toList()
            : _recent;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const LargeTitle('Search'),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration:
                BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              MIcon(MIcons.search, size: 20, color: c.sub),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
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
                  child: MIcon(MIcons.close, size: 16, color: c.sub),
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
                onTap: () => setState(() => _mode = m),
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
          child: Row(children: [
            Expanded(
                child: Text(searching ? 'Top Results' : 'Recent Searches', style: T.section)),
            if (!searching && _mode == _Mode.music && _recent.isNotEmpty)
              Tap(
                onTap: () => setState(_recent.clear),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text('Clear',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: c.link)),
                  ),
                ),
              ),
          ]),
        ),
        if (_mode != _Mode.music)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Text('${info.$1} search arrives with Phase 3.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.sub)),
          )
        else if (searching && results.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Text('No results for “${_query.text.trim()}”',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.sub)),
          )
        else
          for (final t in results)
            TrackRow(
              track: t,
              subtitle: 'Song · ${t.artist}',
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              onTap: () {
                FocusScope.of(context).unfocus();
                Player.I.playTrack(t, from: 'Search');
              },
            ),
        const SizedBox(height: 16),
      ],
    );
  }
}
