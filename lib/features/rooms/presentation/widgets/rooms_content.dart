import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao carregar salas:\n${state.error}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }
    if (state.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma sala encontrada.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: state.rooms.length,
      itemBuilder: (context, index) {
        final RoomEntity room = state.rooms[index];
        final bool selected = state.selectedRoom?.id == room.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: selected ? AppColors.navyElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ref.read(roomsViewModelProvider.notifier).selectRoom(room);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: selected ? AppColors.lime : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.22),
                      child: Text(
                        _roomInitials(room.name),
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: selected
                                      ? AppColors.lime
                                      : AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            room.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _roomInitials(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }

  final List<String> parts = trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  return trimmed[0].toUpperCase();
}
