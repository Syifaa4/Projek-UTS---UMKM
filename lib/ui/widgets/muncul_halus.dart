import 'package:flutter/material.dart';

class MunculHalus extends StatelessWidget {
  const MunculHalus({
    super.key,
    required this.child,
    this.tunda = Duration.zero,
  });

  final Widget child;
  final Duration tunda;

  @override
  Widget build(BuildContext context) {
    // Hormati pengaturan "kurangi animasi" di HP
    if (MediaQuery.of(context).disableAnimations) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350) + tunda,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
