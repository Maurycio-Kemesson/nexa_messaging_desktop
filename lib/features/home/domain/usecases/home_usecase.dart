import '../entities/home_entity.dart';
import '../repositories/home_repository.dart';

class HomeUseCase {
  const HomeUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeEntity> call() {
    return _repository.execute();
  }
}
