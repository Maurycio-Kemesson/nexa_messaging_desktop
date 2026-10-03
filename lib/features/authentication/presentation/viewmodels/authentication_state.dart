class AuthenticationState {
  const AuthenticationState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  AuthenticationState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AuthenticationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
