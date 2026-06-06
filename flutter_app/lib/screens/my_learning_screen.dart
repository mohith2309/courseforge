import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/course_card.dart';

class MyLearningScreen extends ConsumerWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('My Learning')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final enrolled = all
              .where((c) => progress.enrolledCourseIds.contains(c.id))
              .toList();
          if (enrolled.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No courses yet',
              message: 'Enroll in a course to start learning. '
                  'The IAS foundation course is a great place to begin.',
              action: FilledButton(
                onPressed: () => context.go('/browse'),
                child: const Text('Browse courses'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 96),
            children: [
              for (final c in enrolled) ...[
                CourseCard(
                  course: c,
                  progress: notifier.completionFor(c),
                ),
                const SizedBox(height: Gap.md),
              ],
              if (progress.bookmarkedLessonIds.isNotEmpty)
                _BookmarksSection(courses: enrolled),
            ],
          );
        },
      ),
    );
  }
}

class _BookmarksSection extends ConsumerWidget {
  const _BookmarksSection({required this.courses});
  final List<Course> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(progressProvider).bookmarkedLessonIds;
    final entries = <(Course, Lesson)>[];
    for (final c in courses) {
      // Optimization: Iterate modules/lessons directly to avoid O(L) list allocations in .allLessons
      for (final m in c.modules) {
        for (final l in m.lessons) {
          if (marks.contains(l.id)) entries.add((c, l));
        }
      }
    }
    if (entries.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Gap.sm),
        Text('Bookmarks', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Gap.sm),
        for (final (course, lesson) in entries)
          Card(
            margin: const EdgeInsets.only(bottom: Gap.sm),
            child: ListTile(
              leading: const Icon(Icons.bookmark, color: Color(0xFFEA580C)),
              title: Text(lesson.title),
              subtitle: Text(course.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push('/learn/${course.id}/${lesson.id}'),
            ),
          ),
      ],
    );
  }
}
