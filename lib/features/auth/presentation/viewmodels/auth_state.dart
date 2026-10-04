import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.session,
    this.error,
  });

  final bool isLoading;
  final bool isInitialized;
  final AuthSessionEntity? session;
  final String? error;

  static const _noChange = Object();

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    Object? session = _noChange,
    Object? error = _noChange,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      session: identical(session, _noChange)
          ? this.session
          : session as AuthSessionEntity?,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }
}
