import 'package:nexa_messaging_desktop/src/rust/api/client.dart' as client_api;
import 'package:nexa_messaging_desktop/src/rust/api/simple.dart' as rust_api;

import '../../domain/repositories/rust_test_repository.dart';

class RustTestRepositoryImpl implements RustTestRepository {
  const RustTestRepositoryImpl();

  @override
  String greet(String name) {
    return rust_api.greet(name: name);
  }

  @override
  Future<String> connectMatrix() {
    return client_api.connectMatrix();
  }
}
