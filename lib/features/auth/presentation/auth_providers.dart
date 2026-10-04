import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nexa_messaging_desktop/features/auth/data/datasources/secure_auth_session_storage.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth_usecase.dart';

final Provider<AuthSessionStorage> authSessionStorageProvider =
    Provider<AuthSessionStorage>((ref) {
      return const SecureAuthSessionStorage();
    });

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      final AuthSessionStorage sessionStorage = ref.read(
        authSessionStorageProvider,
      );

      return AuthRepositoryImpl(sessionStorage);
    });

final Provider<AuthUseCase> authUseCaseProvider = Provider<AuthUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);

  return AuthUseCase(repository);
});
