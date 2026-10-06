import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexa_messaging_desktop/features/auth/domain/entities/auth_session_entity.dart';
import 'package:nexa_messaging_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/auth_providers.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/widgets/auth_content.dart';

class FakeAuthRepository implements AuthRepository {
  Object? loginError;
  ({String homeserver, String username, String password})? loginCall;

  @override
  Future<AuthSessionEntity?> getSession() async => null;

  @override
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    loginCall = (
      homeserver: homeserver,
      username: username,
      password: password,
    );

    if (loginError != null) {
      throw loginError!;
    }

    return AuthSessionEntity(
      homeserver: homeserver,
      userId: '@$username:matrix.org',
      deviceId: 'DEVICE',
      accessToken: 'token',
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pumpAuthContent(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: AuthContent())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Usuário'),
      '  alice  ',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), ' secret ');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('submits the trimmed username and the raw password', (
    tester,
  ) async {
    await pumpAuthContent(tester);

    await fillAndSubmit(tester);

    expect(repository.loginCall?.homeserver, 'https://matrix.org');
    expect(repository.loginCall?.username, 'alice');
    expect(repository.loginCall?.password, ' secret ');
    expect(find.text('Autenticado como @alice:matrix.org'), findsOneWidget);
  });

  testWidgets('shows the error when login fails', (tester) async {
    repository.loginError = Exception('invalid credentials');
    await pumpAuthContent(tester);

    await fillAndSubmit(tester);

    expect(find.text('Exception: invalid credentials'), findsOneWidget);
    expect(find.textContaining('Autenticado como'), findsNothing);
  });
}
