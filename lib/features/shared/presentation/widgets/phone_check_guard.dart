import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../auth/presentation/screens/phone_add_screen.dart';

class PhoneCheckGuard extends ConsumerStatefulWidget {
  final Widget child;
  final String? redirectRoute;

  const PhoneCheckGuard({super.key, required this.child, this.redirectRoute});

  @override
  ConsumerState<PhoneCheckGuard> createState() => _PhoneCheckState();
}

class _PhoneCheckState extends ConsumerState<PhoneCheckGuard> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loading while checking auth state
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If not logged in, show a simple message and let parent guards handle navigation
    if (!authState.isLoggedIn) {
      return widget.child; // Pass through to let AuthGuard handle it
    }

    // Check if user has verified phone or contacts
    final hasVerifiedPhone = authState.userPhone != null;
    final hasContacts =
        authState.userContacts != null && authState.userContacts!.isNotEmpty;

    if (!hasVerifiedPhone && !hasContacts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const PhoneAddScreen()));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If logged in and has phone/contacts, show the child widget
    return widget.child;
  }
}
