import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  const AuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSessionEntity> call({
    required String homeserver,
    required String username,
    required String password,
  }) {
    return _repository.login(
      homeserver: homeserver,
      username: username,
      password: password,
    );
  }

  Future<AuthSessionEntity?> getSession() {
    return _repository.getSession();
  }

  Future<void> logout() {
    return _repository.logout();
  }
}
