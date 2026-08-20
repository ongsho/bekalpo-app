// lib/app/app.dart
import 'package:bekalpo/core/theme/app_theme.dart';
import 'package:bekalpo/core/providers/theme_provider.dart';
import 'package:bekalpo/core/network/app_update_service.dart';
import 'package:bekalpo/features/bottom_nav/presentation/screens/main_nav_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_routes.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    final themeMode = switch (appThemeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bekalpo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _UpdateChecker(child: MainNavScreen()),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

class _UpdateChecker extends StatefulWidget {
  final Widget child;
  const _UpdateChecker({required this.child});

  @override
  State<_UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<_UpdateChecker> {
  bool _hasShownUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    // Check for updates on app start
    // Immediate updates will start automatically
    // Flexible updates will return update info for UI handling
    // DEV-ONLY: Uncomment below lines to enable mock mode for UI testing
    // Note: Mock mode only shows custom dialog, not actual Google Play UI
    // For actual Google Play In-App Update testing, app must be installed from Play Store
    // if (kDebugMode) {
    //   AppUpdateService().enableMockMode();
    //   AppUpdateService().setMockScenario('flexible_update');
    // }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasShownUpdateDialog) return;

    final updateInfo = await AppUpdateService().checkForUpdate();

    // For flexible updates, Google Play handles the UI automatically
    // For immediate updates, Google Play also handles the UI automatically
    // We don't need to show any custom dialog - let Google Play handle everything
    // This code just ensures we only check once per session
    if (updateInfo != null) {
      _hasShownUpdateDialog = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
