import 'package:bekalpo/features/bottom_nav/presentation/providers/nav_provider.dart';
import 'package:bekalpo/features/bottom_nav/presentation/widgets/bottom_nav_bar.dart';
import 'package:bekalpo/features/home/presentation/screens/home_screen.dart';
import 'package:bekalpo/features/search/presentation/screens/search_screen.dart';
import 'package:bekalpo/features/profile/presentation/screens/profile_screen.dart';
import 'package:bekalpo/features/shared/presentation/widgets/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const _PlaceholderScreen(title: 'Post Ad'),
    const _PlaceholderScreen(title: 'Messages'),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Only handle back button for main navigation, not for sub-screens
          // Check if we're on a main tab (not in a sub-screen like search results)
          if (Navigator.of(context).canPop()) {
            // Let the normal navigation handle it (for sub-screens)
            return;
          }

          // Handle main navigation back button
          if (currentIndex == 0) {
            // On home tab - show exit confirmation
            _showExitConfirmation(context);
          } else {
            // On other tabs - go to home tab
            ref.read(navIndexProvider.notifier).state = 0;
          }
        }
      },
      child: Scaffold(
        body: ConnectivityWrapper(
          child: IndexedStack(index: currentIndex, children: _screens),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldExit == true && context.mounted) {
      // Handle app exit
      SystemNavigator.pop();
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
