import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/demo_data.dart';
import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
import '../ui/cover_art.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

void openNowPlaying(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const NowPlayingPage(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));
}

enum _Panel { art, lyrics, queue }

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  _Panel _panel = _Panel.art;
  double _drag = 0;

  void _toggle(_Panel p) => setState(() => _panel = _panel == p ? _Panel.art : p);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, 1000)),
      onVerticalDragEnd: (d) {
        if (_drag > 140 || (d.primaryVelocity ?? 0) > 700) {
          Navigator.of(context).pop();
        } else {
          setState(() => _drag = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, _drag),
        child: Material(
          color: c.npBg,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: Listenable.merge([Player.I, Library.I]),
              builder: (context, _) {
                final p = Player.I;
                final t = p.current;
                if (t == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) Navigator.of(context).maybePop();
                  });
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Column(children: [
                    Tap(
                      onTap: () => Navigator.of(context).pop(),
                      semantics: 'Close player',
                      child: SizedBox(
                          width: 88, height: 44, child: Center(child: Grabber(color: c.npTrack))),
                    ),
                    Text(p.fromLabel.isEmpty ? 'Now Playing' : 'Playing from ${p.fromLabel}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.npSub)),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, box) {
                      final size = math.max(
                          160.0,
                          math.min(box.maxWidth, MediaQuery.sizeOf(context).height - 470));
                      return SizedBox(
                        width: size,
                        height: size,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: switch (_panel) {
                            _Panel.art => _Art(key: const ValueKey('art'), track: t, size: size),
                            _Panel.lyrics => const _Lyrics(key: ValueKey('lyrics')),
                            _Panel.queue => const _Queue(key: ValueKey('queue')),
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 26,
                                  height: 32 / 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(t.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, color: c.npSub)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      CircleIconButton(
                        Library.I.isLiked(t.id) ? MIcons.heartFilled : MIcons.heart,
                        bg: c.npChip,
                        color: Library.I.isLiked(t.id) ? kRed : c.text,
                        label: Library.I.isLiked(t.id)
                            ? 'Remove from Liked Songs'
                            : 'Add to Liked Songs',
                        onTap: () => Library.I.toggleLike(t.id),
                      ),
                      const SizedBox(width: 10),
                      CircleIconButton(MIcons.more,
                          bg: c.npChip, label: 'More options', onTap: () => showSongSheet(context, t)),
                    ]),
                    const SizedBox(height: 26),
                    const _Progress(),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      CircleIconButton(MIcons.shuffle,
                          iconSize: 24,
                          label: 'Shuffle',
                          color: p.shuffle ? kRed : c.npSub,
                          onTap: p.toggleShuffle),
                      CircleIconButton(MIcons.previous,
                          size: 56, iconSize: 32, label: 'Previous track', onTap: p.previous),
                      Tap(
                        onTap: p.togglePlay,
                        semantics: p.playing ? 'Pause' : 'Play',
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(color: c.playBg, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: p.loading && !p.playing
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 3, color: c.playFg))
                              : MIcon(p.playing ? MIcons.pause : MIcons.play,
                                  size: 32, color: c.playFg),
                        ),
                      ),
                      CircleIconButton(MIcons.next,
                          size: 56, iconSize: 32, label: 'Next track', onTap: p.next),
                      CircleIconButton(
                          p.loop == LoopMode.one ? MIcons.repeatOne : MIcons.repeat,
                          iconSize: 24,
                          label: 'Repeat',
                          color: p.loop == LoopMode.off ? c.npSub : kRed,
                          onTap: p.cycleRepeat),
                    ]),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _BottomButton(
                          icon: MIcons.devices,
                          label: 'Devices',
                          active: false,
                          onTap: () => _showDevices(context)),
                      _BottomButton(
                          icon: MIcons.lyrics,
                          label: 'Lyrics',
                          active: _panel == _Panel.lyrics,
                          onTap: () => _toggle(_Panel.lyrics)),
                      _BottomButton(
                          icon: MIcons.queue,
                          label: 'Queue',
                          active: _panel == _Panel.queue,
                          onTap: () => _toggle(_Panel.queue)),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDevices(BuildContext context) {
    showMSheet(context, (ctx) {
      final c = ctx.c;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Center(child: Grabber()),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text('Play On', style: T.section),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const MIcon(MIcons.phone, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('This iPhone',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Speaker', style: TextStyle(fontSize: 13, color: c.sub)),
              ]),
            ),
            const MIcon(MIcons.check, size: 20, color: kRed),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
              'For AirPlay and Bluetooth speakers, use Control Center for now.',
              style: TextStyle(fontSize: 13, color: c.sub)),
        ),
        const SizedBox(height: 12),
        Tap(
          onTap: () => Navigator.of(ctx).pop(),
          child: Container(
            height: 50,
            decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]);
    });
  }
}

class _Art extends StatelessWidget {
  const _Art({super.key, required this.track, required this.size});
  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final playing = Player.I.playing;
    return Center(
      child: AnimatedScale(
        scale: playing ? 1 : 0.86,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: context.c.artShadow, blurRadius: 48, offset: const Offset(0, 24))
            ],
          ),
          child: CoverArt(track.cover, size: size, radius: 20),
        ),
      ),
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress();

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  double? _scrub;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final audio = Player.I.audio;
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, _) {
        final total = audio.duration ?? Duration.zero;
        final pos = audio.position;
        final ms = total.inMilliseconds;
        final frac = _scrub ?? (ms == 0 ? 0.0 : (pos.inMilliseconds / ms).clamp(0.0, 1.0));
        final shown = Duration(milliseconds: (frac * ms).round());
        return LayoutBuilder(builder: (context, box) {
          void update(double dx) =>
              setState(() => _scrub = (dx / box.maxWidth).clamp(0.0, 1.0));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            onHorizontalDragEnd: (_) {
              if (_scrub != null && ms > 0) {
                Player.I.seek(Duration(milliseconds: (_scrub! * ms).round()));
              }
              setState(() => _scrub = null);
            },
            onTapUp: (d) {
              if (ms > 0) {
                Player.I.seek(Duration(
                    milliseconds: ((d.localPosition.dx / box.maxWidth).clamp(0.0, 1.0) * ms).round()));
              }
            },
            child: Column(children: [
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: _scrub != null ? 8 : 4,
                decoration:
                    BoxDecoration(color: c.npTrack, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: frac,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(color: c.text, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.npSub,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_fmt(shown)),
                  Text('-${_fmt(total - shown)}'),
                ]),
              ),
            ]),
          );
        });
      },
    );
  }
}

/// Placeholder lyrics that follow the playback position. Real synced
/// lyrics from LRCLIB replace these in Phase 5.
class _Lyrics extends StatelessWidget {
  const _Lyrics({super.key});

  static const _secondsPerLine = 6;

  @override
  Widget build(BuildContext context) {
    final audio = Player.I.audio;
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, _) {
        final current = (audio.position.inSeconds ~/ _secondsPerLine) % demoLyrics.length;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < demoLyrics.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Tap(
                  onTap: () => Player.I.seek(Duration(
                      seconds: (audio.position.inSeconds ~/
                                  (_secondsPerLine * demoLyrics.length)) *
                              _secondsPerLine *
                              demoLyrics.length +
                          i * _secondsPerLine)),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: i == current ? 1 : 0.32,
                    child: Text(demoLyrics[i],
                        style: const TextStyle(
                            fontSize: 24,
                            height: 30 / 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final upNext = Player.I.upNext;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 40,
        child: Row(children: [
          const Expanded(child: Text('Up Next', style: T.section)),
          if (upNext.isNotEmpty)
            Tap(
              onTap: Player.I.clearUpNext,
              child: Text('Clear',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.npActiveFg)),
            ),
        ]),
      ),
      Expanded(
        child: upNext.isEmpty
            ? Center(
                child: Text('Nothing up next.', style: TextStyle(fontSize: 15, color: c.npSub)))
            : ListView(padding: EdgeInsets.zero, children: [
                for (final t in upNext)
                  SizedBox(
                    height: 58,
                    child: Row(children: [
                      CoverArt(t.cover, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.rowTitle),
                              const SizedBox(height: 2),
                              Text(t.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: c.npSub)),
                            ]),
                      ),
                      SizedBox(width: 32, child: MIcon(MIcons.grip, size: 20, color: c.npSub)),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton(
      {required this.icon, required this.label, required this.active, required this.onTap});
  final MIcons icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = active ? c.npActiveFg : c.text;
    return Tap(
      onTap: onTap,
      semantics: label,
      child: SizedBox(
        width: 88,
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: active ? c.npActiveBg : Colors.transparent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: MIcon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
