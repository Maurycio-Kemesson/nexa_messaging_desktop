import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/authentication_usecase.dart';
import '../authentication_providers.dart';
import 'authentication_state.dart';

final authenticationViewModelProvider =
    NotifierProvider<
        AuthenticationViewModel,
        AuthenticationState>(
  AuthenticationViewModel.new,
);

class AuthenticationViewModel
    extends Notifier<AuthenticationState> {
  late final AuthenticationUseCase _useCase;

  @override
  AuthenticationState build() {
    _useCase = ref.read(
      authenticationUseCaseProvider,
    );

    return const AuthenticationState();
  }

  Future<void> execute() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _useCase();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
