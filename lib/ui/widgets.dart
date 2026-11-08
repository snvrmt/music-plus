import 'package:flutter/material.dart';

import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
import 'cover_art.dart';
import 'icons.dart';

/// Tap target that dims slightly while pressed, like iOS.
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, this.onTap, this.semantics});
  final Widget child;
  final VoidCallback? onTap;
  final String? semantics;

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _down && widget.onTap != null ? 0.55 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Round 44px icon button.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton(this.icon,
      {super.key, this.onTap, this.bg, this.color, this.size = 44, this.iconSize = 22, this.label});
  final MIcons icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? color;
  final double size;
  final double iconSize;
  final String? label;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        semantics: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: MIcon(icon, size: iconSize, color: color ?? context.c.text),
        ),
      );
}

class LargeTitle extends StatelessWidget {
  const LargeTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
        child: Row(children: [
          Expanded(child: Text(text, style: T.largeTitle)),
          if (trailing != null) trailing!,
        ]),
      );
}

void showSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$what is coming in a later phase'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
}

/// A song row: cover, title, subtitle, optional trailing, "more" button.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    this.subtitle,
    this.coverSize = 52,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 8, 0),
    this.height = 64,
    this.border = false,
  });

  final Track track;
  final VoidCallback onTap;
  final String? subtitle;
  final double coverSize;
  final Widget? trailing;
  final Widget? leading;
  final EdgeInsets padding;
  final double height;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: Player.I,
      builder: (context, _) {
        final isCurrent = Player.I.current?.id == track.id;
        return Tap(
          onTap: onTap,
          child: Container(
            height: height,
            padding: padding,
            decoration: border
                ? BoxDecoration(border: Border(bottom: BorderSide(color: c.line)))
                : null,
            child: Row(children: [
              leading ?? CoverArt(track.cover, size: coverSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.rowTitle.copyWith(color: isCurrent ? kRed : c.text)),
                    const SizedBox(height: 2),
                    Text(subtitle ?? track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.rowSub.copyWith(color: c.sub)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              CircleIconButton(MIcons.more,
                  color: c.sub, label: 'More options for ${track.title}',
                  onTap: () => showSongSheet(context, track)),
            ]),
          ),
        );
      },
    );
  }
}

/// Drag handle shown at the top of sheets.
class Grabber extends StatelessWidget {
  const Grabber({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: color ?? context.c.grabber,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

Future<T?> showMSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = context.c;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.sheet,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: builder(ctx),
      ),
    ),
  );
}

class SheetRow extends StatelessWidget {
  const SheetRow(this.icon, this.label, {super.key, required this.onTap, this.trailing});
  final MIcons icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        child: Row(children: [
          MIcon(icon, size: 22, color: kRed),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.text))),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

/// The song options sheet (SongSheet in the design).
Future<void> showSongSheet(BuildContext context, Track track) {
  final messengerContext = context;
  return showMSheet(context, (ctx) {
    final c = ctx.c;
    return ListenableBuilder(
      listenable: Library.I,
      builder: (ctx, _) {
        final lib = Library.I;
        final liked = lib.isLiked(track.id);
        final dl = lib.isDownloaded(track.id);
        void close() => Navigator.of(ctx).pop();
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const Grabber(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
            child: Row(children: [
              CoverArt(track.cover, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(track.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(track.artist, style: TextStyle(fontSize: 14, color: c.sub)),
                ]),
              ),
            ]),
          ),
          SheetRow(MIcons.playNext, 'Play Next', onTap: () {
            Player.I.playNext(track);
            close();
          }),
          SheetRow(MIcons.playlistAdd, 'Add to Playlist', onTap: () {
            close();
            showSoon(messengerContext, 'Adding to playlists');
          }),
          SheetRow(liked ? MIcons.heartFilled : MIcons.heart,
              liked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
              onTap: () => lib.toggleLike(track)),
          SheetRow(MIcons.download, dl ? 'Remove Download' : 'Download',
              onTap: () {
                lib.remember(track);
                lib.toggleDownload(track.id);
              }),
          SheetRow(MIcons.user, 'Go to Artist', onTap: () {
            close();
            showSoon(messengerContext, 'Artist pages');
          }),
          SheetRow(MIcons.album, 'Go to Album', onTap: () {
            close();
            showSoon(messengerContext, 'Album pages');
          }),
          SheetRow(MIcons.share, 'Share', onTap: close),
        ]);
      },
    );
  });
}
