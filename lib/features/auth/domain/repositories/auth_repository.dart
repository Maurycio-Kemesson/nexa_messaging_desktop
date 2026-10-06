import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';

abstract interface class AuthRepository {
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  });

  Future<AuthSessionEntity?> getSession();

  Future<void> logout();
}
