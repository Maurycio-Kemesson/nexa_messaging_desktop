# Testes

O Nexa tem **100 testes unitários** em Flutter, organizados por feature e por camada. Eles validam o comportamento das ViewModels, Use Cases e States sem depender do Rust, do Matrix SDK ou de rede, e rodam em poucos segundos.

```bash
flutter test
```

```text
00:02 +100: All tests passed!
```

## Estratégia

A arquitetura MVVM ([ADR 002](adr/002-arquitetura-mvvm.md)) concentra a lógica da aplicação nas ViewModels e nos Use Cases, e isola toda a integração com o Rust nas implementações de Repository. A estratégia de testes segue essa divisão:

| Camada | Testada? | Como |
| --- | --- | --- |
| State | Sim | Teste direto da classe imutável: valores padrão, `copyWith` e propriedades derivadas. |
| Use Case | Sim | Instanciado com um Repository falso, verificando a delegação e os argumentos. |
| ViewModel | Sim | Criada por um `ProviderContainer` com o Repository falso injetado, verificando as transições de estado. |
| Repository (implementação) | Não | Depende da biblioteca nativa carregada pelo `RustLib.init()`. |
| Rust (`rust/src/api`) | Parcial | Testes de integração contra o `matrix.org` (ver [abaixo](#testes-rust)). |
| Views / Widgets | Não | Ver [Limitações](limitacoes.md#sem-testes-de-integração-ou-de-widget). |

Como as ViewModels dependem apenas dos contratos de Repository (`domain/repositories/`), basta substituir o Repository por uma implementação falsa para testar toda a lógica de apresentação de forma determinística.

## Estrutura

Os testes espelham a estrutura de `lib/features/`. Cada feature tem três arquivos, um por camada:

```text
test/features/
├── auth/
│   ├── auth_state_test.dart
│   ├── auth_usecase_test.dart
│   └── auth_view_model_test.dart
├── home/
├── messages/
├── recovery/
├── rooms/
└── rust_test/
```

| Feature | State | Use Case | ViewModel | Total |
| --- | --- | --- | --- | --- |
| `auth` | 4 | 3 | 12 | 19 |
| `home` | 3 | 1 | 5 | 9 |
| `messages` | 8 | 3 | 22 | 33 |
| `recovery` | 3 | 1 | 6 | 10 |
| `rooms` | 8 | 1 | 9 | 18 |
| `rust_test` | 3 | 2 | 6 | 11 |
| **Total** | **29** | **11** | **60** | **100** |

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
| `auth` | Restauração da sessão no `build` (com sessão, sem sessão e com falha); login com sucesso e falha; logout com sucesso e falha mantendo a sessão; `isAuthenticatedProvider` acompanhando login e logout. |
| `rooms` | Carregamento da lista, lista vazia, seleção e troca de sala, sala selecionada preservada após recarregar. |
| `messages` | Primeira página do histórico; envio ignorando mensagem vazia e removendo espaços; recarga do histórico após enviar; atualização em tempo real somente da sala atual, sem duplicatas e com propagação de erros do stream; cancelamento da assinatura ao descartar a ViewModel; paginação com `endToken` até o fim do histórico, bloqueio de chamadas concorrentes e nova tentativa após falha. |
| `recovery` | Repasse da Recovery Key, marcação de sucesso e reinício do sucesso quando uma nova tentativa falha. |
| `home` / `rust_test` | Execução do Use Case e tratamento de carregamento e erro. |

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

Os testes Rust ficam em `rust/src/api/matrix.rs` e são executados com:

```bash
cd rust
cargo test
```

| Teste | O que verifica |
| --- | --- |
| `should_create_matrix_client` | Criação de um `Client` apontando para `https://matrix.org`. |
| `should_get_matrix_login_types` | Consulta dos tipos de login suportados pelo homeserver. |
| `should_login_to_matrix` | Login com usuário e senha. |

Esses testes acessam a rede, e o `should_login_to_matrix` exige credenciais reais (hoje estão vazias no código, então ele falha). Por isso eles não fazem parte da verificação obrigatória antes de cada PR. Os detalhes estão em [Limitações](limitacoes.md#testes-rust-dependentes-de-rede).
