# Bekalpo Bottom Navigation Plan

## Overview
Bottom navigation bar implementation for Bekalpo - a buy/sell secondhand items marketplace app.

## Navigation Items

### Primary Tabs (5 items)
1. **হোম (Home)** - Browse ads and categories
   - Icon: `home_outlined` / `home`
   - Screen: `HomeScreen` (existing)
   - Route: `/`

2. **অনুসন্ধান (Search)** - Search products
   - Icon: `search_outlined` / `search`
   - Screen: `SearchScreen` (existing)
   - Route: `/search`

3. **বিজ্ঞাপন (Post Ad)** - Post new advertisements
   - Icon: `add_circle_outline` / `add_circle`
   - Screen: `PostAdScreen` (new - to be created)
   - Route: `/post-ad`

4. **বার্তা (Messages)** - Chat between buyers and sellers
   - Icon: `chat_bubble_outline` / `chat_bubble`
   - Screen: `MessagesScreen` (new - to be created)
   - Route: `/messages`

5. **প্রোফাইল (Profile)** - User profile and settings
   - Icon: `person_outline` / `person`
   - Screen: `ProfileScreen` (new - to be created)
   - Route: `/profile`

## Architecture

### Directory Structure
```
lib/features/
├── bottom_nav/
│   ├── presentation/
│   │   ├── widgets/
│   │   │   └── bottom_nav_bar.dart
│   │   └── screens/
│   │       └── main_nav_screen.dart
├── post_ad/ (new feature)
│   ├── data/
│   │   ├── models/
│   │   └── services/
│   └── presentation/
│       ├── screens/
│       │   └── post_ad_screen.dart
│       └── widgets/
├── messages/ (new feature)
│   ├── data/
│   │   ├── models/
│   │   └── services/
│   └── presentation/
│       ├── screens/
│       │   ├── messages_screen.dart
│       │   └── chat_screen.dart
│       └── widgets/
└── profile/ (new feature)
    ├── data/
    │   ├── models/
    │   └── services/
    └── presentation/
        ├── screens/
        │   └── profile_screen.dart
        └── widgets/
```

### Component Design

#### 1. BottomNavBar Widget
- Uses Flutter's `BottomNavigationBar`
- 5 navigation items with icons and labels
- Active/inactive state styling
- Brand color integration (`AppColors.brand500`)
- Smooth transitions between tabs

#### 2. MainNavScreen Widget
- Container for bottom navigation
- Uses `PageView` or `IndexedStack` for tab content
- Manages navigation state
- Handles tab switching logic
- Integrates with existing routing system

## Implementation Phases

### Phase 1: Core Navigation Structure
1. Create `bottom_nav` feature directory structure
2. Implement `BottomNavBar` widget
3. Implement `MainNavScreen` with tab switching
4. Update `app.dart` to use `MainNavScreen` as initial route
5. Update routing to handle nested navigation

### Phase 2: Integrate Existing Screens
1. Wrap `HomeScreen` for tab 1
2. Wrap `SearchScreen` for tab 2
3. Remove navigation to these screens from other parts of app
4. Update app routes accordingly

### Phase 3: Create Placeholder Screens
1. Create `PostAdScreen` with basic UI
2. Create `MessagesScreen` with basic UI
3. Create `ProfileScreen` with basic UI
4. Add navigation to these tabs

### Phase 4: Full Feature Implementation
1. Implement post ad functionality
2. Implement messaging system
3. Implement user profile features
4. Add proper state management with Riverpod

## Design Specifications

### Visual Style
- **Height**: 56px (standard Material Design)
- **Background**: White (light mode), Dark grey (dark mode)
- **Active Icon**: Brand color (#0A66C1)
- **Inactive Icon**: Grey (#9E9E9E)
- **Active Label**: Brand color (#0A66C1)
- **Inactive Label**: Grey (#9E9E9E)
- **Font Size**: 12px for labels
- **Icon Size**: 24px

### Behavior
- Tap to switch tabs
- Maintain state when switching tabs (using `IndexedStack`)
- No animation on tab switch (instant)
- Active tab indicator (optional - can be added later)

## State Management

### Navigation State
```dart
final navIndexProvider = StateProvider<int>((ref) => 0);
```

### Tab Screens State
Each tab will maintain its own state using existing Riverpod providers:
- Home: `postsProvider`, `categoriesProvider`
- Search: Search state (local)
- Post Ad: Form state (to be created)
- Messages: Chat state (to be created)
- Profile: User state (to be created)

## Routing Integration

### Updated Routes
```dart
class AppRoutes {
  static const String mainNav = "/";  // Changed from home
  static const String home = "/home";  // Nested route
  static const String search = "/search";  // Nested route
  static const String postAd = "/post-ad";  // Nested route
  static const String messages = "/messages";  // Nested route
  static const String profile = "/profile";  // Nested route
  // ... other routes remain the same
}
```

### Navigation Logic
- Bottom nav handles main tab switching
- Individual tabs handle their own internal navigation
- Deep links can navigate to specific tabs
- Back button behavior preserved

## Dependencies
No additional dependencies needed - using existing:
- `flutter_riverpod` for state management
- Material Design components

## Benefits
1. **Better UX**: Easy access to main features
2. **Standard Pattern**: Follows mobile app conventions
3. **Scalable**: Easy to add/remove tabs
4. **State Preservation**: Each tab maintains its state
5. **Clear Navigation**: Users always know where they are

## Notes
- Post Ad, Messages, and Profile screens will start with placeholder UI
- Full implementation of these features will be done in subsequent phases
- Existing navigation to Home and Search will be replaced with bottom nav
- Theme selector FAB will be moved to Profile screen
