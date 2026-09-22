import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../../app/router/app_routes.dart';

/// Service for handling deep links and Android App Links
/// Handles both cold start (app not running) and warm start (app in background)
class DeepLinkService {
  final GlobalKey<NavigatorState> navigatorKey;
  String? _lastHandledSlug;

  // App links instance
  final AppLinks _appLinks = AppLinks();

  // Stream subscription for warm start links
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService(this.navigatorKey);

  /// Initialize the deep link service
  /// Call this when the app starts
  Future<void> initialize() async {
    // Handle cold start (app launched from link)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle warm start (app already running, link tapped)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  /// Handle incoming deep link URI
  void _handleDeepLink(Uri uri) {
    // Check if the URI matches our expected pattern: https://bekalpo.com/ads/{slug}
    if (uri.scheme == 'https' &&
        uri.host == 'bekalpo.com' &&
        uri.path.startsWith('/ads/')) {
      // Extract slug from path: /ads/{slug} -> {slug}
      final slug = uri.path.substring('/ads/'.length);

      if (slug.isNotEmpty) {
        _navigateToPost(slug);
      }
    }
  }

  /// Navigate to post preview screen with duplicate guard
  void _navigateToPost(String slug) {
    // Duplicate navigation guard - skip if same slug was just handled
    if (_lastHandledSlug == slug) {
      return;
    }
    _lastHandledSlug = slug;

    // Navigate using the global navigator key
    navigatorKey.currentState?.pushNamed(
      AppRoutes.postPreview,
      arguments: slug,
    );
  }

  /// Dispose the service and cancel subscriptions
  void dispose() {
    _linkSubscription?.cancel();
  }
}
