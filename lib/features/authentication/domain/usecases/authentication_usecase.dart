import '../entities/authentication_entity.dart';
import '../repositories/authentication_repository.dart';

class AuthenticationUseCase {
  const AuthenticationUseCase(
    this._repository,
  );

  final AuthenticationRepository _repository;

  Future<AuthenticationEntity> call() {
    return _repository.execute();
  }
}
