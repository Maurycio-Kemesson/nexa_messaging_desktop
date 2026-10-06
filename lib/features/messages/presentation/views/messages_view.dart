import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
import 'package:nexa_messaging_desktop/core/widgets/nexa_logo.dart';

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

    Future.microtask(() {
      ref
          .read(messagesViewModelProvider.notifier)
          .loadMessages(roomId: widget.roomId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.navy,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.navyLight,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const NexaLogo(height: 28),
                const SizedBox(width: 16),
                Container(width: 1, height: 28, color: AppColors.divider),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.roomName, style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text('Sala', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: MessagesContent()),
          _MessageComposer(
            controller: _messageController,
            roomId: widget.roomId,
          ),
        ],
      ),
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

    Future<void> send() async {
      if (isSending) {
        return;
      }

      final MessagesViewModel viewModel = ref.read(
        messagesViewModelProvider.notifier,
      );

      final String message = controller.text;

      await viewModel.sendMessage(roomId: roomId, message: message);

      if (!context.mounted) {
        return;
      }

      final bool hasError = ref.read(
        messagesViewModelProvider.select((state) => state.error != null),
      );

      if (!hasError) {
        controller.clear();
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.navyLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => send(),
              decoration: const InputDecoration(
                hintText: 'Digite uma mensagem...',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSending ? null : send,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.navy,
              disabledBackgroundColor: AppColors.navyElevated,
              minimumSize: const Size(44, 44),
            ),
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
