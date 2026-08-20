# In-App Update Testing Guide

This guide explains how to test the Google Play In-App Update functionality in development and production.

## Overview

The `AppUpdateService` supports two modes:
1. **Production Mode**: Uses actual Google Play In-App Update API
2. **Mock Mode**: Simulates update scenarios for development testing

## Production Testing

To test in-app updates in production, you need to deploy your app to Google Play with different version codes.

### Steps:

1. **Deploy Test Version**: Upload version `1.3.0+9` to Play Store (internal testing track)
2. **Deploy New Version**: Upload version `1.4.0+10` to Play Store (internal testing track)
3. **Install Test Version**: Install version `1.3.0+9` on a test device
4. **Check for Updates**: The app will automatically check for updates on launch
5. **Verify Update Flow**: The update dialog/flow should appear based on update type

### Update Types:

- **Immediate Update**: Blocks app usage until update is complete
- **Flexible Update**: Allows user to continue using app while update downloads

## Development Testing (Mock Mode)

Mock mode allows you to test the update service without deploying to Play Store.

### Enabling Mock Mode

```dart
import 'package:bekalpo/core/network/app_update_service.dart';

final service = AppUpdateService();
service.enableMockMode();
```

### Mock Scenarios

The service supports three mock scenarios:

#### 1. No Update Available

```dart
service.setMockScenario('no_update');
final result = await service.checkForUpdate();
// result will be null
```

#### 2. Immediate Update Available

```dart
service.setMockScenario('immediate_update');
final result = await service.checkForUpdate();
// Immediate update will start automatically
// result will be null
```

#### 3. Flexible Update Available

```dart
service.setMockScenario('flexible_update');
final result = await service.checkForUpdate();
// result will be null (simulated)
// You can show update UI to user
```

### Complete Mock Test Example

```dart
void testUpdateService() {
  final service = AppUpdateService();
  service.enableMockMode();
  
  // Test no update
  service.setMockScenario('no_update');
  service.checkForUpdate().then((result) {
    print('No update test: $result');
  });
  
  // Test immediate update
  service.setMockScenario('immediate_update');
  service.checkForUpdate().then((result) {
    print('Immediate update test: $result');
  });
  
  // Test flexible update
  service.setMockScenario('flexible_update');
  service.checkForUpdate().then((result) {
    print('Flexible update test: $result');
  });
  
  // Disable mock mode when done
  service.disableMockMode();
}
```

### Running Built-in Mock Tests

The service includes a built-in test function:

```dart
AppUpdateService.runMockTests();
```

This will print test scenarios to the console for manual testing.

## Integration in App

The service is already integrated in `app_bootstrap.dart`:

```dart
@override
void initState() {
  super.initState();
  InternetService().initialize();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppUpdateService().checkForUpdate();
  });
}
```

### Handling Flexible Updates

For flexible updates, you need to show UI to the user and call `startFlexibleUpdate()` when they accept:

```dart
final updateInfo = await AppUpdateService().checkForUpdate();
if (updateInfo != null) {
  // Show update dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Update Available'),
      content: const Text('A new version is available.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            AppUpdateService().startFlexibleUpdate();
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}
```

## Best Practices

1. **Enable Mock Mode Only in Development**: Never enable mock mode in production builds
2. **Reset Check State**: Use `resetCheckState()` to re-check for updates during testing
3. **Handle Update Progress**: Show progress indicators for flexible updates
4. **Test on Real Devices**: Play Store in-app updates only work on real Android devices, not emulators
5. **Use Internal Testing Track**: Use Play Store's internal testing track for early testing

## Troubleshooting

### Updates Not Showing in Production

- Ensure the app is installed from Play Store (not sideloaded)
- Check that the new version has a higher version code
- Verify the app is signed with the same signing key
- Wait for Play Store to propagate the update (can take 2-3 hours)

### Mock Mode Not Working

- Ensure `enableMockMode()` is called before `checkForUpdate()`
- Use `resetCheckState()` if you need to re-check for updates
- Check console logs for debug output

### Update Fails

- Check internet connectivity
- Verify Play Store is installed and updated
- Ensure sufficient storage space on device
- Check Play Developer Console for any app suspension

## Additional Resources

- [Google Play In-App Updates Documentation](https://developer.android.com/guide/playcore/in-app-updates)
- [in_app_update Flutter Package](https://pub.dev/packages/in_app_update)
- See `lib/core/network/app_update_integration_example.dart` for complete integration example
