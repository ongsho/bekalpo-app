# In-App Update Testing Guide

This guide explains how to test the Google Play In-App Update functionality.

## Overview

The `AppUpdateService` uses the actual Google Play In-App Update API. Google Play handles all UI elements (dialogs, notifications, progress bars) natively.

**Important**: In-app updates only work when the app is installed from Google Play Store. Debug APKs cannot test in-app updates.

## Production Testing

To test in-app updates, you must deploy your app to Google Play with different version codes.

### Steps:

1. **Deploy Current Version to Play Store:**
   - Go to [Play Console](https://play.google.com/console)
   - Select your app
   - Navigate to **Testing & Release → Internal Testing**
   - Build release APK: `flutter build apk --release`
   - Upload version `1.3.0+9` to Internal Testing track
   - Wait for review (usually quick for internal testing)

2. **Deploy Newer Version:**
   - Update version in `pubspec.yaml`: `version: 1.4.0+10`
   - Build release APK: `flutter build apk --release`
   - Upload version `1.4.0+10` to Internal Testing track
   - Wait for review

3. **Test on Device:**
   - Add yourself as a tester in Internal Testing settings
   - Open the opt-in URL on your test device
   - Install version `1.3.0+9` from Play Store
   - Open the app
   - Google Play will show the native update dialog automatically

### Update Types:

- **Immediate Update**: Google Play shows a full-screen dialog blocking app usage until update completes
- **Flexible Update**: Google Play downloads in background and shows a snackbar/notification when complete

## Development Testing (Mock Mode)

Mock mode allows you to test the service logic without Play Store deployment, but **it does not show Google Play UI**.

### Enabling Mock Mode

In `lib/app/app.dart`, uncomment these lines:

```dart
if (kDebugMode) {
  AppUpdateService().enableMockMode();
  AppUpdateService().setMockScenario('flexible_update');
}
```

### Mock Scenarios

The service supports three mock scenarios:

#### 1. No Update Available

```dart
service.setMockScenario('no_update');
await service.checkForUpdate();
// Logs: "Mock - No update available"
```

#### 2. Immediate Update Available

```dart
service.setMockScenario('immediate_update');
await service.checkForUpdate();
// Logs: "Mock - Immediate update available"
// Simulates immediate update starting
```

#### 3. Flexible Update Available

```dart
service.setMockScenario('flexible_update');
await service.checkForUpdate();
// Logs: "Mock - Flexible update available"
// Simulates flexible update starting
```

### Running Built-in Mock Tests

```dart
AppUpdateService.runMockTests();
```

This will print test scenarios to the console.

## Integration in App

The service is integrated in `lib/app/app.dart` inside the `_UpdateChecker` widget:

```dart
class _UpdateCheckerState extends State<_UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await AppUpdateService().checkForUpdate();
    // Google Play handles all UI automatically
    // No custom dialog needed
  }
}
```

## Best Practices

1. **Only Test with Play Store**: In-app updates require Play Store installation
2. **Use Internal Testing Track**: Use internal testing for development testing
3. **Test on Real Devices**: In-app updates don't work on emulators
4. **Check Version Codes**: Ensure newer version has higher version code
5. **Wait for Propagation**: Play Store updates can take 2-3 hours to propagate

## Troubleshooting

### Updates Not Showing

- **ERROR_APP_NOT_OWNED**: App not installed from Play Store (sideloaded or debug APK)
- **No update available**: Version code not higher than installed version
- **Wait time**: Play Store may take 2-3 hours to recognize new version

### Update Fails

- Check internet connectivity
- Verify Play Store is installed and updated
- Ensure sufficient storage space
- Check Play Developer Console for app status

### Debug Logs

The service logs all update checks:

```
AppUpdateService: Calling InAppUpdate.checkForUpdate()...
AppUpdateService: Update availability = UpdateAvailability.updateAvailable
AppUpdateService: Immediate update allowed = true/false
AppUpdateService: Flexible update allowed = true/false
AppUpdateService: Starting immediate/flexible update flow
```

## Additional Resources

- [Google Play In-App Updates Documentation](https://developer.android.com/guide/playcore/in-app-updates)
- [in_app_update Flutter Package](https://pub.dev/packages/in_app_update)
- [Play Console Internal Testing](https://support.google.com/googleplay/android-developer/answer/9303479)
