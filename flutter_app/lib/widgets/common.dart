import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A subtle gradient "thumbnail" tile carrying the course's emoji glyph.
/// Stands in for real cover art while keeping the UI on-brand and crisp.
class CourseThumb extends StatelessWidget {
  const CourseThumb({
    super.key,
    required this.emoji,
    this.size = 64,
    this.radius = Radii.md,
  });

  final String emoji;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: muted, fontSize: 13)),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.md, Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: muted),
            const SizedBox(height: Gap.md),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: Gap.sm),
            Text(message,
                style: TextStyle(color: muted),
                textAlign: TextAlign.center),
            if (action != null) const SizedBox(height: Gap.lg),
            ?action,
          ],
        ),
      ),
    );
  }
}

String priceLabel(int inr) => '₹${inr.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d\d)+\d$)'),
      (m) => '${m[1]},',
    )}';
