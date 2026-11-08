import 'package:flutter/material.dart';

import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
import '../ui/cover_art.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'simple_pages.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.playlist, required this.back});
  final Playlist playlist;
  final String back;

  static Route<void> route(Playlist p, {required String back}) =>
      MaterialPageRoute(builder: (_) => PlaylistPage(playlist: p, back: back));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = playlist;
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Library.I,
          builder: (context, _) {
            final downloaded = Library.I.isDownloaded(p.id);
            return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
              BackHeader(
                label: back,
                trailing: CircleIconButton(MIcons.more,
                    bg: c.chip, label: 'More options', onTap: () => showSoon(context, 'Playlist editing')),
              ),
              const SizedBox(height: 18),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: dark ? const Color(0x99000000) : const Color(0x38111114),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      )
                    ],
                  ),
                  child: CoverArt(p.cover, size: 220, radius: 16),
                ),
              ),
              const SizedBox(height: 14),
              Text(p.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Playlist · ${p.tracks.length} songs',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.sub)),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                    child: _Pill(
                      icon: MIcons.play,
                      label: 'Play',
                      bg: kRed,
                      fg: Colors.white,
                      onTap: () => Player.I.playQueue(p.tracks, from: p.title),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Pill(
                      icon: MIcons.shuffle,
                      label: 'Shuffle',
                      bg: c.chip,
                      fg: c.link,
                      onTap: () => Player.I.playQueue(p.tracks, from: p.title, shuffle: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tap(
                    onTap: () => Library.I.toggleDownload(p.id),
                    semantics: downloaded ? 'Downloaded' : 'Download',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: c.chip, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: downloaded
                          ? Stack(alignment: Alignment.center, children: [
                              MIcon(MIcons.downloaded, size: 22, color: c.link),
                              MIcon(MIcons.check, size: 13, color: c.page, stroke: 3.2),
                            ])
                          : MIcon(MIcons.download, size: 22, color: c.link, stroke: 2),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < p.tracks.length; i++)
                TrackRow(
                  track: p.tracks[i],
                  coverSize: 44,
                  height: 58,
                  border: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                  trailing: Text(p.tracks[i].durationLabel,
                      style: TextStyle(
                          fontSize: 13,
                          color: c.sub,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  onTap: () => Player.I.playQueue(p.tracks, start: i, from: p.title),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon, required this.label, required this.bg, required this.fg, required this.onTap});
  final MIcons icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            MIcon(icon, size: 20, color: fg, stroke: 2),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
          ]),
        ),
      );
}
