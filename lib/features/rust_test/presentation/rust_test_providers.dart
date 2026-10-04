import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/rust_test_repository_impl.dart';
import '../domain/repositories/rust_test_repository.dart';
import '../domain/usecases/rust_test_usecase.dart';

final rustTestRepositoryProvider = Provider<RustTestRepository>((ref) {
  return const RustTestRepositoryImpl();
});

final rustTestUseCaseProvider = Provider<RustTestUseCase>((ref) {
  final repository = ref.read(rustTestRepositoryProvider);

  return RustTestUseCase(repository);
});
