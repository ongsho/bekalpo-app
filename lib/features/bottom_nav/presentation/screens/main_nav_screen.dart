import 'package:bekalpo/features/bottom_nav/presentation/providers/nav_provider.dart';
import 'package:bekalpo/features/bottom_nav/presentation/widgets/bottom_nav_bar.dart';
import 'package:bekalpo/features/home/presentation/screens/home_screen.dart';
import 'package:bekalpo/features/search/presentation/screens/search_screen.dart';
import 'package:bekalpo/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: const BottomNavBar(),
    );
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
