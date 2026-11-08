import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
import '../ui/cover_art.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'playlist.dart';
import 'simple_pages.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rows = <(MIcons, String, Widget Function())>[
      (MIcons.user, 'Artists', () => const PlaceholderPage(title: 'Artists', back: 'Music')),
      (MIcons.album, 'Albums', () => const PlaceholderPage(title: 'Albums', back: 'Music')),
      (MIcons.music, 'Songs',
          () => TrackListPage(title: 'Songs', back: 'Music', tracks: allTracks)),
      (MIcons.heart, 'Liked Songs', () => const _LiveList(liked: true)),
      (MIcons.download, 'Downloaded', () => const _LiveList(liked: false)),
    ];

    return ListenableBuilder(
      listenable: Library.I,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          LargeTitle('Music',
              trailing: Builder(
                builder: (btnContext) => Transform.translate(
                  offset: const Offset(10, 0),
                  child: CircleIconButton(MIcons.plus,
                      color: kRed, iconSize: 28, label: 'Add',
                      onTap: () => _openAddMenu(btnContext)),
                ),
              )),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              for (var i = 0; i < rows.length; i++)
                Tap(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => rows[i].$3())),
                  child: Container(
                    height: 52,
                    decoration: i < rows.length - 1
                        ? BoxDecoration(border: Border(bottom: BorderSide(color: c.line)))
                        : null,
                    child: Row(children: [
                      MIcon(rows[i].$1, color: kRed),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text(rows[i].$2,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500))),
                      MIcon(MIcons.chevronRight, size: 20, color: c.sub, stroke: 2),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Playlists', style: T.section),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(builder: (context, box) {
              final w = (box.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 16,
                children: [
                  for (final p in playlists)
                    Tap(
                      onTap: () =>
                          Navigator.of(context).push(PlaylistPage.route(p, back: 'Music')),
                      child: SizedBox(
                        width: w,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Stack(children: [
                            CoverArt(p.cover, size: w, radius: 12),
                            if (Library.I.isDownloaded(p.id))
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration:
                                      BoxDecoration(color: c.badgeBg, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: MIcon(MIcons.downloadBadge,
                                      size: 16, color: c.badgeFg),
                                ),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          Text(p.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: T.rowTitle),
                          const SizedBox(height: 2),
                          Text('Playlist', style: T.rowSub.copyWith(color: c.sub)),
                        ]),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openAddMenu(BuildContext context) {
    final c = context.c;
    final box = context.findRenderObject() as RenderBox;
    final top = box.localToGlobal(Offset.zero).dy + box.size.height + 4;
    final outer = context;
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: c.scrim,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (ctx, _, __) {
        Widget item(MIcons icon, String title, String sub, bool primary, VoidCallback onTap) =>
            Tap(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary ? kRed : c.chip,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: MIcon(icon,
                        size: 20, color: primary ? Colors.white : kRed, stroke: 2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 13, color: c.sub)),
                    ]),
                  ),
                ]),
              ),
            );
        return Stack(children: [
          Positioned(
            top: top,
            right: 20,
            width: 272,
            child: Material(
              color: c.menu,
              borderRadius: BorderRadius.circular(16),
              elevation: 12,
              shadowColor: Colors.black38,
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                item(MIcons.playlistAdd, 'New Playlist', 'Start an empty playlist', true, () {
                  Navigator.of(ctx).pop();
                  showSoon(outer, 'Creating playlists');
                }),
                Divider(height: 1, thickness: 1, color: c.line),
                item(MIcons.importIcon, 'Import from Spotify', 'Paste a Spotify playlist link',
                    false, () {
                  Navigator.of(ctx).pop();
                  showSoon(outer, 'Spotify import');
                }),
              ]),
            ),
          ),
        ]);
      },
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          child: child,
        ),
      ),
    );
  }
}

/// Liked or Downloaded songs, updating live as you like/download.
class _LiveList extends StatelessWidget {
  const _LiveList({required this.liked});
  final bool liked;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Library.I,
      builder: (context, _) {
        final lib = Library.I;
        final List<Track> tracks;
        if (liked) {
          tracks = allTracks.where((t) => lib.isLiked(t.id)).toList();
        } else {
          final fromPlaylists = playlists
              .where((p) => lib.isDownloaded(p.id))
              .expand((p) => p.tracks)
              .map((t) => t.id)
              .toSet();
          tracks = allTracks
              .where((t) => lib.isDownloaded(t.id) || fromPlaylists.contains(t.id))
              .toList();
        }
        return TrackListPage(
          title: liked ? 'Liked Songs' : 'Downloaded',
          back: 'Music',
          tracks: tracks,
          emptyText: liked
              ? 'Tap the heart on a song and it shows up here.'
              : 'Download songs or playlists to listen offline.',
        );
      },
    );
  }
}
