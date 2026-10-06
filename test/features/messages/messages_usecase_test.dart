import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/usecases/messages_usecase.dart';

const _page = MessagesPageEntity(messages: [], endToken: 'token');

class FakeMessagesRepository implements MessagesRepository {
  final Stream<MessageEntity> updates = const Stream.empty();

  String? requestedRoomId;
  String? requestedFromToken;
  String? sentRoomId;
  String? sentMessage;

  @override
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  }) async {
    requestedRoomId = roomId;
    requestedFromToken = fromToken;
    return _page;
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String message,
  }) async {
    sentRoomId = roomId;
    sentMessage = message;
  }

  @override
  Stream<MessageEntity> watchMessages() => updates;
}

void main() {
  late FakeMessagesRepository repository;
  late MessagesUseCase useCase;

  setUp(() {
    repository = FakeMessagesRepository();
    useCase = MessagesUseCase(repository);
  });

  group('MessagesUseCase', () {
    test('call delegates getMessages to the repository', () async {
      final result = await useCase(roomId: '!room:matrix.org', fromToken: 't1');

      expect(result, same(_page));
      expect(repository.requestedRoomId, '!room:matrix.org');
      expect(repository.requestedFromToken, 't1');
    });

    test('sendMessage delegates to the repository', () async {
      await useCase.sendMessage(roomId: '!room:matrix.org', message: 'Hi');

      expect(repository.sentRoomId, '!room:matrix.org');
      expect(repository.sentMessage, 'Hi');
    });

    test('watchMessages returns the repository stream', () {
      expect(useCase.watchMessages(), same(repository.updates));
    });
  });
}
