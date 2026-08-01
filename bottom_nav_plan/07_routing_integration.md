# Routing Integration

## Updated Routes Structure

### Current Routes (Before)
```dart
class AppRoutes {
  static const String home = "/";
  static const String postPreview = "/post";
  static const String search = "/search";
  static const String searchResults = "/search/results";
  static const String categoryHierarchy = "/category-hierarchy";
  static const String locationHierarchy = "/location-hierarchy";
}
```

### New Routes (After)
```dart
class AppRoutes {
  // Main navigation
  static const String mainNav = "/";  // Changed from home
  
  // Tab routes (nested)
  static const String home = "/home";
  static const String search = "/search";
  static const String postAd = "/post-ad";
  static const String messages = "/messages";
  static const String profile = "/profile";
  
  // Detail routes (remain the same)
  static const String postPreview = "/post";
  static const String searchResults = "/search/results";
  static const String categoryHierarchy = "/category-hierarchy";
  static const String locationHierarchy = "/location-hierarchy";
}
```

## Navigation Logic

### Initial Route
```dart
// app.dart
initialRoute: AppRoutes.mainNav,
```

### Main Navigation Screen
```dart
// app_routes.dart
case AppRoutes.mainNav:
  return MaterialPageRoute(builder: (_) => const MainNavScreen());
```

### Tab Navigation
Tab switching is handled internally by `MainNavScreen` via `navIndexProvider`, not through routes.

### Deep Linking to Tabs
```dart
// Navigate to specific tab from anywhere
Navigator.pushNamed(context, AppRoutes.mainNav);
// Then set tab index
ref.read(navIndexProvider.notifier).state = targetIndex;
```

### Nested Navigation
Each tab can have its own internal navigation:

```dart
// Home tab internal navigation
Navigator.pushNamed(context, AppRoutes.categoryHierarchy, arguments: category);

// Search tab internal navigation
Navigator.pushNamed(context, AppRoutes.searchResults, arguments: query);

// Post Ad tab internal navigation
Navigator.pushNamed(context, AppRoutes.postPreview, arguments: slug);
```

## Route Handler Updates

### Updated generateRoute
```dart
static Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.mainNav:
      return MaterialPageRoute(builder: (_) => const MainNavScreen());
    
    case AppRoutes.home:
      // This is now nested, handled by MainNavScreen
      return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 0));
    
    case AppRoutes.search:
      // This is now nested, handled by MainNavScreen
      return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 1));
    
    case AppRoutes.postPreview:
      final slug = settings.arguments as String?;
      if (slug == null) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("Invalid post slug"))),
        );
      }
      return MaterialPageRoute(builder: (_) => PostPreviewScreen(slug: slug));
    
    case AppRoutes.searchResults:
      final query = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (_) => SearchResultsScreen(query: query ?? ''),
      );
    
    // ... other routes remain the same
    
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text("Route not found"))),
      );
  }
}
```

## Back Button Behavior

### Current Behavior
- Pressing back from HomeScreen exits app

### New Behavior
- Pressing back from any tab exits app (when on main nav)
- Pressing back from nested screens goes back to previous screen
- Pressing back from detail screens goes back to originating tab

### Implementation
```dart
// MainNavScreen
WillPopScope(
  onWillPop: () async {
    if (ref.read(navIndexProvider) != 0) {
      // If not on home tab, go to home tab
      ref.read(navIndexProvider.notifier).state = 0;
      return false;
    }
    // If on home tab, allow exit
    return true;
  },
  child: // ... child widgets
)
```

## Navigation Updates Required

### Remove Old Navigation
1. Remove `Navigator.pushNamed(context, AppRoutes.home)` from all screens
2. Remove `Navigator.pushNamed(context, AppRoutes.search)` from all screens
3. Update any hardcoded navigation to use bottom nav

### Add New Navigation
1. Update HomeScreen search button to switch to search tab instead of navigating
2. Update any other navigation to use tab switching where appropriate

### Example Update
```dart
// Before
void _onSearchTap() {
  Navigator.pushNamed(context, AppRoutes.search);
}

// After
void _onSearchTap() {
  ref.read(navIndexProvider.notifier).state = 1; // Switch to search tab
}
```

## Web Routing Considerations

### URL Structure
- `/` - Main nav (home tab)
- `/home` - Home tab
- `/search` - Search tab
- `/post-ad` - Post ad tab
- `/messages` - Messages tab
- `/profile` - Profile tab

### URL Updates
When tabs change, update URL without full page reload:
```dart
// Update URL on tab change
void _onTabChange(int index) {
  ref.read(navIndexProvider.notifier).state = index;
  // Update URL based on index
  final route = _getRouteFromIndex(index);
  // Use web-specific URL updating
}
```

## Migration Checklist

- [ ] Update `AppRoutes` constants
- [ ] Update `generateRoute` method
- [ ] Update `initialRoute` in app.dart
- [ ] Remove old navigation to HomeScreen
- [ ] Remove old navigation to SearchScreen
- [ ] Update HomeScreen search button
- [ ] Update any other hardcoded navigation
- [ ] Test back button behavior
- [ ] Test deep linking to tabs
- [ ] Test nested navigation within tabs
- [ ] Update web URL routing (if applicable)
