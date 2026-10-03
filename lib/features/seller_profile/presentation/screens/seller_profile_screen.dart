import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/post_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mappers/post_mapper.dart';
import '../../../../core/models/post.dart';
import '../../../../core/models/user.dart';
import '../../../home/presentation/widgets/ad_card.dart';
import '../../../../app/router/app_routes.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  final User user;

  const SellerProfileScreen({super.key, required this.user});

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final userId = widget.user.id;
      if (userId != null) {
        ref.read(sellerPostsProvider(userId).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.id;
    final postsCount = widget.user.postsCount ?? 0;

    if (userId != null) {
      final sellerPostsAsync = ref.watch(sellerPostsProvider(userId));

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Seller Profile'),
          backgroundColor: AppColors.brand500,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: sellerPostsAsync.when(
          loading: () => SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(user: widget.user, postsCount: postsCount),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          error: (_, _) => SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(user: widget.user, postsCount: postsCount),
                const SizedBox(height: 16),
                const Center(child: Text('Failed to load posts')),
              ],
            ),
          ),
          data: (state) {
            final posts = state.posts;
            final isLoadingMore = state.isLoadingMore;

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  ref.read(sellerPostsProvider(userId).notifier).loadMore();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _ProfileHeader(user: widget.user, postsCount: postsCount),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller\'s Posts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PostsGrid(posts: posts),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: AppColors.brand500,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(user: widget.user, postsCount: postsCount),
            const SizedBox(height: 16),
            const Center(child: Text('Unable to load posts')),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final User user;
  final int postsCount;

  const _ProfileHeader({required this.user, required this.postsCount});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _phoneRevealed = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final avatar = user.avatar;
    final name = user.name ?? 'Unknown';
    final username = user.username;
    final phone = user.phone;
    final contacts = user.contacts;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile info row
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.brand500,
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar)
                    : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        (name)[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (username != null)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatMemberSince(user.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 14,
                          color: AppColors.brand500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.postsCount} Posts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contact action row
          if (contacts != null && contacts.isNotEmpty || phone != null) ...[
            _ContactActionRow(
              icon: Icons.phone,
              iconBg: AppColors.brand500.withOpacity(0.1),
              iconColor: AppColors.brand500,
              title: _phoneRevealed
                  ? (contacts?.first.value ?? phone ?? 'N/A')
                  : '01xxxxxxxxx',
              subtitle: _phoneRevealed
                  ? 'Tap again to call'
                  : 'Tap to reveal number',
              onTap: () => _handlePhoneTap(contacts?.first.value ?? phone),
            ),
            const SizedBox(height: 10),
            _ContactActionRow(
              icon: Icons.chat,
              iconBg: Colors.green.withOpacity(0.1),
              iconColor: Colors.green,
              title: 'WhatsApp',
              subtitle: 'Connect on WhatsApp',
              onTap: () => _handleWhatsAppTap(
                contacts?.first.value ?? phone,
                sellerName: name,
              ),
            ),
            const SizedBox(height: 10),
            _ContactActionRow(
              icon: Icons.message,
              iconBg: Colors.orange.withOpacity(0.1),
              iconColor: Colors.orange,
              title: 'Send Message',
              subtitle: 'Chat with seller',
              onTap: () {
                // TODO: Implement messaging
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatMemberSince(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _handlePhoneTap(String? phoneNumber) async {
    if (!_phoneRevealed) {
      setState(() => _phoneRevealed = true);
      return;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final sanitized = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleWhatsAppTap(
    String? phoneNumber, {
    String? sellerName,
  }) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }

    final waNumber = _toWhatsAppFormat(phoneNumber);
    final message = _buildWhatsAppMessage(sellerName);

    final uri = Uri.https('api.whatsapp.com', '/send/', {
      'phone': waNumber,
      'text': message,
      'type': 'phone_number',
      'app_absent': '0',
    });

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  String _buildWhatsAppMessage(String? sellerName) {
    final name = (sellerName == null || sellerName.isEmpty)
        ? 'সেলার'
        : sellerName;

    final buffer = StringBuffer()
      ..writeln('হ্যালো $name,')
      ..writeln()
      ..writeln(
        'আমি আপনার প্রোফাইল দেখেছি এবং আপনার পোস্টগুলো সম্পর্কে আরও জানতে চাই।',
      )
      ..writeln()
      ..writeln('আপনি কি দয়া করে বিস্তারিত জানাতে পারবেন?')
      ..writeln()
      ..write('ধন্যবাদ');

    return buffer.toString();
  }

  /// Normalizes a BD local number (e.g. "01317774455" or "01317-774455")
  /// to WhatsApp format (e.g. "8801317774455")
  String _toWhatsAppFormat(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.startsWith('01')) {
      return '88$cleaned';
    } else if (cleaned.startsWith('8801')) {
      return cleaned;
    }
    return cleaned;
  }
}

class _ContactActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D27)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsGrid extends StatelessWidget {
  final List<Post> posts;

  const _PostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No posts available'),
        ),
      );
    }

    final ads = posts.map((post) => post.toAdModel()).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        return AdCard(
          ad: ads[index],
          postId: posts[index].id,
          onTap: () {
            if (ads[index].slug?.isNotEmpty == true) {
              Navigator.pushNamed(
                context,
                AppRoutes.postPreview,
                arguments: ads[index].slug,
              );
            }
          },
        );
      },
    );
  }
}
