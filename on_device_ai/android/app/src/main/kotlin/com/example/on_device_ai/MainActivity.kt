package com.example.on_device_ai

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.on_device_ai.services.LLMService
import com.example.on_device_ai.models.ModelConfig
import timber.log.Timber

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.example.on_device_ai/llm"
    private lateinit var llmService: LLMService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        llmService = LLMService(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "initializeModel" -> {
                            val modelPath = call.argument<String>("modelPath") ?: ""
                            val modelName = call.argument<String>("modelName") ?: "Mistral 7B"
                            val contextSize = call.argument<Int>("contextSize") ?: 4096
                            val threads = call.argument<Int>("threads") ?: 4
                            val gpuLayers = call.argument<Int>("gpuLayers") ?: 0
                            
                            val config = ModelConfig(
                                modelPath = modelPath,
                                modelName = modelName,
                                contextSize = contextSize,
                                threads = threads,
                                gpuLayers = gpuLayers
                            )
                            
                            val success = llmService.loadModelSync(config)
                            result.success(success)
                        }
                        
                        "getInference" -> {
                            val prompt = call.argument<String>("prompt") ?: ""
                            val maxTokens = call.argument<Int>("maxTokens") ?: 512
                            
                            val response = llmService.getInferenceSync(prompt, maxTokens)
                            result.success(response)
                        }
                        
                        "getStreamingTokens" -> {
                            val prompt = call.argument<String>("prompt") ?: ""
                            val maxTokens = call.argument<Int>("maxTokens") ?: 512
                            
                            val tokens = llmService.getStreamingTokensSync(prompt, maxTokens)
                            result.success(tokens)
                        }
                        
                        "releaseModel" -> {
                            llmService.releaseModel()
                            result.success(null)
                        }
                        
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Timber.e(e, "Error handling method: ${call.method}")
                    result.error("FLUTTER_ERROR", e.message, null)
                }
            }
    }
}
