import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/{{name.snakeCase()}}_usecase.dart';
import '../{{name.snakeCase()}}_providers.dart';
import '{{name.snakeCase()}}_state.dart';

final {{name.camelCase()}}ViewModelProvider =
    NotifierProvider<
        {{name.pascalCase()}}ViewModel,
        {{name.pascalCase()}}State>(
  {{name.pascalCase()}}ViewModel.new,
);

class {{name.pascalCase()}}ViewModel
    extends Notifier<{{name.pascalCase()}}State> {
  late final {{name.pascalCase()}}UseCase _useCase;

  @override
  {{name.pascalCase()}}State build() {
    _useCase = ref.read(
      {{name.camelCase()}}UseCaseProvider,
    );

    return const {{name.pascalCase()}}State();
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
