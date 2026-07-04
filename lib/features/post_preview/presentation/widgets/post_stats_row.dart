import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Three stat pills (Views / Clicks / Rating) shown under the price.
class PostStatsRow extends StatelessWidget {
  final int? views;
  final int? clicks;
  final double? rating;

  const PostStatsRow({
    super.key,
    required this.views,
    required this.clicks,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.remove_red_eye_outlined,
          color: AppColors.brand500,
          value: views?.toString() ?? '0',
          label: 'Views',
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.touch_app_outlined,
          color: AppColors.warning500,
          value: clicks?.toString() ?? '0',
          label: 'Clicks',
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.star_rounded,
          color: AppColors.warning500,
          value: rating?.toString() ?? '0',
          label: 'Rating',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatPill({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}