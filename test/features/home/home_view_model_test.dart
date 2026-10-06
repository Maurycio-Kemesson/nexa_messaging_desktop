import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/home/domain/entities/home_entity.dart';
import 'package:nexa_messaging_desktop/features/home/domain/repositories/home_repository.dart';
import 'package:nexa_messaging_desktop/features/home/presentation/home_providers.dart';
import 'package:nexa_messaging_desktop/features/home/presentation/viewmodels/home_view_model.dart';

class FakeHomeRepository implements HomeRepository {
  Object? error;
  Completer<void>? completer;
  int calls = 0;

  @override
  Future<HomeEntity> execute() async {
    calls++;
    if (completer != null) {
      await completer!.future;
    }
    if (error != null) {
      throw error!;
    }
    return const HomeEntity(id: 'home');
  }
}

void main() {
  late FakeHomeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeHomeRepository();
    container = ProviderContainer.test(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
  });

  HomeViewModel viewModel() => container.read(homeViewModelProvider.notifier);

  test('starts idle', () {
    final state = container.read(homeViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('executes the use case', () async {
    await viewModel().execute();

    final state = container.read(homeViewModelProvider);
    expect(repository.calls, 1);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('sets isLoading while executing', () async {
    repository.completer = Completer<void>();

    final future = viewModel().execute();

    expect(container.read(homeViewModelProvider).isLoading, isTrue);

    repository.completer!.complete();
    await future;

    expect(container.read(homeViewModelProvider).isLoading, isFalse);
  });

  test('exposes the error on failure', () async {
    repository.error = Exception('failure');

    await viewModel().execute();

    final state = container.read(homeViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, 'Exception: failure');
  });

  test('clears the error when retrying with success', () async {
    repository.error = Exception('failure');
    await viewModel().execute();

    repository.error = null;
    await viewModel().execute();

    expect(container.read(homeViewModelProvider).error, isNull);
  });
}
