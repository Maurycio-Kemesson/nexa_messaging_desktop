import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/home/presentation/viewmodels/home_state.dart';

void main() {
  group('HomeState', () {
    test('has sensible defaults', () {
      const state = HomeState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith overrides the given fields', () {
      final copy = const HomeState().copyWith(isLoading: true, error: 'error');

      expect(copy.isLoading, isTrue);
      expect(copy.error, 'error');
    });

    test('copyWith keeps isLoading and clears error when omitted', () {
      const state = HomeState(isLoading: true, error: 'error');

      final copy = state.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.error, isNull);
    });
  });
}
