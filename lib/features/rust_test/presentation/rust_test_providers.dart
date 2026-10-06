import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/connect_matrix_usecase.dart';

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

final connectMatrixUseCaseProvider = Provider<ConnectMatrixUseCase>((ref) {
  final repository = ref.read(rustTestRepositoryProvider);

  return ConnectMatrixUseCase(repository);
});
