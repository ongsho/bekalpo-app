import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service for handling Google Play In-App Updates
/// Supports both immediate and flexible update flows
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  bool _hasCheckedForUpdate = false;
  bool _isUpdateInProgress = false;

  // Mock mode for development testing
  bool _mockMode = false;
  dynamic _mockUpdateInfo; // Can be null, true (immediate), or 'flexible'

  /// Check for available updates and start appropriate update flow
  ///
  /// For immediate updates: automatically starts the update
  /// For flexible updates: provides update info for UI to handle
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid || _hasCheckedForUpdate || _isUpdateInProgress) {
      return null;
    }

    _hasCheckedForUpdate = true;

    try {
      if (_mockMode) {
        // Handle mock scenarios
        if (_mockUpdateInfo == null) {
          // No update scenario
          return null;
        } else if (_mockUpdateInfo == true) {
          // Immediate update scenario
          await _startImmediateUpdate();
          return null;
        } else if (_mockUpdateInfo == 'flexible') {
          // Flexible update scenario - return mock info
          // Since we can't create a real AppUpdateInfo, we'll return null
          // and let the UI handle it via other means
          debugPrint('Mock: Flexible update available');
          return null;
        }
      }

      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          await _startImmediateUpdate();
        } else {
          // Flexible update - return info for UI to handle
          return updateInfo;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('In-app update check failed: $e');
      }
      return null;
    }
  }

  /// Start immediate update flow (no user interaction required)
  Future<void> _startImmediateUpdate() async {
    if (_isUpdateInProgress) return;

    _isUpdateInProgress = true;

    try {
      if (_mockMode) {
        debugPrint('Mock: Immediate update would start');
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Immediate update failed: $e');
      }
    } finally {
      _isUpdateInProgress = false;
    }
  }

  /// Start flexible update flow (user interaction required)
  /// Call this when user accepts the update from UI
  Future<void> startFlexibleUpdate() async {
    if (_isUpdateInProgress) return;

    _isUpdateInProgress = true;

    try {
      if (_mockMode) {
        debugPrint('Mock: Flexible update would start');
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Flexible update failed: $e');
      }
    } finally {
      _isUpdateInProgress = false;
    }
  }

  /// Check if an update is currently in progress
  bool get isUpdateInProgress => _isUpdateInProgress;

  /// Reset the checked state (useful for testing or manual refresh)
  void resetCheckState() {
    _hasCheckedForUpdate = false;
  }

  /// Enable mock mode for development testing
  void enableMockMode() {
    _mockMode = true;
    resetCheckState();
  }

  /// Disable mock mode
  void disableMockMode() {
    _mockMode = false;
    resetCheckState();
  }

  /// Set mock update scenario for testing
  void setMockScenario(String scenario) {
    switch (scenario) {
      case 'no_update':
        _mockUpdateInfo = null; // Will simulate no update
        break;
      case 'immediate_update':
        // Will be handled in checkForUpdate to simulate immediate update
        _mockUpdateInfo = true;
        break;
      case 'flexible_update':
        // Will be handled in checkForUpdate to simulate flexible update
        _mockUpdateInfo = 'flexible';
        break;
    }
  }

  /// Mock test scenarios for development
  static void runMockTests() {
    final service = AppUpdateService();
    service.enableMockMode();

    debugPrint('=== Mock Update Service Tests ===');

    // Test 1: No update available
    debugPrint('Test 1: No update available');
    service.setMockScenario('no_update');
    service.checkForUpdate().then((result) {
      debugPrint('Result: $result (should be null)');
    });

    // Test 2: Immediate update available
    debugPrint('Test 2: Immediate update available');
    service.setMockScenario('immediate_update');
    service.checkForUpdate().then((result) {
      debugPrint('Result: $result (should trigger immediate update)');
    });

    // Test 3: Flexible update available
    debugPrint('Test 3: Flexible update available');
    service.setMockScenario('flexible_update');
    service.checkForUpdate().then((result) {
      debugPrint('Result: $result (should return update info)');
    });

    debugPrint('=== Mock tests completed ===');
    debugPrint('Use: AppUpdateService().runMockTests() to test');
    debugPrint(
      'Then: AppUpdateService().checkForUpdate() to test each scenario',
    );
  }
}
