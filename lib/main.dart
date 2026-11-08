import 'package:flutter/material.dart';

void main() => runApp(const MusicPlayerApp());

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF2D55),
        scaffoldBackgroundColor: const Color(0xFF0E0E10),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}

/// Bottom-tab shell: Home, Search, Library, with a mini-player above the tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  static const _pages = [
    _PlaceholderPage(
      icon: Icons.home_rounded,
      title: 'Home',
      subtitle: 'Recently played and downloads will live here.',
    ),
    _PlaceholderPage(
      icon: Icons.search_rounded,
      title: 'Search',
      subtitle: 'YouTube Music search arrives in Phase 3.',
    ),
    _PlaceholderPage(
      icon: Icons.library_music_rounded,
      title: 'Library',
      subtitle: 'Playlists, albums and offline tracks arrive in Phase 4.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_tab]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MiniPlayer(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
              NavigationDestination(
                  icon: Icon(Icons.library_music_rounded), label: 'Library'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(icon, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Static mini-player for now; it gets wired to the real player in Phase 2.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.music_note_rounded,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nothing playing',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Phase 1 build works!',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.play_arrow_rounded, size: 30),
          ),
        ],
      ),
    );
  }
}
