import 'package:flutter/services.dart';
import 'dart:io';
import '../models/chat_models.dart';

class LLMService {
  static const platform = MethodChannel('com.example.on_device_ai/llm');
  
  static const String _initModel = 'initializeModel';
  static const String _getInference = 'getInference';
  static const String _getStreamingTokens = 'getStreamingTokens';
  static const String _releaseModel = 'releaseModel';

  /// Check if model file exists in common storage locations
  static Future<String?> findModelFile() async {
    final List<String> possiblePaths = [
      '/storage/emulated/0/Documents/mistral-7b-instruct-v0.2.Q4_K_M.gguf',
      '/storage/emulated/0/Download/mistral-7b-instruct-v0.2.Q4_K_M.gguf',
      '/storage/emulated/0/Downloads/mistral-7b-instruct-v0.2.Q4_K_M.gguf',
      '/storage/emulated/0/DCIM/mistral-7b-instruct-v0.2.Q4_K_M.gguf',
      '/sdcard/Documents/mistral-7b-instruct-v0.2.Q4_K_M.gguf',
    ];
    
    for (String path in possiblePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          print('Model found at: $path');
          return path;
        }
      } catch (e) {
        print('Error checking path $path: $e');
      }
    }
    
    return null;
  }
  
  /// Initialize the LLM model
  /// Returns true if successful, false otherwise
  static Future<bool> initializeModel(ModelConfig config) async {
    try {
      final bool result = await platform.invokeMethod<bool>(
        _initModel,
        {
          'modelPath': config.modelPath,
          'modelName': config.modelName,
          'contextSize': config.contextSize,
          'threads': config.threads,
          'gpuLayers': config.gpuLayers,
        },
      ) ?? false;
      
      return result;
    } catch (e) {
      print('Error initializing model: $e');
      return false;
    }
  }

  /// Get inference response for a prompt (non-streaming)
  static Future<String> getInference(String prompt, {int maxTokens = 512}) async {
    try {
      final String result = await platform.invokeMethod<String>(
        _getInference,
        {
          'prompt': prompt,
          'maxTokens': maxTokens,
        },
      ) ?? '';
      
      return result;
    } catch (e) {
      print('Error getting inference: $e');
      return 'Error: Failed to get inference';
    }
  }

  /// Get streaming tokens for a prompt
  /// Returns a Stream of token strings
  static Stream<String> getStreamingTokens(
    String prompt, {
    int maxTokens = 512,
  }) async* {
    try {
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onToken') {
          final token = call.arguments as String?;
          if (token != null) {
            // Token is handled through stream controller
          }
        }
        return null;
      });

      // Call the native method
      await platform.invokeMethod(
        _getStreamingTokens,
        {
          'prompt': prompt,
          'maxTokens': maxTokens,
        },
      );

      // For now, yield empty as Kotlin will use EventChannel in production
      // This is a simplified implementation
    } catch (e) {
      print('Error getting streaming tokens: $e');
      yield 'Error: $e';
    }
  }

  /// Release the model and free resources
  static Future<void> releaseModel() async {
    try {
      await platform.invokeMethod(_releaseModel);
    } catch (e) {
      print('Error releasing model: $e');
    }
  }
}
