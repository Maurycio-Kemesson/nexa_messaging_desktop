import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';

import '../../domain/usecases/messages_usecase.dart';
import '../messages_providers.dart';
import 'messages_state.dart';

final NotifierProvider<MessagesViewModel, MessagesState>
messagesViewModelProvider = NotifierProvider<MessagesViewModel, MessagesState>(
  MessagesViewModel.new,
);

class MessagesViewModel extends Notifier<MessagesState> {
  late final MessagesUseCase _messagesUseCase;

  StreamSubscription<MessageEntity>? _messagesSubscription;

  String? _currentRoomId;
  String? _historyEndToken;
  bool _isLoadingMore = false;

  @override
  MessagesState build() {
    _messagesUseCase = ref.read(messagesUseCaseProvider);

    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });

    _startMessageUpdates();

    return const MessagesState();
  }

  Future<void> loadMessages({required String roomId}) async {
    _currentRoomId = roomId;
    _historyEndToken = null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _messagesUseCase.call(roomId: roomId);

      _historyEndToken = page.endToken;

      state = state.copyWith(isLoading: false, messages: page.messages);
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

  void _startMessageUpdates() {
    _messagesSubscription = _messagesUseCase.watchMessages().listen(
      _onMessageReceived,
      onError: (Object error) {
        state = state.copyWith(error: error.toString());
      },
    );
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
    if (_currentRoomId == null) {
      return;
    }

    if (_historyEndToken == null) {
      return;
    }

    if (_isLoadingMore) {
      return;
    }

    _isLoadingMore = true;

    debugPrint(
      'MESSAGES: carregando mensagens anteriores. '
      'token=$_historyEndToken',
    );

    try {
      final page = await _messagesUseCase.call(
        roomId: _currentRoomId!,
        fromToken: _historyEndToken,
      );

      debugPrint(
        'MESSAGES: carregadas '
        '${page.messages.length} mensagens anteriores',
      );

      _historyEndToken = page.endToken;

      final existingIds = state.messages.map((message) => message.id).toSet();

      final newMessages = page.messages.where(
        (message) => !existingIds.contains(message.id),
      );

      state = state.copyWith(messages: [...newMessages, ...state.messages]);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      _isLoadingMore = false;
    }
  }
}
