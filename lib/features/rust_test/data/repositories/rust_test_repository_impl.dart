import 'package:nexa_messaging_desktop/src/rust/api/simple.dart' as rust_api;
import '../../domain/repositories/rust_test_repository.dart';


class RustTestRepositoryImpl implements RustTestRepository {
  const RustTestRepositoryImpl();

 @override
  String greet(String name) {
    return rust_api.greet(name: name);
  }
}
