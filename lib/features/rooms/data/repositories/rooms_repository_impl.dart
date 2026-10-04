import 'package:nexa_messaging_desktop/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nexa_messaging_desktop/src/rust/api/client.dart'
    as rust_client_api;
import 'package:nexa_messaging_desktop/src/rust/api/rooms.dart' as rust_api;

class RoomsRepositoryImpl implements RoomsRepository {
  const RoomsRepositoryImpl(this._sessionStorage);

  final AuthSessionStorage _sessionStorage;

  @override
  Future<List<RoomEntity>> getRooms() async {
    final AuthSessionEntity? session = await _sessionStorage.get();

    if (session == null) {
      throw Exception('Authenticated session not found');
    }

    await rust_client_api.restoreMatrixSession(
      homeserver: session.homeserver,
      userId: session.userId,
      deviceId: session.deviceId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    final List<rust_api.RoomSummary> rooms = await rust_api.getRooms();
    return rooms
        .map((room) => RoomEntity(id: room.id, name: room.name))
        .toList();
  }
}
