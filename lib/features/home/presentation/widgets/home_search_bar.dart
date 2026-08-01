// lib/features/home/presentation/widgets/home_search_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.location,
    required this.onLocationTap,
    required this.onSearchTap,
  });

  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brand100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Location chip — fixed width ───────────────────────────
          // SizedBox(
          //   width: 100,
          //   child: InkWell(
          //     borderRadius: const BorderRadius.horizontal(
          //       left: Radius.circular(10),
          //     ),
          //     onTap: onLocationTap,
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 10),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           const Icon(
          //             Icons.location_on_rounded,
          //             size: 15,
          //             color: AppColors.brand500,
          //           ),
          //           const SizedBox(width: 3),
          //           Expanded(
          //             child: Text(
          //               location,
          //               maxLines: 1,
          //               overflow: TextOverflow.ellipsis,
          //               style: const TextStyle(
          //                 fontSize: 12.5,
          //                 fontWeight: FontWeight.w600,
          //                 color: Colors.black87,
          //               ),
          //             ),
          //           ),
          //           const Icon(
          //             Icons.keyboard_arrow_down_rounded,
          //             size: 14,
          //             color: Colors.black45,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          // ── Divider ───────────────────────────────────────────────
          Container(height: 22, width: 1, color: AppColors.surfaceBorder),

          // ── Search placeholder — takes remaining space ──────────────
          Expanded(
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: Colors.black45),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search products, brands...',
                        style: TextStyle(fontSize: 13.5, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
