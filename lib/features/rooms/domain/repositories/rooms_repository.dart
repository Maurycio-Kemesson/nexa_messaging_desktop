import '../entities/rooms_entity.dart';

abstract interface class RoomsRepository {
  Future<List<RoomEntity>> getRooms();
}
