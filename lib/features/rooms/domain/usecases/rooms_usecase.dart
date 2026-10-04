import '../entities/rooms_entity.dart';
import '../repositories/rooms_repository.dart';

class RoomsUseCase {
  final RoomsRepository _repository;
  const RoomsUseCase(this._repository);
  Future<List<RoomEntity>> call() {
    return _repository.getRooms();
  }
}
