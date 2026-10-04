import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/viewmodels/messages_state.dart';

import '../viewmodels/messages_view_model.dart';

class MessagesContent extends ConsumerWidget {
  const MessagesContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MessagesState state = ref.watch(messagesViewModelProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Text(
          'Erro ao carregar mensagens:\n${state.error}',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem encontrada.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final MessageEntity message = state.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message.content),
            ],
          ),
        );
      },
    );
  }
}
