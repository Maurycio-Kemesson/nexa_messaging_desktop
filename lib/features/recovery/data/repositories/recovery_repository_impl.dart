import 'package:nexa_messaging_desktop/src/rust/api/client.dart' as rust_api;

import '../../domain/repositories/recovery_repository.dart';

class RecoveryRepositoryImpl implements RecoveryRepository {
  const RecoveryRepositoryImpl();

  @override
  Future<void> recover({required String recoveryKey}) {
    return rust_api.recoverMatrixEncryption(recoveryKey: recoveryKey);
  }
}
