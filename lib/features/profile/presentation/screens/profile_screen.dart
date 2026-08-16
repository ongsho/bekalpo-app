import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../auth/presentation/screens/auth_entry_screen.dart';

class AppColors {
  static const bgOuter = Color(0xFFEAF2EC);
  static const cardBg = Colors.white;
  static const green = Color(0xFF1FA855);
  static const red = Color(0xFFE74C3C);
  static const textDark = Color(0xFF1A1A1A);
  static const textGray = Color(0xFF8A8A8A);
  static const iconGray = Color(0xFF555555);
  static const dividerColor = Color(0xFFF0F0F0);
  static const chevronGray = Color(0xFFBFBFBF);
}

class ProfileMenuItem {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.onTap,
  });
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading indicator while checking auth state
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.cardBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.isLoggedIn) {
      return const _LoggedInProfile();
    } else {
      return const _GuestProfile();
    }
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(title: "Guest"),
                  const SizedBox(height: 20),
                  _ProfileHeader(
                    isLoggedIn: false,
                    userName: null,
                    userEmail: null,
                    avatar: null,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.account_circle_outlined,
                          label: "My Account",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.post_add,
                          label: "My Post",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.location_on_outlined,
                          label: "Address",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.security_outlined,
                          label: "Security",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    const _SectionTitle(title: "Support & Help"),
                    const SizedBox(height: 8),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.contact_mail_outlined,
                          label: "Contact Us",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.info_outline,
                          label: "About Us",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.security,
                          label: "Safety Tips",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.groups_outlined,
                          label: "Community Guidelines",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.help_outline,
                          label: "FAQ's",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.article_outlined,
                          label: "Our Blog",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    const _SectionTitle(title: "Legal Info"),
                    const SizedBox(height: 8),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: "Privacy Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.description_outlined,
                          label: "Terms of Services",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.currency_exchange,
                          label: "Refund Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.cookie_outlined,
                          label: "Cookie Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.warning_amber_outlined,
                          label: "Disclaimer",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        "App version 003",
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedInProfile extends ConsumerWidget {
  const _LoggedInProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(title: "My Profile"),
                  const SizedBox(height: 20),
                  _ProfileHeader(
                    isLoggedIn: authState.isLoggedIn,
                    userName: authState.userName,
                    userEmail: authState.userEmail,
                    avatar: authState.avatar,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.account_circle_outlined,
                          label: "My Account",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.post_add,
                          label: "My Post",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.location_on_outlined,
                          label: "Address",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.security_outlined,
                          label: "Security",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    const _SectionTitle(title: "Support & Help"),
                    const SizedBox(height: 8),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.contact_mail_outlined,
                          label: "Contact Us",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.info_outline,
                          label: "About Us",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.security,
                          label: "Safety Tips",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.groups_outlined,
                          label: "Community Guidelines",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.help_outline,
                          label: "FAQ's",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.article_outlined,
                          label: "Our Blog",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    const _SectionTitle(title: "Legal Info"),
                    const SizedBox(height: 8),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: "Privacy Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.description_outlined,
                          label: "Terms of Services",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.currency_exchange,
                          label: "Refund Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.cookie_outlined,
                          label: "Cookie Policy",
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.warning_amber_outlined,
                          label: "Disclaimer",
                          onTap: () {},
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerColor, height: 32),
                    _MenuSection(
                      items: [
                        ProfileMenuItem(
                          icon: Icons.logout,
                          label: "Log Out",
                          destructive: true,
                          onTap: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        "App version 003",
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Update auth state (will clear token automatically)
              await ref.read(authProvider.notifier).logout();

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "Log Out",
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textDark,
            ),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;
  final String? avatar;

  const _ProfileHeader({
    required this.isLoggedIn,
    this.userName,
    this.userEmail,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: isLoggedIn && avatar != null
              ? CachedNetworkImageProvider(avatar!)
              : null,
          child: (!isLoggedIn || avatar == null)
              ? Icon(Icons.person_outline, size: 40, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLoggedIn ? (userName ?? "User") : "Guest User",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLoggedIn ? (userEmail ?? "") : "Browse as guest",
                style: const TextStyle(fontSize: 13, color: AppColors.textGray),
              ),
              const SizedBox(height: 10),
              if (!isLoggedIn)
                _LoginButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthEntryScreen(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          "Login",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textGray,
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<ProfileMenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(children: items.map((item) => _MenuRow(item: item)).toList());
  }
}

class _MenuRow extends StatelessWidget {
  final ProfileMenuItem item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.destructive ? AppColors.red : AppColors.textDark;
    final iconColor = item.destructive ? AppColors.red : AppColors.iconGray;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.chevronGray,
            ),
          ],
        ),
      ),
    );
  }
}
