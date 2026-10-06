import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Inline post gallery: lightweight PageView + thumbnail strip + dots.
/// Tapping an image (or the fullscreen button) opens [PostGalleryViewer],
/// which has the native-gallery feel (pinch zoom, double-tap zoom, smooth
/// swipe between images).
///
/// If [onFullscreenTap] is given it is used instead of the built-in viewer.
class PostGallery extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onFullscreenTap;

  const PostGallery({super.key, required this.images, this.onFullscreenTap});

  @override
  State<PostGallery> createState() => _PostGalleryState();
}

class _PostGalleryState extends State<PostGallery> {
  static const double _thumbSize = 56;
  static const double _thumbGap = 8;

  final PageController _controller = PageController();
  final ScrollController _thumbController = ScrollController();
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  @override
  void dispose() {
    _controller.dispose();
    _thumbController.dispose();
    _index.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    _index.value = i;
    _scrollThumbTo(i);
    // Warm up the next image so the next swipe is instant.
    final images = widget.images;
    if (i + 1 < images.length) {
      precacheImage(CachedNetworkImageProvider(images[i + 1]), context);
    }
  }

  void _scrollThumbTo(int i) {
    if (!_thumbController.hasClients) return;
    final viewport = _thumbController.position.viewportDimension;
    final target = i * (_thumbSize + _thumbGap) - (viewport - _thumbSize) / 2;
    _thumbController.animateTo(
      target.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openViewer() async {
    if (widget.onFullscreenTap != null) {
      widget.onFullscreenTap!();
      return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) =>
            PostGalleryViewer(images: widget.images, indexListenable: _index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // Sync inline carousel with whatever image the user ended on.
    if (mounted && _controller.hasClients) {
      _controller.jumpToPage(_index.value);
      _scrollThumbTo(_index.value);
    }
  }

  static String _heroTag(String url) => 'post_gallery_$url';

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark
        ? const Color(0xFF2A2D3A)
        : Colors.grey.shade100;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 320,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 48,
            color: onSurface.withOpacity(0.4),
          ),
        ),
      );
    }

    // Decode at screen resolution, not original size -> big memory/jank win.
    final mq = MediaQuery.of(context);
    final cacheWidth = (mq.size.width * mq.devicePixelRatio).round();

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                width: double.infinity,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: _openViewer,
                      child: Hero(
                        tag: _heroTag(images[index]),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: cacheWidth,
                          fadeInDuration: const Duration(milliseconds: 150),
                          placeholder: (_, __) => Container(
                            color: placeholderColor,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: placeholderColor,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Counter — only this small widget rebuilds on page change.
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _index,
                  builder: (_, i, __) => Text(
                    '${i + 1} / ${images.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 10,
              top: 10,
              child: InkWell(
                onTap: _openViewer,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (images.length > 1)
          Column(
            children: [
              SizedBox(
                height: _thumbSize,
                child: ListView.separated(
                  controller: _thumbController,
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _index,
                        builder: (context, current, child) {
                          return Container(
                            width: _thumbSize,
                            height: _thumbSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: current == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: child,
                          );
                        },
                        // Thumbnail image is built once, not on every swipe.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            fadeInDuration: const Duration(milliseconds: 100),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? const Color(0xFF2A2D3A)
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: _index,
                builder: (context, current, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: current == i ? 20 : 6,
                      decoration: BoxDecoration(
                        color: current == i
                            ? Theme.of(context).primaryColor
                            : onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Fullscreen viewer: pinch zoom, double-tap zoom, pan while zoomed, and
/// smooth page swipe once the image is at its edge (handled by photo_view).
class PostGalleryViewer extends StatefulWidget {
  final List<String> images;
  final ValueNotifier<int> indexListenable;

  const PostGalleryViewer({
    super.key,
    required this.images,
    required this.indexListenable,
  });

  @override
  State<PostGalleryViewer> createState() => _PostGalleryViewerState();
}

class _PostGalleryViewerState extends State<PostGalleryViewer> {
  /// Double-tap zoom level relative to the "fit" size (3.0 = 3x).
  static const double _doubleTapZoom = 3.0;

  static const double _thumbSize = 60;
  static const double _thumbGap = 8;
  static const double _thumbPadding = 12;

  final ScrollController _thumbController = ScrollController();

  late final PageController _controller = PageController(
    initialPage: widget.indexListenable.value,
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollThumbTo(widget.indexListenable.value, animate: false);
    });
  }

  void _scrollThumbTo(int i, {bool animate = true}) {
    if (!_thumbController.hasClients) return;
    final viewport = _thumbController.position.viewportDimension;
    final target =
        _thumbPadding +
        i * (_thumbSize + _thumbGap) -
        (viewport - _thumbSize) / 2;
    final offset = target.clamp(0.0, _thumbController.position.maxScrollExtent);
    if (animate) {
      _thumbController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _thumbController.jumpTo(offset);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _thumbController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: images.length,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              widget.indexListenable.value = i;
              _scrollThumbTo(i);
              if (i + 1 < images.length) {
                precacheImage(
                  CachedNetworkImageProvider(images[i + 1]),
                  context,
                );
              }
            },
            builder: (context, index) {
              final z = _doubleTapZoom;
              return PhotoViewGalleryPageOptions.customChild(
                heroAttributes: PhotoViewHeroAttributes(
                  tag: _PostGalleryState._heroTag(images[index]),
                ),
                // Virtual child size = screen * zoom. "originalSize" is
                // scale 1.0 of this box, so double-tap lands exactly on
                // _doubleTapZoom x the fit size, whatever the image's real
                // pixel size is.
                childSize: Size(screen.width * z, screen.height * z),
                minScale: PhotoViewComputedScale.contained,
                // Pinch can go 1.5x beyond the double-tap level.
                maxScale: PhotoViewComputedScale.contained * (z * 1.5),
                // Double-tap: fit <-> zoomed, nothing in between.
                scaleStateCycle: (actual) =>
                    actual == PhotoViewScaleState.initial
                    ? PhotoViewScaleState.originalSize
                    : PhotoViewScaleState.initial,
                // The child is laid out at childSize (z x screen) and then
                // scaled down, so UI bits inside are multiplied by z.
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (_, __) => Center(
                    child: SizedBox(
                      width: 28 * z,
                      height: 28 * z,
                      child: CircularProgressIndicator(
                        strokeWidth: 2 * z,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48 * z,
                      color: Colors.white54,
                    ),
                  ),
                ),
              );
            },
          ),

          // Thumbnail strip
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: _thumbSize,
                    child: ListView.separated(
                      controller: _thumbController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _thumbPadding,
                      ),
                      itemCount: images.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _thumbGap),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _controller.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: widget.indexListenable,
                            builder: (context, current, child) {
                              final active = current == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: _thumbSize,
                                height: _thumbSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Opacity(
                                  opacity: active ? 1.0 : 0.6,
                                  child: child,
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                                memCacheHeight: 150,
                                fadeInDuration: const Duration(
                                  milliseconds: 100,
                                ),
                                errorWidget: (_, __, ___) =>
                                    Container(color: Colors.grey.shade800),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.45),
                ),
              ),
            ),
          ),

          // Counter
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.indexListenable,
                  builder: (_, i, __) => Text(
                    '${i + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
