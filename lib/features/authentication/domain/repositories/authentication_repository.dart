import '../entities/authentication_entity.dart';

abstract interface class AuthenticationRepository {
  Future<AuthenticationEntity> execute();
}
