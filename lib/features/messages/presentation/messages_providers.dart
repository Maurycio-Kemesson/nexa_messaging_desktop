import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/messages_repository_impl.dart';
import '../domain/repositories/messages_repository.dart';
import '../domain/usecases/messages_usecase.dart';

final Provider<MessagesRepository> messagesRepositoryProvider =
    Provider<MessagesRepository>((ref) {
      return const MessagesRepositoryImpl();
    });

final Provider<MessagesUseCase> messagesUseCaseProvider =
    Provider<MessagesUseCase>((ref) {
      final repository = ref.read(messagesRepositoryProvider);
      return MessagesUseCase(repository);
    });
