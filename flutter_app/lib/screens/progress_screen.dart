import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'certificate_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final enrolled = all
              .where((c) => progress.enrolledCourseIds.contains(c.id))
              .toList();

          if (enrolled.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No progress yet',
              message: 'Your streak, completion, and certificates show up here '
                  'once you start a course.',
            );
          }

          final completedCourses = enrolled
              .where((c) => notifier.completionFor(c) >= 1.0)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 96),
            children: [
              _StatGrid(
                streak: progress.streak,
                minutes: progress.timeSpentMinutes,
                courses: enrolled.length,
                certificates: completedCourses.length,
              ),
              const SizedBox(height: Gap.lg),
              Text('Completion by course',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Gap.md),
              _CompletionChart(
                courses: enrolled,
                completion: {
                  for (final c in enrolled) c.title: notifier.completionFor(c),
                },
              ),
              const SizedBox(height: Gap.lg),
              Text('Achievements',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Gap.sm),
              _Badges(
                progress: progress,
                completedCourses: completedCourses.length,
              ),
              const SizedBox(height: Gap.lg),
              Text('Certificates',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Gap.sm),
              if (completedCourses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(Gap.md),
                  decoration: BoxDecoration(
                    color: context.surfaceAlt,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    'Finish 100% of a course to earn a verifiable certificate.',
                    style: TextStyle(color: context.fg),
                  ),
                )
              else
                for (final c in completedCourses)
                  Card(
                    margin: const EdgeInsets.only(bottom: Gap.sm),
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium,
                          color: AppColors.accent),
                      title: Text(c.title),
                      subtitle: const Text('Completed · tap to view certificate'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CertificateScreen(course: c),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: Gap.lg),
              if (enrolled.any((c) => notifier.completionFor(c) < 1.0))
                FilledButton.icon(
                  onPressed: () => context.go('/learning'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Keep learning'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.progress, required this.completedCourses});
  final ProgressState progress;
  final int completedCourses;

  @override
  Widget build(BuildContext context) {
    final perfectQuiz = progress.quizScores.values.any((s) => s >= 100);
    final badges = <(IconData, String, bool)>[
      (Icons.school, 'First steps', progress.completedLessonIds.isNotEmpty),
      (Icons.bolt, 'Level 5', progress.level >= 5),
      (Icons.local_fire_department, '3-day streak', progress.streak >= 3),
      (Icons.whatshot, 'Week warrior', progress.streak >= 7),
      (Icons.star, 'Perfect quiz', perfectQuiz),
      (Icons.bookmark, 'Curator', progress.bookmarkedLessonIds.length >= 3),
      (Icons.timer, 'Hour of focus', progress.timeSpentMinutes >= 60),
      (Icons.workspace_premium, 'Graduate', completedCourses >= 1),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gap.sm,
      crossAxisSpacing: Gap.sm,
      childAspectRatio: 0.82,
      children: [
        for (final (icon, label, earned) in badges)
          Tooltip(
            message: earned ? '$label · unlocked' : '$label · locked',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned
                        ? AppColors.accent
                        : context.surfaceAlt,
                  ),
                  child: Icon(icon,
                      color: earned ? Colors.white : context.muted, size: 24),
                ),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 10,
                        color: earned ? context.fg : context.muted,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.streak,
    required this.minutes,
    required this.courses,
    required this.certificates,
  });
  final int streak;
  final int minutes;
  final int courses;
  final int certificates;

  @override
  Widget build(BuildContext context) {
    final hours = (minutes / 60);
    final items = [
      (Icons.local_fire_department, '$streak', 'day streak', AppColors.accent),
      (Icons.timer_outlined, hours >= 1 ? '${hours.toStringAsFixed(1)}h' : '${minutes}m', 'time spent', AppColors.primary),
      (Icons.menu_book, '$courses', 'courses', AppColors.secondary),
      (Icons.workspace_premium, '$certificates', 'certificates', AppColors.warning),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gap.md,
      crossAxisSpacing: Gap.md,
      childAspectRatio: 1.4,
      children: [
        for (final (icon, value, label, color) in items)
          Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: Gap.sm),
                Text(value,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompletionChart extends StatelessWidget {
  const _CompletionChart({required this.courses, required this.completion});
  final List<Course> courses;
  final Map<String, double> completion;

  @override
  Widget build(BuildContext context) {
    final entries = completion.entries.toList();
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.lg, Gap.md, Gap.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  final words = entries[i].key.split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      words.length > 1 ? '${words.first}…' : words.first,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < entries.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (entries[i].value * 100),
                  width: 22,
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
