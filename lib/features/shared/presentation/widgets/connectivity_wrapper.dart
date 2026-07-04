import 'dart:async';
import 'package:bekalpo/core/network/internet_service.dart';
import 'package:flutter/material.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bannerController;
  late final Animation<Offset> _slideAnim;

  StreamSubscription? _sub;
  bool? _lastStatus;
  bool _bannerVisible = false;
  bool _isOnline = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _bannerController,
            curve: Curves.easeOutCubic,
          ),
        );

    InternetService.hasInternet().then((status) {
      if (!status && mounted) {
        _lastStatus = false;
        _showBanner(false);
      }
    });

    _sub = InternetService().stream.listen((status) {
      if (_lastStatus == status) return;
      _lastStatus = status;
      _showBanner(status);
    });
  }

  void _showBanner(bool isOnline) {
    _hideTimer?.cancel();
    setState(() {
      _isOnline = isOnline;
      _bannerVisible = true;
    });
    _bannerController.forward(from: 0);
    if (isOnline) {
      _hideTimer = Timer(const Duration(milliseconds: 2500), _hideBanner);
    }
  }

  Future<void> _hideBanner() async {
    await _bannerController.reverse();
    if (mounted) setState(() => _bannerVisible = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _bannerController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_bannerVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _ConnectivityBanner(isOnline: _isOnline),
            ),
          ),
      ],
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  const _ConnectivityBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: bottomPadding + 10,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        boxShadow: [
          BoxShadow(
            color:
                (isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626))
                    .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Back online' : 'No internet connection',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
