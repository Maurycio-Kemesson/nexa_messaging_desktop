import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session_entity.dart';
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

final currentSessionProvider = Provider<AuthSessionEntity?>((ref) {
  return ref.watch(authViewModelProvider.select((state) => state.session));
});

class AuthViewModel extends Notifier<AuthState> {
  AuthUseCase get _authUseCase => ref.read(authUseCaseProvider);

  @override
  AuthState build() {
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _authUseCase.getSession();

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        session: session,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: error.toString(),
      );
    }
  }

  /// A sessão local é sempre encerrada. Uma falha ao revogar a sessão no
  /// homeserver é exposta em [AuthState.error].
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authUseCase.logout();

      state = state.copyWith(isLoading: false, session: null);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        session: null,
        error: error.toString(),
      );
    }
  }
}
