import '../repositories/rust_test_repository.dart';

class RustTestUseCase {
  const RustTestUseCase(this._repository);

  final RustTestRepository _repository;

  String call(String name) {
    return _repository.greet(name);
  }
}
