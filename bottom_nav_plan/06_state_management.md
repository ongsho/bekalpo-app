# State Management

## Navigation State

### navIndexProvider
**Location**: `lib/features/bottom_nav/presentation/providers/nav_index_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);
```

**Purpose**: Track currently selected tab index

**Usage**:
```dart
final navIndex = ref.watch(navIndexProvider);
```

**Update**:
```dart
ref.read(navIndexProvider.notifier).state = newIndex;
```

## Tab Screen States

### Home Tab State
**Existing Providers**:
- `postsProvider` - Posts data and loading state
- `categoriesProvider` - Categories data and loading state

**State Preservation**: Maintained via `IndexedStack`

### Search Tab State
**Local State**:
- Search query (`TextEditingController`)
- Search suggestions (`List<SearchSuggestion>`)
- Loading state (`bool`)
- Error state (`String?`)

**State Preservation**: Maintained via `IndexedStack`

### Post Ad Tab State
**New Providers** (to be created):
```dart
final postAdFormProvider = StateProvider<PostAdForm>((ref) => PostAdForm());
final postAdLoadingProvider = StateProvider<bool>((ref) => false);
final postAdErrorProvider = StateProvider<String?>((ref) => null);
```

**Form Model**:
```dart
class PostAdForm {
  final String title;
  final String description;
  final String price;
  final String category;
  final String location;
  final List<String> imageUrls;
  
  PostAdForm({
    this.title = '',
    this.description = '',
    this.price = '',
    this.category = '',
    this.location = '',
    this.imageUrls = const [],
  });
}
```

### Messages Tab State
**New Providers** (to be created):
```dart
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  // Fetch conversations
});

final activeChatProvider = StateProvider<Chat?>((ref) => null);
final messagesProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  // Fetch messages for chat
});
```

**Models**:
```dart
class Conversation {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
}
```

### Profile Tab State
**New Providers** (to be created):
```dart
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  // Fetch user profile
});

final themeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.system);
```

**Model**:
```dart
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime joinedDate;
  final int totalAds;
  final int activeAds;
}
```

## State Architecture

### Provider Hierarchy
```
App (ConsumerWidget)
└── MainNavScreen (ConsumerWidget)
    ├── navIndexProvider (StateProvider)
    ├── HomeScreen
    │   ├── postsProvider (FutureProvider)
    │   └── categoriesProvider (FutureProvider)
    ├── SearchScreen (local state)
    ├── PostAdScreen
    │   ├── postAdFormProvider (StateProvider)
    │   ├── postAdLoadingProvider (StateProvider)
    │   └── postAdErrorProvider (StateProvider)
    ├── MessagesScreen
    │   ├── conversationsProvider (FutureProvider)
    │   ├── activeChatProvider (StateProvider)
    │   └── messagesProvider (FutureProvider.family)
    └── ProfileScreen
        ├── userProfileProvider (FutureProvider)
        └── themeProvider (StateProvider)
```

## State Synchronization

### Cross-Tab Communication
- **Home to Post Ad**: Navigate to Post Ad tab with pre-filled category
- **Post Ad to Home**: Refresh posts after successful ad posting
- **Profile to Home**: Refresh posts after profile changes

### Implementation
```dart
// Navigate to specific tab
ref.read(navIndexProvider.notifier).state = targetIndex;

// Refresh data after action
ref.read(postsProvider.notifier).refresh();
```

## Performance Considerations

### IndexedStack Benefits
- All tabs stay in memory
- No rebuild when switching tabs
- Smooth instant switching
- Scroll positions preserved

### Memory Management
- Consider lazy loading for heavy tabs
- Dispose unused resources in tab lifecycle
- Use `AutomaticKeepAliveClientMixin` if needed

### Optimization Strategies
- Cache API responses
- Use `const` widgets where possible
- Implement pagination for lists
- Debounce search queries
