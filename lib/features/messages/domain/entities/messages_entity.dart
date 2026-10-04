class MessageEntity {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;

  const MessageEntity({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });
}
