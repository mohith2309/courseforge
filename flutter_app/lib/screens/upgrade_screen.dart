import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  static const _proPerks = [
    ('Full-length video lessons', 'Free gives you the short version — Pro plays the complete, detailed lesson.'),
    ('No watermark', 'Clean lesson videos with the CourseForge mark removed.'),
    ('Unlimited AI practice quizzes', 'Generate fresh adaptive questions as many times as you like.'),
    ('Priority AI generation', 'Longer, richer courses with faster regeneration.'),
  ];

  static const _freePerks = [
    'Unlimited AI-built courses',
    'All lessons, key points & notes',
    'Quizzes + AI doubt solver',
    'Progress tracking & certificates',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CourseForge Pro')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          Container(
            padding: const EdgeInsets.all(Gap.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.secondary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 40),
                const SizedBox(height: Gap.sm),
                Text(
                  isPro ? 'You\'re on Pro 🎉' : 'Learn without limits',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Everything important is free, forever. Pro just makes it nicer.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          Text('Always free', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Gap.sm),
          for (final p in _freePerks)
            _PerkRow(icon: Icons.check_circle, color: AppColors.success, title: p),

          const SizedBox(height: Gap.lg),
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Pro perks', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (final (title, sub) in _proPerks)
            _PerkRow(
              icon: Icons.auto_awesome,
              color: AppColors.accent,
              title: title,
              subtitle: sub,
            ),

          const SizedBox(height: Gap.lg),
          if (isPro)
            OutlinedButton(
              onPressed: () => ref.read(isProProvider.notifier).setPro(false),
              child: const Text('Switch back to Free'),
            )
          else ...[
            _PlanCard(
              label: 'Monthly',
              price: '₹199',
              cadence: '/month',
              onTap: () => _activate(context, ref, 199),
            ),
            const SizedBox(height: Gap.sm),
            _PlanCard(
              label: 'Yearly · best value',
              price: '₹1,499',
              cadence: '/year',
              highlight: true,
              onTap: () => _activate(context, ref, 1499),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Secure payment by Razorpay — UPI, cards, netbanking & wallets.',
              style: TextStyle(color: context.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref, int amountInr) async {
    final api = ref.read(apiClientProvider);
    final auth = ref.read(authProvider);
    if (api.isConfigured && !auth.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upgrade to Pro.')),
      );
      return;
    }
    // 1. Server-priced Pro order (platform keeps 100%).
    String? orderId;
    String? keyId;
    bool mock = true;
    if (api.isConfigured) {
      final order = await api.createProOrder(amountInr: amountInr);
      if (order == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start checkout. Try again.')),
          );
        }
        return;
      }
      orderId = order.orderId;
      keyId = order.keyId;
      mock = order.mock;
    }
    // 2. Native Razorpay checkout.
    final result = await ref.read(razorpayCheckoutProvider).pay(
          amountInr: amountInr,
          description: 'CourseForge Pro',
          orderId: orderId,
          keyId: keyId,
        );
    if (!context.mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Payment cancelled')),
      );
      return;
    }
    // 3. Verify (server flips the Pro flag).
    if (api.isConfigured && orderId != null) {
      final ok = await api.verifyPayment(
        orderId: orderId,
        courseId: 'pro',
        buyerId: auth.userId ?? 'guest',
        paymentId: result.paymentId,
        signature: result.signature,
        mock: result.simulated || mock || result.signature == null,
      );
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment could not be verified.')),
          );
        }
        return;
      }
    }
    await ref.read(isProProvider.notifier).setPro(true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Pro! Watermark removed. 🎉')),
      );
      Navigator.of(context).maybePop();
    }
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(color: context.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.cadence,
    required this.onTap,
    this.highlight = false,
  });
  final String label;
  final String price;
  final String cadence;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: highlight ? AppColors.accent.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: highlight ? AppColors.accent : context.border,
            width: highlight ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(price,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text(cadence, style: TextStyle(color: context.muted)),
          ],
        ),
      ),
    );
  }
}
