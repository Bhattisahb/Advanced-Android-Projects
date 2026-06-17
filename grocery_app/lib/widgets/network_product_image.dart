import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Loads remote product photos with browser-like headers — avoids Unsplash/CDN
/// rejecting Flutter's default HTTP client.
class NetworkProductImage extends StatelessWidget {
  const NetworkProductImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.boxFit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit boxFit;
  final BorderRadius? borderRadius;

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept':
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget errorBox() => Container(
          height: height,
          width: width,
          color: bg,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
        );

    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return errorBox();

    Widget buildImage(double? w, double? h) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        height: h,
        width: w,
        fit: boxFit,
        httpHeaders: _headers,
        placeholder: (_, __) => Container(
          height: h,
          width: w,
          color: bg,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => errorBox(),
      );
    }

    Widget image = height != null || width != null
        ? buildImage(width, height)
        : LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth.isFinite ? c.maxWidth : null;
              final h = c.maxHeight.isFinite ? c.maxHeight : null;
              return buildImage(w, h);
            },
          );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
