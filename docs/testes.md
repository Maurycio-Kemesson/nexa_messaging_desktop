# Testes

O Nexa tem testes Flutter organizados por feature e por camada. Eles validam ViewModels, Use Cases, States e as telas de login e de mensagens sem depender do Rust, do Matrix SDK ou de rede.

```bash
flutter test
```

## Estratégia

A arquitetura MVVM ([ADR 002](adr/002-arquitetura-mvvm.md)) concentra a lógica da aplicação nas ViewModels e nos Use Cases, e isola toda a integração com o Rust nas implementações de Repository. A estratégia de testes segue essa divisão:

| Camada | Testada? | Como |
| --- | --- | --- |
| State | Sim | Teste direto da classe imutável: valores padrão, `copyWith` e propriedades derivadas. |
| Use Case | Sim | Instanciado com um Repository falso, verificando a delegação e os argumentos. |
| ViewModel | Sim | Criada por um `ProviderContainer` com o Repository falso injetado, verificando as transições de estado. |
| Views / Widgets | Parcial | `AuthContent` e `MessagesView` com Repositories falsos, cobrindo login, envio e atualização em tempo real. |
| Repository (implementação) | Não | Depende da biblioteca nativa carregada pelo `RustLib.init()`. |
| Rust (`rust/src/api`) | Não | Ver [Limitações](limitacoes.md#sem-testes-da-camada-rust-nem-de-integração). |

Como as ViewModels dependem apenas dos contratos de Repository (`domain/repositories/`), basta substituir o Repository por uma implementação falsa para testar toda a lógica de apresentação de forma determinística.

## Estrutura

Os testes espelham a estrutura de `lib/features/`:

```text
test/features/
├── auth/
│   ├── auth_state_test.dart
│   ├── auth_usecase_test.dart
│   ├── auth_view_model_test.dart
│   └── auth_content_test.dart
├── home/
├── messages/
│   ├── ...
│   └── messages_view_test.dart
├── recovery/
└── rooms/
```

Cada feature tem testes de State, Use Case e ViewModel. `auth` e `messages` também têm testes de widget.

## O que é verificado

### States

* Valores padrão do estado inicial.
* `copyWith` mantendo todos os campos quando nada é passado.
* `copyWith` sobrescrevendo os campos informados.
* `copyWith` limpando campos anuláveis (`session`, `selectedRoom`, `error`) quando `null` é passado explicitamente.
* Propriedades derivadas, como `isEmpty` em `RoomsState` e `MessagesState` (falso durante o carregamento, com itens ou com erro).

### Use Cases

* Delegação ao Repository com os argumentos corretos (por exemplo homeserver, usuário e senha no login, ou a Recovery Key na recuperação).
* Retorno do resultado do Repository sem alteração.

### ViewModels

Padrões verificados em todas as features:

* Estado inicial.
* `isLoading`/`isSending` verdadeiro enquanto a operação está pendente e falso ao terminar.
* Erro exposto no `State` quando o Repository lança uma exceção.
* Erro anterior limpo ao repetir a operação com sucesso.

Comportamentos específicos de cada feature:

| Feature | Cenários |
| --- | --- |
| `auth` | Restauração da sessão no `build` (com sessão, sem sessão e com falha); login com sucesso e falha; logout que sempre encerra a sessão local, mesmo quando o servidor falha; `isAuthenticatedProvider` acompanhando login e logout. |
| `rooms` | Carregamento da lista, lista vazia, seleção e troca de sala, sala selecionada preservada após recarregar. |
| `messages` | Primeira página do histórico; resposta atrasada ignorada ao trocar de sala; envio ignorando mensagem vazia e removendo espaços; recarga do histórico após enviar; envio atrasado que não substitui a sala atual; atualização em tempo real somente da sala atual, sem duplicatas e com propagação de erros do stream; cancelamento da assinatura ao descartar a ViewModel; paginação com `endToken` até o fim do histórico, bloqueio de chamadas concorrentes e nova tentativa após falha. |
| `recovery` | Repasse da Recovery Key, marcação de sucesso e reinício do sucesso quando uma nova tentativa falha. |
| `home` | Execução do Use Case e tratamento de carregamento e erro. |

### Widgets

* `AuthContent`: envio do formulário com usuário recortado e senha intacta; exibição do erro quando o login falha.
* `MessagesView`: estado vazio, histórico, mensagem em tempo real, compositor limpo após envio e texto preservado quando o envio falha.

## Como os testes são montados

### Repository falso

Cada teste de ViewModel define um `Fake<Feature>Repository` que implementa o contrato do domínio. Em vez de usar uma biblioteca de mocks, os fakes registram as chamadas em campos públicos e permitem configurar retornos e erros:

```dart
class FakeAuthRepository implements AuthRepository {
  AuthSessionEntity? storedSession;
  Object? loginError;
  Completer<void>? loginCompleter;
  String? loginUsername;

  @override
  Future<AuthSessionEntity> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    loginUsername = username;
    if (loginCompleter != null) await loginCompleter!.future;
    if (loginError != null) throw loginError!;
    return _session;
  }

  // getSession() e logout() seguem o mesmo padrão
}
```

* Um **`Completer`** mantém a operação pendente, o que permite verificar o estado intermediário (`isLoading == true`).
* Um campo de **erro** faz o fake lançar uma exceção para testar o caminho de falha.
* No `FakeMessagesRepository`, um **`StreamController.broadcast()`** simula as mensagens em tempo real que, em produção, vêm do `StreamSink` do Rust.

### Injeção com Riverpod

A ViewModel é criada por um `ProviderContainer.test`, sobrescrevendo apenas o provider do Repository. O Use Case real continua sendo usado, o que também testa a ligação entre as camadas:

```dart
setUp(() {
  repository = FakeAuthRepository();
  container = ProviderContainer.test(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
});
```

O `ProviderContainer.test` descarta o container automaticamente ao final de cada teste.

### Operações assíncronas

* `pumpEventQueue()` processa microtasks pendentes, por exemplo a restauração de sessão disparada com `Future.microtask` no `build` do `AuthViewModel` ou um evento adicionado ao stream.
* Para verificar estados intermediários, o teste inicia a operação sem `await`, verifica o estado, completa o `Completer` e então aguarda o resultado:

```dart
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
```

## Escrevendo testes para uma nova feature

1. Gere a feature com o Mason (`mason make feature --name nome_da_feature`). O brick já cria `test/features/<feature>/<feature>_view_model_test.dart` como ponto de partida.
2. Crie um fake do Repository implementando o contrato em `domain/repositories/`.
3. Crie a ViewModel com `ProviderContainer.test`, sobrescrevendo o provider do Repository com o fake.
4. Cubra pelo menos estado inicial, sucesso, carregamento, falha e nova tentativa após falha.
5. Adicione `<feature>_state_test.dart` e `<feature>_usecase_test.dart` seguindo os arquivos existentes.
6. Antes do Pull Request, execute `dart format .`, `flutter analyze` e `flutter test`.

## Testes Rust

Não há testes Rust no crate. A verificação obrigatória antes de cada PR é `dart format .`, `flutter analyze` e `flutter test`. Detalhes em [Limitações](limitacoes.md#sem-testes-da-camada-rust-nem-de-integração).
