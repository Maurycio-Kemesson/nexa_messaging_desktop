import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/connect_matrix_usecase.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/rust_test_usecase.dart';

import '../rust_test_providers.dart';
import 'rust_test_state.dart';

final rustTestViewModelProvider =
    NotifierProvider<RustTestViewModel, RustTestState>(RustTestViewModel.new);

class RustTestViewModel extends Notifier<RustTestState> {
  late final RustTestUseCase _rustTestUseCase;
  late final ConnectMatrixUseCase _connectMatrixUseCase;

  @override
  RustTestState build() {
    _rustTestUseCase = ref.read(rustTestUseCaseProvider);
    _connectMatrixUseCase = ref.read(connectMatrixUseCaseProvider);

    return const RustTestState();
  }

  void greet() {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = _rustTestUseCase('Maurycio');

      state = state.copyWith(message: message, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> connectMatrix() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final homeserver = await _connectMatrixUseCase();

      state = state.copyWith(
        message: 'Homeserver: $homeserver',
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}
