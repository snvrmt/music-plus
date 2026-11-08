import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The exact icons from the Music+ design, drawn from their SVG paths.
class MIcon extends StatelessWidget {
  const MIcon(this.icon, {super.key, this.size = 24, this.color, this.stroke});

  final MIcons icon;
  final double size;
  final Color? color;
  final double? stroke;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color ?? Colors.black;
    final sw = stroke ?? icon.stroke;
    final attrs = icon.filled
        ? 'fill="#000"'
        : 'fill="none" stroke="#000" stroke-width="$sw" '
            'stroke-linecap="round" stroke-linejoin="round"';
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        '$attrs>${icon.body}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

enum MIcons {
  home('<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>'),
  search('<circle cx="11" cy="11" r="7"/><path d="m20 20-4.2-4.2"/>'),
  podcasts('<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>'),
  music('<path d="M9 18V6l11-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="17.5" cy="16" r="2.5"/>'),
  user('<circle cx="12" cy="8" r="4"/><path d="M4 20c1.5-4 14.5-4 16 0"/>'),
  album('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="2.5"/>'),
  heart('<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>', stroke: 1.9),
  heartFilled('<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>', filled: true),
  download('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v8m0 0-3.2-3.2m3.2 3.2 3.2-3.2"/>'),
  downloadBadge('<path d="M12 4v12m0 0-5-5m5 5 5-5M5 20h14"/>', stroke: 2.2),
  downloaded('<circle cx="12" cy="12" r="10"/>', filled: true),
  check('<path d="m5 12.5 4.5 4.5L19 7.5"/>', stroke: 2.6),
  play('<path d="M8 5.5v13l11-6.5z"/>', filled: true),
  pause('<rect x="6" y="5" width="4" height="14" rx="1.2"/><rect x="14" y="5" width="4" height="14" rx="1.2"/>', filled: true),
  next('<path d="M5 6l9 6-9 6z"/><rect x="16.5" y="6" width="2.5" height="12" rx="1"/>', filled: true),
  previous('<path d="M19 6l-9 6 9 6z"/><rect x="5" y="6" width="2.5" height="12" rx="1"/>', filled: true),
  more('<circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/>', filled: true),
  chevronRight('<path d="m9 6 6 6-6 6"/>', stroke: 2.2),
  chevronLeft('<path d="m15 5-7 7 7 7"/>', stroke: 2.2),
  plus('<path d="M12 5v14M5 12h14"/>', stroke: 2.2),
  close('<path d="M6 6l12 12M18 6 6 18"/>', stroke: 2.2),
  shuffle('<path d="M3 7h3.5a4 4 0 0 1 3.2 1.6l4.6 6.8a4 4 0 0 0 3.2 1.6H21m0 0-3-3m3 3-3 3M3 17h3.5a4 4 0 0 0 3-1.3M14 8.6A4 4 0 0 1 17.5 7H21m0 0-3-3m3 3-3 3"/>'),
  repeat('<path d="m17 3 3 3-3 3M4 11V9a3 3 0 0 1 3-3h13M7 21l-3-3 3-3M20 13v2a3 3 0 0 1-3 3H4"/>'),
  repeatOne('<path d="m17 3 3 3-3 3M4 11V9a3 3 0 0 1 3-3h13M7 21l-3-3 3-3M20 13v2a3 3 0 0 1-3 3H4"/><path d="M11.5 10.5 13 9.5v5"/>'),
  devices('<rect x="6" y="3" width="12" height="18" rx="2"/><circle cx="12" cy="14" r="3"/><circle cx="12" cy="7" r="1"/>'),
  lyrics('<path d="M4 5h16v11H9l-5 4z"/><path d="M8 9.5h8M8 12.5h5"/>'),
  queue('<path d="M4 6h16M4 12h10M4 18h7"/><path d="M17 14v6m-3-3h6"/>'),
  playlistAdd('<path d="M4 6h12M4 11h12M4 16h7m10-2v6m-3-3h6"/>', stroke: 1.9),
  playNext('<path d="M4 7h10M4 12h10M4 17h6m6-3 4 3-4 3z"/>', stroke: 1.9),
  share('<path d="M12 4v11M8 8l4-4 4 4M6 13v5a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2v-5"/>', stroke: 1.9),
  importIcon('<path d="M12 4v11m0 0-4-4m4 4 4-4"/><path d="M5 15v3a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-3"/>', stroke: 2),
  phone('<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M11 18.5h2"/>'),
  grip('<path d="M5 9h14M5 15h14"/>', stroke: 2),
  settings('<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>');

  const MIcons(this.body, {this.filled = false, this.stroke = 1.8});
  final String body;
  final bool filled;
  final double stroke;
}
