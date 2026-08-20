import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Static list of safety tips shown at the bottom of the post preview.
class PostSafetyTips extends StatelessWidget {
  const PostSafetyTips({super.key});

  static const _tips = [
    'Check the item before you buy',
    'Pay only after collecting item',
    'Beware of unrealistic offers',
    'Meet seller at a safe location',
    'Do not make an abrupt decision',
    'Be honest with the ad you post',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning500.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.warning500,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Safety tips',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 15,
                    color: AppColors.success500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
