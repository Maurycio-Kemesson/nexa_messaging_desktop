import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/recovery_usecase.dart';
import '../recovery_providers.dart';
import 'recovery_state.dart';

class RecoveryViewModel extends Notifier<RecoveryState> {
  late final RecoveryUseCase _recoveryUseCase;

  @override
  RecoveryState build() {
    _recoveryUseCase = ref.read(recoveryUseCaseProvider);

    return const RecoveryState();
  }

  Future<void> recover({required String recoveryKey}) async {
    state = state.copyWith(isLoading: true, isSuccess: false, error: null);

    try {
      await _recoveryUseCase(recoveryKey: recoveryKey);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}
