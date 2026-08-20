// lib/app/app_bootstrap.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/internet_service.dart';
import '../core/providers/theme_provider.dart';
import '../core/constants/app_colors.dart';
import 'app.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    InternetService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: _ThemeAwareStatusBar(child: const App()));
  }
}

class _ThemeAwareStatusBar extends ConsumerWidget {
  const _ThemeAwareStatusBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark =
        appThemeMode == AppThemeMode.dark ||
        (appThemeMode == AppThemeMode.system &&
            platformBrightness == Brightness.dark);

    // Light: brand500 bg + white icons
    // Dark:  #0F1117 bg + white icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF0F1117) : AppColors.brand500,
        statusBarIconBrightness: Brightness.light, // সবসময় white
        statusBarBrightness: Brightness.dark, // iOS সবসময় white
      ),
    );

    return child;
  }
}
