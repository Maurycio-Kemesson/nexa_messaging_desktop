abstract interface class RecoveryRepository {
  Future<void> recover({required String recoveryKey});
}
