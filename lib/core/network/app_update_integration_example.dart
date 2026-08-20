import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'app_update_service.dart';

/// Example integration of AppUpdateService
/// 
/// This file demonstrates how to integrate the in-app update service
/// into your Flutter application for both production and development.
/// 
/// For production use:
/// 1. Call AppUpdateService().checkForUpdate() in your app's initialization
/// 2. Handle flexible updates by showing UI to the user
/// 3. Call AppUpdateService().startFlexibleUpdate() when user accepts
/// 
/// For development testing:
/// 1. Enable mock mode: AppUpdateService().enableMockMode()
/// 2. Set mock scenario: AppUpdateService().setMockScenario('flexible_update')
/// 3. Test the update flow without needing Play Store deployment
class AppUpdateIntegrationExample extends StatefulWidget {
  const AppUpdateIntegrationExample({super.key});

  @override
  State<AppUpdateIntegrationExample> createState() => _AppUpdateIntegrationExampleState();
}

class _AppUpdateIntegrationExampleState extends State<AppUpdateIntegrationExample> {
  final AppUpdateService _updateService = AppUpdateService();
  AppUpdateInfo? _updateInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isLoading = true);
    
    final updateInfo = await _updateService.checkForUpdate();
    
    if (mounted) {
      setState(() {
        _updateInfo = updateInfo;
        _isLoading = false;
      });

      // If flexible update is available, show update dialog
      if (updateInfo != null) {
        _showUpdateDialog();
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of the app is available. Would you like to update now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startFlexibleUpdate();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startFlexibleUpdate() async {
    setState(() => _isLoading = true);
    
    await _updateService.startFlexibleUpdate();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update downloaded! Restart to apply.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_updateInfo != null)
              const Text('Update available!')
            else
              const Text('No update available'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkForUpdates,
              child: const Text('Check for Updates'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Development testing example
/// 
/// Uncomment the code below to test the update service in development
/// without deploying to Play Store.
void exampleDevTesting() {
  final service = AppUpdateService();
  
  // Enable mock mode
  service.enableMockMode();
  
  // Test different scenarios
  // 1. No update
  service.setMockScenario('no_update');
  
  // 2. Immediate update
  service.setMockScenario('immediate_update');
  
  // 3. Flexible update
  service.setMockScenario('flexible_update');
  
  // Check for update (will use mock data)
  service.checkForUpdate();
  
  // Disable mock mode when done
  service.disableMockMode();
}
