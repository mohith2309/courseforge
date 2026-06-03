import 'package:flutter/material.dart';

/// A subtle entrance: fade in while rising a few pixels. Staggered by [index]
/// for lists so items arrive in sequence — not a theme park, just enough to
/// feel intentional. No-ops under reduced-motion.
class FadeInUp extends StatelessWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.index = 0,
    this.distance = 12,
  });

  final Widget child;
  final int index;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return child;

    final delayMs = (index * 45).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        // Hold at start until the stagger delay has elapsed.
        final span = 320 / (320 + delayMs);
        final start = 1 - span;
        final p = t <= start ? 0.0 : ((t - start) / span).clamp(0.0, 1.0);
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, (1 - p) * distance),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
