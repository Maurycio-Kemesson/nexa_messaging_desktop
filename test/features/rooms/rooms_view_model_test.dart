import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/rooms_providers.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/viewmodels/rooms_view_model.dart';

const _general = RoomEntity(id: '!general:matrix.org', name: 'General');
const _random = RoomEntity(id: '!random:matrix.org', name: 'Random');

class FakeRoomsRepository implements RoomsRepository {
  List<RoomEntity> rooms = const [_general, _random];
  Object? error;
  Completer<void>? completer;
  int calls = 0;

  @override
  Future<List<RoomEntity>> getRooms() async {
    calls++;
    if (completer != null) {
      await completer!.future;
    }
    if (error != null) {
      throw error!;
    }
    return rooms;
  }
}

void main() {
  late FakeRoomsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRoomsRepository();
    container = ProviderContainer.test(
      overrides: [
        roomsRepositoryProvider.overrideWithValue(repository),
        currentSessionProvider.overrideWithValue(null),
      ],
    );
  });

  RoomsViewModel viewModel() => container.read(roomsViewModelProvider.notifier);

  test('starts with an empty state without loading rooms', () {
    final state = container.read(roomsViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.rooms, isEmpty);
    expect(state.selectedRoom, isNull);
    expect(state.error, isNull);
    expect(repository.calls, 0);
  });

  group('loadRooms', () {
    test('loads the rooms', () async {
      await viewModel().loadRooms();

      final state = container.read(roomsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.rooms, [_general, _random]);
      expect(state.error, isNull);
    });

    test('sets isLoading while the request is pending', () async {
      repository.completer = Completer<void>();

      final future = viewModel().loadRooms();

      expect(container.read(roomsViewModelProvider).isLoading, isTrue);

      repository.completer!.complete();
      await future;

      expect(container.read(roomsViewModelProvider).isLoading, isFalse);
    });

    test('marks the state as empty when there are no rooms', () async {
      repository.rooms = const [];

      await viewModel().loadRooms();

      expect(container.read(roomsViewModelProvider).isEmpty, isTrue);
    });

    test('exposes the error on failure', () async {
      repository.error = Exception('network');

      await viewModel().loadRooms();

      final state = container.read(roomsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.rooms, isEmpty);
      expect(state.error, 'Exception: network');
      expect(state.isEmpty, isFalse);
    });

    test('clears a previous error when retrying', () async {
      repository.error = Exception('network');
      await viewModel().loadRooms();

      repository.error = null;
      await viewModel().loadRooms();

      final state = container.read(roomsViewModelProvider);
      expect(state.error, isNull);
      expect(state.rooms, [_general, _random]);
    });

    test('keeps the selected room after reloading', () async {
      await viewModel().loadRooms();
      viewModel().selectRoom(_random);

      await viewModel().loadRooms();

      expect(container.read(roomsViewModelProvider).selectedRoom, _random);
    });
  });

  group('selectRoom', () {
    test('selects the room keeping the list', () async {
      await viewModel().loadRooms();

      viewModel().selectRoom(_general);

      final state = container.read(roomsViewModelProvider);
      expect(state.selectedRoom, _general);
      expect(state.rooms, [_general, _random]);
    });

    test('replaces the previous selection', () {
      viewModel()
        ..selectRoom(_general)
        ..selectRoom(_random);

      expect(container.read(roomsViewModelProvider).selectedRoom, _random);
    });
  });
}
