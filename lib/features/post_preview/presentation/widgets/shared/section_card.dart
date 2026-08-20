import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// A white card with a left-accented header bar (icon + title) and content
/// below it. Used across post preview sections (Specification, Description,
/// Seller, Safety tips) — extract here so other screens can reuse the same
/// visual pattern instead of re-implementing it.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderBar(title: title, icon: icon),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SectionHeaderBar extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeaderBar({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.brand500, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.brand500),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip used for badges ("For sale") and multi-select
/// specification tags (e.g. selected feature lists).
class BadgeChip extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? foreground;

  const BadgeChip({
    super.key,
    required this.text,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackground =
        background ??
        (isDark
            ? AppColors.brand500.withOpacity(0.15)
            : AppColors.brand500.withOpacity(0.08));
    final effectiveForeground = foreground ?? AppColors.brand500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: effectiveForeground,
        ),
      ),
    );
  }
}
