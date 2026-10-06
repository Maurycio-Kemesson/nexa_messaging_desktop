import '../entities/messages_entity.dart';
import '../entities/messages_page_entity.dart';
import '../repositories/messages_repository.dart';

class MessagesUseCase {
  final MessagesRepository _repository;

  const MessagesUseCase(this._repository);

  Future<MessagesPageEntity> call({required String roomId, String? fromToken}) {
    return _repository.getMessages(roomId: roomId, fromToken: fromToken);
  }

  Future<void> sendMessage({required String roomId, required String message}) {
    return _repository.sendMessage(roomId: roomId, message: message);
  }

  Stream<MessageEntity> watchMessages() {
    return _repository.watchMessages();
  }
}
