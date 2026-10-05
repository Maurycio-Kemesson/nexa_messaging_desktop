import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/recovery_repository_impl.dart';
import '../domain/repositories/recovery_repository.dart';
import '../domain/usecases/recovery_usecase.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/recovery_repository_impl.dart';
import '../domain/repositories/recovery_repository.dart';
import '../domain/usecases/recovery_usecase.dart';
import 'viewmodels/recovery_state.dart';
import 'viewmodels/recovery_view_model.dart';

final Provider<RecoveryRepository> recoveryRepositoryProvider =
    Provider<RecoveryRepository>((ref) {
      return const RecoveryRepositoryImpl();
    });

final Provider<RecoveryUseCase> recoveryUseCaseProvider =
    Provider<RecoveryUseCase>((ref) {
      final repository = ref.read(recoveryRepositoryProvider);

      return RecoveryUseCase(repository);
    });

final recoveryViewModelProvider =
    NotifierProvider<RecoveryViewModel, RecoveryState>(RecoveryViewModel.new);
