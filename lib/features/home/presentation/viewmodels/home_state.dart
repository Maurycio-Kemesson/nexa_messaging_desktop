class HomeState {
  const HomeState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  HomeState copyWith({bool? isLoading, String? error}) {
    return HomeState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}
