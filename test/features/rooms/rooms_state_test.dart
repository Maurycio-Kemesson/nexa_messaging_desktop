import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/viewmodels/rooms_state.dart';

void main() {
  const room = RoomEntity(id: '!room:matrix.org', name: 'Room');

  group('RoomsState', () {
    test('has sensible defaults', () {
      const state = RoomsState();

      expect(state.isLoading, isFalse);
      expect(state.rooms, isEmpty);
      expect(state.selectedRoom, isNull);
      expect(state.error, isNull);
    });

    group('isEmpty', () {
      test('is true when idle without rooms and error', () {
        expect(const RoomsState().isEmpty, isTrue);
      });

      test('is false while loading', () {
        expect(const RoomsState(isLoading: true).isEmpty, isFalse);
      });

      test('is false when there are rooms', () {
        expect(const RoomsState(rooms: [room]).isEmpty, isFalse);
      });

      test('is false when there is an error', () {
        expect(const RoomsState(error: 'error').isEmpty, isFalse);
      });
    });

    test('copyWith keeps every field when nothing is passed', () {
      const state = RoomsState(
        isLoading: true,
        rooms: [room],
        selectedRoom: room,
        error: 'error',
      );

      final copy = state.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.rooms, [room]);
      expect(copy.selectedRoom, room);
      expect(copy.error, 'error');
    });

    test('copyWith overrides the given fields', () {
      const state = RoomsState();

      final copy = state.copyWith(
        isLoading: true,
        rooms: [room],
        selectedRoom: room,
        error: 'error',
      );

      expect(copy.isLoading, isTrue);
      expect(copy.rooms, [room]);
      expect(copy.selectedRoom, room);
      expect(copy.error, 'error');
    });

    test('copyWith clears selectedRoom and error when null is passed', () {
      const state = RoomsState(selectedRoom: room, error: 'error');

      final copy = state.copyWith(selectedRoom: null, error: null);

      expect(copy.selectedRoom, isNull);
      expect(copy.error, isNull);
    });
  });
}
