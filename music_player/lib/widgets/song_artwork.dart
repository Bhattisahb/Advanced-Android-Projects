import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../models/index.dart';
import '../theme/app_colors.dart';

class _CachedArtwork {
  final Uint8List? bytes;
  final int pixelSize;

  const _CachedArtwork({required this.bytes, required this.pixelSize});
}

class SongArtwork extends StatefulWidget {
  final Song song;
  final double size;
  final double borderRadius;
  final double iconSize;
  final Color accentColor;

  const SongArtwork({
    super.key,
    required this.song,
    required this.size,
    this.borderRadius = 8,
    this.iconSize = 28,
    this.accentColor = AppColors.accent,
  });

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static final Map<int, _CachedArtwork> _artworkCache = {};

  late Future<Uint8List?> _artworkFuture;

  int _targetPixelSize(double devicePixelRatio) {
    final logical = widget.size * devicePixelRatio;
    // Request enough pixels for crisp display; avoid tiny thumbs scaled up.
    final target = logical.round().clamp(200, 1200);
    if (widget.size >= 120) {
      return target.clamp(512, 1200);
    }
    return target;
  }

  @override
  void initState() {
    super.initState();
    _artworkFuture = _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant SongArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.mediaId != widget.song.mediaId ||
        oldWidget.size != widget.size) {
      _artworkFuture = _loadArtwork();
    }
  }

  Future<Uint8List?> _loadArtwork() async {
    final mediaId = widget.song.mediaId;
    if (mediaId == null) return null;

    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final pixelSize = _targetPixelSize(dpr);

    final cached = _artworkCache[mediaId];
    if (cached != null && cached.pixelSize >= pixelSize) {
      return cached.bytes;
    }

    final artwork = await _audioQuery.queryArtwork(
      mediaId,
      ArtworkType.AUDIO,
      size: pixelSize,
      quality: 100,
    );

    final existing = _artworkCache[mediaId];
    if (existing == null || pixelSize >= existing.pixelSize) {
      _artworkCache[mediaId] = _CachedArtwork(
        bytes: artwork,
        pixelSize: pixelSize,
      );
    }

    return artwork;
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final decodeSize = (widget.size * dpr).round().clamp(1, 1200);

    final placeholder = _ArtworkPlaceholder(
      size: widget.size,
      borderRadius: widget.borderRadius,
      iconSize: widget.iconSize,
      accentColor: widget.accentColor,
    );

    if (widget.song.mediaId == null) {
      return placeholder;
    }

    return FutureBuilder<Uint8List?>(
      future: _artworkFuture,
      builder: (context, snapshot) {
        final artwork = snapshot.data;
        if (artwork == null || artwork.isEmpty) {
          return placeholder;
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            width: widget.size,
            height: widget.size,
            color: AppColors.surfaceLight,
            alignment: Alignment.center,
            child: Image.memory(
              artwork,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              cacheWidth: decodeSize,
              cacheHeight: decodeSize,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double iconSize;
  final Color accentColor;

  const _ArtworkPlaceholder({
    required this.size,
    required this.borderRadius,
    required this.iconSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Icon(
        Icons.music_note,
        size: iconSize,
        color: accentColor,
      ),
    );
  }
}
