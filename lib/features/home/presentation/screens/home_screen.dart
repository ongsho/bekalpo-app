// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/category_grid.dart';
import '../widgets/category_grid_skeleton.dart';
import '../widgets/ad_card.dart';
import '../widgets/ad_card_skeleton.dart';
import '../widgets/section_header.dart';
import '../../data/models/ad_model.dart';
import '../../../../core/models/category.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../features/shared/presentation/widgets/theme_selector_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;

  // FIX #2: no longer `final` hardcoded — updates via setState after location pick
  String _location = 'Bangladesh';

  // FIX #4: guard flag so scroll listener can't fire loadMore() multiple times
  // while a load is already in-flight (helps avoid pagination flood / jank / freeze)
  bool _isLoadMoreTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (_isLoadMoreTriggered) return; // already loading, skip

      final state = ref.read(postsProvider).valueOrNull;
      // extra guard: don't trigger if already loading or no more pages
      if (state != null && (state.isLoadingMore || !state.hasMore)) return;

      _isLoadMoreTriggered = true;
      ref.read(postsProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreTriggered = false;
        } else {
          _isLoadMoreTriggered = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchTap() {
    Navigator.pushNamed(context, AppRoutes.search);
  }

  // FIX #3: pass the tapped category as arguments, and update local location
  // if the hierarchy screen returns one (kept generic — adjust return type to
  // whatever your locationHierarchy screen actually returns, e.g. a String or a Location object)
  void _onCategoryTap(Category cat) {
    Navigator.pushNamed(context, AppRoutes.categoryHierarchy, arguments: cat);
  }

  Future<void> _onLocationTap() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.locationHierarchy,
    );
    if (result != null && result is String && mounted) {
      setState(() {
        _location = result;
      });
    }
  }

  // FIX #5: give feedback instead of silently doing nothing when slug is empty
  void _onAdTap(AdModel ad) {
    if (ad.slug.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.postPreview, arguments: ad.slug);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This ad is unavailable right now')),
      );
    }
  }

  SliverPadding _hpad(Widget sliver) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    sliver: sliver,
  );

  Widget _adSliverGrid(List<AdModel> ads) => _hpad(
    SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => RepaintBoundary(
          child: AdCard(ad: ads[index], onTap: () => _onAdTap(ads[index])),
        ),
        childCount: ads.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // TEMPORARY: theme switcher FAB — পরে সরিয়ে দেওয়া হবে
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ThemeSelectorSheet.show(context),
        tooltip: 'Change theme',
        child: const Icon(Icons.palette_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(postsProvider.notifier).refresh();
          await ref.read(categoriesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 600,
          slivers: [
            HomeAppBar(
              location: _location,
              onLocationTap: _onLocationTap,
              onSearchTap: _onSearchTap,
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            _hpad(
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Browse Categories',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            ..._buildCategorySlivers(categoriesAsync),

            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            ..._buildPostSlivers(postsAsync),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategorySlivers(
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      loading: () => [
        _hpad(
          SliverToBoxAdapter(child: const CategoryGridSkeleton(itemCount: 8)),
        ),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Could not load categories',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade400),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(categoriesProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (categories) {
        if (categories.isEmpty) return [];
        return [
          _hpad(
            SliverToBoxAdapter(
              child: CategoryGrid(
                categories: categories,
                onTap: _onCategoryTap,
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _buildPostSlivers(AsyncValue<PostsState> postsAsync) {
    return postsAsync.when(
      loading: () => [
        _hpad(
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Popular Trending Ads',
                  subtitle: 'Explore the most popular and trending ads.',
                  actionLabel: '',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                // FIX #1: renamed to match the actual skeleton widget class.
                // If your file defines a different name (e.g. AdGridSkeleton),
                // just swap this back — the key point is it must match exactly
                // what's exported from ad_card_skeleton.dart
                const AdCardSkeleton(itemCount: 6),
              ],
            ),
          ),
        ),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load ads',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.read(postsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (postsState) {
        final ads = postsState.posts.map((p) => p.toAdModel()).toList();

        if (ads.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    const Text('No ads available yet. Check back soon!'),
                  ],
                ),
              ),
            ),
          ];
        }

        return [
          if (postsState.isShowingCachedData)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.offline_bolt_outlined,
                      size: 15,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Showing saved ads — pull down to refresh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          _hpad(
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Popular Trending Ads',
                subtitle: 'Explore the most popular and trending ads.',
                actionLabel: '',
                onAction: () {},
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          _adSliverGrid(ads),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: postsState.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : !postsState.hasMore
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'সব বিজ্ঞাপন দেখা হয়ে গেছে',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          if (postsState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Failed to load more',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(postsProvider.notifier).loadMore(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
    );
  }
}
