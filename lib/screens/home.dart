import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../player/player.dart';
import '../theme.dart';
import '../ui/cover_art.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'playlist.dart';
import 'simple_pages.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        LargeTitle('Home',
            trailing: CircleIconButton(MIcons.user,
                bg: c.chip, label: 'Open account menu', onTap: () => _openDrawer(context))),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Playlists', style: T.section),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final p = playlists[i];
              return Tap(
                onTap: () => Navigator.of(context).push(PlaylistPage.route(p, back: 'Home')),
                child: SizedBox(
                  width: 160,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CoverArt(p.cover, size: 160, radius: 12),
                    const SizedBox(height: 10),
                    Text(p.title, style: T.rowTitle),
                    const SizedBox(height: 2),
                    Text(p.subtitle, style: T.rowSub.copyWith(color: c.sub)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Tap(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TrackListPage(
                    title: 'Recently Played',
                    back: 'Home',
                    tracks: recentlyPlayed,
                  ))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              const Text('Recently played', style: T.section),
              const SizedBox(width: 4),
              MIcon(MIcons.chevronRight, size: 20, color: c.sub, stroke: 2.4),
            ]),
          ),
        ),
        for (var i = 0; i < recentlyPlayed.length; i++)
          TrackRow(
            track: recentlyPlayed[i],
            onTap: () => Player.I.playQueue(recentlyPlayed, start: i, from: 'Recently Played'),
          ),
      ],
    );
  }

  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Close account menu',
      barrierColor: context.c.scrim,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, __) => const _AccountDrawer(),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _AccountDrawer extends StatelessWidget {
  const _AccountDrawer();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? const Color(0xFF2C2C2E) : c.chip;
    void open(Widget page) {
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => page));
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: c.sheet,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
        child: SizedBox(
          width: 300,
          height: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tap(
                    onTap: () => open(const PlaceholderPage(title: 'Profile', back: 'Home')),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: cardBg, borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFB5C74), Color(0xFFFA233B)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const MIcon(MIcons.user, size: 28, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Your Name',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('View Profile', style: TextStyle(fontSize: 14, color: c.sub)),
                          ]),
                        ),
                        MIcon(MIcons.chevronRight, size: 18, color: c.sub),
                      ]),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration:
                        BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: Tap(
                      onTap: () => open(const PlaceholderPage(title: 'Settings', back: 'Home')),
                      child: SizedBox(
                        height: 56,
                        child: Row(children: [
                          const SizedBox(width: 12),
                          const MIcon(MIcons.settings, color: kRed),
                          const SizedBox(width: 14),
                          const Expanded(
                              child: Text('Settings',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
                          MIcon(MIcons.chevronRight, size: 18, color: c.sub),
                          const SizedBox(width: 12),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
