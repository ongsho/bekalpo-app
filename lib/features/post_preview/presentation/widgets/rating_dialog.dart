import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/post_provider.dart';

class RatingDialog extends ConsumerStatefulWidget {
  final int postId;
  final int? initialRating;
  final String? initialComment;

  const RatingDialog({
    super.key,
    required this.postId,
    this.initialRating,
    this.initialComment,
  });

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating ?? 0;
    _commentController.text = widget.initialComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(postRepositoryProvider)
          .submitRating(
            postId: widget.postId,
            rating: _selectedRating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you rate this post?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildStarRating(),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitRating,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          iconSize: 40,
          onPressed: () {
            setState(() => _selectedRating = starValue);
          },
          icon: Icon(
            _selectedRating >= starValue ? Icons.star : Icons.star_border,
            color: _selectedRating >= starValue
                ? AppColors.warning500
                : Colors.grey,
          ),
        );
      }),
    );
  }
}
