import 'dart:async';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      debugPrint('DeepLinkService: Initializing...');
    }

    // Handle cold start (app launched from link)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      if (kDebugMode) {
        debugPrint('DeepLinkService: Cold start link received: $initialLink');
      }
      _handleDeepLink(initialLink);
    } else {
      if (kDebugMode) {
        debugPrint('DeepLinkService: No cold start link');
      }
    }

    // Handle warm start (app already running, link tapped)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (kDebugMode) {
          debugPrint('DeepLinkService: Warm start link received: $uri');
        }
        _handleDeepLink(uri);
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('DeepLinkService: Error in link stream: $error');
        }
      },
    );
  }

  /// Handle incoming deep link URI
  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      debugPrint('DeepLinkService: Handling URI: $uri');
      debugPrint(
        'DeepLinkService: Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}',
      );
    }

    String? slug;

    // Check if the URI matches our expected pattern: https://bekalpo.com/ads/{slug}
    if (uri.scheme == 'https' &&
        uri.host == 'bekalpo.com' &&
        uri.path.startsWith('/ads/')) {
      // Extract slug from path: /ads/{slug} -> {slug}
      slug = uri.path.substring('/ads/'.length);
    }
    // Check for custom URL scheme: bekalpo://ads/{slug}
    else if (uri.scheme == 'bekalpo' &&
        uri.host == 'ads' &&
        uri.path.isNotEmpty) {
      // Extract slug from path: /{slug} -> {slug}
      slug = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    }

    if (kDebugMode) {
      debugPrint('DeepLinkService: Extracted slug: $slug');
    }

    if (slug != null && slug.isNotEmpty) {
      _navigateToPost(slug);
    } else {
      if (kDebugMode) {
        debugPrint('DeepLinkService: Slug is empty, skipping navigation');
      }
    }
  }

  /// Navigate to post preview screen with duplicate guard
  void _navigateToPost(String slug) {
    // Duplicate navigation guard - skip if same slug was just handled
    if (_lastHandledSlug == slug) {
      if (kDebugMode) {
        debugPrint('DeepLinkService: Duplicate slug detected, skipping: $slug');
      }
      return;
    }
    _lastHandledSlug = slug;

    if (kDebugMode) {
      debugPrint(
        'DeepLinkService: Navigating to post preview with slug: $slug',
      );
    }

    // Check if navigation stack is empty (cold start)
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) return;

    final canPop = navigatorState.canPop();

    if (kDebugMode) {
      debugPrint('DeepLinkService: Can pop: $canPop');
    }

    // If navigation stack is empty (cold start), clear stack and set post preview as root
    if (!canPop) {
      if (kDebugMode) {
        debugPrint(
          'DeepLinkService: Cold start detected, setting post preview as root',
        );
      }
      navigatorState.pushNamedAndRemoveUntil(
        AppRoutes.postPreview,
        (route) => false,
        arguments: slug,
      );
    } else {
      // Warm start - add to existing navigation stack
      if (kDebugMode) {
        debugPrint('DeepLinkService: Warm start detected, adding to stack');
      }
      navigatorState.pushNamed(AppRoutes.postPreview, arguments: slug);
    }
  }

  /// Dispose the service and cancel subscriptions
  void dispose() {
    _linkSubscription?.cancel();
    if (kDebugMode) {
      debugPrint('DeepLinkService: Disposed');
    }
  }
}
