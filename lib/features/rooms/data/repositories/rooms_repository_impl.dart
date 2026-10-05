import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nexa_messaging_desktop/src/rust/api/rooms.dart' as rust_api;

class RoomsRepositoryImpl implements RoomsRepository {
  const RoomsRepositoryImpl();

  @override
  Future<List<RoomEntity>> getRooms() async {
    final List<rust_api.RoomSummary> rooms = await rust_api.getRooms();

    return rooms
        .map((room) => RoomEntity(id: room.id, name: room.name))
        .toList();
  }
}
