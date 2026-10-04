import '../entities/home_entity.dart';

abstract interface class HomeRepository {
  Future<HomeEntity> execute();
}
