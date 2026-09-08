import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/category.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/providers/search_provider.dart';
import '../../../../app/router/app_routes.dart';

class CategorySelectorBottomSheet extends ConsumerStatefulWidget {
  final Function(String categoryId, String categoryName)? onCategorySelected;
  final Category? initialParentCategory;

  const CategorySelectorBottomSheet({
    super.key,
    this.onCategorySelected,
    this.initialParentCategory,
  });

  @override
  ConsumerState<CategorySelectorBottomSheet> createState() =>
      _CategorySelectorBottomSheetState();
}

class _CategorySelectorBottomSheetState
    extends ConsumerState<CategorySelectorBottomSheet> {
  Category? _selectedParent;
  bool _startedAtStage2 = false;

  @override
  void initState() {
    super.initState();
    // If an initial parent is provided, start directly at Stage 2
    if (widget.initialParentCategory != null) {
      _selectedParent = widget.initialParentCategory;
      _startedAtStage2 = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildContent(categoriesState, theme)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  splashColor: theme.colorScheme.primary.withOpacity(0.15),
                  highlightColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectionSteps(theme),
        ],
      ),
    );
  }

  Widget _buildSelectionSteps(ThemeData theme) {
    return Row(
      children: [
        _buildStepIndicator(1, _selectedParent != null, 'Parent', theme),
        _buildStepConnector(_selectedParent != null, theme),
        _buildStepIndicator(2, false, 'Child', theme),
      ],
    );
  }

  Widget _buildStepIndicator(
    int step,
    bool isCompleted,
    String label,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? theme.colorScheme.primary : theme.dividerColor,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: theme.colorScheme.surface, size: 18)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isConnected, ThemeData theme) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isConnected ? theme.colorScheme.primary : theme.dividerColor,
    );
  }

  Widget _buildContent(
    AsyncValue<List<Category>> categoriesState,
    ThemeData theme,
  ) {
    if (categoriesState.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (categoriesState.hasError) {
      return _buildErrorState(
        'Failed to load categories',
        () => ref.read(categoriesProvider.notifier).refresh(),
        theme,
      );
    }

    final categories = categoriesState.value ?? [];

    if (_selectedParent == null) {
      return _buildParentList(categories, theme);
    } else {
      return _buildChildList(theme);
    }
  }

  Widget _buildParentList(List<Category> categories, ThemeData theme) {
    if (categories.isEmpty) {
      return _buildEmptyState('No categories available', theme);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildParentTile(category, theme);
      },
    );
  }

  Widget _buildParentTile(Category category, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedParent = category;
          });
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          leading: category.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    category.image!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 24,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category,
                    size: 24,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
          title: Text(
            category.nameEn ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: category.nameBn != null
              ? Text(
                  category.nameBn!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildChildList(ThemeData theme) {
    final children = _selectedParent?.children ?? [];

    if (children.isEmpty) {
      return _buildEmptyState('No subcategories available', theme);
    }

    return Column(
      children: [
        _buildBackButton(
          () {
            if (_startedAtStage2) {
              // If we started at Stage 2, close the sheet instead of going to Stage 1
              Navigator.pop(context);
            } else {
              // Normal back to Stage 1
              setState(() {
                _selectedParent = null;
              });
            }
          },
          _selectedParent?.nameEn ?? '',
          theme,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return _buildChildTile(child, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChildTile(Category child, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(child.id.toString(), child.nameEn ?? '');
          } else {
            Navigator.pushNamed(
              context,
              AppRoutes.searchResults,
              arguments: SearchFilters(
                search: '',
                category: child.id.toString(),
                categoryName: child.nameEn,
              ),
            );
          }
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          title: Text(
            child.nameEn ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: child.nameBn != null
              ? Text(
                  child.nameBn!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (child.postCount != null && child.postCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${child.postCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onTap, String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.15),
          highlightColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    String message,
    VoidCallback onRetry,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
