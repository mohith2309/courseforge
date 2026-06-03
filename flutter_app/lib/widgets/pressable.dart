import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tappable wrapper that gives the "premium" feel: a subtle scale-down on
/// press (spring-like) plus a light haptic the instant your finger lands —
/// so the element feels like a physical object, not a flat rectangle.
///
/// Respects reduced-motion (skips the scale, keeps the haptic + tap).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = (_down && !reduceMotion) ? widget.scale : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _down = true);
        if (widget.haptic) HapticFeedback.selectionClick();
      },
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Small helper for the common success moments — a slightly weightier tap.
class Buzz {
  Buzz._();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void select() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
}
