# Comunicação Flutter/Rust

A comunicação entre o Dart e o Rust é feita pelo [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/) (FRB) na versão 2.13.0. O FRB lê as funções públicas do módulo `crate::api`, gera o código de serialização dos dois lados e expõe ao Dart funções com tipos equivalentes aos do Rust.

## Como as peças se encaixam

```text
rust/src/api/*.rs                    código Rust escrito à mão
        │
        │ flutter_rust_bridge_codegen generate
        ▼
rust/src/frb_generated.rs            pontos de entrada FFI e (de)serialização no Rust
lib/src/rust/frb_generated*.dart     runtime, carregamento da biblioteca e (de)serialização no Dart
lib/src/rust/api/*.dart              funções e classes Dart chamadas pelos Repositories
        │
        │ flutter build / flutter run
        ▼
rust_builder/ (Cargokit)             compila o crate e empacota a biblioteca nativa no app
```

* **`flutter_rust_bridge.yaml`** define a entrada (`crate::api`), a raiz do crate (`rust/`) e a saída Dart (`lib/src/rust`).
* **`rust_builder/`** é um plugin Flutter local (dependência `rust_lib_nexa_messaging_desktop` no `pubspec.yaml`). Ele usa o Cargokit para chamar o `cargo build` durante o build do Flutter, gerando `.dll` no Windows, `.dylib`/framework no macOS e `.so` no Linux.
* **`RustLib.init()`**, chamado em `main()` antes de `runApp`, carrega a biblioteca nativa, valida que o código gerado corresponde ao Rust compilado e executa a função marcada com `#[frb(init)]` (`init_app`, em `simple.rs`).

## Funções expostas ao Flutter

| Função Rust | Função Dart | Retorno no Dart | Usada por |
| --- | --- | --- | --- |
| `login_matrix` | `loginMatrix` | `Future<AuthSession>` | `AuthRepositoryImpl.login` |
| `restore_matrix_session` | `restoreMatrixSession` | `Future<void>` | `AuthRepositoryImpl.getSession` |
| `start_matrix_sync` | `startMatrixSync` | `Future<void>` | `AuthRepositoryImpl` (após login e restauração) |
| `logout_matrix` | `logoutMatrix` | `Future<void>` | `AuthRepositoryImpl.logout` |
| `recover_matrix_encryption` | `recoverMatrixEncryption` | `Future<void>` | `RecoveryRepositoryImpl` |
| `get_rooms` | `getRooms` | `Future<List<RoomSummary>>` | `RoomsRepositoryImpl` |
| `get_messages` | `getMessages` | `Future<MessagesPage>` | `MessagesRepositoryImpl` |
| `send_message` | `sendMessage` | `Future<void>` | `MessagesRepositoryImpl` |
| `subscribe_to_messages` | `subscribeToMessages` | `Stream<MessageSummary>` | `MessagesRepositoryImpl.watchMessages` |

Funções auxiliares internas são marcadas com `#[flutter_rust_bridge::frb(ignore)]` ou não são `pub`, e por isso não aparecem no Dart (por exemplo `get_authenticated_client`, `matrix_message_sender` e `matrix_store_path`).

## Tipos compartilhados

Structs Rust com campos públicos são convertidas em classes Dart imutáveis, com `==` e `hashCode` gerados:

| Rust | Dart | Campos |
| --- | --- | --- |
| `AuthSession` | `AuthSession` | `userId`, `deviceId`, `accessToken`, `refreshToken?` |
| `RoomSummary` | `RoomSummary` | `id`, `name` |
| `MessageSummary` | `MessageSummary` | `id`, `roomId`, `sender`, `content`, `timestamp` (`PlatformInt64`, milissegundos) |
| `MessagesPage` | `MessagesPage` | `messages`, `endToken?` |

Mapeamentos usados no projeto: `String` ↔ `String`, `Option<T>` ↔ `T?`, `Vec<T>` ↔ `List<T>`, `i64` ↔ `PlatformInt64`.

Esses tipos são DTOs de fronteira. Os Repositories os convertem em Entities do domínio, de modo que o restante do app não depende do código gerado.

## Modos de chamada

### Assíncrona (padrão)

Toda função sem atributo especial vira uma `Future` no Dart. Funções `async fn` rodam no runtime Tokio do FRB, e funções síncronas comuns rodam em uma thread do pool do FRB. Em ambos os casos a thread de UI do Flutter não é bloqueada.

```rust
#[flutter_rust_bridge::frb]
pub async fn get_rooms() -> Result<Vec<RoomSummary>, String> { ... }
```

```dart
final List<rust_api.RoomSummary> rooms = await rust_api.getRooms();
```

### Síncrona

Com `#[frb(sync)]`, a chamada é executada diretamente na thread do Dart e retorna o valor sem `Future`. O Nexa não usa esse modo: as operações com o Matrix são assíncronas para não bloquear a interface.

### Streams (Rust → Dart)

Para eventos contínuos, a função Rust recebe um `StreamSink<T>`. O FRB remove esse parâmetro da assinatura Dart e devolve um `Stream<T>`:

```rust
#[flutter_rust_bridge::frb]
pub async fn subscribe_to_messages(sink: StreamSink<MessageSummary>) {
    let mut receiver = matrix_message_sender().subscribe();
    loop {
        match receiver.recv().await {
            Ok(message) => if sink.add(message).is_err() { break; },
            Err(RecvError::Lagged(_)) => continue,
            Err(RecvError::Closed) => break,
        }
    }
}
```

```dart
Stream<MessageEntity> watchMessages() {
  return rust_api.subscribeToMessages().map(
    (message) => MessageEntity(...),
  );
}
```

O fluxo completo de mensagens em tempo real é:

```text
[Thread do sync]                       [Runtime do FRB]                [Isolate do Flutter]
client.sync() ─► event handler ─► broadcast::Sender ─► Receiver ─► StreamSink ─► Stream ─► MessagesViewModel
```

Quando o Flutter cancela a assinatura do `Stream`, o próximo `sink.add` falha e o loop no Rust termina.

## Tratamento de erros

As funções expostas retornam `Result<T, String>`. Os erros do Matrix SDK são convertidos com `map_err(|error| error.to_string())`.

No Dart, um `Err` é lançado como exceção quando a `Future` é aguardada. As ViewModels capturam a exceção e a expõem no `State`:

```dart
try {
  final session = await _authUseCase.call(...);
  state = state.copyWith(isLoading: false, session: session);
} catch (error) {
  state = state.copyWith(isLoading: false, error: error.toString());
}
```

O uso de `String` como tipo de erro simplifica a fronteira, mas impede que o Flutter diferencie tipos de falha (credencial inválida, rede indisponível, sessão expirada). Veja [Limitações](limitacoes.md#erros-sem-tipagem-na-fronteira-flutterrust).

## Concorrência e estado compartilhado

* O FRB executa as funções `async` em um runtime Tokio multi-thread. Por isso o cliente Matrix global fica em um `Mutex`, e o lock é mantido apenas para clonar ou substituir o `Client`, nunca durante um `await`.
* O sync contínuo (`client.sync()`) roda em uma `std::thread` dedicada, com um runtime Tokio `current_thread` próprio. Assim o loop de longa duração não ocupa as threads usadas pelas demais chamadas do Flutter.
* O handle em `MATRIX_SYNC` garante uma única thread de sync. `logout_matrix` envia um sinal de encerramento e espera a thread terminar antes de descartar o `Client`.

## Adicionando uma nova função

1. Criar ou alterar a função pública em `rust/src/api/` com `#[flutter_rust_bridge::frb]`, retornando `Result<T, String>` quando puder falhar.
2. Se for um módulo novo, declará-lo em `rust/src/api/mod.rs`.
3. Executar `flutter_rust_bridge_codegen generate`.
4. Consumir a função gerada em `lib/src/rust/api/` **somente** dentro de uma implementação de Repository, convertendo o retorno em uma Entity.
5. Expor a operação por um Use Case e criar testes da ViewModel e do Use Case com um Repository falso.
