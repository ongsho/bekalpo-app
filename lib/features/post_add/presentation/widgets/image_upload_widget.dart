import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Image section of the post form.
///
/// - Server images: rendered DIRECTLY from [uploadedImages] (parent is the
///   single source of truth, no private copy -> no stale UI).
/// - Local previews: only exist while an upload is in flight. They are cleared
///   when [isUploading] goes true -> false (success OR failure).
/// - Drag & drop reorder only works between server images.
class ImageUploadWidget extends StatefulWidget {
  final List<String> uploadedImages;
  final ValueChanged<List<File>> onImagesSelected;
  final ValueChanged<List<String>> onImagesReordered;
  final ValueChanged<int> onImageRemoved;
  final bool isUploading;
  final int maxImages;

  const ImageUploadWidget({
    super.key,
    required this.uploadedImages,
    required this.onImagesSelected,
    required this.onImagesReordered,
    required this.onImageRemoved,
    this.isUploading = false,
    this.maxImages = 10,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  List<String> _localPreviews = [];

  int get _total => widget.uploadedImages.length + _localPreviews.length;
  bool get _canAdd => !widget.isUploading && _total < widget.maxImages;

  @override
  void didUpdateWidget(covariant ImageUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Upload finished (success or failure) -> server list is the truth now.
    if (oldWidget.isUploading && !widget.isUploading) {
      _localPreviews = [];
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickImages() async {
    final remaining = widget.maxImages - _total;
    if (remaining <= 0) {
      _toast('Maximum ${widget.maxImages} images allowed');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;

      if (picked.length > remaining) {
        _toast(
          'Only $remaining more image${remaining > 1 ? 's' : ''} can be added',
        );
      }

      final files = picked.take(remaining).map((x) => File(x.path)).toList();

      setState(() => _localPreviews = files.map((f) => f.path).toList());
      widget.onImagesSelected(files);
    } catch (e) {
      _toast('Error picking images: $e');
    }
  }

  /// Parent does the optimistic update + API call + rollback on failure.
  void _move(int from, int to) {
    if (from == to || widget.isUploading) return;
    final list = List<String>.from(widget.uploadedImages);
    final item = list.removeAt(from);
    list.insert(to, item);
    widget.onImagesReordered(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverCount = widget.uploadedImages.length;
    final itemCount = _total + (_canAdd ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          if (_total == 0)
            _buildEmptyState(theme)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) {
                if (i < serverCount) return _buildServerTile(theme, i);
                if (i < _total) {
                  return _buildLocalTile(
                    theme,
                    _localPreviews[i - serverCount],
                    isCover: i == 0,
                  );
                }
                return _buildAddTile(theme);
              },
            ),
          if (widget.isUploading) ...[
            const SizedBox(height: 12),
            _buildUploadingRow(theme),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(ThemeData theme) {
    final subtitle = _total == 0
        ? 'Add up to ${widget.maxImages} photos'
        : widget.uploadedImages.length > 1
        ? '$_total/${widget.maxImages} • First photo is the cover • Long press & drag to reorder'
        : '$_total/${widget.maxImages} • First photo is the cover';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.image_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- tiles

  Widget _buildServerTile(ThemeData theme, int index) {
    final url = widget.uploadedImages[index];

    return LongPressDraggable<int>(
      key: ValueKey(url),
      data: index,
      maxSimultaneousDrags: widget.isUploading ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 96,
          height: 96,
          child: _tileFrame(theme, child: _networkThumb(theme, url)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _tileFrame(theme, child: _networkThumb(theme, url)),
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != index,
        onAcceptWithDetails: (d) => _move(d.data, index),
        builder: (context, candidate, rejected) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _tileFrame(
                theme,
                highlight: candidate.isNotEmpty,
                child: _networkThumb(theme, url),
              ),
              if (index == 0)
                Positioned(bottom: 6, left: 6, child: _badge('Cover')),
              Positioned(
                top: 4,
                right: 4,
                child: _removeButton(() => widget.onImageRemoved(index)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocalTile(
    ThemeData theme,
    String path, {
    required bool isCover,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _tileFrame(
          theme,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(path), fit: BoxFit.cover),
              const ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCover) Positioned(bottom: 6, left: 6, child: _badge('Cover')),
      ],
    );
  }

  Widget _buildAddTile(ThemeData theme) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 1.5,
          ),
          color: theme.colorScheme.primaryContainer.withOpacity(0.12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.55),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to add photos',
              style: TextStyle(
                color: theme.colorScheme.primary.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingRow(ThemeData theme) {
    final n = _localPreviews.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          n > 0
              ? 'Uploading $n image${n > 1 ? 's' : ''}...'
              : 'Updating images...',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- helpers

  Widget _tileFrame(
    ThemeData theme, {
    required Widget child,
    bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? theme.colorScheme.primary : theme.dividerColor,
          width: highlight ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox.expand(child: child),
      ),
    );
  }

  Widget _networkThumb(ThemeData theme, String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      errorWidget: (context, _, __) => Container(
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: widget.isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 14),
      ),
    );
  }
}
