import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Terang: warna polos. Gelap: gradasi navy + cahaya statis (murah, tanpa blur).
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  Widget _blob(Color warna, double ukuran,
      {double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: ukuran, height: ukuran,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              warna.withValues(alpha: 0.30),
              warna.withValues(alpha: 0),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    if (!c.isDark) {
      return ColoredBox(color: c.bg, child: child);
    }
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1222), Color(0xFF14213F), Color(0xFF1C2F5A)],
              ),
            ),
          ),
        ),
        _blob(const Color(0xFFE8B04B), 300, top: -100, right: -120),
        _blob(const Color(0xFF4DA3FF), 340, bottom: 140, left: -170),
        child,
      ],
    );
  }
}

/// Terang: kartu putih bersudut bulat. Gelap: kaca (blur hanya jika blur:true).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;

    if (!c.isDark) {
      return RepaintBoundary(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003882).withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    final isi = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: c.cardBorder),
      ),
      child: child,
    );

    final pakaiBlur = blur && !MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: pakaiBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: isi,
              )
            : isi,
      ),
    );
  }
}