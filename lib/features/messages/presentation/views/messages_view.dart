import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/messages_view_model.dart';

import '../widgets/messages_content.dart';

class MessagesView extends ConsumerStatefulWidget {
  const MessagesView({required this.roomId, required this.roomName, super.key});

  final String roomId;
  final String roomName;

  @override
  ConsumerState<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<MessagesView> {
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
      ],
    );
  }
}
