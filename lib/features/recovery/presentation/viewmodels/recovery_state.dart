class RecoveryState {
  const RecoveryState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? error;

  RecoveryState copyWith({bool? isLoading, bool? isSuccess, String? error}) {
    return RecoveryState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}
