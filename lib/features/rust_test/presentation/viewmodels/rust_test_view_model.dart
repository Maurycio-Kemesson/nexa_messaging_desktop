import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/rust_test_usecase.dart';

import '../rust_test_providers.dart';
import 'rust_test_state.dart';

final rustTestViewModelProvider =
    NotifierProvider<RustTestViewModel, RustTestState>(RustTestViewModel.new);

class RustTestViewModel extends Notifier<RustTestState> {
  late final RustTestUseCase _useCase;

  @override
  RustTestState build() {
    _useCase = ref.read(rustTestUseCaseProvider);

    return const RustTestState();
  }

  void greet() {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = _useCase('Maurycio Kemesson');

      state = state.copyWith(message: message, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}
