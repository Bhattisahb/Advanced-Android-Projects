package com.example.on_device_ai.models

import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val id: String = java.util.UUID.randomUUID().toString(),
    val text: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis(),
    val isLoading: Boolean = false
)

@Serializable
data class ModelConfig(
    val modelPath: String,
    val modelName: String = "Mistral 7B Q4_K_M",
    val contextSize: Int = 4096,
    val threads: Int = 4,
    val gpuLayers: Int = 0  // 0 for CPU only, > 0 for GPU acceleration
)

data class LLMState(
    val isLoading: Boolean = false,
    val isModelLoaded: Boolean = false,
    val error: String? = null,
    val messages: List<ChatMessage> = emptyList()
)
