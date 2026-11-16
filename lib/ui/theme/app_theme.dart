import 'package:flutter/material.dart';

class DagiraColors extends ThemeExtension<DagiraColors> {
  const DagiraColors({
    required this.bg,
    required this.card,
    required this.cardBorder,
    required this.brand,
    required this.onBrand,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.masuk,
    required this.keluar,
    required this.warning,
    required this.chip,
    required this.info,
    required this.isDark,
  });

  final Color bg, card, cardBorder, brand, onBrand, accent, onAccent;
  final Color textPrimary, textSecondary, masuk, keluar, warning, chip, info;
  final bool isDark;

  static const terang = DagiraColors(
    bg: Color(0xFFF6F4EF),
    card: Colors.white,
    cardBorder: Color(0xFFE9E4D9),
    brand: Color(0xFF1F3A5F),
    onBrand: Colors.white,
    accent: Color(0xFFE8B04B),
    onAccent: Color(0xFF2B2006),
    textPrimary: Color(0xFF1B2433),
    textSecondary: Color(0xFF6B7385),
    masuk: Color(0xFF2E8B67),
    keluar: Color(0xFFCF5C55),
    warning: Color(0xFFB7791F),
    chip: Color(0xFFEFEBE2),
    info: Color(0xFF2F5D9B),
    isDark: false,
  );

  static const gelap = DagiraColors(
    bg: Color(0xFF0E1526),
    card: Color(0xFF18213A),
    cardBorder: Color(0x24FFFFFF),
    brand: Color(0xFF1E2F57),
    onBrand: Colors.white,
    accent: Color(0xFFE8B04B),
    onAccent: Color(0xFF2B2006),
    textPrimary: Color(0xFFEAEFF9),
    textSecondary: Color(0xFFA7B1C7),
    masuk: Color(0xFF5FD3A3),
    keluar: Color(0xFFF29089),
    warning: Color(0xFFF0C060),
    chip: Color(0xFF222D4B),
    info: Color(0xFF8DB4F0),
    isDark: true,
  );

  @override
  DagiraColors copyWith() => this;

  @override
  DagiraColors lerp(ThemeExtension<DagiraColors>? other, double t) =>
      t < 0.5 ? this : (other as DagiraColors? ?? this);
}

extension DagiraContext on BuildContext {
  DagiraColors get dg => Theme.of(this).extension<DagiraColors>()!;
}

class AppTheme {
  static ThemeData get terang => _bangun(DagiraColors.terang, Brightness.light);
  static ThemeData get gelap => _bangun(DagiraColors.gelap, Brightness.dark);

  static ThemeData _bangun(DagiraColors c, Brightness b) {
    final terang = b == Brightness.light;
    final skema = ColorScheme.fromSeed(
      seedColor: c.brand,
      brightness: b,
      primary: terang ? c.brand : c.accent,
      onPrimary: terang ? Colors.white : c.onAccent,
      secondary: c.accent,
      surface: c.card,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: skema,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: [c],
      textTheme: ThemeData(brightness: b).textTheme.apply(
            bodyColor: c.textPrimary,
            displayColor: c.textPrimary,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: terang ? c.brand : Colors.transparent,
        foregroundColor: terang ? Colors.white : c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: terang ? Colors.white : c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: c.accent,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? c.onAccent
                  : c.textSecondary,
            )),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
      ),
    );
  }
}