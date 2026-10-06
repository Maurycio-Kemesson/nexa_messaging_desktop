class {{name.pascalCase()}}State {
  const {{name.pascalCase()}}State({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  {{name.pascalCase()}}State copyWith({
    bool? isLoading,
    String? error,
  }) {
    return {{name.pascalCase()}}State(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
