// app/router/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/bottom_nav/presentation/screens/main_nav_screen.dart';
import '../../features/post_preview/presentation/screens/post_preview_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

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
        return MaterialPageRoute(builder: (_) => const MainNavScreen());

      case postPreview:
        final slug = settings.arguments as String?;
        if (slug == null) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text("Invalid post slug"))),
          );
        }
        return MaterialPageRoute(builder: (_) => PostPreviewScreen(slug: slug));

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case searchResults:
        final query = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(query: query ?? ''),
        );

      // case categoryHierarchy:
      //   final category =
      //       settings.arguments; // adjust type to your Category model
      //   return MaterialPageRoute(
      //     builder: (_) => CategoryHierarchyScreen(category: category),
      //   );

      // case locationHierarchy:
      //   return MaterialPageRoute(
      //     builder: (_) => const LocationHierarchyScreen(),
      //   );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
