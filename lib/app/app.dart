// lib/app/app.dart
import 'package:bekalpo/core/theme/app_theme.dart';
import 'package:bekalpo/core/providers/theme_provider.dart';
import 'package:bekalpo/features/bottom_nav/presentation/screens/main_nav_screen.dart';
import 'package:bekalpo/features/shared/presentation/widgets/connectivity_wrapper.dart';
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
      home: const MainNavScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
