import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/usecases/auth_usecase.dart';

const AuthSessionEntity _session = AuthSessionEntity(
  homeserver: 'https://matrix.org',
  userId: '@user:matrix.org',
  deviceId: 'DEVICE',
  accessToken: 'token',
);

class FakeAuthRepository implements AuthRepository {
  String? homeserver;
  String? username;
  String? password;
  int getSessionCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    this.homeserver = homeserver;
    this.username = username;
    this.password = password;
    return _session;
  }

  @override
  Future<AuthSessionEntity?> getSession() async {
    getSessionCalls++;
    return _session;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

void main() {
  late FakeAuthRepository repository;
  late AuthUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = AuthUseCase(repository);
  });

  group('AuthUseCase', () {
    test('call delegates login to the repository', () async {
      final result = await useCase(
        homeserver: 'https://matrix.org',
        username: 'user',
        password: 'secret',
      );

      expect(result, same(_session));
      expect(repository.homeserver, 'https://matrix.org');
      expect(repository.username, 'user');
      expect(repository.password, 'secret');
    });

    test('getSession delegates to the repository', () async {
      final result = await useCase.getSession();

      expect(result, same(_session));
      expect(repository.getSessionCalls, 1);
    });

    test('logout delegates to the repository', () async {
      await useCase.logout();

      expect(repository.logoutCalls, 1);
    });
  });
}
