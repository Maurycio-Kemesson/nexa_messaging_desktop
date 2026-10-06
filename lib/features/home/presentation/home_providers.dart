import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/usecases/home_usecase.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return const HomeRepositoryImpl();
});

final homeUseCaseProvider = Provider<HomeUseCase>((ref) {
  final repository = ref.read(homeRepositoryProvider);

  return HomeUseCase(repository);
});
