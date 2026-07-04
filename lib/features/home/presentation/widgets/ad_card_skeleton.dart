// lib/features/home/presentation/widgets/ad_card_skeleton.dart
import 'package:flutter/material.dart';

class AdCardSkeleton extends StatelessWidget {
  final int itemCount;
  const AdCardSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, __) => const _AdCardSkeleton(),
    );
  }
}

class _AdCardSkeleton extends StatelessWidget {
  const _AdCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(w: 48, h: 9),
                const SizedBox(height: 4),
                _box(w: double.infinity, h: 11),
                const SizedBox(height: 3),
                _box(w: 100, h: 11),
                const SizedBox(height: 4),
                _box(w: 70, h: 9),
                const SizedBox(height: 6),
                _box(w: 60, h: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required double w, required double h}) => Container(
    width: w,
    height: h,
    margin: const EdgeInsets.only(bottom: 1),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
