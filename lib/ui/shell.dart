import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../player/player.dart';
import '../screens/home.dart';
import '../screens/library.dart';
import '../screens/now_playing.dart';
import '../screens/podcasts.dart';
import '../screens/search.dart';
import '../theme.dart';
import 'cover_art.dart';
import 'icons.dart';
import 'widgets.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.root);
  final String label;
  final MIcons icon;
  final Widget root;
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  static const _tabs = [
    _Tab('Home', MIcons.home, HomePage()),
    _Tab('Search', MIcons.search, SearchPage()),
    _Tab('Podcasts', MIcons.podcasts, PodcastsPage()),
    _Tab('Music', MIcons.music, LibraryPage()),
  ];

  final _keys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void _select(int i) {
    if (i == _tab) {
      _keys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _tab = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.page,
      body: Column(children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Navigator(
                    key: _keys[i],
                    onGenerateRoute: (_) => PageRouteBuilder(
                      pageBuilder: (_, __, ___) => _tabs[i].root,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const MiniPlayer(),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(10, bottomInset - 8)),
          child: _Dock(
            tabs: _tabs,
            current: _tab,
            onSelect: _select,
          ),
        ),
      ]),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.tabs, required this.current, required this.onSelect});
  final List<_Tab> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.dock,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: c.dockBorder),
        boxShadow: [BoxShadow(color: c.dockShadow, blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: Tap(
              onTap: () => onSelect(i),
              semantics: tabs[i].label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: i == current ? c.activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MIcon(tabs[i].icon, color: i == current ? kRed : c.sub),
                    const SizedBox(height: 4),
                    Text(tabs[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: i == current ? kRed : c.sub,
                        )),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: Player.I,
      builder: (context, _) {
        final p = Player.I;
        final t = p.current;
        if (t == null) return const SizedBox(height: 10);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Tap(
            onTap: () => openNowPlaying(context),
            semantics: 'Open now playing: ${t.title} by ${t.artist}',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.mini,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CoverArt(t.cover, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(t.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.sub)),
                  ]),
                ),
                CircleIconButton(p.playing ? MIcons.pause : MIcons.play,
                    iconSize: 24,
                    label: p.playing ? 'Pause' : 'Play',
                    onTap: p.togglePlay),
                CircleIconButton(MIcons.next,
                    iconSize: 24, label: 'Next track', onTap: p.next),
              ]),
            ),
          ),
        );
      },
    );
  }
}
