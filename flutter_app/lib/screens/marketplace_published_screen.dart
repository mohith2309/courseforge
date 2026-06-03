import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animate.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';

/// Community marketplace — published, admin-approved courses from other
/// creators, with a Razorpay-backed buy flow.
class MarketplacePublishedScreen extends ConsumerWidget {
  const MarketplacePublishedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendOn = ref.watch(apiClientProvider).isConfigured;
    final listingsAsync = ref.watch(publishedCoursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community courses')),
      body: !backendOn
          ? const EmptyState(
              icon: Icons.cloud_off,
              title: 'Marketplace is offline',
              message: 'Start the backend and run with '
                  '--dart-define=BACKEND_URL=… to browse community courses.',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(publishedCoursesProvider.future),
              child: listingsAsync.when(
                loading: () => const SkeletonList(count: 4),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load',
                  message: '$e',
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No courses yet',
                          message: 'Approved community courses appear here. '
                              'Publish one from Settings → Publish.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(Gap.md),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
                    itemBuilder: (_, i) =>
                        FadeInUp(index: i, child: _ListingCard(listing: listings[i])),
                  );
                },
              ),
            ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing});
  final PublishedListing listing;

  bool get _owned => false; // could check library; kept simple

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = listing.course;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseThumb(emoji: c.thumbnailEmoji),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(c.subtitle,
                          style: TextStyle(color: context.muted, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Icon(Icons.person_outline, size: 15, color: context.muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(listing.publisherName,
                      style: TextStyle(color: context.muted, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                if (listing.publisherVerified) ...[
                  const SizedBox(width: 6),
                  const _VerifiedBadge(),
                ],
              ],
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                StatChip(
                    icon: Icons.play_lesson_outlined,
                    label: '${c.totalLessons} lessons'),
                const SizedBox(width: Gap.md),
                StatChip(
                    icon: Icons.people_outline,
                    label: '${listing.enrollmentsCount} enrolled'),
                const Spacer(),
                Text(priceLabel(listing.priceInr),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: Gap.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent),
                onPressed: _owned
                    ? null
                    : () => _openCheckout(context, ref, listing),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text('Buy · ${priceLabel(listing.priceInr)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 13, color: AppColors.primary),
          SizedBox(width: 3),
          Text('Verified',
              style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

void _openCheckout(BuildContext context, WidgetRef ref, PublishedListing l) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CheckoutSheet(listing: l),
  );
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet({required this.listing});
  final PublishedListing listing;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  bool _busy = false;
  String? _status;

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _status = 'Opening secure checkout…';
    });
    try {
      final err = await buyListing(ref, widget.listing);
      if (!mounted) return;
      if (err == null) {
        Buzz.success();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchased! Added to My Learning. 🎉')),
        );
        context.push('/course/${widget.listing.course.id}');
      } else {
        setState(() {
          _busy = false;
          _status = err;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Could not complete: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final earn = (l.priceInr * 0.7).round();
    return Padding(
      padding: EdgeInsets.only(
        left: Gap.md,
        right: Gap.md,
        top: Gap.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              CourseThumb(emoji: l.course.thumbnailEmoji, size: 48),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.course.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('by ${l.publisherName}',
                        style: TextStyle(color: context.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
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
                _row(context, 'Course price', priceLabel(l.priceInr)),
                _row(context, 'Creator earns (70%)', priceLabel(earn),
                    muted: true),
                _row(context, 'Platform fee (30%)',
                    priceLabel(l.priceInr - earn),
                    muted: true),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          if (_status != null) ...[
            Text(_status!, style: TextStyle(color: context.muted, fontSize: 13)),
            const SizedBox(height: Gap.sm),
          ],
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _busy ? null : _pay,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock),
            label: Text('Pay ${priceLabel(l.priceInr)}'),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Secured by Razorpay · test mode (no real charge in this build).',
            style: TextStyle(color: context.muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: muted ? context.muted : null)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: muted ? context.muted : null)),
        ],
      ),
    );
  }
}
