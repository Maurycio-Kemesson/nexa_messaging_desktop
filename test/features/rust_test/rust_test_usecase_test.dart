import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/rust_test/domain/repositories/rust_test_repository.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/connect_matrix_usecase.dart';
import 'package:nexa_messaging_desktop/features/rust_test/domain/usecases/rust_test_usecase.dart';

class FakeRustTestRepository implements RustTestRepository {
  @override
  String greet(String name) => 'Hello, $name!';

  @override
  Future<String> connectMatrix() async => 'https://matrix.org';
}

void main() {
  final repository = FakeRustTestRepository();

  test('RustTestUseCase greets through the repository', () {
    expect(RustTestUseCase(repository)('Nexa'), 'Hello, Nexa!');
  });

  test('ConnectMatrixUseCase returns the homeserver', () async {
    expect(await ConnectMatrixUseCase(repository)(), 'https://matrix.org');
  });
}
