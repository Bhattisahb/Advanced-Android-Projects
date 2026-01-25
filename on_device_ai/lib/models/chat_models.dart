class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ModelConfig {
  final String modelPath;
  final String modelName;
  final int contextSize;
  final int threads;
  final int gpuLayers;

  const ModelConfig({
    required this.modelPath,
    this.modelName = 'Mistral 7B Instruct Q4_K_M',
    this.contextSize = 4096,
    this.threads = 4,
    this.gpuLayers = 0,
  });
}

class LLMState {
  final bool isLoading;
  final bool isModelLoaded;
  final String? error;
  final List<ChatMessage> messages;

  const LLMState({
    this.isLoading = false,
    this.isModelLoaded = false,
    this.error,
    this.messages = const [],
  });

  LLMState copyWith({
    bool? isLoading,
    bool? isModelLoaded,
    String? error,
    List<ChatMessage>? messages,
  }) {
    return LLMState(
      isLoading: isLoading ?? this.isLoading,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
      error: error,
      messages: messages ?? this.messages,
    );
  }
}
