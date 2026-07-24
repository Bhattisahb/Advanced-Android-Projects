import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class Compressor {
  static Future<File?> compressImage(
      File originalFile,
      int targetKB,
      ) async {
    final targetBytes = targetKB * 1024;

    final tempDir = await getTemporaryDirectory();

    File bestFile = originalFile;

    int quality = 95;

    // Maximum 18 attempts
    for (int i = 0; i < 18; i++) {
      final outputPath =
          "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

      final XFile? result =
      await FlutterImageCompress.compressAndGetFile(
        bestFile.path,
        outputPath,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (result == null) {
        return bestFile;
      }

      final compressed = File(result.path);

      final size = compressed.lengthSync();

      // Success
      if (size <= targetBytes) {
        return compressed;
      }

      bestFile = compressed;

      // Lower quality every loop
      quality -= 5;

      // Prevent going too low
      if (quality < 10) {
        break;
      }
    }

    return bestFile;
  }
}