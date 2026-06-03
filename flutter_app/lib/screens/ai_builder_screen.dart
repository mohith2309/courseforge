import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_bar.dart';

class AIBuilderScreen extends ConsumerStatefulWidget {
  const AIBuilderScreen({super.key});

  @override
  ConsumerState<AIBuilderScreen> createState() => _AIBuilderScreenState();
}

class _AIBuilderScreenState extends ConsumerState<AIBuilderScreen> {
  final _controller = TextEditingController();

  static const _examples = [
    'I\'m studying for IAS, help me crack it',
    'Teach me Python from scratch',
    'Prepare me for IELTS speaking',
    'I want to understand the stock market',
    'Help me learn basic French',
  ];

  Future<void> _build() async {
    final goal = _controller.text.trim();
    if (goal.isEmpty) return;
    FocusScope.of(context).unfocus();
    final course =
        await ref.read(courseGenerationProvider.notifier).generate(goal);
    if (course != null && mounted) {
      ref.read(courseGenerationProvider.notifier).reset();
      context.push('/course/${course.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gen = ref.watch(courseGenerationProvider);
    final coursesAsync = ref.watch(coursesProvider);

    if (gen.isLoading) {
      return const Scaffold(body: SafeArea(child: _BuildingView()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 96),
          children: [
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                const CourseThumb(emoji: '🔨', size: 40, radius: Radii.sm),
                const SizedBox(width: Gap.sm),
                Text('CourseForge',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                _UpgradePill(),
              ],
            ),
            const SizedBox(height: Gap.md),
            const GameBar(),
            const SizedBox(height: Gap.xl),
            Text('What do you want to learn?',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: Gap.sm),
            Text(
              'Tell me your goal in your own words. I\'ll build a full course '
              'for you — modules, lessons, and quizzes — and you can start '
              'right away.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dMuted
                    : AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _build(),
              decoration: const InputDecoration(
                hintText: 'e.g. I\'m studying for IAS, help me crack it',
              ),
            ),
            const SizedBox(height: Gap.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _build,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Build my course'),
            ),
            if (gen.hasError) ...[
              const SizedBox(height: Gap.sm),
              Text('Something went wrong. Please try again.',
                  style: const TextStyle(color: AppColors.destructive)),
            ],
            const SizedBox(height: Gap.lg),
            Text('Try one of these',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final ex in _examples)
                  ActionChip(
                    label: Text(ex),
                    onPressed: () {
                      _controller.text = ex;
                      _build();
                    },
                  ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            coursesAsync.maybeWhen(
              data: (courses) {
                final aiCourses =
                    courses.where((c) => c.aiGenerated).toList();
                if (aiCourses.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your AI courses',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: Gap.sm),
                    for (final c in aiCourses) _AICourseTile(course: c),
                  ],
                );
              },
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradePill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.pill),
      onTap: () => context.push('/upgrade'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPro ? AppColors.primary : AppColors.accent,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPro ? Icons.workspace_premium : Icons.bolt,
                size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(isPro ? 'Pro' : 'Upgrade',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AICourseTile extends ConsumerWidget {
  const _AICourseTile({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completion =
        ref.read(progressProvider.notifier).completionFor(course);
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      child: ListTile(
        leading: CourseThumb(emoji: course.thumbnailEmoji, size: 44),
        title: Text(course.title),
        subtitle: Text(
          '${course.modules.length} modules · ${course.totalLessons} lessons'
          ' · ${(completion * 100).round()}% done',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/course/${course.id}'),
      ),
    );
  }
}

/// Full-screen "building your course" state with cycling status lines.
class _BuildingView extends StatefulWidget {
  const _BuildingView();

  @override
  State<_BuildingView> createState() => _BuildingViewState();
}

class _BuildingViewState extends State<_BuildingView> {
  static const _steps = [
    'Understanding your goal…',
    'Designing the right modules…',
    'Writing your lessons…',
    'Creating quizzes to test you…',
    'Putting it all together…',
  ];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: Gap.lg),
            Text('Building your course',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Gap.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _steps[_i],
                key: ValueKey(_i),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dMuted
                      : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
