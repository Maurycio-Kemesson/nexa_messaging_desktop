import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/auth_usecase.dart';
import '../auth_providers.dart';
import 'auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final AuthState authState = ref.watch(authViewModelProvider);

  return authState.session != null;
});

class AuthViewModel extends Notifier<AuthState> {
  late final AuthUseCase _authUseCase;

  @override
  AuthState build() {
    _authUseCase = ref.read(authUseCaseProvider);

    Future.microtask(_restoreSession);

    return const AuthState();
  }

  Future<void> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _authUseCase.call(
        homeserver: homeserver,
        username: username,
        password: password,
      );

      state = state.copyWith(isLoading: false, session: session);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> _restoreSession() async {
    debugPrint('AUTH: iniciando restauração da sessão');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _authUseCase.getSession();

      debugPrint('AUTH: sessão encontrada? ${session != null}');

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        session: session,
      );

      debugPrint('AUTH: estado inicializado: ${state.isInitialized}');
    } catch (error) {
      debugPrint('AUTH: erro ao restaurar sessão: $error');

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authUseCase.logout();

      state = state.copyWith(isLoading: false, session: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}
