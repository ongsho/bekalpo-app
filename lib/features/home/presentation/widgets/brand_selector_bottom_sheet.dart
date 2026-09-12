import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/brand.dart';

class BrandSelectorBottomSheet extends StatefulWidget {
  final List<Brand> brands;
  final Function(Brand brand)? onBrandSelected;

  const BrandSelectorBottomSheet({
    super.key,
    required this.brands,
    this.onBrandSelected,
  });

  @override
  State<BrandSelectorBottomSheet> createState() =>
      _BrandSelectorBottomSheetState();
}

class _BrandSelectorBottomSheetState extends State<BrandSelectorBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          const Divider(),
          _buildSearchField(theme),
          const Divider(),
          Expanded(child: _buildContent(theme)),
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
                'Select Brand',
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
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search brands...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.brands.isEmpty) {
      return _buildEmptyState('No brands available', theme);
    }

    final filteredBrands = _searchQuery.isEmpty
        ? widget.brands
        : widget.brands
              .where(
                (brand) => brand.displayName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    if (filteredBrands.isEmpty) {
      return _buildEmptyState('No brands found', theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredBrands.length,
      itemBuilder: (context, index) {
        final brand = filteredBrands[index];
        return _buildBrandTile(brand, theme);
      },
    );
  }

  Widget _buildBrandTile(Brand brand, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          if (widget.onBrandSelected != null) {
            widget.onBrandSelected!(brand);
          }
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business,
              size: 24,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          title: Text(
            brand.displayName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
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
