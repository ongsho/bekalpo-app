import 'package:flutter/material.dart';

/// Splash screen — navigates after a short delay.
/// Fix: always check `mounted` before using BuildContext after an async gap.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    // ✅ Guard with mounted check before using context across async gap
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A66C1),
      body: Center(
        child: Image.network(
          'https://bekalpo.com/images/logo/logo.png',
          width: 160,
          errorBuilder: (_, e, __) => const Text(
            'Bekalpo',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}