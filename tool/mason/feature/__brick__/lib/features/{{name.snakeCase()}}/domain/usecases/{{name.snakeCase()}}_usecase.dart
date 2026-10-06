import '../entities/{{name.snakeCase()}}_entity.dart';
import '../repositories/{{name.snakeCase()}}_repository.dart';

class {{name.pascalCase()}}UseCase {
  const {{name.pascalCase()}}UseCase(
    this._repository,
  );

  final {{name.pascalCase()}}Repository _repository;

  Future<{{name.pascalCase()}}Entity> call() {
    return _repository.execute();
  }
}
