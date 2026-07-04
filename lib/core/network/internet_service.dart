// lib/core/network/internet_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  factory InternetService() => _instance;
  InternetService._internal();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get stream => _controller.stream;

  StreamSubscription? _subscription;
  bool? _lastStatus;

  void initialize() {
    _emitStatus();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _emitStatus(connectivityResults: results);
    });
  }

  Future<void> _emitStatus({
    List<ConnectivityResult>? connectivityResults,
  }) async {
    final hasConnection = connectivityResults != null
        ? await _evaluate(connectivityResults)
        : await hasInternet();

    if (_lastStatus != hasConnection) {
      _lastStatus = hasConnection;
      _controller.add(hasConnection);
    }
  }

  static Future<bool> _evaluate(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    // connectivity_plus says we're online — do a soft DNS check against
    // our own backend. Failure here does NOT hard-fail (avoids false negatives
    // on networks that block third-party DNS — e.g. some BD ISPs).
    return await _dnsCheck();
  }

  static Future<bool> _dnsCheck() async {
    try {
      final result = await InternetAddress.lookup(
        'admin.bekalpo.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      // DNS failed but connectivity_plus said we're online — treat as online.
      // Better a false positive than a false negative (no blank screens).
      return true;
    }
  }

  static Future<bool> hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    return await _dnsCheck();
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
