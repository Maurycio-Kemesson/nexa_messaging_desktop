import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/viewmodels/messages_state.dart';

import '../viewmodels/messages_view_model.dart';

class MessagesContent extends ConsumerStatefulWidget {
  const MessagesContent({super.key});

  @override
  ConsumerState<MessagesContent> createState() => _MessagesContentState();
}

class _MessagesContentState extends ConsumerState<MessagesContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels <= position.minScrollExtent) {
      ref.read(messagesViewModelProvider.notifier).loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MessagesState state = ref.watch(messagesViewModelProvider);
    debugPrint('FLUTTER: mensagens no estado=${state.messages.length}');
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
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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
