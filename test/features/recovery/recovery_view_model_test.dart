import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/recovery/domain/repositories/recovery_repository.dart';
import 'package:nexa_messaging_desktop/features/recovery/presentation/recovery_providers.dart';
import 'package:nexa_messaging_desktop/features/recovery/presentation/viewmodels/recovery_view_model.dart';

class FakeRecoveryRepository implements RecoveryRepository {
  Object? error;
  Completer<void>? completer;
  String? recoveryKey;

  @override
  Future<void> recover({required String recoveryKey}) async {
    this.recoveryKey = recoveryKey;
    if (completer != null) {
      await completer!.future;
    }
    if (error != null) {
      throw error!;
    }
  }
}

void main() {
  late FakeRecoveryRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRecoveryRepository();
    container = ProviderContainer.test(
      overrides: [recoveryRepositoryProvider.overrideWithValue(repository)],
    );
  });

  RecoveryViewModel viewModel() =>
      container.read(recoveryViewModelProvider.notifier);

  test('starts idle', () {
    final state = container.read(recoveryViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.isSuccess, isFalse);
    expect(state.error, isNull);
  });

  test('passes the recovery key and marks success', () async {
    await viewModel().recover(recoveryKey: 'EsTc abcd 1234');

    final state = container.read(recoveryViewModelProvider);
    expect(repository.recoveryKey, 'EsTc abcd 1234');
    expect(state.isLoading, isFalse);
    expect(state.isSuccess, isTrue);
    expect(state.error, isNull);
  });

  test('sets isLoading while recovering', () async {
    repository.completer = Completer<void>();

    final future = viewModel().recover(recoveryKey: 'key');

    final pending = container.read(recoveryViewModelProvider);
    expect(pending.isLoading, isTrue);
    expect(pending.isSuccess, isFalse);

    repository.completer!.complete();
    await future;

    expect(container.read(recoveryViewModelProvider).isLoading, isFalse);
  });

  test('exposes the error on failure', () async {
    repository.error = Exception('invalid key');

    await viewModel().recover(recoveryKey: 'key');

    final state = container.read(recoveryViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.isSuccess, isFalse);
    expect(state.error, 'Exception: invalid key');
  });

  test('clears the error when retrying with success', () async {
    repository.error = Exception('invalid key');
    await viewModel().recover(recoveryKey: 'wrong');

    repository.error = null;
    await viewModel().recover(recoveryKey: 'right');

    final state = container.read(recoveryViewModelProvider);
    expect(state.isSuccess, isTrue);
    expect(state.error, isNull);
  });

  test('resets success when a new attempt fails', () async {
    await viewModel().recover(recoveryKey: 'right');

    repository.error = Exception('invalid key');
    await viewModel().recover(recoveryKey: 'wrong');

    final state = container.read(recoveryViewModelProvider);
    expect(state.isSuccess, isFalse);
    expect(state.error, 'Exception: invalid key');
  });
}
