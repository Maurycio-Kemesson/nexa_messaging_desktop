import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/messages_providers.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/views/messages_view.dart';

const _roomId = '!room:matrix.org';

MessageEntity _message(String id, String content) {
  return MessageEntity(
    id: id,
    roomId: _roomId,
    sender: '@alice:matrix.org',
    content: content,
    timestamp: DateTime(2026, 1, 1),
  );
}

class FakeMessagesRepository implements MessagesRepository {
  final StreamController<MessageEntity> updates =
      StreamController<MessageEntity>.broadcast();

  List<MessageEntity> messages = [];
  bool failOnSend = false;
  final List<String> sentMessages = [];

  @override
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  }) async {
    return MessagesPageEntity(messages: messages, endToken: null);
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String message,
  }) async {
    if (failOnSend) {
      throw Exception('send failed');
    }

    sentMessages.add(message);
    messages = [...messages, _message('${messages.length}', message)];
  }

  @override
  Stream<MessageEntity> watchMessages() => updates.stream;

  Future<void> dispose() => updates.close();
}

void main() {
  late FakeMessagesRepository repository;

  setUp(() => repository = FakeMessagesRepository());

  tearDown(() => repository.dispose());

  Future<void> pumpMessagesView(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MessagesView(roomId: _roomId, roomName: 'General'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state for a room without messages', (
    tester,
  ) async {
    await pumpMessagesView(tester);

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Nenhuma mensagem encontrada.'), findsOneWidget);
  });

  testWidgets('shows the room history and real-time messages', (tester) async {
    repository.messages = [_message('1', 'Olá')];
    await pumpMessagesView(tester);

    expect(find.text('Olá'), findsOneWidget);

    repository.updates.add(_message('2', 'Tudo bem?'));
    await tester.pumpAndSettle();

    expect(find.text('Tudo bem?'), findsOneWidget);
  });

  testWidgets('sends the message and clears the composer', (tester) async {
    await pumpMessagesView(tester);

    await send(tester, 'Primeira mensagem');

    expect(repository.sentMessages, ['Primeira mensagem']);
    expect(find.text('Primeira mensagem'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('keeps the text in the composer when sending fails', (
    tester,
  ) async {
    repository.failOnSend = true;
    await pumpMessagesView(tester);

    await send(tester, 'Não enviada');

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Não enviada',
    );
  });
}
