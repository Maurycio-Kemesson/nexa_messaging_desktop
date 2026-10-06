import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/home/domain/entities/home_entity.dart';
import 'package:nexa_messaging_desktop/features/home/domain/repositories/home_repository.dart';
import 'package:nexa_messaging_desktop/features/home/domain/usecases/home_usecase.dart';

const _entity = HomeEntity(id: 'home');

class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeEntity> execute() async => _entity;
}

void main() {
  test('HomeUseCase returns the entity from the repository', () async {
    final useCase = HomeUseCase(FakeHomeRepository());

    expect(await useCase(), same(_entity));
  });
}
