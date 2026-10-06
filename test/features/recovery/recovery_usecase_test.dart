import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/recovery/domain/repositories/recovery_repository.dart';
import 'package:nexa_messaging_desktop/features/recovery/domain/usecases/recovery_usecase.dart';

class FakeRecoveryRepository implements RecoveryRepository {
  String? recoveryKey;

  @override
  Future<void> recover({required String recoveryKey}) async {
    this.recoveryKey = recoveryKey;
  }
}

void main() {
  test(
    'RecoveryUseCase delegates the recovery key to the repository',
    () async {
      final repository = FakeRecoveryRepository();

      await RecoveryUseCase(repository)(recoveryKey: 'key');

      expect(repository.recoveryKey, 'key');
    },
  );
}
