import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color brand25 = Color(0xFFF4F9FE);
  static const Color brand50 = Color(0xFFE8F3FC);
  static const Color brand100 = Color(0xFFCFE6FA);
  static const Color brand200 = Color(0xFF9FCEF5);
  static const Color brand300 = Color(0xFF6FB5EF);
  static const Color brand400 = Color(0xFF3F9DE8);
  static const Color brand500 = Color(0xFF0A66C2); // Primary
  static const Color brand600 = Color(0xFF0957A5);
  static const Color brand700 = Color(0xFF074788);
  static const Color brand800 = Color(0xFF06386B);
  static const Color brand900 = Color(0xFF04284D);
  static const Color brand950 = Color(0xFF021629);

  static const MaterialColor primarySwatch =
      MaterialColor(0xFF0A66C2, <int, Color>{
        50: brand50,
        100: brand100,
        200: brand200,
        300: brand300,
        400: brand400,
        500: brand500,
        600: brand600,
        700: brand700,
        800: brand800,
        900: brand900,
      });

  // Neutral / Surface Colors
  static const Color surfaceBg = Color(0xFFF5F6FA); // page background
  static const Color surfaceBorder = Color(0xFFE7E9EE); // card / divider border
  static const Color textDark = Color(0xFF1A1A1A); // primary text color
  static const Color textGray = Color(0xFF8A8A8A); // secondary text color

  // Semantic Colors
  static const Color success500 = Color(0xFF16A34A); // green — verified, safety
  static const Color warning500 = Color(0xFFF59E0B); // amber — badges, ratings
  static const Color error500 = Color(
    0xFFDC2626,
  ); // red — error, destructive actions
}
