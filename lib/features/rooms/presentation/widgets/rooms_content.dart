import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/entities/rooms_entity.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/viewmodels/rooms_state.dart';

import '../viewmodels/rooms_view_model.dart';

class RoomsContent extends ConsumerWidget {
  const RoomsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoomsState state = ref.watch(roomsViewModelProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Text(
          'Erro ao carregar salas:\n${state.error}',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.isEmpty) {
      return const Center(
        child: Text('Nenhuma sala encontrada.', textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      itemCount: state.rooms.length,
      itemBuilder: (context, index) {
        final RoomEntity room = state.rooms[index];
        return ListTile(
          title: Text(room.name),
          subtitle: Text(room.id),
          selected: state.selectedRoom?.id == room.id,
          onTap: () {
            ref.read(roomsViewModelProvider.notifier).selectRoom(room);
          },
        );
      },
    );
  }
}
