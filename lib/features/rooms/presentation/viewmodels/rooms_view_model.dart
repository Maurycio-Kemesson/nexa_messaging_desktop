import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';

import '../../domain/usecases/rooms_usecase.dart';
import '../rooms_providers.dart';
import 'rooms_state.dart';

final NotifierProvider<RoomsViewModel, RoomsState> roomsViewModelProvider =
    NotifierProvider<RoomsViewModel, RoomsState>(RoomsViewModel.new);

class RoomsViewModel extends Notifier<RoomsState> {
  late final RoomsUseCase _roomsUseCase;

  @override
  RoomsState build() {
    _roomsUseCase = ref.read(roomsUseCaseProvider);

    return const RoomsState();
  }

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final List<RoomEntity> rooms = await _roomsUseCase.call();

      state = state.copyWith(isLoading: false, rooms: rooms);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void selectRoom(RoomEntity room) {
    state = state.copyWith(selectedRoom: room);
  }
}
