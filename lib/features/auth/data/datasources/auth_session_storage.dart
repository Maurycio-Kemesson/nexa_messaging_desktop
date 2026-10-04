import '../../domain/entities/auth_session_entity.dart';

abstract interface class AuthSessionStorage {
  Future<void> save(AuthSessionEntity session);

  Future<AuthSessionEntity?> get();

  Future<void> clear();
}
