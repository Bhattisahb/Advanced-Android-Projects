import 'dart:io';

import 'package:flutter/services.dart';

enum DeleteMediaResult {
  deleted,
  cancelled,
  needAllFilesAccess,
  failed,
}

/// Android-native delete media via [MethodChannel].
class FileActionsService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.music_player/file_actions',
  );

  static bool get isSupported => Platform.isAndroid;

  static Future<DeleteMediaResult> deleteMediaFile(
    String path, {
    int? mediaId,
  }) async {
    if (!isSupported || path.isEmpty) return DeleteMediaResult.failed;
    try {
      final result = await _channel.invokeMethod<String>('deleteMedia', {
        'path': path,
        'mediaId': ?mediaId,
      });
      return switch (result) {
        'deleted' => DeleteMediaResult.deleted,
        'cancelled' => DeleteMediaResult.cancelled,
        'need_all_files_access' => DeleteMediaResult.needAllFilesAccess,
        _ => DeleteMediaResult.failed,
      };
    } on PlatformException {
      return DeleteMediaResult.failed;
    }
  }

  static Future<bool> hasAllFilesAccess() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('hasAllFilesAccess');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> openAllFilesAccessSettings() async {
    if (!isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openAllFilesAccessSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
