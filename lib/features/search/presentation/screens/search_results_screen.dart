// lib/features/search/presentation/screens/search_results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/search_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import '../../../home/data/models/ad_model.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../app/router/app_routes.dart';
import '../../../shared/presentation/widgets/connectivity_wrapper.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final SearchFilters _filters;
  late final ScrollController _scrollController;
  bool _isLoadMoreTriggered = false;

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(search: widget.query);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (_isLoadMoreTriggered) return;
      final state = ref.read(searchProvider(_filters));
      if (state.isLoadingMore || !state.hasMore) return;

      _isLoadMoreTriggered = true;
      ref
          .read(searchProvider(_filters).notifier)
          .loadMore()
          .whenComplete(() => _isLoadMoreTriggered = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onAdTap(AdModel ad) {
    if (ad.slug.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.postPreview, arguments: ad.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider(_filters));
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: AppColors.brand500,
              padding: EdgeInsets.fromLTRB(4, statusBarHeight + 8, 14, 12),
              child: Row(
                children: [
                  // ── Back button ─────────────────────────────────────
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    color: Colors.white,
                    onPressed: _handleBack,
                  ),
                  const SizedBox(width: 4),
                  // ── Title ───────────────────────────────────────────
                  Expanded(
                    child: Text(
                      'Results for "${widget.query}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ───────────────────────────────────────────────────
            Expanded(child: ConnectivityWrapper(child: _buildBody(state))),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Could not load results',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(searchProvider(_filters).notifier).search(_filters),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No results for "${widget.query}"'),
          ],
        ),
      );
    }

    final ads = state.results.map((p) => p.toAdModel()).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => RepaintBoundary(
                child: AdCard(
                  ad: ads[index],
                  onTap: () => _onAdTap(ads[index]),
                ),
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
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : !state.hasMore
                  ? Text(
                      'সব ফলাফল দেখা হয়ে গেছে',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
