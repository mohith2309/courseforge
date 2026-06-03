import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/course_card.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final filtered = ref.watch(filteredCoursesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      body: SafeArea(
        child: coursesAsync.when(
          loading: () => const SkeletonList(count: 5),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load courses',
            message: '$e',
          ),
          data: (allCourses) {
            final featured = allCourses.where((c) => c.featured).toList();
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(child: _SearchBar(initial: query)),
                if (ref.watch(apiClientProvider).isConfigured)
                  const SliverToBoxAdapter(child: _CommunityBanner()),
                SliverToBoxAdapter(
                  child: categoriesAsync.maybeWhen(
                    data: (cats) => _CategoryRow(
                      categories: cats,
                      selected: selectedCategory,
                    ),
                    orElse: () => const SizedBox(height: 48),
                  ),
                ),
                if (query.isEmpty && selectedCategory == 'All') ...[
                  const SliverToBoxAdapter(child: SectionHeader('Featured')),
                  SliverToBoxAdapter(child: _FeaturedCarousel(featured)),
                ],
                SliverToBoxAdapter(
                  child: SectionHeader(
                    query.isEmpty && selectedCategory == 'All'
                        ? 'All courses'
                        : 'Results',
                  ),
                ),
                ...filtered.when(
                  loading: () => [
                    const SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.all(Gap.xl),
                            child: Center(
                                child: CircularProgressIndicator()))),
                  ],
                  error: (e, _) => [SliverToBoxAdapter(child: Text('$e'))],
                  data: (list) {
                    if (list.isEmpty) {
                      return [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.search_off,
                            title: 'No matches',
                            message: 'Try a different search or category.',
                          ),
                        ),
                      ];
                    }
                    return [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            Gap.md, 0, Gap.md, 96),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: Gap.md),
                          itemBuilder: (_, i) => CourseCard(course: list[i]),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => context.push('/marketplace'),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFFF59E0B)],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Colors.white),
              const SizedBox(width: Gap.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community courses',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('Browse & buy courses from other creators',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
      child: Row(
        children: [
          const CourseThumb(emoji: '🔨', size: 40, radius: Radii.sm),
          const SizedBox(width: Gap.sm),
          Text('CourseForge',
              style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
      child: TextField(
        controller: TextEditingController(text: initial)
          ..selection = TextSelection.collapsed(offset: initial.length),
        textInputAction: TextInputAction.search,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Search courses, topics, tags…',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.categories, required this.selected});
  final List<String> categories;
  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSel = cat == selected;
          return ChoiceChip(
            label: Text(cat),
            selected: isSel,
            onSelected: (_) =>
                ref.read(selectedCategoryProvider.notifier).state = cat,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel(this.courses);
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        itemCount: courses.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
        itemBuilder: (_, i) {
          final c = courses[i];
          return Pressable(
            onTap: () => context.push('/course/${c.id}'),
            child: Container(
              width: 290,
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.lg),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.thumbnailEmoji,
                          style: const TextStyle(fontSize: 30)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: const Text('FEATURED',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(c.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: Gap.sm),
                  Text(priceLabel(c.priceInr),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
