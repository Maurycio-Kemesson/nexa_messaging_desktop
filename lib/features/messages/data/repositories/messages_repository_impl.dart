import 'package:flutter/material.dart';
import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_page_entity.dart';
import 'package:nexa_messaging_desktop/src/rust/api/rooms.dart' as rust_api;

import '../../domain/entities/messages_entity.dart';
import '../../domain/repositories/messages_repository.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  const MessagesRepositoryImpl();

  @override
  Future<MessagesPageEntity> getMessages({
    required String roomId,
    String? fromToken,
  }) async {
    final rust_api.MessagesPage page = await rust_api.getMessages(
      roomId: roomId,
      fromToken: fromToken,
    );

    debugPrint('REPOSITORY: page.messages=${page.messages.length}');

    final messages = page.messages
        .map(
          (message) => MessageEntity(
            id: message.id,
            roomId: message.roomId,
            sender: message.sender,
            content: message.content,
            timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
          ),
        )
        .toList();

    debugPrint('REPOSITORY: mensagens convertidas=${messages.length}');

    return MessagesPageEntity(messages: messages, endToken: page.endToken);
  }

  @override
  Future<void> sendMessage({required String roomId, required String message}) {
    return rust_api.sendMessage(roomId: roomId, message: message);
  }

  @override
  Stream<MessageEntity> watchMessages() {
    return rust_api.subscribeToMessages().map(
      (message) => MessageEntity(
        id: message.id,
        roomId: message.roomId,
        sender: message.sender,
        content: message.content,
        timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
      ),
    );
  }
}
