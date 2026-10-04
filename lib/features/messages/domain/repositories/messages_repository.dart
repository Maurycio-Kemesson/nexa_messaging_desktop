import '../entities/messages_entity.dart';

abstract interface class MessagesRepository {
  Future<List<MessageEntity>> getMessages({required String roomId});
}
