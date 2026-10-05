import 'package:flutter/foundation.dart';
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

    rust_api.startMatrixSync();

    return entity;
  }

  @override
  Future<AuthSessionEntity?> getSession() async {
    final AuthSessionEntity? session = await _sessionStorage.get();

    if (session == null) {
      return null;
    }

    await rust_api.restoreMatrixSession(
      homeserver: session.homeserver,
      userId: session.userId,
      deviceId: session.deviceId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    final backup = await rust_api.checkMatrixBackup();

    debugPrint('BACKUP MATRIX: $backup');

    rust_api.startMatrixSync();

    return session;
  }

  @override
  Future<void> logout() {
    return _sessionStorage.clear();
  }
}
