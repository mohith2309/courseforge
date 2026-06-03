import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'pressable.dart';

/// Standard catalog card used in lists and search results.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.progress});

  final Course course;
  final double? progress; // null = not enrolled

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;
    return Card(
      child: Pressable(
        onTap: () => context.push('/course/${course.id}'),
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CourseThumb(emoji: course.thumbnailEmoji),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(course.subtitle,
                            style: TextStyle(color: muted, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  StatChip(
                      icon: Icons.star_rounded,
                      label:
                          '${course.rating} (${course.reviewCount})'),
                  const SizedBox(width: Gap.md),
                  StatChip(
                      icon: Icons.play_lesson_outlined,
                      label: '${course.totalLessons} lessons'),
                  const Spacer(),
                  Text(priceLabel(course.priceInr),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.accent)),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: Gap.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${(progress! * 100).round()}% complete',
                    style: TextStyle(color: muted, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
