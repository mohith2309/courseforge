import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmering placeholder block. Premium apps reserve the layout and shimmer
/// while loading instead of showing a bare spinner (no layout shift, less
/// "waiting"). Respects reduced-motion (static block, no sweep).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });
  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final base = context.surfaceAlt;
    final hi = context.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    Widget box(Gradient? g) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base,
            gradient: g,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );

    if (reduce) return box(null);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final dx = (_c.value * 2) - 1; // -1 → 1 sweep
        return box(LinearGradient(
          begin: Alignment(dx - 0.6, 0),
          end: Alignment(dx + 0.6, 0),
          colors: [base, hi, base],
          stops: const [0.35, 0.5, 0.65],
        ));
      },
    );
  }
}

/// Placeholder shaped like a course card, for list loading states.
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Skeleton(width: 64, height: 64, radius: Radii.md),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 180, height: 16),
                      SizedBox(height: 8),
                      Skeleton(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            const Skeleton(width: double.infinity, height: 38, radius: Radii.sm),
          ],
        ),
      ),
    );
  }
}

/// A short stack of card skeletons.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Gap.md),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
      itemBuilder: (_, _) => const CourseCardSkeleton(),
    );
  }
}
