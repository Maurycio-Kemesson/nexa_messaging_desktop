import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_state.dart';

void main() {
  const AuthSessionEntity session = AuthSessionEntity(
    homeserver: 'https://matrix.org',
    userId: '@user:matrix.org',
    deviceId: 'DEVICE',
    accessToken: 'token',
  );

  group('AuthState', () {
    test('has sensible defaults', () {
      const state = AuthState();

      expect(state.isLoading, isFalse);
      expect(state.isInitialized, isFalse);
      expect(state.session, isNull);
      expect(state.error, isNull);
    });

    test('copyWith keeps every field when nothing is passed', () {
      const state = AuthState(
        isLoading: true,
        isInitialized: true,
        session: session,
        error: 'error',
      );

      final copy = state.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.isInitialized, isTrue);
      expect(copy.session, same(session));
      expect(copy.error, 'error');
    });

    test('copyWith overrides the given fields', () {
      const state = AuthState();

      final copy = state.copyWith(
        isLoading: true,
        isInitialized: true,
        session: session,
        error: 'error',
      );

      expect(copy.isLoading, isTrue);
      expect(copy.isInitialized, isTrue);
      expect(copy.session, same(session));
      expect(copy.error, 'error');
    });

    test('copyWith clears session and error when null is passed', () {
      const state = AuthState(session: session, error: 'error');

      final copy = state.copyWith(session: null, error: null);

      expect(copy.session, isNull);
      expect(copy.error, isNull);
    });
  });
}
