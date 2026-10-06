import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/recovery/presentation/viewmodels/recovery_state.dart';

void main() {
  group('RecoveryState', () {
    test('has sensible defaults', () {
      const state = RecoveryState();

      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith overrides the given fields', () {
      const state = RecoveryState();

      final copy = state.copyWith(
        isLoading: true,
        isSuccess: true,
        error: 'error',
      );

      expect(copy.isLoading, isTrue);
      expect(copy.isSuccess, isTrue);
      expect(copy.error, 'error');
    });

    test('copyWith keeps flags and clears error when they are omitted', () {
      const state = RecoveryState(
        isLoading: true,
        isSuccess: true,
        error: 'error',
      );

      final copy = state.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.isSuccess, isTrue);
      expect(copy.error, isNull);
    });
  });
}
