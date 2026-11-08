import 'package:flutter/material.dart';

import '../data/models.dart';
import '../player/player.dart';
import '../theme.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

/// "‹ Music" style back link from the design.
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
      child: Row(children: [
        Tap(
          onTap: () => Navigator.of(context).maybePop(),
          semantics: 'Back to $label',
          child: SizedBox(
            height: 44,
            child: Row(children: [
              MIcon(MIcons.chevronLeft, color: c.link),
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.link)),
              const SizedBox(width: 8),
            ]),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class TrackListPage extends StatelessWidget {
  const TrackListPage(
      {super.key, required this.title, required this.back, required this.tracks, this.emptyText});
  final String title;
  final String back;
  final List<Track> tracks;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        bottom: false,
        child: ListView(children: [
          BackHeader(label: back),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(title, style: T.largeTitle),
          ),
          if (tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Text(emptyText ?? 'Nothing here yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: c.sub)),
            ),
          for (var i = 0; i < tracks.length; i++)
            TrackRow(
              track: tracks[i],
              onTap: () => Player.I.playQueue(tracks, start: i, from: title),
            ),
        ]),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.back});
  final String title;
  final String back;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BackHeader(label: back),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(title, style: T.largeTitle),
          ),
          Expanded(
            child: Center(
              child: Text('Coming in a later phase.',
                  style: TextStyle(fontSize: 16, color: c.sub)),
            ),
          ),
        ]),
      ),
    );
  }
}
