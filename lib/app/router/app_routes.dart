// app/router/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/bottom_nav/presentation/screens/main_nav_screen.dart';
import '../../features/post_preview/presentation/screens/post_preview_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/my_posts/presentation/screens/my_posts_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/post_add/presentation/screens/post_add_screen.dart';

class AppRoutes {
  static const String home = "/";
  static const String postPreview = "/post";
  static const String search = "/search";
  static const String searchResults = "/search/results";
  static const String categoryHierarchy = "/category-hierarchy";
  static const String locationHierarchy = "/location-hierarchy";
  static const String myPosts = "/my-posts";
  static const String profileEdit = "/profile/edit";
  static const String postAdd = "/post-add";

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
        final searchParams = settings.arguments;
        // Handle both String (legacy from search screen) and SearchFilters (new from category/location)
        if (searchParams == null) {
          return MaterialPageRoute(
            builder: (_) => SearchResultsScreen(searchParams: ''),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(searchParams: searchParams),
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

      case myPosts:
        return MaterialPageRoute(builder: (_) => const MyPostsScreen());

      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());

      case postAdd:
        final args = settings.arguments;
        String? postId;
        Map<String, dynamic>? initialData;
        
        if (args is String) {
          postId = args;
        } else if (args is Map<String, dynamic>) {
          postId = args['postId'] as String?;
          initialData = args;
        }
        
        return MaterialPageRoute(
          builder: (_) => PostAddScreen(
            postId: postId,
            initialData: initialData,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
