import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';

/// Duolingo-style status bar: streak · hearts · level + a daily-goal bar.
/// Reads live from progress + subscription state.
class GameBar extends ConsumerWidget {
  const GameBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final isPro = ref.watch(isProProvider);

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                icon: Icons.local_fire_department,
                color: AppColors.accent,
                value: '${p.streak}',
                label: 'streak',
              ),
              _HeartStat(
                hearts: isPro ? -1 : p.heartsRemaining,
                onTap: () => context.push('/upgrade'),
              ),
              _Stat(
                icon: Icons.bolt,
                color: AppColors.primary,
                value: 'Lv ${p.level}',
                label: '${p.xp} XP',
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              const Icon(Icons.flag, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Daily goal',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.muted)),
              const Spacer(),
              Text('${p.todayXp}/${ProgressState.dailyGoal} XP',
                  style: TextStyle(fontSize: 12, color: context.muted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: p.dailyGoalProgress,
              minHeight: 8,
              backgroundColor: context.surfaceAlt,
              color: p.dailyGoalProgress >= 1
                  ? AppColors.success
                  : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: TextStyle(fontSize: 11, color: context.muted)),
          ],
        ),
      ],
    );
  }
}

class _HeartStat extends StatelessWidget {
  const _HeartStat({required this.hearts, required this.onTap});
  final int hearts; // -1 = unlimited (Pro)
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlimited = hearts < 0;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.sm),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.favorite, color: AppColors.destructive, size: 22),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(unlimited ? '∞' : '$hearts',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Text(unlimited ? 'Pro' : 'hearts',
                  style: TextStyle(fontSize: 11, color: context.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
