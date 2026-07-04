// main.dart
import 'package:flutter/material.dart';
import 'package:bekalpo/app/app_bootstrap.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar: brand color background, white icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.brand500,
      statusBarIconBrightness: Brightness.light, // Android — white icons
      statusBarBrightness: Brightness.dark, // iOS — white icons
    ),
  );

  runApp(const AppBootstrap());
}
