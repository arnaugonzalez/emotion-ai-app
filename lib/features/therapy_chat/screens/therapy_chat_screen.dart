import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/therapy_chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../../../shared/services/user_profile_service.dart';
import '../../../shared/services/token_usage_service.dart';
import 'package:intl/intl.dart';

class TherapyChatScreen extends ConsumerStatefulWidget {
  const TherapyChatScreen({super.key});

  @override
  ConsumerState<TherapyChatScreen> createState() => _TherapyChatScreenState();
}

class _TherapyChatScreenState extends ConsumerState<TherapyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasCheckedProfile = false;
  bool _isLimitExceeded = false;

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
    _checkTokenLimit();
  }

  Future<void> _checkTokenLimit() async {
    final tokenService = ref.read(tokenUsageServiceProvider);
    final hasEnoughTokens = await tokenService.canMakeRequest(
      100,
    ); // Small test amount
    setState(() {
      _isLimitExceeded = !hasEnoughTokens;
    });
  }

  Future<void> _checkUserProfile() async {
    if (_hasCheckedProfile) return;

    final profileService = ref.read(userProfileServiceProvider);
    final hasProfile = await profileService.hasProfile();

    if (!hasProfile && mounted) {
      // Delay showing the dialog until after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showProfileSetupDialog();
      });
    }

    _hasCheckedProfile = true;
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // Check token limit before sending
      final tokenService = ref.read(tokenUsageServiceProvider);
      final hasEnoughTokens = await tokenService.canMakeRequest(
        100,
      ); // Small test amount

      if (!hasEnoughTokens) {
        setState(() {
          _isLimitExceeded = true;
        });
        return;
      }

      ref.read(therapyChatProvider.notifier).sendMessage(text);
      _messageController.clear();
      _scrollToBottom();

      // Check limit after sending
      _checkTokenLimit();
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

  void _showTokenLimitDialog() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final resetTime = DateFormat.jm().format(tomorrow);
    final resetDate = DateFormat.yMMMd().format(tomorrow);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Daily Token Limit Reached'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You have reached your daily token usage limit. This helps us ensure fair usage of the AI service for all users.',
                ),
                const SizedBox(height: 16),
                Text('Your limit will reset at $resetTime on $resetDate.'),
                const SizedBox(height: 16),
                const Text(
                  'Need a higher limit? Consider upgrading to an admin account.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
                child: const Text('View Usage Stats'),
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
            // Token limit warning
            if (_isLimitExceeded)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily token limit reached. The limit will reset tomorrow.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showTokenLimitDialog,
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ),

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
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
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
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isLimitExceeded && !chatState.isLoading,
                          decoration: InputDecoration(
                            hintText:
                                _isLimitExceeded
                                    ? 'Daily token limit reached'
                                    : 'Type your message...',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted:
                              (_) => _isLimitExceeded ? null : _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed:
                          (_isLimitExceeded || chatState.isLoading)
                              ? null
                              : _sendMessage,
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
