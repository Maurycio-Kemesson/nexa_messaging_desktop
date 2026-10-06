import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/usecases/rooms_usecase.dart';

const _rooms = [RoomEntity(id: '!room:matrix.org', name: 'Room')];

class FakeRoomsRepository implements RoomsRepository {
  @override
  Future<List<RoomEntity>> getRooms() async => _rooms;
}

void main() {
  test('RoomsUseCase returns the rooms from the repository', () async {
    final useCase = RoomsUseCase(FakeRoomsRepository());

    expect(await useCase(), same(_rooms));
  });
}
