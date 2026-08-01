# Architecture

## Directory Structure

### New Feature: bottom_nav
```
lib/features/bottom_nav/
├── presentation/
│   ├── widgets/
│   │   └── bottom_nav_bar.dart
│   └── screens/
│       └── main_nav_screen.dart
```

### New Feature: post_ad
```
lib/features/post_ad/
├── data/
│   ├── models/
│   │   └── post_ad_model.dart
│   └── services/
│       └── post_ad_service.dart
└── presentation/
    ├── screens/
    │   └── post_ad_screen.dart
    └── widgets/
        ├── photo_upload.dart
        ├── category_selector.dart
        └── location_selector.dart
```

### New Feature: messages
```
lib/features/messages/
├── data/
│   ├── models/
│   │   ├── conversation_model.dart
│   │   └── message_model.dart
│   └── services/
│       └── chat_service.dart
└── presentation/
    ├── screens/
    │   ├── messages_screen.dart
    │   └── chat_screen.dart
    └── widgets/
        ├── conversation_list_item.dart
        └── message_bubble.dart
```

### New Feature: profile
```
lib/features/profile/
├── data/
│   ├── models/
│   │   └── user_profile_model.dart
│   └── services/
│       └── profile_service.dart
└── presentation/
    ├── screens/
    │   └── profile_screen.dart
    └── widgets/
        ├── profile_header.dart
        ├── settings_list.dart
        └── theme_selector.dart
```

## Component Design

### 1. BottomNavBar Widget
**Location**: `lib/features/bottom_nav/presentation/widgets/bottom_nav_bar.dart`

**Responsibilities**:
- Display 5 navigation items
- Handle tap events
- Show active/inactive states
- Integrate with brand colors

**Key Features**:
- Uses Flutter's `BottomNavigationBar`
- 5 items with icons and labels
- Active/inactive state styling
- Brand color integration

### 2. MainNavScreen Widget
**Location**: `lib/features/bottom_nav/presentation/screens/main_nav_screen.dart`

**Responsibilities**:
- Container for bottom navigation
- Manage tab content
- Handle tab switching logic
- Integrate with routing system

**Key Features**:
- Uses `IndexedStack` for state preservation
- Manages navigation state via Riverpod
- Handles tab switching
- Integrates with existing routing

## Data Flow
1. User taps bottom nav item
2. `BottomNavBar` notifies `MainNavScreen`
3. `MainNavScreen` updates navigation state via Riverpod
4. `IndexedStack` switches to corresponding tab
5. Tab content maintains its state

## Integration Points
- **App Routes**: Updated to support nested navigation
- **Theme**: Uses existing `AppColors` and `AppTheme`
- **State Management**: Uses existing `flutter_riverpod`
- **Network**: Uses existing `api_service.dart`
