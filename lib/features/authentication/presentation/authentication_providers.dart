import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/authentication_repository_impl.dart';
import '../domain/repositories/authentication_repository.dart';
import '../domain/usecases/authentication_usecase.dart';

final authenticationRepositoryProvider =
    Provider<AuthenticationRepository>((ref) {
  return const AuthenticationRepositoryImpl();
});

final authenticationUseCaseProvider =
    Provider<AuthenticationUseCase>((ref) {
  final repository = ref.read(
    authenticationRepositoryProvider,
  );

  return AuthenticationUseCase(
    repository,
  );
});
