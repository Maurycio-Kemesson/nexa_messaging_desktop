import '../entities/{{name.snakeCase()}}_entity.dart';

abstract interface class {{name.pascalCase()}}Repository {
  Future<{{name.pascalCase()}}Entity> execute();
}
