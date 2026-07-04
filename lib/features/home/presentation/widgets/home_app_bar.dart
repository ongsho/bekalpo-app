// lib/features/home/presentation/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'home_search_bar.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.location,
    required this.onLocationTap,
    required this.onSearchTap,
  });

  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;

  static const double _logoRowHeight = 48;
  static const double _searchRowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // Dark mode এ dark bg, light mode এ brand500
    final Color barColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.brand500
        : AppColors.brand500;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeAppBarDelegate(
        statusBarHeight: statusBarHeight,
        logoRowHeight: _logoRowHeight,
        searchRowHeight: _searchRowHeight,
        barColor: barColor,
        location: location,
        onLocationTap: onLocationTap,
        onSearchTap: onSearchTap,
      ),
    );
  }
}

class _HomeAppBarDelegate extends SliverPersistentHeaderDelegate {
  const _HomeAppBarDelegate({
    required this.statusBarHeight,
    required this.logoRowHeight,
    required this.searchRowHeight,
    required this.barColor,
    required this.location,
    required this.onLocationTap,
    required this.onSearchTap,
  });

  final double statusBarHeight;
  final double logoRowHeight;
  final double searchRowHeight;
  final Color barColor;
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;

  @override
  double get maxExtent => statusBarHeight + logoRowHeight + searchRowHeight;

  @override
  double get minExtent => statusBarHeight + searchRowHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double logoOpacity = (1 - shrinkOffset / logoRowHeight).clamp(
      0.0,
      1.0,
    );

    return Container(
      color: barColor,
      child: Stack(
        children: [
          // ── Logo — fades on scroll ────────────────────────────────
          Positioned(
            top: statusBarHeight + (8 - shrinkOffset).clamp(0.0, 8.0),
            left: 16,
            child: Opacity(
              opacity: logoOpacity,
              child: Image.asset('assets/images/logowhite.png', height: 26),
            ),
          ),

          // ── Search bar — always pinned ────────────────────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: HomeSearchBar(
              location: location,
              onLocationTap: onLocationTap,
              onSearchTap: onSearchTap,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeAppBarDelegate old) =>
      old.location != location ||
      old.statusBarHeight != statusBarHeight ||
      old.barColor != barColor;
}
