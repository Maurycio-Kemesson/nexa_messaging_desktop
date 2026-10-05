import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';

import '../entities/messages_entity.dart';

abstract interface class MessagesRepository {
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  });
  Future<void> sendMessage({required String roomId, required String message});
  Stream<MessageEntity> watchMessages();
}
