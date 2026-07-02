import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../providers/llm_provider.dart';
import '../services/llm_service.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModel();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref.read(llmStateProvider.notifier).releaseModel();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // First, find the model file
    final modelPath = await LLMService.findModelFile();
    
    if (modelPath == null) {
      // Model not found - show error
      if (mounted) {
        ref.read(llmStateProvider.notifier).state = 
          ref.read(llmStateProvider).copyWith(
            error: 'Model file not found!\n\nPlease copy "mistral-7b-instruct-v0.2.Q4_K_M.gguf" to your phone:\n\n📱 /storage/emulated/0/Documents/\n\nYou can:\n1. Connect phone via USB\n2. Copy the model file to Documents folder\n3. Reopen the app\n\nFile size: ~4.3 GB',
          );
      }
      return;
    }

    final modelConfig = ModelConfig(
      modelPath: modelPath,
      modelName: 'Mistral 7B Instruct Q4_K_M',
      contextSize: 4096,
      threads: 4,
      gpuLayers: 0,
    );

    ref.read(llmStateProvider.notifier).initializeModel(modelConfig);
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    await ref.read(llmStateProvider.notifier).sendMessage(message);

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final llmState = ref.watch(llmStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('On-Device AI Chat'),
        elevation: 2.0,
        actions: [
          if (llmState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                ref.read(llmStateProvider.notifier).clearChat();
              },
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Error message
          if (llmState.error != null)
            ErrorMessage(
              message: llmState.error ?? 'Unknown error',
              onDismiss: () {
                ref.read(llmStateProvider.notifier).clearError();
              },
            ),

          // Chat messages area
          Expanded(
            child: llmState.isLoading && !llmState.isModelLoaded
                ? const LoadingIndicator(message: 'Loading model...')
                : llmState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64.0,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Welcome to On-Device AI',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Ask me anything! Running Mistral 7B locally.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ChatMessageList(messages: llmState.messages),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
            ),
            child: Column(
              children: [
                // Status message
                if (!llmState.isModelLoaded && !llmState.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Model not ready...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.0,
                      ),
                    ),
                  ),

                // Input field and send button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: llmState.isModelLoaded && !llmState.isLoading,
                        decoration: InputDecoration(
                          hintText: 'Ask me something...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 10.0,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FloatingActionButton(
                      onPressed: llmState.isModelLoaded && !llmState.isLoading
                          ? _sendMessage
                          : null,
                      mini: true,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
