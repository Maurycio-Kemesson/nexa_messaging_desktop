import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/{{name.snakeCase()}}_repository_impl.dart';
import '../domain/repositories/{{name.snakeCase()}}_repository.dart';
import '../domain/usecases/{{name.snakeCase()}}_usecase.dart';

final {{name.camelCase()}}RepositoryProvider =
    Provider<{{name.pascalCase()}}Repository>((ref) {
  return const {{name.pascalCase()}}RepositoryImpl();
});

final {{name.camelCase()}}UseCaseProvider =
    Provider<{{name.pascalCase()}}UseCase>((ref) {
  final repository = ref.read(
    {{name.camelCase()}}RepositoryProvider,
  );

  return {{name.pascalCase()}}UseCase(
    repository,
  );
});
