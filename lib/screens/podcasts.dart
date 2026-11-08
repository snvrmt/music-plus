import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

class PodcastsPage extends StatelessWidget {
  const PodcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const LargeTitle('Podcasts'),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: c.activeBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const MIcon(MIcons.podcasts, size: 34, color: kRed),
              ),
              const SizedBox(height: 16),
              const Text('No shows yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Follow shows from Search and new episodes will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: c.sub)),
            ]),
          ),
        ),
      ),
    ]);
  }
}
