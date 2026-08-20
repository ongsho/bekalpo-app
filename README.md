# bekalpo

A Flutter application with authentication, profile management, and in-app update capabilities.

## Getting Started

This project is a Flutter application with the following features:
- User authentication (phone/email signup and signin)
- Profile management
- Dark/light theme support
- Google Play In-App Updates

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release Notes

### Version 1.3.0

**Features:**
- Added Google Play In-App Update service with both immediate and flexible update flows
- Added mock mode for development testing of in-app updates
- Improved theme support across all authentication screens
- Enhanced profile header to display both email and phone number

**UI/UX Improvements:**
- All auth screens now properly support light/dark themes with dynamic colors
- Replaced logout AlertDialog with BottomSheet for better UX
- Added error color constant (AppColors.error500) for consistent red styling
- Improved focus states in auth form fields

**Bug Fixes:**
- Fixed hardcoded colors in authentication screens
- Fixed logout button displaying pink instead of red

**Technical:**
- Added AppUpdateService for handling Google Play In-App Updates
- Added integration example for in-app update service
- Updated app version to 1.3.0+9

## Development

### Testing In-App Updates

The AppUpdateService includes a mock mode for development testing without deploying to Play Store:

```dart
final service = AppUpdateService();
service.enableMockMode();
service.setMockScenario('flexible_update');
service.checkForUpdate();
```

See `lib/core/network/app_update_integration_example.dart` for more details.
