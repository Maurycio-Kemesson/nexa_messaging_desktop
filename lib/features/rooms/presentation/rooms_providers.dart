import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexa_messaging_desktop/features/rooms/data/repositories/rooms_repository_impl.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/repositories/rooms_repository.dart';
import 'package:nexa_messaging_desktop/features/rooms/domain/usecases/rooms_usecase.dart';

final Provider<RoomsRepository> roomsRepositoryProvider =
    Provider<RoomsRepository>((ref) {
      return const RoomsRepositoryImpl();
    });

final Provider<RoomsUseCase> roomsUseCaseProvider = Provider<RoomsUseCase>((
  ref,
) {
  final RoomsRepository repository = ref.read(roomsRepositoryProvider);

  return RoomsUseCase(repository);
});
