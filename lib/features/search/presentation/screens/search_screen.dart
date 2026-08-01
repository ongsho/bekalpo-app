// lib/features/search/presentation/screens/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/search_suggestion.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/router/app_routes.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.searchResults,
      arguments: query.trim(),
    );
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _debounce?.cancel();

    if (suggestion.type == 'product' && suggestion.slug != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.postPreview,
        arguments: suggestion.slug,
      );
    } else {
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
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),

                // ── Search box — standalone, white rounded ───────────
                Expanded(
                  child: Container(
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search for anything on Bekalpo',
          style: TextStyle(color: Colors.grey),
        ),
      );
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
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        final isProduct = s.type == 'product';
        return ListTile(
          leading: Icon(
            isProduct ? Icons.shopping_bag_outlined : Icons.search,
            color: Colors.grey.shade600,
          ),
          title: Text(s.text),
          subtitle: !isProduct && s.location != null
              ? Text(s.location!, style: const TextStyle(fontSize: 12))
              : null,
          onTap: () => _onSuggestionTap(s),
        );
      },
    );
  }
}
