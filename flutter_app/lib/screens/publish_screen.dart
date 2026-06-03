import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Publish one of your courses to the marketplace. You set the price; the
/// platform keeps a 30% commission (you keep 70%). Submissions go to review.
class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key, this.courseId});
  final String? courseId;

  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  Course? _selected;
  final _price = TextEditingController(text: '299');
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final backendOn = ref.watch(apiClientProvider).isConfigured;
    final coursesAsync = ref.watch(coursesProvider);

    // Not signed in → prompt to sign in first.
    if (!auth.signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publish a course')),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in to publish',
          message: backendOn
              ? 'Publishing a course needs an account so we can pay you.'
              : 'Publishing needs the backend. Start server/ and set BACKEND_URL.',
          action: backendOn
              ? FilledButton(
                  onPressed: () => context.push('/auth'),
                  child: const Text('Sign in'),
                )
              : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Publish a course')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          // Publishable = your own AI-built courses.
          final mine = all.where((c) => c.aiGenerated).toList();
          if (_selected == null && mine.isNotEmpty) {
            _selected = mine.firstWhere(
              (c) => c.id == widget.courseId,
              orElse: () => mine.first,
            );
          }

          if (mine.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_awesome,
              title: 'Nothing to publish yet',
              message: 'Build a course on the Build tab first, then come back '
                  'to publish it.',
            );
          }

          final price = int.tryParse(_price.text) ?? 0;
          final earn = (price * 0.7).round();

          return ListView(
            padding: const EdgeInsets.all(Gap.md),
            children: [
              Text('Choose a course',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              RadioGroup<String>(
                groupValue: _selected?.id,
                onChanged: (id) => setState(
                    () => _selected = mine.firstWhere((c) => c.id == id)),
                child: Column(
                  children: [
                    for (final c in mine)
                      RadioListTile<String>(
                        value: c.id,
                        title: Text(c.title),
                        subtitle: Text(
                            '${c.modules.length} modules · ${c.totalLessons} lessons'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
              Text('Set your price (₹)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixText: '₹ '),
              ),
              const SizedBox(height: Gap.md),
              Container(
                padding: const EdgeInsets.all(Gap.md),
                decoration: BoxDecoration(
                  color: context.surfaceAlt,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Column(
                  children: [
                    _row(context, 'List price', '₹$price'),
                    _row(context, 'Platform fee (30%)', '−₹${price - earn}'),
                    const Divider(),
                    _row(context, 'You earn per sale', '₹$earn', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _busy || _selected == null
                    ? null
                    : () => _publish(price),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.publish),
                label: const Text('Submit for review'),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Submitted courses are reviewed before going live in the '
                'marketplace.',
                style: TextStyle(color: context.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? null : context.muted)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppColors.accent : null)),
        ],
      ),
    );
  }

  Future<void> _publish(int price) async {
    setState(() => _busy = true);
    final auth = ref.read(authProvider);
    final err = await ref.read(apiClientProvider).publishCourse(
          course: _selected!,
          priceInr: price,
          publisherId: auth.userId!,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for review! 🎉')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.destructive),
      );
    }
  }
}
