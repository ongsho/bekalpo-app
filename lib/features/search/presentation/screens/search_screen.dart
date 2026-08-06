// lib/features/search/presentation/screens/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/search_suggestion.dart';
import '../../../../core/models/search_history.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/providers/search_history_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/router/app_routes.dart';
import '../../../bottom_nav/presentation/providers/nav_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    setState(() {}); // refresh clear-button visibility

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(postRepositoryProvider);
      final results = await repo.getSearchSuggestions(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load suggestions';
      });
    }
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    _debounce?.cancel();
    _focusNode.unfocus(); // Close keyboard before navigation

    // Save to search history
    ref.read(searchHistoryProvider.notifier).addSearchQuery(query.trim());

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.searchResults,
      arguments: query.trim(),
    );
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _debounce?.cancel();
    _focusNode.unfocus(); // Close keyboard before navigation

    if (suggestion.type == 'product' && suggestion.slug != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.postPreview,
        arguments: suggestion.slug,
      );
    } else {
      // Save to search history
      ref.read(searchHistoryProvider.notifier).addSearchQuery(suggestion.text);

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.searchResults,
        arguments: suggestion.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final currentIndex = ref.watch(navIndexProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    // Request focus when search tab becomes active
    if (currentIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────
          Container(
            color: AppColors.brand500,
            padding: EdgeInsets.fromLTRB(4, statusBarHeight + 8, 14, 12),
            child: Row(
              children: [
                // ── Back button — standalone, no box ─────────────────
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 22),
                  color: Colors.white,
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).state = 0,
                ),
                const SizedBox(width: 4),

                // ── Search box — standalone, white rounded ───────────
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search products, brands...',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: Colors.black45,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            onChanged: _onQueryChanged,
                            onSubmitted: _submitSearch,
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              _onQueryChanged('');
                            },
                            child: Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────
          Expanded(child: _buildBody(searchHistory)),
        ],
      ),
    );
  }

  Widget _buildBody(List<SearchHistoryItem> searchHistory) {
    if (_controller.text.trim().isEmpty) {
      return _buildSearchHistory(searchHistory);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          'No suggestions found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        final isProduct = s.type == 'product';
        final isEnriched = s.type == 'enriched';

        return ListTile(
          leading: isProduct && s.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: s.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                )
              : Icon(
                  isEnriched
                      ? Icons.category_outlined
                      : isProduct
                      ? Icons.shopping_bag_outlined
                      : Icons.search,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
          title: isEnriched && s.query != null
              ? _buildHighlightedText(s.text, s.query!)
              : Text(
                  s.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          subtitle: s.description != null && s.description!.isNotEmpty
              ? Text(
                  _truncateDescription(s.description!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => _onSuggestionTap(s),
        );
      },
    );
  }

  Widget _buildSearchHistory(List<SearchHistoryItem> searchHistory) {
    if (searchHistory.isEmpty) {
      return const Center(
        child: Text(
          'Search for anything on Bekalpo',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchHistoryProvider.notifier).clearHistory();
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.brand500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search history items as chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchHistory.map((item) {
              return _buildHistoryChip(item);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryChip(SearchHistoryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () {
          _controller.text = item.query;
          _submitSearch(item.query);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                item.query,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  ref
                      .read(searchHistoryProvider.notifier)
                      .removeSearchQuery(item.query);
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateDescription(String description) {
    // Remove newlines and extra whitespace
    String cleaned = description
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length > 50) {
      return '${cleaned.substring(0, 50)}...';
    }
    return cleaned;
  }

  Widget _buildHighlightedText(String text, String query) {
    // Use the current input value for highlighting instead of the query field
    String currentQuery = _controller.text.trim();
    if (currentQuery.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      );
    }

    // Find the matching part and highlight it (case insensitive)
    final String lowerText = text.toLowerCase();
    final String lowerQuery = currentQuery.toLowerCase();
    final int index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: text.substring(index, index + currentQuery.length),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: text.substring(index + currentQuery.length),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
