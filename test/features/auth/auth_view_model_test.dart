import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/auth_providers.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_view_model.dart';

const _session = AuthSessionEntity(
  homeserver: 'https://matrix.org',
  userId: '@user:matrix.org',
  deviceId: 'DEVICE',
  accessToken: 'token',
  refreshToken: 'refresh',
);

class FakeAuthRepository implements AuthRepository {
  AuthSessionEntity? storedSession;
  Object? getSessionError;
  Object? loginError;
  Object? logoutError;
  Completer<void>? loginCompleter;

  String? loginHomeserver;
  String? loginUsername;
  String? loginPassword;
  int logoutCalls = 0;

  @override
  Future<AuthSessionEntity?> getSession() async {
    if (getSessionError != null) {
      throw getSessionError!;
    }
    return storedSession;
  }

  @override
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    loginHomeserver = homeserver;
    loginUsername = username;
    loginPassword = password;

    if (loginCompleter != null) {
      await loginCompleter!.future;
    }
    if (loginError != null) {
      throw loginError!;
    }
    return _session;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) {
      throw logoutError!;
    }
  }
}

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  Future<AuthViewModel> createInitializedViewModel() async {
    final viewModel = container.read(authViewModelProvider.notifier);
    await pumpEventQueue();
    return viewModel;
  }

  Future<void> login(AuthViewModel viewModel) {
    return viewModel.login(
      homeserver: 'https://matrix.org',
      username: 'user',
      password: 'secret',
    );
  }

  group('AuthViewModel session restore', () {
    test('starts not initialized', () {
      final state = container.read(authViewModelProvider);

      expect(state.isInitialized, isFalse);
      expect(state.session, isNull);
    });

    test('restores the stored session on build', () async {
      repository.storedSession = _session;

      await createInitializedViewModel();

      final state = container.read(authViewModelProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.session, same(_session));
      expect(state.error, isNull);
    });

    test('initializes without session when none is stored', () async {
      await createInitializedViewModel();

      final state = container.read(authViewModelProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
    });

    test('initializes with error when restore fails', () async {
      repository.getSessionError = Exception('storage failure');

      await createInitializedViewModel();

      final state = container.read(authViewModelProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
      expect(state.error, 'Exception: storage failure');
    });
  });

  group('AuthViewModel login', () {
    test('stores the session on success', () async {
      final viewModel = await createInitializedViewModel();

      await login(viewModel);

      final state = container.read(authViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.session, same(_session));
      expect(state.error, isNull);
      expect(repository.loginHomeserver, 'https://matrix.org');
      expect(repository.loginUsername, 'user');
      expect(repository.loginPassword, 'secret');
    });

    test('sets isLoading while the request is pending', () async {
      repository.loginCompleter = Completer<void>();
      final viewModel = await createInitializedViewModel();

      final future = login(viewModel);
      await pumpEventQueue();

      expect(container.read(authViewModelProvider).isLoading, isTrue);

      repository.loginCompleter!.complete();
      await future;

      expect(container.read(authViewModelProvider).isLoading, isFalse);
    });

    test('exposes the error and keeps session empty on failure', () async {
      repository.loginError = Exception('invalid credentials');
      final viewModel = await createInitializedViewModel();

      await login(viewModel);

      final state = container.read(authViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
      expect(state.error, 'Exception: invalid credentials');
    });

    test('clears a previous error when retrying', () async {
      repository.loginError = Exception('invalid credentials');
      final viewModel = await createInitializedViewModel();
      await login(viewModel);

      repository.loginError = null;
      await login(viewModel);

      final state = container.read(authViewModelProvider);
      expect(state.error, isNull);
      expect(state.session, same(_session));
    });
  });

  group('AuthViewModel logout', () {
    test('clears the session on success', () async {
      repository.storedSession = _session;
      final viewModel = await createInitializedViewModel();

      await viewModel.logout();

      final state = container.read(authViewModelProvider);
      expect(repository.logoutCalls, 1);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
      expect(state.isInitialized, isTrue);
    });

    test('ends the local session and exposes the server error', () async {
      repository
        ..storedSession = _session
        ..logoutError = Exception('logout failed');
      final viewModel = await createInitializedViewModel();

      await viewModel.logout();

      final state = container.read(authViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.session, isNull);
      expect(state.error, 'Exception: logout failed');
    });
  });

  group('isAuthenticatedProvider', () {
    test('is false without session', () async {
      await createInitializedViewModel();

      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('follows login and logout', () async {
      final viewModel = await createInitializedViewModel();

      await login(viewModel);
      expect(container.read(isAuthenticatedProvider), isTrue);

      await viewModel.logout();
      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });
}
