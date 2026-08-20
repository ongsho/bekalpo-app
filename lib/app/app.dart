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
    // DEV-ONLY: Uncomment below lines to enable mock mode for testing
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

    // Production path: real flexible update available
    if (updateInfo != null && mounted) {
      _hasShownUpdateDialog = true;
      _showUpdateDialog();
    }

    // DEV-ONLY: Mock mode testing hook for flexible update dialog
    // This allows testing the dialog UI without Play Store deployment
    // Has no effect when mock mode is disabled
    final updateService = AppUpdateService();
    if (updateService.isMockFlexibleUpdateAvailable && mounted) {
      _hasShownUpdateDialog = true;
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of the app is available. Would you like to update now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startFlexibleUpdate();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startFlexibleUpdate() async {
    await AppUpdateService().startFlexibleUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update downloaded! Restart to apply.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
