// app/router/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/post_preview/presentation/screens/post_preview_screen.dart';

class AppRoutes {
  static const String home = "/";
  static const String postPreview = "/post";
  static const String search = "/search";
  static const String searchResults = "/search/results";
  static const String categoryHierarchy = "/category-hierarchy";
  static const String locationHierarchy = "/location-hierarchy";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case postPreview:
        final slug = settings.arguments as String?;
        if (slug == null) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text("Invalid post slug"))),
          );
        }
        return MaterialPageRoute(builder: (_) => PostPreviewScreen(slug: slug));

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
