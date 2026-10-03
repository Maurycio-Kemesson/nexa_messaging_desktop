import '../../domain/entities/authentication_entity.dart';
import '../../domain/repositories/authentication_repository.dart';

class AuthenticationRepositoryImpl
    implements AuthenticationRepository {
  const AuthenticationRepositoryImpl();

  @override
  Future<AuthenticationEntity> execute() async {
    throw UnimplementedError();
  }
}
