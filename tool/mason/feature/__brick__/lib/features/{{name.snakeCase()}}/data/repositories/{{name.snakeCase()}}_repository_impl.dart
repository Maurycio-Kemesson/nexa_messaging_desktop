import '../../domain/entities/{{name.snakeCase()}}_entity.dart';
import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';

class {{name.pascalCase()}}RepositoryImpl
    implements {{name.pascalCase()}}Repository {
  const {{name.pascalCase()}}RepositoryImpl();

  @override
  Future<{{name.pascalCase()}}Entity> execute() async {
    throw UnimplementedError();
  }
}
