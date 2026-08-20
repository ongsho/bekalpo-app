import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/screens/auth_entry_screen.dart';

class ProfileMenuItem {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;
  final String? url;
  final bool requiresAuth;

  const ProfileMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.onTap,
    this.url,
    this.requiresAuth = false,
  });
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
        enableDomStorage: true,
      ),
    );
  }
}

class _AuthMenuSection extends ConsumerWidget {
  final String title;
  final List<ProfileMenuItem> items;
  final bool requiresAuth;

  const _AuthMenuSection({
    required this.title,
    required this.items,
    this.requiresAuth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (requiresAuth && !authState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        _MenuSection(items: items),
      ],
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading indicator while checking auth state
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.brand500,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(title: "Guest"),
                    const SizedBox(height: 20),
                    _ProfileHeader(
                      isLoggedIn: false,
                      userName: null,
                      userEmail: null,
                      userPhone: null,
                      avatar: null,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthMenuSection(
                            title: "Account",
                            requiresAuth: true,
                            items: [
                              ProfileMenuItem(
                                icon: Icons.account_circle_outlined,
                                label: "My Account",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                              ProfileMenuItem(
                                icon: Icons.post_add,
                                label: "My Post",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
                          _AuthMenuSection(
                            title: "Settings",
                            requiresAuth: true,
                            items: [
                              ProfileMenuItem(
                                icon: Icons.location_on_outlined,
                                label: "Address",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                              ProfileMenuItem(
                                icon: Icons.security_outlined,
                                label: "Security",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          _AuthMenuSection(
                            title: "Support & Help",
                            items: [
                              ProfileMenuItem(
                                icon: Icons.contact_mail_outlined,
                                label: "Contact Us",
                                url: 'https://bekalpo.com/contact',
                              ),
                              ProfileMenuItem(
                                icon: Icons.info_outline,
                                label: "About Us",
                                url: 'https://bekalpo.com/about',
                              ),
                              ProfileMenuItem(
                                icon: Icons.security,
                                label: "Safety Tips",
                                url: 'https://bekalpo.com/safety-tips',
                              ),
                              ProfileMenuItem(
                                icon: Icons.groups_outlined,
                                label: "Community Guidelines",
                                url: 'https://bekalpo.com/community-guidelines',
                              ),
                              ProfileMenuItem(
                                icon: Icons.help_outline,
                                label: "FAQ's",
                                url: 'https://bekalpo.com/faq',
                              ),
                              ProfileMenuItem(
                                icon: Icons.article_outlined,
                                label: "Our Blog",
                                url: 'https://bekalpo.com/blog',
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
                          _AuthMenuSection(
                            title: "Legal Info",
                            items: [
                              ProfileMenuItem(
                                icon: Icons.privacy_tip_outlined,
                                label: "Privacy Policy",
                                url: 'https://bekalpo.com/privacy-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.description_outlined,
                                label: "Terms of Services",
                                url: 'https://bekalpo.com/tos',
                              ),
                              ProfileMenuItem(
                                icon: Icons.currency_exchange,
                                label: "Refund Policy",
                                url: 'https://bekalpo.com/refund-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.cookie_outlined,
                                label: "Cookie Policy",
                                url: 'https://bekalpo.com/cookie-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.warning_amber_outlined,
                                label: "Disclaimer",
                                url: 'https://bekalpo.com/disclaimer',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              "App version 003",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.brand500,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(title: "My Profile"),
                    const SizedBox(height: 20),
                    _ProfileHeader(
                      isLoggedIn: authState.isLoggedIn,
                      userName: authState.userName,
                      userEmail: authState.userEmail,
                      userPhone: authState.userPhone,
                      avatar: authState.avatar,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthMenuSection(
                            title: "Account",
                            requiresAuth: true,
                            items: [
                              ProfileMenuItem(
                                icon: Icons.account_circle_outlined,
                                label: "My Account",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                              ProfileMenuItem(
                                icon: Icons.post_add,
                                label: "My Post",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
                          _AuthMenuSection(
                            title: "Settings",
                            requiresAuth: true,
                            items: [
                              ProfileMenuItem(
                                icon: Icons.location_on_outlined,
                                label: "Address",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                              ProfileMenuItem(
                                icon: Icons.security_outlined,
                                label: "Security",
                                requiresAuth: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
                          _AuthMenuSection(
                            title: "Support & Help",
                            items: [
                              ProfileMenuItem(
                                icon: Icons.contact_mail_outlined,
                                label: "Contact Us",
                                url: 'https://bekalpo.com/contact',
                              ),
                              ProfileMenuItem(
                                icon: Icons.info_outline,
                                label: "About Us",
                                url: 'https://bekalpo.com/about',
                              ),
                              ProfileMenuItem(
                                icon: Icons.security,
                                label: "Safety Tips",
                                url: 'https://bekalpo.com/safety-tips',
                              ),
                              ProfileMenuItem(
                                icon: Icons.groups_outlined,
                                label: "Community Guidelines",
                                url: 'https://bekalpo.com/community-guidelines',
                              ),
                              ProfileMenuItem(
                                icon: Icons.help_outline,
                                label: "FAQ's",
                                url: 'https://bekalpo.com/faq',
                              ),
                              ProfileMenuItem(
                                icon: Icons.article_outlined,
                                label: "Our Blog",
                                url: 'https://bekalpo.com/blog',
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
                          _AuthMenuSection(
                            title: "Legal Info",
                            items: [
                              ProfileMenuItem(
                                icon: Icons.privacy_tip_outlined,
                                label: "Privacy Policy",
                                url: 'https://bekalpo.com/privacy-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.description_outlined,
                                label: "Terms of Services",
                                url: 'https://bekalpo.com/tos',
                              ),
                              ProfileMenuItem(
                                icon: Icons.currency_exchange,
                                label: "Refund Policy",
                                url: 'https://bekalpo.com/refund-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.cookie_outlined,
                                label: "Cookie Policy",
                                url: 'https://bekalpo.com/cookie-policy',
                              ),
                              ProfileMenuItem(
                                icon: Icons.warning_amber_outlined,
                                label: "Disclaimer",
                                url: 'https://bekalpo.com/disclaimer',
                              ),
                            ],
                          ),
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            height: 32,
                          ),
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
                          Center(
                            child: Text(
                              "App version 003",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              "Log Out",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              "Are you sure you want to log out?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update auth state (will clear token automatically)
                      await ref.read(authProvider.notifier).logout();

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Log Out",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.settings_outlined, size: 20, color: Colors.white),
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
  final String? userPhone;
  final String? avatar;

  const _ProfileHeader({
    required this.isLoggedIn,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: isLoggedIn && avatar != null
              ? CachedNetworkImageProvider(avatar!)
              : null,
          child: (!isLoggedIn || avatar == null)
              ? Icon(
                  Icons.person_outline,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                )
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              if (isLoggedIn) ...[
                Text(
                  userEmail ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  userPhone != null ? _formatPhoneForDisplay(userPhone!) : '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ] else
                Text(
                  "Browse as guest",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
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

String _formatPhoneForDisplay(String phone) {
  // Ensure phone starts with 0 for consistency
  String formattedPhone = phone;
  if (formattedPhone.startsWith('+880')) {
    formattedPhone = formattedPhone.substring(4);
  } else if (formattedPhone.startsWith('880')) {
    formattedPhone = formattedPhone.substring(3);
  }
  if (!formattedPhone.startsWith('0')) {
    formattedPhone = '0$formattedPhone';
  }
  // Display as +88001XXXXXXXXX
  if (formattedPhone.length > 1) {
    return '+880${formattedPhone.substring(1)}';
  }
  return formattedPhone;
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
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brand500,
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<ProfileMenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((item) {
          return InkWell(
            onTap:
                item.onTap ??
                () {
                  if (item.url != null) {
                    _launchUrl(item.url!);
                  }
                },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: item.destructive
                        ? const Color(0xFFDC2626)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: item.destructive
                            ? const Color(0xFFDC2626)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
