import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/messages_providers.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/viewmodels/messages_view_model.dart';

class FakeMessagesRepository implements MessagesRepository {
  bool sendMessageCalled = false;
  bool getMessagesCalled = false;
  bool shouldThrowOnSend = false;

  String? sentRoomId;
  String? sentMessage;

  Completer<void>? sendCompleter;

  @override
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  }) async {
    getMessagesCalled = true;

    return const MessagesPageEntity(messages: [], endToken: null);
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String message,
  }) async {
    sendMessageCalled = true;
    sentRoomId = roomId;
    sentMessage = message;

    if (shouldThrowOnSend) {
      throw Exception('Failed to send message');
    }

    if (sendCompleter != null) {
      await sendCompleter!.future;
    }
  }

  @override
  Stream<MessageEntity> watchMessages() {
    return const Stream.empty();
  }
}

void main() {
  test('Should not send an empty message', () async {
    final repository = FakeMessagesRepository();

    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final viewModel = container.read(messagesViewModelProvider.notifier);

    await viewModel.sendMessage(roomId: '!room:matrix.org', message: '   ');

    expect(repository.sendMessageCalled, isFalse);
  });

  test('Should send a valid message', () async {
    final repository = FakeMessagesRepository();

    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final viewModel = container.read(messagesViewModelProvider.notifier);

    await viewModel.sendMessage(
      roomId: '!room:matrix.org',
      message: 'Hello Matrix!',
    );

    expect(repository.sendMessageCalled, isTrue);
    expect(repository.sentRoomId, '!room:matrix.org');
    expect(repository.sentMessage, 'Hello Matrix!');
  });

  test('Should set isSending while sending a message', () async {
    final repository = FakeMessagesRepository()
      ..sendCompleter = Completer<void>();

    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final viewModel = container.read(messagesViewModelProvider.notifier);

    final future = viewModel.sendMessage(
      roomId: '!room:matrix.org',
      message: 'Hello Matrix!',
    );

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.isSending, isTrue);

    repository.sendCompleter!.complete();

    await future;

    expect(viewModel.state.isSending, isFalse);
  });

  test('Should handle send message error', () async {
    final repository = FakeMessagesRepository()..shouldThrowOnSend = true;

    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final viewModel = container.read(messagesViewModelProvider.notifier);

    await viewModel.sendMessage(
      roomId: '!room:matrix.org',
      message: 'Hello Matrix!',
    );

    expect(viewModel.state.isSending, isFalse);

    expect(viewModel.state.error, 'Exception: Failed to send message');
  });

  test('Should reload messages after sending', () async {
    final repository = FakeMessagesRepository();

    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final viewModel = container.read(messagesViewModelProvider.notifier);

    await viewModel.sendMessage(
      roomId: '!room:matrix.org',
      message: 'Hello Matrix!',
    );

    expect(repository.sendMessageCalled, isTrue);
    expect(repository.getMessagesCalled, isTrue);
  });
}
