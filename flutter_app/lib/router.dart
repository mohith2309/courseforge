import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/pressable.dart';
import 'screens/ai_builder_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/my_learning_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/doubt_solver_screen.dart';
import 'screens/upgrade_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/publish_screen.dart';
import 'screens/marketplace_published_screen.dart';
import 'screens/admin_screen.dart';
import 'theme/app_theme.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/build',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => _HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/build',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: AIBuilderScreen()),
          ),
          GoRoute(
            path: '/browse',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: MarketplaceScreen()),
          ),
          GoRoute(
            path: '/learning',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: MyLearningScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/course/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => CourseDetailScreen(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/learn/:courseId/:lessonId',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => LearningScreen(
          courseId: s.pathParameters['courseId']!,
          lessonId: s.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:courseId/:lessonId',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => QuizScreen(
          courseId: s.pathParameters['courseId']!,
          lessonId: s.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/practice/:courseId/:lessonId',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => QuizScreen(
          courseId: s.pathParameters['courseId']!,
          lessonId: s.pathParameters['lessonId']!,
          practice: true,
        ),
      ),
      GoRoute(
        path: '/doubt/:courseId/:lessonId',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => DoubtSolverScreen(
          courseId: s.pathParameters['courseId']!,
          lessonId: s.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/upgrade',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const UpgradeScreen(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const AuthScreen(),
      ),
      GoRoute(
        path: '/publish',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => PublishScreen(courseId: s.uri.queryParameters['course']),
      ),
      GoRoute(
        path: '/marketplace',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const MarketplacePublishedScreen(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const AdminScreen(),
      ),
    ],
  );
});

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.child});
  final Widget child;

  static const _tabs = [
    (path: '/build', icon: Icons.auto_awesome_outlined, active: Icons.auto_awesome, label: 'Build'),
    (path: '/browse', icon: Icons.explore_outlined, active: Icons.explore, label: 'Explore'),
    (path: '/learning', icon: Icons.menu_book_outlined, active: Icons.menu_book, label: 'Learning'),
    (path: '/progress', icon: Icons.insights_outlined, active: Icons.insights, label: 'Progress'),
    (path: '/settings', icon: Icons.settings_outlined, active: Icons.settings, label: 'Settings'),
  ];

  // Green gradient (deep emerald → fresh green) — no blue.
  static const _activeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A8754), Color(0xFF3DDC84)],
  );

  int _indexFor(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final i = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Lower alpha so the blurred content shows through (true frosted glass).
    final islandBg =
        (dark ? const Color(0xFF15211F) : Colors.white).withValues(alpha: 0.62);
    final inactive = dark ? AppColors.dMuted : AppColors.muted;

    return Scaffold(
      // Let body slide UNDER the floating island for the frosted-glass effect.
      extendBody: true,
      body: child,
      // Floating "pill island" navigation (gradient active tab).
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: islandBg,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                      color: dark ? AppColors.dBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < _tabs.length; i++)
                      _PillItem(
                        icon: _tabs[i].icon,
                        activeIcon: _tabs[i].active,
                        label: _tabs[i].label,
                        selected: i == index,
                        gradient: _activeGradient,
                        inactiveColor: inactive,
                        onTap: () {
                          if (i != index) {
                            Buzz.select();
                            context.go(_tabs[i].path);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One item in the pill island. Active = a gradient capsule with icon + label
/// (animated); inactive = an icon only. Mirrors the floating-navbar slides.
class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.gradient,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Gradient gradient;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 11, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0A8754).withValues(alpha: 0.38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon,
                size: 22, color: selected ? Colors.white : inactiveColor),
            if (selected) ...[
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
