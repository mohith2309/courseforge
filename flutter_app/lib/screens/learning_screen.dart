import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/lesson_player.dart';
import '../widgets/pressable.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  final Set<String> _tried = {};
  String? _busyLesson;

  bool _thin(Lesson l) => l.script.trim().split(RegExp(r'\s+')).length < 150;

  /// On opening an AI-built lesson with thin/placeholder text, fetch a full
  /// taught version from the backend, then save it into the course.
  Future<void> _maybeGenerate(Course course, Lesson lesson) async {
    final api = ref.read(apiClientProvider);
    if (!api.isConfigured || !course.aiGenerated) return;
    if (!_thin(lesson) || _tried.contains(lesson.id) || _busyLesson != null) {
      return;
    }
    _tried.add(lesson.id);
    setState(() => _busyLesson = lesson.id);

    final module = course.modules.firstWhere(
      (m) => m.lessons.any((l) => l.id == lesson.id),
      orElse: () => course.modules.first,
    );
    try {
      final data = await api.generateLesson(
        courseTitle: course.title,
        moduleTitle: module.title,
        lessonTitle: lesson.title,
        summary: lesson.summary,
      );
      if (data != null && (data['script']?.toString().isNotEmpty ?? false)) {
        await ref.read(coursesProvider.notifier).updateLesson(
          course.id,
          lesson.id,
          {
            'script': data['script'],
            if (data['keyPoints'] != null) 'keyPoints': data['keyPoints'],
            if (data['quiz'] != null) 'quiz': data['quiz'],
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Couldn’t expand this lesson — showing the outline.')));
      }
    } catch (_) {
      // Timeout / flaky network — fall back to the outline, never hang the screen.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Network hiccup — showing the outline. Reopen to retry.')));
      }
    } finally {
      // Always clear the spinner, success or failure.
      if (mounted) setState(() => _busyLesson = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('Course not found')));
        }
        final lessons = course.allLessons;
        final index = lessons.indexWhere((l) => l.id == widget.lessonId);
        if (index < 0) {
          return const Scaffold(body: Center(child: Text('Lesson not found')));
        }
        final lesson = lessons[index];
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeGenerate(course, lesson));
        if (_busyLesson == lesson.id) {
          return _PreparingLesson(title: lesson.title);
        }
        return _LessonView(course: course, lessons: lessons, index: index);
      },
    );
  }
}

/// Full-screen "writing your lesson" state while the AI teaches it.
class _PreparingLesson extends StatelessWidget {
  const _PreparingLesson({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: Gap.lg),
              Text('Writing your lesson…',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Gap.sm),
              Text('“$title”',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted)),
              const SizedBox(height: Gap.xs),
              Text('Your tutor is explaining this in depth.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonView extends ConsumerWidget {
  const _LessonView({
    required this.course,
    required this.lessons,
    required this.index,
  });
  final Course course;
  final List<Lesson> lessons;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = lessons[index];
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final bookmarked = progress.bookmarkedLessonIds.contains(lesson.id);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dMuted
        : AppColors.muted;

    final prev = index > 0 ? lessons[index - 1] : null;
    final next = index < lessons.length - 1 ? lessons[index + 1] : null;

    void goTo(Lesson l) =>
        context.pushReplacement('/learn/${course.id}/${l.id}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${index + 1} of ${lessons.length}'),
        actions: [
          IconButton(
            tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
            icon: Icon(bookmarked
                ? Icons.bookmark
                : Icons.bookmark_border),
            color: bookmarked ? AppColors.accent : null,
            onPressed: () => notifier.toggleBookmark(lesson.id),
          ),
          IconButton(
            tooltip: 'Lessons',
            icon: const Icon(Icons.list),
            onPressed: () => _showLessonList(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          Text(lesson.title,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Gap.sm),
          Row(children: [
            Icon(Icons.schedule, size: 15, color: muted),
            const SizedBox(width: 4),
            Text('${lesson.durationMinutes} min read',
                style: TextStyle(color: muted)),
          ]),
          const SizedBox(height: Gap.md),

          // Interactive lesson video — plays the generated content as a
          // narrated slide reel. Free = short + watermark; Pro = full, no mark.
          LessonPlayer(
            lesson: lesson,
            isPro: ref.watch(isProProvider),
            onUpgrade: () => context.push('/upgrade'),
          ),
          const SizedBox(height: Gap.lg),

          if (lesson.summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(lesson.summary,
                  style: const TextStyle(height: 1.5, fontSize: 15)),
            ),
            const SizedBox(height: Gap.lg),
          ],

          Text(lesson.script, style: const TextStyle(height: 1.65, fontSize: 16)),
          const SizedBox(height: Gap.lg),

          if (lesson.keyPoints.isNotEmpty) ...[
            Text('Key points',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            for (final kp in lesson.keyPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                        child: Text(kp,
                            style: const TextStyle(height: 1.45))),
                  ],
                ),
              ),
            const SizedBox(height: Gap.md),
          ],

          OutlinedButton.icon(
            onPressed: () => _editNote(context, ref, lesson),
            icon: const Icon(Icons.edit_note),
            label: Text(progress.notes.containsKey(lesson.id)
                ? 'Edit your note'
                : 'Add a note'),
          ),
          if (progress.notes[lesson.id]?.isNotEmpty ?? false) ...[
            const SizedBox(height: Gap.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: context.surfaceAlt,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(progress.notes[lesson.id]!,
                  style: TextStyle(color: context.fg)),
            ),
          ],

          const SizedBox(height: Gap.lg),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/doubt/${course.id}/${lesson.id}'),
            icon: const Icon(Icons.psychology_alt_outlined),
            label: const Text('Ask the AI doubt-solver'),
          ),

          const SizedBox(height: Gap.lg),
          const Divider(),
          const SizedBox(height: Gap.md),

          // Primary action: take the quiz (marks lesson complete via quiz),
          // or mark complete directly if the lesson has no quiz.
          if (lesson.quiz != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () =>
                  context.push('/quiz/${course.id}/${lesson.id}'),
              icon: const Icon(Icons.quiz_outlined),
              label: Text('Take quiz · ${lesson.quiz!.questions.length} Qs'),
            )
          else
            FilledButton.icon(
              onPressed: () async {
                await notifier.completeLesson(
                    lesson.id, lesson.durationMinutes);
                if (context.mounted && next != null) goTo(next);
              },
              icon: const Icon(Icons.check),
              label: const Text('Mark complete'),
            ),

          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: () => _practiceMore(context, ref, lesson),
            icon: const Icon(Icons.refresh),
            label: const Text('Practice more (AI generates new questions)'),
          ),

          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: prev == null ? null : () => goTo(prev),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: OutlinedButton(
                  // Next always works and marks this lesson done — the quiz is
                  // optional, never a gate to moving forward.
                  onPressed: next == null
                      ? null
                      : () async {
                          await notifier.completeLesson(
                              lesson.id, lesson.durationMinutes);
                          Buzz.light();
                          if (context.mounted) goTo(next);
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('Next'), Icon(Icons.chevron_right)],
                  ),
                ),
              ),
            ],
          ),
          if (lesson.quiz != null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: Text(
                'The quiz is optional — you can move on anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  /// Generates a fresh, adaptive practice set (harder once you've passed once)
  /// and opens it. Routed to NIM via the AI service.
  Future<void> _practiceMore(
      BuildContext context, WidgetRef ref, Lesson lesson) async {
    final isPro = ref.read(isProProvider);
    final hearts = ref.read(progressProvider).heartsRemaining;
    if (!isPro && hearts <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Out of hearts'),
          content: const Text(
            'You\'ve used today\'s practice hearts. They refill tomorrow — or '
            'go Pro for unlimited practice.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Maybe later')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/upgrade');
              },
              child: const Text('Go Pro'),
            ),
          ],
        ),
      );
      return;
    }
    final scores = ref.read(progressProvider).quizScores;
    final passedBefore = (scores[lesson.quiz?.id] ?? 0) >= 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final questions = await ref.read(aiServiceProvider).generatePracticeQuiz(
          lesson: lesson,
          difficulty: passedBefore ? 'hard' : 'medium',
        );
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close spinner
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate questions. Try again.')),
      );
      return;
    }
    ref.read(practiceQuizProvider.notifier).state = questions;
    if (context.mounted) {
      context.push('/practice/${course.id}/${lesson.id}');
    }
  }

  void _showLessonList(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        final progress = ref.read(progressProvider);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, controller) => ListView.builder(
            controller: controller,
            itemCount: lessons.length,
            itemBuilder: (_, i) {
              final l = lessons[i];
              final done = progress.completedLessonIds.contains(l.id);
              return ListTile(
                leading: Icon(
                  done ? Icons.check_circle : Icons.circle_outlined,
                  color: done ? AppColors.success : null,
                ),
                title: Text(l.title),
                subtitle: Text('${l.durationMinutes} min'),
                selected: i == index,
                onTap: () {
                  Navigator.pop(context);
                  context.pushReplacement('/learn/${course.id}/${l.id}');
                },
              );
            },
          ),
        );
      },
    );
  }

  void _editNote(BuildContext context, WidgetRef ref, Lesson lesson) {
    final controller = TextEditingController(
        text: ref.read(progressProvider).notes[lesson.id] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: Gap.md,
          right: Gap.md,
          top: Gap.sm,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + Gap.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your note', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write what you want to remember…',
              ),
            ),
            const SizedBox(height: Gap.md),
            FilledButton(
              onPressed: () {
                ref
                    .read(progressProvider.notifier)
                    .saveNote(lesson.id, controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }
}
