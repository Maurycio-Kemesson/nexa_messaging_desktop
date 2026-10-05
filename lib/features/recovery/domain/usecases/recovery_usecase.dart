import '../repositories/recovery_repository.dart';

class RecoveryUseCase {
  final RecoveryRepository _repository;

  const RecoveryUseCase(this._repository);

  Future<void> call({required String recoveryKey}) {
    return _repository.recover(recoveryKey: recoveryKey);
  }
}
