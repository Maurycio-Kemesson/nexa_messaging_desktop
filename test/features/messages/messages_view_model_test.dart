import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/messages_providers.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/viewmodels/messages_view_model.dart';

const _roomId = '!room:matrix.org';

MessageEntity _message(String id, {String roomId = _roomId}) {
  return MessageEntity(
    id: id,
    roomId: roomId,
    sender: '@user:matrix.org',
    content: 'content $id',
    timestamp: DateTime(2026, 1, 1),
  );
}

typedef GetMessagesCall = ({String roomId, String? fromToken});

class FakeMessagesRepository implements MessagesRepository {
  final StreamController<MessageEntity> updates =
      StreamController<MessageEntity>.broadcast();

  final List<GetMessagesCall> getMessagesCalls = [];

  Future<MessagesPageEntity> Function(GetMessagesCall call)? onGetMessages;

  bool sendMessageCalled = false;
  bool shouldThrowOnSend = false;
  String? sentRoomId;
  String? sentMessage;
  Completer<void>? sendCompleter;

  @override
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  }) {
    final call = (roomId: roomId, fromToken: fromToken);
    getMessagesCalls.add(call);

    final handler = onGetMessages;
    if (handler != null) {
      return handler(call);
    }
    return Future.value(const MessagesPageEntity(messages: [], endToken: null));
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
  Stream<MessageEntity> watchMessages() => updates.stream;

  Future<void> dispose() => updates.close();
}

AuthSessionEntity _session(String deviceId) => AuthSessionEntity(
  homeserver: 'https://matrix.org',
  userId: '@user:matrix.org',
  deviceId: deviceId,
  accessToken: 'token-$deviceId',
);

class FakeSession extends Notifier<AuthSessionEntity?> {
  @override
  AuthSessionEntity? build() => _session('FIRST');

  void set(AuthSessionEntity? value) => state = value;
}

final fakeSessionProvider = NotifierProvider<FakeSession, AuthSessionEntity?>(
  FakeSession.new,
);

void main() {
  late FakeMessagesRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMessagesRepository();
    container = ProviderContainer.test(
      overrides: [
        messagesRepositoryProvider.overrideWithValue(repository),
        currentSessionProvider.overrideWith(
          (ref) => ref.watch(fakeSessionProvider),
        ),
      ],
    );
  });

  tearDown(() => repository.dispose());

  MessagesViewModel viewModel() =>
      container.read(messagesViewModelProvider.notifier);

  List<String> messageIds() => container
      .read(messagesViewModelProvider)
      .messages
      .map((m) => m.id)
      .toList();

  test('starts with an empty state', () {
    final state = container.read(messagesViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.isSending, isFalse);
    expect(state.messages, isEmpty);
    expect(state.error, isNull);
    expect(state.isEmpty, isTrue);
  });

  group('loadMessages', () {
    test('loads the first page of the room', () async {
      repository.onGetMessages = (_) async => MessagesPageEntity(
        messages: [_message('1'), _message('2')],
        endToken: 'token-1',
      );

      await viewModel().loadMessages(roomId: _roomId);

      final state = container.read(messagesViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(messageIds(), ['1', '2']);
      expect(repository.getMessagesCalls.single.roomId, _roomId);
      expect(repository.getMessagesCalls.single.fromToken, isNull);
    });

    test('sets isLoading while the request is pending', () async {
      final completer = Completer<MessagesPageEntity>();
      repository.onGetMessages = (_) => completer.future;

      final future = viewModel().loadMessages(roomId: _roomId);

      expect(container.read(messagesViewModelProvider).isLoading, isTrue);

      completer.complete(
        const MessagesPageEntity(messages: [], endToken: null),
      );
      await future;

      expect(container.read(messagesViewModelProvider).isLoading, isFalse);
    });

    test('exposes the error on failure', () async {
      repository.onGetMessages = (_) async => throw Exception('network');

      await viewModel().loadMessages(roomId: _roomId);

      final state = container.read(messagesViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'Exception: network');
      expect(state.isEmpty, isFalse);
    });

    test('clears a previous error when retrying', () async {
      repository.onGetMessages = (_) async => throw Exception('network');
      await viewModel().loadMessages(roomId: _roomId);

      repository.onGetMessages = null;
      await viewModel().loadMessages(roomId: _roomId);

      expect(container.read(messagesViewModelProvider).error, isNull);
    });

    test('ignores a stale response after switching rooms', () async {
      const otherRoomId = '!other:matrix.org';
      final staleResponse = Completer<MessagesPageEntity>();
      repository.onGetMessages = (call) => call.roomId == _roomId
          ? staleResponse.future
          : Future.value(
              MessagesPageEntity(
                messages: [_message('b', roomId: otherRoomId)],
                endToken: null,
              ),
            );

      final first = viewModel().loadMessages(roomId: _roomId);
      await viewModel().loadMessages(roomId: otherRoomId);

      staleResponse.complete(
        MessagesPageEntity(messages: [_message('a')], endToken: null),
      );
      await first;

      expect(messageIds(), ['b']);
    });
  });

  group('authentication changes', () {
    test('resets the state when the session changes', () async {
      repository.onGetMessages = (_) async =>
          MessagesPageEntity(messages: [_message('1')], endToken: null);
      await viewModel().loadMessages(roomId: _roomId);

      container.read(fakeSessionProvider.notifier)
        ..set(null)
        ..set(_session('SECOND'));

      expect(messageIds(), isEmpty);
      expect(repository.updates.hasListener, isTrue);

      repository.updates.add(_message('2'));
      await pumpEventQueue();

      expect(messageIds(), isEmpty);
    });
  });

  group('sendMessage', () {
    test('does not send an empty message', () async {
      await viewModel().sendMessage(roomId: _roomId, message: '   ');

      expect(repository.sendMessageCalled, isFalse);
      expect(container.read(messagesViewModelProvider).isSending, isFalse);
    });

    test('sends a trimmed message', () async {
      await viewModel().sendMessage(
        roomId: _roomId,
        message: '  Hello Matrix!  ',
      );

      expect(repository.sendMessageCalled, isTrue);
      expect(repository.sentRoomId, _roomId);
      expect(repository.sentMessage, 'Hello Matrix!');
    });

    test('sets isSending while sending a message', () async {
      repository.sendCompleter = Completer<void>();

      final future = viewModel().sendMessage(
        roomId: _roomId,
        message: 'Hello Matrix!',
      );
      await pumpEventQueue();

      expect(container.read(messagesViewModelProvider).isSending, isTrue);

      repository.sendCompleter!.complete();
      await future;

      expect(container.read(messagesViewModelProvider).isSending, isFalse);
    });

    test('exposes the error on failure', () async {
      repository.shouldThrowOnSend = true;

      await viewModel().sendMessage(roomId: _roomId, message: 'Hello Matrix!');

      final state = container.read(messagesViewModelProvider);
      expect(state.isSending, isFalse);
      expect(state.error, 'Exception: Failed to send message');
      expect(repository.getMessagesCalls, isEmpty);
    });

    test('reloads the room messages after sending', () async {
      repository.onGetMessages = (_) async =>
          MessagesPageEntity(messages: [_message('sent')], endToken: null);

      await viewModel().sendMessage(roomId: _roomId, message: 'Hello Matrix!');

      expect(repository.getMessagesCalls.single.roomId, _roomId);
      expect(messageIds(), ['sent']);
    });

    test('does not replace the current room after a stale send', () async {
      const otherRoomId = '!other:matrix.org';
      repository.sendCompleter = Completer<void>();
      repository.onGetMessages = (call) async => MessagesPageEntity(
        messages: [_message('shown', roomId: call.roomId)],
        endToken: null,
      );

      final send = viewModel().sendMessage(roomId: _roomId, message: 'Hello');
      await pumpEventQueue();
      await viewModel().loadMessages(roomId: otherRoomId);

      repository.sendCompleter!.complete();
      await send;

      expect(
        container.read(messagesViewModelProvider).messages.single.roomId,
        otherRoomId,
      );
      expect(messageIds(), ['shown']);
      expect(container.read(messagesViewModelProvider).isSending, isFalse);
    });
  });

  group('real-time updates', () {
    setUp(() {
      repository.onGetMessages = (_) async =>
          MessagesPageEntity(messages: [_message('1')], endToken: null);
    });

    test('appends messages received for the current room', () async {
      await viewModel().loadMessages(roomId: _roomId);

      repository.updates.add(_message('2'));
      await pumpEventQueue();

      expect(messageIds(), ['1', '2']);
    });

    test('ignores messages from other rooms', () async {
      await viewModel().loadMessages(roomId: _roomId);

      repository.updates.add(_message('2', roomId: '!other:matrix.org'));
      await pumpEventQueue();

      expect(messageIds(), ['1']);
    });

    test('ignores messages before a room is loaded', () async {
      viewModel();

      repository.updates.add(_message('2'));
      await pumpEventQueue();

      expect(messageIds(), isEmpty);
    });

    test('ignores duplicated messages', () async {
      await viewModel().loadMessages(roomId: _roomId);

      repository.updates
        ..add(_message('1'))
        ..add(_message('2'))
        ..add(_message('2'));
      await pumpEventQueue();

      expect(messageIds(), ['1', '2']);
    });

    test('exposes stream errors', () async {
      await viewModel().loadMessages(roomId: _roomId);

      repository.updates.addError(Exception('sync failed'));
      await pumpEventQueue();

      final state = container.read(messagesViewModelProvider);
      expect(state.error, 'Exception: sync failed');
      expect(messageIds(), ['1']);
    });

    test('cancels the subscription when disposed', () {
      viewModel();
      expect(repository.updates.hasListener, isTrue);

      container.dispose();

      expect(repository.updates.hasListener, isFalse);
    });
  });

  group('loadMoreMessages', () {
    test('does nothing before a room is loaded', () async {
      await viewModel().loadMoreMessages();

      expect(repository.getMessagesCalls, isEmpty);
    });

    test('does nothing when there is no older history', () async {
      await viewModel().loadMessages(roomId: _roomId);

      await viewModel().loadMoreMessages();

      expect(repository.getMessagesCalls, hasLength(1));
    });

    test('prepends older messages using the history token', () async {
      repository.onGetMessages = (call) async => call.fromToken == null
          ? MessagesPageEntity(
              messages: [_message('3'), _message('4')],
              endToken: 'token-1',
            )
          : MessagesPageEntity(
              messages: [_message('1'), _message('2'), _message('3')],
              endToken: null,
            );

      await viewModel().loadMessages(roomId: _roomId);
      await viewModel().loadMoreMessages();

      expect(repository.getMessagesCalls.last.roomId, _roomId);
      expect(repository.getMessagesCalls.last.fromToken, 'token-1');
      expect(messageIds(), ['1', '2', '3', '4']);
    });

    test('follows the next token until history ends', () async {
      final pages = {
        null: MessagesPageEntity(messages: [_message('3')], endToken: 't1'),
        't1': MessagesPageEntity(messages: [_message('2')], endToken: 't2'),
        't2': MessagesPageEntity(messages: [_message('1')], endToken: null),
      };
      repository.onGetMessages = (call) async => pages[call.fromToken]!;

      await viewModel().loadMessages(roomId: _roomId);
      await viewModel().loadMoreMessages();
      await viewModel().loadMoreMessages();
      await viewModel().loadMoreMessages();

      expect(repository.getMessagesCalls.map((call) => call.fromToken), [
        null,
        't1',
        't2',
      ]);
      expect(messageIds(), ['1', '2', '3']);
    });

    test('ignores concurrent calls while loading', () async {
      final olderPage = Completer<MessagesPageEntity>();
      repository.onGetMessages = (call) => call.fromToken == null
          ? Future.value(
              MessagesPageEntity(messages: [_message('2')], endToken: 't1'),
            )
          : olderPage.future;

      await viewModel().loadMessages(roomId: _roomId);

      final first = viewModel().loadMoreMessages();
      await viewModel().loadMoreMessages();

      olderPage.complete(
        MessagesPageEntity(messages: [_message('1')], endToken: null),
      );
      await first;

      expect(repository.getMessagesCalls, hasLength(2));
      expect(messageIds(), ['1', '2']);
    });

    test('keeps messages, exposes the error and allows retry', () async {
      var failOlderPage = true;
      repository.onGetMessages = (call) async {
        if (call.fromToken == null) {
          return MessagesPageEntity(messages: [_message('2')], endToken: 't1');
        }
        if (failOlderPage) {
          throw Exception('history failed');
        }
        return MessagesPageEntity(messages: [_message('1')], endToken: null);
      };

      await viewModel().loadMessages(roomId: _roomId);
      await viewModel().loadMoreMessages();

      expect(
        container.read(messagesViewModelProvider).error,
        'Exception: history failed',
      );
      expect(messageIds(), ['2']);

      failOlderPage = false;
      await viewModel().loadMoreMessages();

      expect(messageIds(), ['1', '2']);
    });
  });
}
