import '../../domain/entities/messages_entity.dart';

class MessagesState {
  final bool isLoading;
  final bool isSending;
  final List<MessageEntity> messages;
  final String? error;

  const MessagesState({
    this.isLoading = false,
    this.isSending = false,
    this.messages = const [],
    this.error,
  });

  bool get isEmpty => !isLoading && messages.isEmpty && error == null;

  MessagesState copyWith({
    bool? isLoading,
    bool? isSending,
    List<MessageEntity>? messages,
    Object? error = _noChange,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }

  static const _noChange = Object();
}
