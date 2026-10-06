import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';

import '../../domain/usecases/messages_usecase.dart';
import '../messages_providers.dart';
import 'messages_state.dart';

final NotifierProvider<MessagesViewModel, MessagesState>
messagesViewModelProvider = NotifierProvider<MessagesViewModel, MessagesState>(
  MessagesViewModel.new,
);

class MessagesViewModel extends Notifier<MessagesState> {
  MessagesUseCase get _messagesUseCase => ref.read(messagesUseCaseProvider);

  String? _currentRoomId;
  String? _historyEndToken;
  bool _isLoadingMore = false;

  @override
  MessagesState build() {
    ref.watch(currentSessionProvider);

    _currentRoomId = null;
    _historyEndToken = null;
    _isLoadingMore = false;

    final StreamSubscription<MessageEntity> subscription = _messagesUseCase
        .watchMessages()
        .listen(
          _onMessageReceived,
          onError: (Object error) {
            state = state.copyWith(error: error.toString());
          },
        );

    ref.onDispose(subscription.cancel);

    return const MessagesState();
  }

  Future<void> loadMessages({required String roomId}) async {
    _currentRoomId = roomId;
    _historyEndToken = null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _messagesUseCase.call(roomId: roomId);

      if (roomId != _currentRoomId) {
        return;
      }

      _historyEndToken = page.endToken;

      state = state.copyWith(isLoading: false, messages: page.messages);
    } catch (error) {
      if (roomId != _currentRoomId) {
        return;
      }

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

      if (_isCurrentRoom(roomId)) {
        await loadMessages(roomId: roomId);
      }

      state = state.copyWith(isSending: false);
    } catch (error) {
      if (_isCurrentRoom(roomId)) {
        state = state.copyWith(isSending: false, error: error.toString());
      } else {
        state = state.copyWith(isSending: false);
      }
    }
  }

  bool _isCurrentRoom(String roomId) {
    return _currentRoomId == null || _currentRoomId == roomId;
  }

  void _onMessageReceived(MessageEntity message) {
    if (message.roomId != _currentRoomId) {
      return;
    }

    final alreadyExists = state.messages.any((item) => item.id == message.id);

    if (alreadyExists) {
      return;
    }

    state = state.copyWith(messages: [...state.messages, message]);
  }

  Future<void> loadMoreMessages() async {
    final String? roomId = _currentRoomId;
    final String? fromToken = _historyEndToken;

    if (roomId == null || fromToken == null || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;

    try {
      final page = await _messagesUseCase.call(
        roomId: roomId,
        fromToken: fromToken,
      );

      if (roomId != _currentRoomId) {
        return;
      }

      _historyEndToken = page.endToken;

      final existingIds = state.messages.map((message) => message.id).toSet();

      final newMessages = page.messages.where(
        (message) => !existingIds.contains(message.id),
      );

      state = state.copyWith(messages: [...newMessages, ...state.messages]);
    } catch (error) {
      if (roomId == _currentRoomId) {
        state = state.copyWith(error: error.toString());
      }
    } finally {
      _isLoadingMore = false;
    }
  }
}
