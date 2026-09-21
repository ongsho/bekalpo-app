import 'package:flutter/material.dart';
import '../../../../core/models/review.dart';
import '../../../../core/constants/app_colors.dart';
import 'shared/section_card.dart';

class ReviewsSection extends StatelessWidget {
  final List<Review>? reviews;
  final int? approvedReviewsCount;
  final double? approvedReviewsAvgRating;

  const ReviewsSection({
    super.key,
    this.reviews,
    this.approvedReviewsCount,
    this.approvedReviewsAvgRating,
  });

  @override
  Widget build(BuildContext context) {
    final approvedReviews = reviews?.where((r) => r.approved == true).toList() ?? [];

    if (approvedReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      title: 'Reviews ($approvedReviewsCount)',
      icon: Icons.rate_review_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (approvedReviewsAvgRating != null) ...[
            _buildRatingSummary(context),
            const SizedBox(height: 16),
          ],
          ...approvedReviews.map((review) => _buildReviewItem(context, review)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning500.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  approvedReviewsAvgRating?.toStringAsFixed(1) ?? '0.0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$approvedReviewsCount reviews',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Based on approved reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brand500.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.brand500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.name ?? 'Anonymous',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (review.rating ?? 0) ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.warning500,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
