import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/messages_usecase.dart';
import '../messages_providers.dart';
import 'messages_state.dart';

final NotifierProvider<MessagesViewModel, MessagesState>
messagesViewModelProvider = NotifierProvider<MessagesViewModel, MessagesState>(
  MessagesViewModel.new,
);

class MessagesViewModel extends Notifier<MessagesState> {
  late final MessagesUseCase _messagesUseCase;

  @override
  MessagesState build() {
    _messagesUseCase = ref.read(messagesUseCaseProvider);

    return const MessagesState();
  }

  Future<void> loadMessages({required String roomId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _messagesUseCase.call(roomId: roomId);

      state = state.copyWith(isLoading: false, messages: messages);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> sendMessage({
    required String roomId,
    required String message,
  }) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      return;
    }

    state = state.copyWith(isSending: true, error: null);

    try {
      await _messagesUseCase.sendMessage(
        roomId: roomId,
        message: trimmedMessage,
      );

      await loadMessages(roomId: roomId);

      state = state.copyWith(isSending: false);
    } catch (error) {
      state = state.copyWith(isSending: false, error: error.toString());
    }
  }
}
