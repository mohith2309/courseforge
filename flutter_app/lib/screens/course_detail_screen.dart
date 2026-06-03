import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));

    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (course) {
        if (course == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.error_outline,
              title: 'Not found',
              message: 'This course no longer exists.',
            ),
          );
        }
        return Scaffold(
          body: _Detail(course: course),
          bottomNavigationBar: _EnrollBar(course: course),
        );
      },
    );
  }
}

class _EnrollBar extends ConsumerWidget {
  const _EnrollBar({required this.course});
  final Course course;

  Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    // Free courses (incl. AI-built) enroll straight away; paid ones open the
    // native Razorpay sheet first.
    if (course.priceInr > 0) {
      final result = await ref.read(razorpayCheckoutProvider).pay(
            amountInr: course.priceInr,
            description: course.title,
          );
      if (!result.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Payment cancelled')),
          );
        }
        return;
      }
    }

    await ref.read(progressProvider.notifier).enroll(course.id);
    Buzz.success();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrolled! 🎉')),
    );
    final first = course.allLessons.first;
    context.push('/learn/${course.id}/${first.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final enrolled = progress.enrolledCourseIds.contains(course.id);
    final notifier = ref.read(progressProvider.notifier);
    final completion = notifier.completionFor(course);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: enrolled
            ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () {
                  // Resume at first incomplete lesson, else lesson 1.
                  final next = course.allLessons.firstWhere(
                    (l) => !progress.completedLessonIds.contains(l.id),
                    orElse: () => course.allLessons.first,
                  );
                  context.push('/learn/${course.id}/${next.id}');
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(completion >= 1.0
                    ? 'Review course'
                    : completion > 0
                        ? 'Continue (${(completion * 100).round()}%)'
                        : 'Start learning'),
              )
            : Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(priceLabel(course.priceInr),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppColors.accent)),
                      const Text('one-time',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      onPressed: () => _enroll(context, ref),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Enroll now'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorAsync = ref.watch(creatorProvider(course.creatorId));
    final progress = ref.watch(progressProvider);
    final enrolled = progress.enrolledCourseIds.contains(course.id);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.secondary],
                ),
              ),
              alignment: Alignment.center,
              child: Text(course.thumbnailEmoji,
                  style: const TextStyle(fontSize: 76)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Gap.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(course.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(course.subtitle, style: TextStyle(color: muted)),
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.md,
                runSpacing: Gap.sm,
                children: [
                  StatChip(
                      icon: Icons.star_rounded,
                      label: '${course.rating} (${course.reviewCount} reviews)'),
                  StatChip(
                      icon: Icons.people_outline,
                      label: '${course.enrollmentsCount} enrolled'),
                  StatChip(
                      icon: Icons.play_lesson_outlined,
                      label: '${course.totalLessons} lessons'),
                  StatChip(
                      icon: Icons.quiz_outlined,
                      label: '${course.totalQuestions} questions'),
                  StatChip(
                      icon: Icons.schedule,
                      label: '${course.totalMinutes} min'),
                ],
              ),
              const SizedBox(height: Gap.lg),
              Text('About this course',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              Text(course.description,
                  style: TextStyle(color: muted, height: 1.55)),
              const SizedBox(height: Gap.lg),
              creatorAsync.maybeWhen(
                data: (c) => c == null ? const SizedBox() : _CreatorTile(c),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: Gap.lg),
              Text('Course content',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
            ]),
          ),
        ),
        ..._buildModules(context, ref, enrolled),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  List<Widget> _buildModules(
      BuildContext context, WidgetRef ref, bool enrolled) {
    return [
      for (final module in course.modules)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: Card(
              margin: const EdgeInsets.only(bottom: Gap.md),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: module.order == 1,
                  tilePadding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  childrenPadding:
                      const EdgeInsets.only(bottom: Gap.sm),
                  title: Text(module.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('${module.lessons.length} lessons'),
                  children: [
                    for (final lesson in module.lessons)
                      _LessonRow(
                        course: course,
                        lesson: lesson,
                        enrolled: enrolled,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _CreatorTile extends StatelessWidget {
  const _CreatorTile(this.creator);
  final Creator creator;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceAlt,
            child: Text(creator.avatarEmoji,
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(creator.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(creator.bio,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends ConsumerWidget {
  const _LessonRow({
    required this.course,
    required this.lesson,
    required this.enrolled,
  });
  final Course course;
  final Lesson lesson;
  final bool enrolled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final done = progress.completedLessonIds.contains(lesson.id);
    final accessible = enrolled || lesson.freePreview;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md),
      leading: Icon(
        done
            ? Icons.check_circle
            : accessible
                ? Icons.play_circle_outline
                : Icons.lock_outline,
        color: done
            ? AppColors.success
            : accessible
                ? AppColors.primary
                : muted,
      ),
      title: Text(lesson.title),
      subtitle: Text(
        '${lesson.durationMinutes} min'
        '${lesson.freePreview ? ' · Free preview' : ''}',
        style: TextStyle(color: muted, fontSize: 12),
      ),
      trailing: accessible ? const Icon(Icons.chevron_right) : null,
      onTap: accessible
          ? () => context.push('/learn/${course.id}/${lesson.id}')
          : null,
    );
  }
}
