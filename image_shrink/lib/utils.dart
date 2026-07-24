import 'dart:io';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
Future<void> saveImage(File file) async {
  await ImageGallerySaverPlus.saveFile(file.path);
}

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return "$bytes B";
  }

  if (bytes < 1024 * 1024) {
    return "${(bytes / 1024).toStringAsFixed(2)} KB";
  }

  if (bytes < 1024 * 1024 * 1024) {
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
}

double compressionPercentage(
    int original,
    int compressed,
    ) {
  return ((original - compressed) / original) * 100;
}

Future<void> shareImage(File file) async {
  await Share.shareXFiles(
    [
      XFile(file.path),
    ],
    text: "Compressed using Image Shrink",
  );
}