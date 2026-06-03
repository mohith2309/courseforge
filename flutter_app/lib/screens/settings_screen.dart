import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final ai = ref.watch(aiServiceProvider);
    final isPro = ref.watch(isProProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const _SectionLabel('Account'),
          ListTile(
            leading: Icon(auth.signedIn ? Icons.account_circle : Icons.person_outline),
            title: Text(auth.signedIn ? (auth.name ?? 'Signed in') : 'Not signed in'),
            subtitle: Text(auth.signedIn
                ? 'Signed in — you can publish courses'
                : 'Optional · sign in to publish your courses'),
            trailing: auth.signedIn
                ? TextButton(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    child: const Text('Sign out'),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 40)),
                    onPressed: () => context.push('/auth'),
                    child: const Text('Sign in'),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.publish_outlined),
            title: const Text('Publish a course'),
            subtitle: const Text('Set a price · you keep 70%'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/publish'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Community marketplace'),
            subtitle: const Text('Browse & buy courses from other creators'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/marketplace'),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin review'),
            subtitle: const Text('Approve submissions · verify publishers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/admin'),
          ),
          const Divider(),
          const _SectionLabel('Plan'),
          ListTile(
            leading: Icon(
              isPro ? Icons.workspace_premium : Icons.bolt,
              color: isPro ? AppColors.primary : AppColors.accent,
            ),
            title: Text(isPro ? 'CourseForge Pro' : 'Free plan'),
            subtitle: Text(isPro
                ? 'Full videos, no watermark, unlimited practice'
                : 'Everything core is free — upgrade for extras'),
            trailing: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isPro ? AppColors.primary : AppColors.accent,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () => context.push('/upgrade'),
              child: Text(isPro ? 'Manage' : 'Upgrade'),
            ),
          ),
          const Divider(),
          const _SectionLabel('Appearance'),
          RadioGroup<ThemeModeChoice>(
            groupValue: mode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
            child: const Column(
              children: [
                RadioListTile(
                    value: ThemeModeChoice.system, title: Text('System default')),
                RadioListTile(
                    value: ThemeModeChoice.light, title: Text('Light')),
                RadioListTile(
                    value: ThemeModeChoice.dark, title: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          const _SectionLabel('AI engines'),
          _StatusTile(
            icon: Icons.auto_awesome,
            title: 'Gemini 2.5 Flash',
            ok: ai.geminiLive,
            okText: 'Live — course generation + grounded doubt solver',
            offText: 'Offline — pass --dart-define=GEMINI_API_KEY=…',
          ),
          _StatusTile(
            icon: Icons.bolt,
            title: 'NVIDIA NIM (Llama 3.1)',
            ok: ai.nimLive,
            okText: 'Live — fast adaptive practice quizzes',
            offText: 'Offline — pass --dart-define=NVIDIA_API_KEY=…',
          ),
          const Divider(),
          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('CourseForge'),
            subtitle: Text(
                'AI-powered course platform · offline-first student app · v1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('Flagship: UPSC IAS Prelims Foundation'),
            subtitle: Text('5 modules · Polity, History, Geography, Economy'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.md, Gap.sm),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.muted)),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.ok,
    required this.okText,
    required this.offText,
  });
  final IconData icon;
  final String title;
  final bool ok;
  final String okText;
  final String offText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(ok ? okText : offText),
      trailing: Icon(
        ok ? Icons.check_circle : Icons.cloud_off,
        color: ok ? AppColors.success : AppColors.muted,
      ),
    );
  }
}
