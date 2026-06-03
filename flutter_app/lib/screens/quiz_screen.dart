import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    this.practice = false,
  });
  final String courseId;
  final String lessonId;

  /// When true, questions come from [practiceQuizProvider] (AI-generated)
  /// instead of the lesson's built-in quiz.
  final bool practice;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _current = 0;
  int? _selected;
  bool _revealed = false;
  int _correct = 0;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('Not found')));
        }
        final lesson = course.allLessons
            .firstWhere((l) => l.id == widget.lessonId);
        final quiz = widget.practice
            ? Quiz(
                id: 'practice-${lesson.id}',
                title: 'Practice',
                passPercentage: 60,
                questions: ref.read(practiceQuizProvider),
              )
            : lesson.quiz;
        if (quiz == null || quiz.questions.isEmpty) {
          return const Scaffold(body: Center(child: Text('No questions here')));
        }
        return _finished
            ? _buildResult(course, lesson, quiz)
            : _buildQuestion(course, lesson, quiz);
      },
    );
  }

  Widget _buildQuestion(Course course, Lesson lesson, Quiz quiz) {
    final q = quiz.questions[_current];
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · Q${_current + 1}/${quiz.questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_current + (_revealed ? 1 : 0)) / quiz.questions.length,
            minHeight: 4,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          Text(q.stem,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(height: 1.4)),
          const SizedBox(height: Gap.lg),
          for (int i = 0; i < q.options.length; i++)
            _OptionTile(
              text: q.options[i],
              state: _stateFor(i, q),
              onTap: _revealed
                  ? null
                  : () {
                      Buzz.select();
                      setState(() => _selected = i);
                    },
            ),
          const SizedBox(height: Gap.md),
          if (_revealed)
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: context.surfaceAlt,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selected == q.correctIndex
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _selected == q.correctIndex
                            ? AppColors.success
                            : AppColors.destructive,
                      ),
                      const SizedBox(width: Gap.sm),
                      Text(
                        _selected == q.correctIndex
                            ? 'Correct'
                            : 'Not quite',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(q.explanation,
                      style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: _revealed
              ? FilledButton(
                  onPressed: () => _advance(quiz),
                  child: Text(_current == quiz.questions.length - 1
                      ? 'See result'
                      : 'Next question'),
                )
              : FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          final correct = _selected == q.correctIndex;
                          setState(() {
                            _revealed = true;
                            if (correct) _correct++;
                          });
                          correct ? Buzz.light() : Buzz.heavy();
                          // Practice quizzes cost a heart per miss (Free only).
                          if (!correct &&
                              widget.practice &&
                              !ref.read(isProProvider)) {
                            ref.read(progressProvider.notifier).useHeart();
                          }
                        },
                  child: const Text('Check answer'),
                ),
        ),
      ),
    );
  }

  _OptState _stateFor(int i, Question q) {
    if (!_revealed) {
      return _selected == i ? _OptState.selected : _OptState.idle;
    }
    if (i == q.correctIndex) return _OptState.correct;
    if (i == _selected) return _OptState.wrong;
    return _OptState.idle;
  }

  void _advance(Quiz quiz) {
    if (_current == quiz.questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _current++;
      _selected = null;
      _revealed = false;
    });
  }

  bool _recorded = false;
  int _xpGained = 0;

  Widget _buildResult(Course course, Lesson lesson, Quiz quiz) {
    final percent = ((_correct / quiz.questions.length) * 100).round();
    final passed = percent >= quiz.passPercentage;

    // Record score once; passing marks the lesson complete and awards XP.
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(progressProvider.notifier);
        final before = ref.read(progressProvider).xp;
        notifier.recordQuizScore(quiz.id, percent);
        if (passed) notifier.completeLesson(lesson.id, lesson.durationMinutes);
        final gained = ref.read(progressProvider).xp - before;
        passed ? Buzz.success() : Buzz.light();
        if (mounted && gained > 0) setState(() => _xpGained = gained);
      });
    }

    final lessons = course.allLessons;
    final index = lessons.indexWhere((l) => l.id == lesson.id);
    final next = index < lessons.length - 1 ? lessons[index + 1] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.workspace_premium : Icons.refresh,
                size: 72,
                color: passed ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: Gap.md),
              Text('$percent%',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: Gap.sm),
              Text(
                passed
                    ? 'Passed! ($_correct/${quiz.questions.length} correct)'
                    : 'You need ${quiz.passPercentage}% to pass. '
                        'Try again — unlimited retakes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_xpGained > 0) ...[
                const SizedBox(height: Gap.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.accent, size: 18),
                      const SizedBox(width: 4),
                      Text('+$_xpGained XP',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.xl),
              if (passed && next != null)
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => context
                      .pushReplacement('/learn/${course.id}/${next.id}'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next lesson'),
                ),
              if (passed && next == null)
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () => context.go('/progress'),
                  icon: const Icon(Icons.celebration),
                  label: const Text('Course complete — view progress'),
                ),
              if (!passed)
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _current = 0;
                    _selected = null;
                    _revealed = false;
                    _correct = 0;
                    _finished = false;
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake quiz'),
                ),
              const SizedBox(height: Gap.sm),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to lesson'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, bg, icon) = switch (state) {
      _OptState.idle => (AppColors.border, null, null),
      _OptState.selected => (AppColors.primary, AppColors.primary.withValues(alpha: 0.08), null),
      _OptState.correct => (AppColors.success, AppColors.success.withValues(alpha: 0.10), Icons.check_circle),
      _OptState.wrong => (AppColors.destructive, AppColors.destructive.withValues(alpha: 0.10), Icons.cancel),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
                color: border,
                width: state == _OptState.idle ? 1 : 2),
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(text,
                      style: const TextStyle(fontSize: 15, height: 1.3))),
              if (icon != null)
                Icon(icon,
                    color: state == _OptState.correct
                        ? AppColors.success
                        : AppColors.destructive),
            ],
          ),
        ),
      ),
    );
  }
}
