import '../../domain/entities/rooms_entity.dart';

class RoomsState {
  final bool isLoading;
  final List<RoomEntity> rooms;
  final RoomEntity? selectedRoom;
  final String? error;

  const RoomsState({
    this.isLoading = false,
    this.rooms = const [],
    this.selectedRoom,
    this.error,
  });

  bool get isEmpty => !isLoading && rooms.isEmpty && error == null;

  RoomsState copyWith({
    bool? isLoading,
    List<RoomEntity>? rooms,
    Object? selectedRoom = _noChange,
    Object? error = _noChange,
  }) {
    return RoomsState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      selectedRoom: identical(selectedRoom, _noChange)
          ? this.selectedRoom
          : selectedRoom as RoomEntity?,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }

  static const _noChange = Object();
}
