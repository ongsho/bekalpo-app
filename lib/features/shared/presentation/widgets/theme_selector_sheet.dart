// lib/features/shared/presentation/widgets/theme_selector_sheet.dart
//
// TEMPORARY — এই widget টা permanent না।
// পরে settings page এ move করা হবে।
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ThemeSelectorSheet extends ConsumerWidget {
  const ThemeSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'App Theme',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how Bekalpo looks to you.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Light',
              mode: AppThemeMode.light,
              selected: current == AppThemeMode.light,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(AppThemeMode.light),
            ),
            const SizedBox(height: 10),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Dark',
              mode: AppThemeMode.dark,
              selected: current == AppThemeMode.dark,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(AppThemeMode.dark),
            ),
            const SizedBox(height: 10),
            _ThemeOption(
              icon: Icons.brightness_auto_rounded,
              label: 'System default',
              mode: AppThemeMode.system,
              selected: current == AppThemeMode.system,
              onTap: () => ref
                  .read(themeProvider.notifier)
                  .setTheme(AppThemeMode.system),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brand500 : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.brand500 : Colors.grey,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.brand500 : null,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.brand500,
              ),
          ],
        ),
      ),
    );
  }
}
