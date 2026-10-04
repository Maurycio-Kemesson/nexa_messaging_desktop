import '../entities/messages_entity.dart';
import '../repositories/messages_repository.dart';

class MessagesUseCase {
  final MessagesRepository _repository;

  const MessagesUseCase(this._repository);

  Future<List<MessageEntity>> call({required String roomId}) {
    return _repository.getMessages(roomId: roomId);
  }
}
