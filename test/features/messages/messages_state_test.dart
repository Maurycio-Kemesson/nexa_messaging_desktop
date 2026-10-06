import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/messages/domain/entities/messages_entity.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/viewmodels/messages_state.dart';

void main() {
  final message = MessageEntity(
    id: '1',
    roomId: '!room:matrix.org',
    sender: '@user:matrix.org',
    content: 'Hello',
    timestamp: DateTime(2026, 1, 1),
  );

  group('MessagesState', () {
    test('has sensible defaults', () {
      const state = MessagesState();

      expect(state.isLoading, isFalse);
      expect(state.isSending, isFalse);
      expect(state.messages, isEmpty);
      expect(state.error, isNull);
    });

    group('isEmpty', () {
      test('is true when idle without messages and error', () {
        expect(const MessagesState().isEmpty, isTrue);
      });

      test('is false while loading', () {
        expect(const MessagesState(isLoading: true).isEmpty, isFalse);
      });

      test('is false when there are messages', () {
        expect(MessagesState(messages: [message]).isEmpty, isFalse);
      });

      test('is false when there is an error', () {
        expect(const MessagesState(error: 'error').isEmpty, isFalse);
      });
    });

    test('copyWith keeps every field when nothing is passed', () {
      final state = MessagesState(
        isLoading: true,
        isSending: true,
        messages: [message],
        error: 'error',
      );

      final copy = state.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.isSending, isTrue);
      expect(copy.messages, [message]);
      expect(copy.error, 'error');
    });

    test('copyWith overrides the given fields', () {
      const state = MessagesState();

      final copy = state.copyWith(
        isLoading: true,
        isSending: true,
        messages: [message],
        error: 'error',
      );

      expect(copy.isLoading, isTrue);
      expect(copy.isSending, isTrue);
      expect(copy.messages, [message]);
      expect(copy.error, 'error');
    });

    test('copyWith clears the error when null is passed', () {
      const state = MessagesState(error: 'error');

      expect(state.copyWith(error: null).error, isNull);
    });
  });
}
