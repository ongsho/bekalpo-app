import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<String> uploadedImages;
  final Function(List<File>) onImagesSelected;
  final Function(List<String>) onImagesReordered;
  final Function(int) onImageRemoved;
  final bool isUploading;

  const ImageUploadWidget({
    super.key,
    required this.uploadedImages,
    required this.onImagesSelected,
    required this.onImagesReordered,
    required this.onImageRemoved,
    this.isUploading = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _images = [];
  List<String> _localPreviewImages = []; // Local image paths for preview

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.uploadedImages);
    _localPreviewImages = [];
  }

  @override
  void didUpdateWidget(ImageUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ImageUploadWidget: didUpdateWidget called');
    print('ImageUploadWidget: Old images: ${oldWidget.uploadedImages.length}');
    print('ImageUploadWidget: New images: ${widget.uploadedImages.length}');
    print('ImageUploadWidget: Local previews: ${_localPreviewImages.length}');

    // Check if the uploaded images list has changed
    final oldLength = oldWidget.uploadedImages.length;
    final newLength = widget.uploadedImages.length;
    final imagesChanged =
        oldLength != newLength ||
        !_listsEqual(oldWidget.uploadedImages, widget.uploadedImages);

    if (imagesChanged) {
      print('ImageUploadWidget: Images changed, updating state');
      setState(() {
        _images = List.from(widget.uploadedImages);
        // Clear local previews when server images are updated
        _localPreviewImages.clear();
      });
      print('ImageUploadWidget: Updated _images to: ${_images.length}');
      print(
        'ImageUploadWidget: Local previews after update: ${_localPreviewImages.length}',
      );
    }
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> _pickImages() async {
    try {
      print('ImageUploadWidget: Starting image picker');

      // Try multi image picker first
      final List<XFile> selectedImages = await _imagePicker.pickMultiImage();

      print(
        'ImageUploadWidget: Multi image picker returned ${selectedImages.length} images',
      );

      if (selectedImages.isNotEmpty) {
        // Convert XFile to File
        final List<File> imageFiles = selectedImages
            .map((xFile) => File(xFile.path))
            .toList();

        print(
          'ImageUploadWidget: Calling onImagesSelected with ${imageFiles.length} files',
        );

        // Show immediate preview
        setState(() {
          _localPreviewImages.addAll(imageFiles.map((file) => file.path));
        });

        // Notify parent to upload images in background
        widget.onImagesSelected(imageFiles);
      } else {
        // If multi picker returned nothing, try single picker
        print(
          'ImageUploadWidget: No images from multi picker, trying single picker',
        );
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );

        print(
          'ImageUploadWidget: Single image picker returned: ${image != null}',
        );

        if (image != null) {
          // Convert XFile to File
          final File imageFile = File(image.path);

          print(
            'ImageUploadWidget: Calling onImagesSelected with single file: ${imageFile.path}',
          );

          // Show immediate preview
          setState(() {
            _localPreviewImages.add(imageFile.path);
          });

          // Notify parent to upload images in background
          widget.onImagesSelected([imageFile]);
        }
      }
    } catch (e) {
      print('ImageUploadWidget: Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      // Remove from appropriate list based on index
      if (index < _localPreviewImages.length) {
        // It's a local preview image
        _localPreviewImages.removeAt(index);
      } else {
        // It's a server image
        final serverIndex = index - _localPreviewImages.length;
        _images.removeAt(serverIndex);
      }
    });

    // Notify parent about removal (only for server images)
    if (index >= _localPreviewImages.length) {
      final serverIndex = index - _localPreviewImages.length;
      widget.onImageRemoved(serverIndex);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    // Only allow reordering of server images, not local previews
    if (oldIndex >= _localPreviewImages.length &&
        newIndex >= _localPreviewImages.length) {
      if (oldIndex != newIndex) {
        final serverOldIndex = oldIndex - _localPreviewImages.length;
        final serverNewIndex = newIndex - _localPreviewImages.length;

        setState(() {
          final String item = _images.removeAt(serverOldIndex);
          _images.insert(serverNewIndex, item);
        });
        widget.onImagesReordered(_images);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Images',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_images.isEmpty && _localPreviewImages.isEmpty)
            _buildEmptyState(theme)
          else
            _buildImageGrid(theme),

          const SizedBox(height: 12),

          if (!widget.isUploading)
            _buildAddButton(theme)
          else
            _buildUploadingIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add images',
              style: TextStyle(
                color: theme.colorScheme.primary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(ThemeData theme) {
    // Combine local previews and uploaded images
    final allImages = [..._localPreviewImages, ..._images];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: allImages.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final imageUrl = allImages[index];
        final isLocalPreview = index < _localPreviewImages.length;

        // Disable drag for local previews (they're being uploaded)
        final canDrag = !isLocalPreview;

        return LongPressDraggable(
          key: ValueKey('image_$index'),
          data: index,
          onDragStarted: () {
            // Could add haptic feedback here
          },
          feedback: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isLocalPreview
                  ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.errorContainer,
                        child: Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
            ),
          ),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) =>
                canDrag && details.data != index,
            onAcceptWithDetails: (details) {
              if (canDrag) {
                _onReorder(details.data, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: candidateData.isNotEmpty && canDrag
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: candidateData.isNotEmpty && canDrag ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isLocalPreview
                          ? Stack(
                              children: [
                                Image.file(
                                  File(imageUrl),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                // Upload indicator overlay - only show if currently uploading
                                if (widget.isUploading)
                                  Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Uploading...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surface,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.errorContainer,
                                child: Icon(
                                  Icons.broken_image,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Add More Images',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Row(
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
            'Uploading images...',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
