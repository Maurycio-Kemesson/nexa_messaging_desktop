class RustTestState {
  const RustTestState({this.message = '', this.isLoading = false, this.error});

  final String message;
  final bool isLoading;
  final String? error;

  RustTestState copyWith({String? message, bool? isLoading, String? error}) {
    return RustTestState(
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
