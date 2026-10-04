import '../repositories/rust_test_repository.dart';

class ConnectMatrixUseCase {
  const ConnectMatrixUseCase(this._repository);

  final RustTestRepository _repository;

  Future<String> call() {
    return _repository.connectMatrix();
  }
}
