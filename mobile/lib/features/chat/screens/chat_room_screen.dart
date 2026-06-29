import 'package:flutter/material.dart';
import 'package:stream_chat/stream_chat.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/stream_chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String channelId;
  final String channelType;

  const ChatRoomScreen({
    super.key,
    required this.channelId,
    this.channelType = 'messaging',
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  late Future<Channel> _channelFuture;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _channelFuture = JobPortalStreamChatService.instance.watchChannel(
      channelId: widget.channelId,
      channelType: widget.channelType,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(Channel channel) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || sending) return;

    try {
      setState(() => sending = true);
      _messageController.clear();
      await channel.sendMessage(Message(text: text));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message right now.')),
      );
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Channel>(
      future: _channelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: _ChatErrorState(
              message: _cleanError(snapshot.error),
              onRetry: () {
                setState(() {
                  _channelFuture = JobPortalStreamChatService.instance
                      .watchChannel(
                    channelId: widget.channelId,
                    channelType: widget.channelType,
                  );
                });
              },
            ),
          );
        }

        final channel = snapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          appBar: AppBar(
            title: const Text('Chat'),
            backgroundColor: const Color(0xFFF8FAFF),
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.primary,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: channel.state?.messagesStream,
                  initialData: channel.state?.messages ?? const <Message>[],
                  builder: (context, messageSnapshot) {
                    final messages = messageSnapshot.data ?? const <Message>[];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Start the conversation.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final currentUserId =
                            JobPortalStreamChatService.instance.currentUserId;
                        final isMine = message.user?.id == currentUserId;
                        return _MessageBubble(message: message, isMine: isMine);
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(channel),
                          decoration: InputDecoration(
                            hintText: 'Write a message...',
                            filled: true,
                            fillColor: const Color(0xFFF4F7FF),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: sending ? null : () => _sendMessage(channel),
                        icon: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _cleanError(Object? error) {
    if (error == null) return 'Unable to open chat right now.';
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(
            color: isMine ? Colors.white : AppColors.textPrimary,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryBlue,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
