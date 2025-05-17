import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/therapy_chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../../../shared/services/user_profile_service.dart';

class TherapyChatScreen extends ConsumerStatefulWidget {
  const TherapyChatScreen({super.key});

  @override
  ConsumerState<TherapyChatScreen> createState() => _TherapyChatScreenState();
}

class _TherapyChatScreenState extends ConsumerState<TherapyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final userProfile = ref.read(userProfileProvider);

    if (userProfile == null || !userProfile.isComplete()) {
      // Delay showing the dialog until after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showProfileSetupDialog();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(therapyChatProvider.notifier).sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _showProfileSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Complete Your Profile'),
            content: const Text(
              'To get the most out of your therapy sessions, please complete your profile information first.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
                child: const Text('Set Up Profile'),
              ),
            ],
          ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Conversation History'),
            content: const Text(
              'This will delete your entire conversation history with the AI therapist. This action cannot be undone. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(therapyChatProvider.notifier)
                      .clearConversationHistory();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation history cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(therapyChatProvider);

    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk it Through'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation history',
            onPressed: () => _showClearHistoryDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child:
                  chatState.messages.isEmpty
                      ? const Center(
                        child: Text('Your conversation will appear here'),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          return ChatMessageWidget(message: message);
                        },
                      ),
            ),

            // Loading indicator
            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),

            // Error message
            if (chatState.error != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red.withAlpha(30),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(therapyChatProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: chatState.isLoading ? null : _sendMessage,
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
