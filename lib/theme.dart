import 'package:flutter/material.dart';

/// Brand red used across Music+.
const kRed = Color(0xFFFA2D48);

/// Design tokens from the Music+ design, light and dark.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.page,
    required this.text,
    required this.sub,
    required this.chip,
    required this.mini,
    required this.line,
    required this.link,
    required this.dock,
    required this.dockBorder,
    required this.dockShadow,
    required this.activeBg,
    required this.sheet,
    required this.scrim,
    required this.grabber,
    required this.menu,
    required this.badgeBg,
    required this.badgeFg,
    required this.npBg,
    required this.npSub,
    required this.npChip,
    required this.npTrack,
    required this.npActiveBg,
    required this.npActiveFg,
    required this.playBg,
    required this.playFg,
    required this.artShadow,
  });

  final Color page, text, sub, chip, mini, line, link;
  final Color dock, dockBorder, dockShadow, activeBg;
  final Color sheet, scrim, grabber, menu, badgeBg, badgeFg;
  final Color npBg, npSub, npChip, npTrack, npActiveBg, npActiveFg;
  final Color playBg, playFg, artShadow;

  static const light = AppColors(
    page: Color(0xFFFFFFFF),
    text: Color(0xFF111114),
    sub: Color(0xFF6B6B76),
    chip: Color(0xFFF4F4F7),
    mini: Color(0xFFF4F4F7),
    line: Color(0xFFE8E8EC),
    link: Color(0xFFD7193A),
    dock: Color(0xFFFFFFFF),
    dockBorder: Color(0xFFE8E8EC),
    dockShadow: Color(0x1F111114),
    activeBg: Color(0xFFFFEEF1),
    sheet: Color(0xFFFFFFFF),
    scrim: Color(0x4D111114),
    grabber: Color(0xFFD1D1D6),
    menu: Color(0xFFFFFFFF),
    badgeBg: Color(0xFFFFFFFF),
    badgeFg: Color(0xFF111114),
    npBg: Color(0xFFFFF1F3),
    npSub: Color(0xFF5C5C66),
    npChip: Color(0x12111114),
    npTrack: Color(0x24111114),
    npActiveBg: Color(0x24FA2D48),
    npActiveFg: Color(0xFFD7193A),
    playBg: Color(0xFF111114),
    playFg: Color(0xFFFFFFFF),
    artShadow: Color(0x471E1B4B),
  );

  static const dark = AppColors(
    page: Color(0xFF000000),
    text: Color(0xFFFFFFFF),
    sub: Color(0xFF8E8E93),
    chip: Color(0xFF1C1C1E),
    mini: Color(0xFF1C1C1E),
    line: Color(0xFF38383A),
    link: Color(0xFFFF4D66),
    dock: Color(0xFF1C1C1E),
    dockBorder: Color(0xFF2C2C2E),
    dockShadow: Color(0x80000000),
    activeBg: Color(0x29FA2D48),
    sheet: Color(0xFF1C1C1E),
    scrim: Color(0x8C000000),
    grabber: Color(0xFF48484A),
    menu: Color(0xFF2C2C2E),
    badgeBg: Color(0xFF000000),
    badgeFg: Color(0xFFFFFFFF),
    npBg: Color(0xFF14122B),
    npSub: Color(0xFFABA8CC),
    npChip: Color(0x1AFFFFFF),
    npTrack: Color(0x2EFFFFFF),
    npActiveBg: Color(0x38FA2D48),
    npActiveFg: Color(0xFFFF4D66),
    playBg: Color(0xFFFFFFFF),
    playFg: Color(0xFF000000),
    artShadow: Color(0x80000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness b) {
  final colors = b == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kRed,
      brightness: b,
      primary: kRed,
      surface: colors.page,
    ),
    scaffoldBackgroundColor: colors.page,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: kRed),
  );
}

/// Shared text styles from the design.
class T {
  static const largeTitle = TextStyle(
      fontSize: 34, height: 44 / 34, fontWeight: FontWeight.w700, letterSpacing: -1.0);
  static const section = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4);
  static const rowTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const rowSub = TextStyle(fontSize: 14);
}
