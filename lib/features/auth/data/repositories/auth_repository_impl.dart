import 'package:nexa_messaging_desktop/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/src/rust/api/client.dart' as rust_api;
import 'package:nexa_messaging_desktop/src/rust/api/matrix.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthSessionStorage _sessionStorage;

  const AuthRepositoryImpl(this._sessionStorage);

  @override
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    final AuthSession session = await rust_api.loginMatrix(
      homeserver: homeserver,
      username: username,
      password: password,
    );

    final AuthSessionEntity entity = AuthSessionEntity(
      homeserver: homeserver,
      userId: session.userId,
      deviceId: session.deviceId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    await _sessionStorage.save(entity);

    return entity;
  }

  @override
  Future<AuthSessionEntity?> getSession() {
    return _sessionStorage.get();
  }

  @override
  Future<void> logout() {
    return _sessionStorage.clear();
  }
}
