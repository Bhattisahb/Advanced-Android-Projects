import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/llm_service.dart';

/// Provider for LLM state
final llmStateProvider = StateNotifierProvider<LLMNotifier, LLMState>((ref) {
  return LLMNotifier();
});

class LLMNotifier extends StateNotifier<LLMState> {
  LLMNotifier() : super(const LLMState());

  /// Initialize the model
  Future<void> initializeModel(ModelConfig config) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await LLMService.initializeModel(config);
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          isModelLoaded: true,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load model. Check if model file exists.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error initializing model: $e',
      );
    }
  }

  /// Send a message and get streaming response
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.isEmpty) return;
    
    if (!state.isModelLoaded) {
      state = state.copyWith(
        error: 'Model not loaded. Please wait for model initialization.',
      );
      return;
    }

    // Add user message to chat
    final userMsg = ChatMessage(
      text: userMessage,
      isUser: true,
    );
    
    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(messages: updatedMessages);

    // Create AI response placeholder
    final aiMsg = ChatMessage(
      text: '',
      isUser: false,
      isLoading: true,
    );
    
    final messagesWithAI = [...updatedMessages, aiMsg];
    state = state.copyWith(messages: messagesWithAI);

    // Get streaming response
    try {
      final response = await LLMService.getInference(userMessage, maxTokens: 512);
      
      // Update AI message with response
      final finalMessages = [...messagesWithAI];
      finalMessages[finalMessages.length - 1] = aiMsg.copyWith(
        text: response,
        isLoading: false,
      );
      
      state = state.copyWith(messages: finalMessages, error: null);
    } catch (e) {
      // Remove incomplete AI message on error
      final finalMessages = [...updatedMessages];
      state = state.copyWith(
        messages: finalMessages,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Clear chat history
  void clearChat() {
    state = state.copyWith(messages: [], error: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Release model on dispose
  void releaseModel() {
    LLMService.releaseModel();
  }
}
