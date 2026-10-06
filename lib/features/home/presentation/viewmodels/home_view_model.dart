import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/home_usecase.dart';
import '../home_providers.dart';
import 'home_state.dart';

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeViewModel extends Notifier<HomeState> {
  HomeUseCase get _useCase => ref.read(homeUseCaseProvider);

  @override
  HomeState build() {
    return const HomeState();
  }

  Future<void> execute() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _useCase();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
