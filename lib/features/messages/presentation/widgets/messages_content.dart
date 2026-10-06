import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';
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

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 80;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
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
    ref.listen(messagesViewModelProvider, (previous, next) {
      final bool countIncreased =
          (previous?.messages.length ?? 0) < next.messages.length;
      final bool firstPage =
          (previous == null || previous.messages.isEmpty) &&
          next.messages.isNotEmpty;

      if (firstPage || (countIncreased && _isNearBottom())) {
        _scrollToEnd();
      }
    });

    final MessagesState state = ref.watch(messagesViewModelProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erro ao carregar mensagens:\n${state.error}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }
    if (state.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma mensagem encontrada.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final String? currentUserId = ref.watch(
      currentSessionProvider.select((session) => session?.userId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double bubbleMaxWidth = constraints.maxWidth * 0.72;

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final MessageEntity message = state.messages[index];
            final bool isMine =
                currentUserId != null && message.sender == currentUserId;

            return _MessageBubble(
              message: message,
              isMine: isMine,
              maxWidth: bubbleMaxWidth,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.maxWidth,
  });

  final MessageEntity message;
  final bool isMine;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String time = DateFormat.Hm().format(message.timestamp.toLocal());

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine) ...[
                Text(
                  _senderLabel(message.sender),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.teal),
                ),
                const SizedBox(height: 4),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isMine ? AppColors.bubbleMine : AppColors.bubbleOther,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    message.content,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(time, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

String _senderLabel(String sender) {
  final Match? match = RegExp(r'^@([^:]+):').firstMatch(sender);
  return match?.group(1) ?? sender;
}
