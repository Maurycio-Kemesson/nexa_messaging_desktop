import 'package:nexa_messaging_desktop/src/rust/api/rooms.dart' as rust_api;

import '../../domain/entities/messages_entity.dart';
import '../../domain/repositories/messages_repository.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  const MessagesRepositoryImpl();

  @override
  Future<List<MessageEntity>> getMessages({required String roomId}) async {
    final List<rust_api.MessageSummary> messages = await rust_api.getMessages(
      roomId: roomId,
    );

    return messages
        .map(
          (message) => MessageEntity(
            id: message.id,
            sender: message.sender,
            content: message.content,
            timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
          ),
        )
        .toList();
  }

  @override
  Future<void> sendMessage({required String roomId, required String message}) {
    return rust_api.sendMessage(roomId: roomId, message: message);
  }
}
