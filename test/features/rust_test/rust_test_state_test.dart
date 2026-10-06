import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/rust_test/presentation/viewmodels/rust_test_state.dart';

void main() {
  group('RustTestState', () {
    test('has sensible defaults', () {
      const state = RustTestState();

      expect(state.message, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith overrides the given fields', () {
      final copy = const RustTestState().copyWith(
        message: 'hello',
        isLoading: true,
        error: 'error',
      );

      expect(copy.message, 'hello');
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'error');
    });

    test('copyWith keeps message and isLoading and clears error when omitted',
        () {
      const state = RustTestState(
        message: 'hello',
        isLoading: true,
        error: 'error',
      );

      final copy = state.copyWith();

      expect(copy.message, 'hello');
      expect(copy.isLoading, isTrue);
      expect(copy.error, isNull);
    });
  });
}
