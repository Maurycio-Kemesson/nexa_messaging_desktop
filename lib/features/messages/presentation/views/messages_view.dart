import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/messages_view_model.dart';

import '../widgets/messages_content.dart';

class MessagesView extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const MessagesView({required this.roomId, required this.roomName, super.key});

  @override
  ConsumerState<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<MessagesView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref
          .read(messagesViewModelProvider.notifier)
          .loadMessages(roomId: widget.roomId),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.roomName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 1),
        const Expanded(child: MessagesContent()),
        const Divider(height: 1),
        _MessageComposer(controller: _messageController, roomId: widget.roomId),
      ],
    );
  }
}

class _MessageComposer extends ConsumerWidget {
  const _MessageComposer({required this.controller, required this.roomId});

  final TextEditingController controller;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSending = ref.watch(
      messagesViewModelProvider.select((state) => state.isSending),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              decoration: const InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSending
                ? null
                : () async {
                    final MessagesViewModel viewModel = ref.read(
                      messagesViewModelProvider.notifier,
                    );

                    final String message = controller.text;

                    await viewModel.sendMessage(
                      roomId: roomId,
                      message: message,
                    );

                    if (!context.mounted) {
                      return;
                    }

                    final bool hasError = ref.read(
                      messagesViewModelProvider.select(
                        (state) => state.error != null,
                      ),
                    );

                    if (!hasError) {
                      controller.clear();
                    }
                  },
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
