import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Lightweight admin console: review pending course submissions and verify
/// publishers. Gated by the admin token (entered here, checked server-side).
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController _token = TextEditingController();

  @override
  void initState() {
    super.initState();
    _token.text = ref.read(adminTokenProvider);
  }

  @override
  Widget build(BuildContext context) {
    final backendOn = ref.watch(apiClientProvider).isConfigured;
    final token = ref.watch(adminTokenProvider);
    final pendingAsync = ref.watch(adminPendingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin · course review')),
      body: !backendOn
          ? const EmptyState(
              icon: Icons.cloud_off,
              title: 'Backend offline',
              message: 'Run the server and set BACKEND_URL to use the admin '
                  'console.',
            )
          : ListView(
              padding: const EdgeInsets.all(Gap.md),
              children: [
                const Text('Admin token'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _token,
                        obscureText: true,
                        decoration: const InputDecoration(
                            hintText: 'ADMIN_TOKEN from server/.env'),
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 52)),
                      onPressed: () {
                        ref.read(adminTokenProvider.notifier).state =
                            _token.text.trim();
                      },
                      child: const Text('Load'),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.lg),
                if (token.isEmpty)
                  const EmptyState(
                    icon: Icons.vpn_key_outlined,
                    title: 'Enter the admin token',
                    message: 'Defaults to "admin-dev" in development.',
                  )
                else
                  pendingAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(Gap.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('$e'),
                    data: (pending) {
                      if (pending.isEmpty) {
                        return const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Nothing to review',
                          message: 'No courses are waiting for approval.',
                        );
                      }
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${pending.length} pending',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                          const SizedBox(height: Gap.sm),
                          for (final c in pending)
                            _PendingCard(data: c, token: token),
                        ],
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard({required this.data, required this.token});
  final Map<String, dynamic> data;
  final String token;

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  Future<void> _review(String action) async {
    setState(() => _busy = true);
    final api = ref.read(apiClientProvider);
    final err = await api.adminReview(
        widget.token, widget.data['id'] as String, action);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ref.invalidate(adminPendingProvider);
      ref.invalidate(publishedCoursesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'approve' ? 'Approved' : 'Rejected')),
      );
    } else {
      _toast(err);
    }
  }

  Future<void> _verifyPublisher() async {
    setState(() => _busy = true);
    final err = await ref.read(apiClientProvider).adminVerifyPublisher(
        widget.token, widget.data['publisherId'] as String);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ref.invalidate(adminPendingProvider);
      _toast('Publisher verified');
    } else {
      _toast(err);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final verified = d['publisherVerified'] as bool? ?? false;
    final lessons = ((d['modules'] as List?) ?? [])
        .fold<int>(0, (n, m) => n + (((m as Map)['lessons'] as List?)?.length ?? 0));
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.md),
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CourseThumb(emoji: d['thumbnailEmoji']?.toString() ?? '📘', size: 44),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['title']?.toString() ?? 'Untitled',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'by ${d['publisherName'] ?? '—'} · '
                        '₹${d['priceInr'] ?? 0} · $lessons lessons',
                        style: TextStyle(color: context.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            if (_busy)
              const Center(child: Padding(
                padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
            if (!_busy)
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 44)),
                    onPressed: () => _review('approve'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        minimumSize: const Size(0, 44)),
                    onPressed: () => _review('reject'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: verified ? null : _verifyPublisher,
                    icon: Icon(verified ? Icons.verified : Icons.verified_outlined,
                        size: 18,
                        color: verified ? AppColors.primary : null),
                    label: Text(verified ? 'Verified' : 'Verify publisher'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
