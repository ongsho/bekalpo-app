import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user.dart';

/// Seller profile card: avatar, name, member-since, and contact actions
/// (reveal phone, message, WhatsApp).
///
/// Phone reveal is purely local UI state, so it's kept inside this widget
/// rather than threaded through the parent screen or a provider.
class PostSellerCard extends StatefulWidget {
  final User user;
  final String postTitle;
  final String? postSlug;

  const PostSellerCard({
    super.key,
    required this.user,
    required this.postTitle,
    this.postSlug,
  });

  @override
  State<PostSellerCard> createState() => _PostSellerCardState();
}

class _PostSellerCardState extends State<PostSellerCard> {
  bool _phoneRevealed = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {},
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brand500,
                  child: Text(
                    (user.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user.name ?? 'Unknown').toUpperCase(),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member since ${_formatMemberSince(user.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 14),

          if (user.contacts != null && user.contacts!.isNotEmpty ||
              user.phone != null)
            _SellerActionRow(
              icon: Icons.phone,
              iconBg: AppColors.brand500.withOpacity(0.1),
              iconColor: AppColors.brand500,
              title: _phoneRevealed
                  ? (user.contacts?.first.value ?? user.phone ?? 'N/A')
                  : '01xxxxxxxxx',
              subtitle: _phoneRevealed
                  ? 'Tap again to call'
                  : 'Tap to reveal number',
              onTap: () =>
                  _handlePhoneTap(user.contacts?.first.value ?? user.phone),
            ),
          const SizedBox(height: 10),

          // _SellerActionRow(
          //   icon: Icons.chat_bubble_outline,
          //   iconBg: AppColors.warning500.withOpacity(0.12),
          //   iconColor: AppColors.warning500,
          //   title: 'Send Message',
          //   subtitle: 'Chat with this seller',
          //   onTap: () {},
          // ),
          // const SizedBox(height: 10),
          _SellerActionRow(
            icon: Icons.chat,
            iconBg: AppColors.success500.withOpacity(0.1),
            iconColor: AppColors.success500,
            title: 'WhatsApp',
            subtitle: 'Connect on WhatsApp',
            onTap: () => _handleWhatsAppTap(
              user.contacts?.first.value ?? user.phone,
              sellerName: user.name,
            ),
          ),
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
    final link = widget.postSlug != null
        ? 'https://bekalpo.com/ads/${widget.postSlug}'
        : null;

    final buffer = StringBuffer()
      ..writeln('হ্যালো $name,')
      ..writeln()
      ..writeln('আমি আপনার পোস্টটি দেখেছি এবং এটি সম্পর্কে আরও জানতে চাই।')
      ..writeln()
      ..writeln('পোস্ট: ${widget.postTitle}');

    if (link != null) {
      buffer.writeln('লিংক: $link');
    }

    buffer
      ..writeln()
      ..writeln('আপনি কি দয়া করে বিস্তারিত জানাতে পারবেন?')
      ..writeln()
      ..write('ধন্যবাদ');

    return buffer.toString();
  }

  /// Normalizes a BD local number (e.g. "01317774455" or "01317-774455")
  /// to WhatsApp format (e.g. "8801317774455")
  String _toWhatsAppFormat(String phoneNumber) {
    var digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Already in international format
    if (digits.startsWith('88') && digits.length >= 13) {
      return digits;
    }

    // Remove leading 0 (Bangladesh local format)
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Ensure BD country code
    return '880$digits';
  }
}

class _SellerActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SellerActionRow({
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
              : AppColors.surfaceBg,
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
