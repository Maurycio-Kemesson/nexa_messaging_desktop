import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/rust_test/domain/repositories/rust_test_repository.dart';
import 'package:nexa_messaging_desktop/features/rust_test/presentation/rust_test_providers.dart';
import 'package:nexa_messaging_desktop/features/rust_test/presentation/viewmodels/rust_test_view_model.dart';

class FakeRustTestRepository implements RustTestRepository {
  Object? greetError;
  Object? connectError;
  Completer<void>? connectCompleter;
  String? greetedName;

  @override
  String greet(String name) {
    greetedName = name;
    if (greetError != null) {
      throw greetError!;
    }
    return 'Hello, $name!';
  }

  @override
  Future<String> connectMatrix() async {
    if (connectCompleter != null) {
      await connectCompleter!.future;
    }
    if (connectError != null) {
      throw connectError!;
    }
    return 'https://matrix.org';
  }
}

void main() {
  late FakeRustTestRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRustTestRepository();
    container = ProviderContainer.test(
      overrides: [rustTestRepositoryProvider.overrideWithValue(repository)],
    );
  });

  RustTestViewModel viewModel() =>
      container.read(rustTestViewModelProvider.notifier);

  test('starts idle', () {
    final state = container.read(rustTestViewModelProvider);

    expect(state.message, isEmpty);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  group('greet', () {
    test('shows the greeting from Rust', () {
      viewModel().greet();

      final state = container.read(rustTestViewModelProvider);
      expect(repository.greetedName, 'Maurycio');
      expect(state.message, 'Hello, Maurycio!');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('exposes the error on failure', () {
      repository.greetError = Exception('ffi failure');

      viewModel().greet();

      final state = container.read(rustTestViewModelProvider);
      expect(state.message, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, 'Exception: ffi failure');
    });
  });

  group('connectMatrix', () {
    test('shows the homeserver', () async {
      await viewModel().connectMatrix();

      final state = container.read(rustTestViewModelProvider);
      expect(state.message, 'Homeserver: https://matrix.org');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('sets isLoading while connecting', () async {
      repository.connectCompleter = Completer<void>();

      final future = viewModel().connectMatrix();

      expect(container.read(rustTestViewModelProvider).isLoading, isTrue);

      repository.connectCompleter!.complete();
      await future;

      expect(container.read(rustTestViewModelProvider).isLoading, isFalse);
    });

    test('keeps the previous message and exposes the error on failure',
        () async {
      viewModel().greet();
      repository.connectError = Exception('unreachable');

      await viewModel().connectMatrix();

      final state = container.read(rustTestViewModelProvider);
      expect(state.message, 'Hello, Maurycio!');
      expect(state.isLoading, isFalse);
      expect(state.error, 'Exception: unreachable');
    });
  });
}
