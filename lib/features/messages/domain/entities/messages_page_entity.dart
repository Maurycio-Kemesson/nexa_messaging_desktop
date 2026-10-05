import 'messages_entity.dart';

class MessagesPageEntity {
  const MessagesPageEntity({required this.messages, required this.endToken});

  final List<MessageEntity> messages;
  final String? endToken;
}
