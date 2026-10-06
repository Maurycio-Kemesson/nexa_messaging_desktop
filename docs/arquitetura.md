# Arquitetura

O Nexa é dividido em duas partes que rodam no mesmo processo:

* **Flutter (Dart)**: interface, estado de tela, regras da aplicação, navegação e persistência da sessão.
* **Rust**: integração com o protocolo Matrix através do Matrix Rust SDK, incluindo sincronização, armazenamento local e criptografia ponta a ponta (E2EE).

A ponte entre as duas partes é o **Flutter Rust Bridge (FRB)**, detalhado em [Comunicação Flutter/Rust](comunicacao-flutter-rust.md).

## Visão geral

```text
┌──────────────────────────── Flutter ────────────────────────────┐
│                                                                 │
│  View ──► ViewModel ──► Use Case ──► Repository (interface)     │
│   ▲           │                           │                     │
│   └── estado ─┘                           ▼                     │
│                                  Repository (implementação)     │
│                                   │                    │        │
│                     flutter_secure_storage    lib/src/rust (FRB)│
└───────────────────────────────────────────────────────┬─────────┘
                                                        │ FFI
┌──────────────────────────── Rust ─────────────────────▼─────────┐
│  rust/src/api (client.rs, rooms.rs, matrix.rs)                  │
│        │                                                        │
│        ▼                                                        │
│  Matrix Rust SDK ──► SQLite (estado + chaves E2EE)              │
└────────┬────────────────────────────────────────────────────────┘
         │ HTTPS (Client-Server API)
         ▼
  Matrix Homeserver
```

## Camadas do Flutter

A camada de apresentação segue **MVVM** ([ADR 002](adr/002-arquitetura-mvvm.md)), complementada por Use Cases e Repositories. Cada feature fica em `lib/features/<feature>/` com a mesma estrutura, gerada pelo brick do Mason ([ADR 003](adr/003-adocao-mason-para-padronizacao-de-features.md)):

```text
lib/features/<feature>/
├── data/
│   ├── datasources/            # acesso a armazenamento local (quando existe)
│   └── repositories/           # implementação que chama o Rust via FRB
├── domain/
│   ├── entities/               # modelos da aplicação, sem dependência de FRB
│   ├── repositories/           # contratos (classes abstratas)
│   └── usecases/               # operações da aplicação
└── presentation/
    ├── <feature>_providers.dart  # injeção de dependências com Riverpod
    ├── viewmodels/             # Notifier + State imutável
    ├── views/                  # telas
    └── widgets/                # componentes da tela
```

| Camada | Responsabilidade | Depende de |
| --- | --- | --- |
| View / Widgets | Renderizar o estado e encaminhar ações do usuário. | ViewModel |
| ViewModel | Manter o `State` da tela, tratar erros e coordenar ações. | Use Case |
| Use Case | Representar uma operação da aplicação (login, listar salas, enviar mensagem). | Contrato do Repository |
| Repository (contrato) | Definir o que a aplicação precisa, sem detalhes de infraestrutura. | Entities |
| Repository (implementação) | Chamar o Rust via FRB e converter os tipos gerados em Entities. | FRB, storage |

As regras de dependência importantes são:

* Nenhuma ViewModel ou View importa `lib/src/rust/`. Apenas as implementações de Repository conhecem a API gerada pelo FRB.
* Os tipos gerados pelo FRB (`AuthSession`, `RoomSummary`, `MessageSummary`, `MessagesPage`) são convertidos em Entities (`AuthSessionEntity`, `RoomEntity`, `MessageEntity`, `MessagesPageEntity`) dentro do Repository. Por exemplo, o `timestamp` em milissegundos vira `DateTime`.
* Os Repositories são injetados pelos providers do Riverpod, o que permite substituí-los por implementações falsas nos testes.

### Gerenciamento de estado

O estado é gerenciado com **Riverpod 3** (`flutter_riverpod`). Cada ViewModel é um `Notifier<State>` exposto por um `NotifierProvider`, e cada `State` é uma classe imutável com `copyWith`. As dependências (Repository e Use Case) são declaradas em `<feature>_providers.dart`.

### Navegação

A navegação usa **go_router** (`lib/core/router/`). O `redirect` consulta o `AuthViewModel`:

* Enquanto a restauração da sessão não terminou (`isInitialized == false`), nenhuma rota é redirecionada.
* Sem sessão, qualquer rota redireciona para `/authentication`.
* Com sessão, a rota de autenticação redireciona para `/home`.

O `RouterRefreshNotifier` escuta o `authViewModelProvider` e força a reavaliação do `redirect` quando o estado de autenticação muda (login, restauração ou logout).

| Rota | Tela | Uso |
| --- | --- | --- |
| `/authentication` | `AuthView` | Login no homeserver. |
| `/home` | `HomeView` | Lista de salas e conversa selecionada. |
| `/recovery` | `RecoveryView` | Recuperação das chaves E2EE com a Recovery Key. |
| `/rust-test` | `RustTestView` | Tela de diagnóstico da integração com o Rust, usada durante o desenvolvimento. |

## Features

| Feature | Responsabilidade |
| --- | --- |
| `auth` | Login, restauração e logout. Persiste a sessão com `flutter_secure_storage`. |
| `home` | Layout principal: lista de salas à esquerda e conversa à direita. |
| `rooms` | Listagem e seleção das salas em que o usuário entrou. |
| `messages` | Histórico paginado, envio de mensagens e atualização em tempo real. |
| `recovery` | Recuperação do estado criptográfico a partir do backup de chaves ([ADR 004](adr/004-persistencia-e-recuperacao-e2ee.md)). |
| `rust_test` | Diagnóstico da ponte Flutter/Rust (função `greet` e conexão ao `matrix.org`). |

## Camada Rust

O crate fica em `rust/` e é compilado como `cdylib`/`staticlib` com o nome `rust_lib_nexa_messaging_desktop`. Somente o módulo `crate::api` é exposto ao Flutter.

| Arquivo | Conteúdo |
| --- | --- |
| `api/client.rs` | Cliente Matrix global, login, restauração de sessão, sincronização em segundo plano, backup e recuperação E2EE. |
| `api/rooms.rs` | Listagem de salas, histórico paginado, envio de mensagens e stream de novas mensagens. |
| `api/matrix.rs` | Tipo `AuthSession`, criação de cliente de teste e testes de integração. |
| `api/simple.rs` | Função `greet` e inicialização padrão do FRB. |
| `frb_generated.rs` | Código gerado pelo FRB. Não editar. |

### Estado global no Rust

O Rust mantém três estados globais, inicializados sob demanda:

* `MATRIX_CLIENT: OnceLock<Mutex<Option<Client>>>`: o `matrix_sdk::Client` autenticado. É preenchido pelo login ou pela restauração e lido por todas as outras operações através de `get_authenticated_client()`. O `Client` é clonável e internamente compartilhado (`Arc`), então cada operação trabalha com um clone barato.
* `MATRIX_MESSAGE_CHANNEL: OnceLock<broadcast::Sender<MessageSummary>>`: canal `tokio::sync::broadcast` (capacidade 100) que distribui as mensagens recebidas pelo sync para os assinantes do Flutter.
* `MATRIX_SYNC_STARTED: AtomicBool`: impede que mais de um loop de sincronização seja iniciado.

### Persistência local do Matrix

O cliente é criado com `sqlite_store`, que guarda o estado do Matrix (salas, tokens de sincronização) e o estado criptográfico (chaves do dispositivo, sessões Olm/Megolm). O diretório é obtido com `dirs::data_dir()`:

| Plataforma | Diretório |
| --- | --- |
| Windows | `%APPDATA%\Nexa Messaging\matrix` |
| macOS | `~/Library/Containers/com.example.nexaMessagingDesktop/Data/Library/Application Support/Nexa Messaging/matrix` (app em sandbox) |
| Linux | `$XDG_DATA_HOME/Nexa Messaging/matrix` (padrão `~/.local/share/Nexa Messaging/matrix`) |

## Fluxos principais

### Inicialização e restauração da sessão

```text
main()
  └─ RustLib.init()                       carrega a biblioteca nativa
  └─ ProviderScope + GoRouter
       └─ AuthViewModel.build()
            └─ _restoreSession()
                 └─ AuthRepository.getSession()
                      ├─ SecureAuthSessionStorage.get()      sem sessão → tela de login
                      ├─ restoreMatrixSession(...)           Rust: Client + SQLite + restore_session
                      ├─ checkMatrixBackup()                 diagnóstico do backup E2EE
                      └─ startMatrixSync()                   inicia o sync em segundo plano
       └─ isInitialized = true → router redireciona para /home
```

### Login

```text
AuthView ─► AuthViewModel.login ─► AuthUseCase ─► AuthRepositoryImpl.login
  └─ loginMatrix(homeserver, username, password)
       Rust: Client::builder()
               .homeserver_url(...)
               .sqlite_store(...)
               .with_encryption_settings(cross-signing + backups automáticos)
             matrix_auth().login_username(...).request_refresh_token()
  └─ SecureAuthSessionStorage.save(sessão)
  └─ startMatrixSync()
```

### Listagem de salas

`RoomsViewModel.loadRooms` chama `getRooms()`. No Rust, a função executa um `sync_once` para garantir que o estado das salas esteja atualizado, percorre `client.joined_rooms()` e calcula o nome de exibição de cada sala (`display_name()`).

### Histórico de mensagens

`MessagesViewModel.loadMessages` chama `getMessages(roomId, fromToken: null)`. No Rust, `room.messages()` busca até 50 eventos para trás (`MessagesOptions::backward()`). Cada evento é classificado:

* `Decrypted` e `PlainText` seguem para conversão.
* `UnableToDecrypt` é descartado (a chave Megolm não está disponível localmente).
* Somente eventos `m.room.message` originais do tipo `m.text` viram `MessageSummary`.

As mensagens são ordenadas por timestamp e retornadas com o `end_token`. Ao rolar até o topo, `loadMoreMessages` reenvia o `end_token` como `fromToken`, e as mensagens novas são inseridas no início da lista sem duplicar IDs.

### Envio de mensagens

`sendMessage(roomId, message)` cria um `RoomMessageEventContent::text_plain` e chama `room.send()`. O SDK cifra automaticamente o conteúdo quando a sala tem E2EE. Após o envio, a ViewModel recarrega a primeira página do histórico.

### Mensagens em tempo real

```text
Thread dedicada (runtime Tokio)
  client.sync(SyncSettings::default())           loop contínuo de sync
    └─ event handler OriginalSyncRoomMessageEvent
         └─ MessageSummary ─► broadcast::Sender

subscribe_to_messages(StreamSink)                 chamada pelo Flutter
  └─ broadcast::Receiver ─► sink.add(message)     ─► Stream<MessageSummary> no Dart

MessagesViewModel
  └─ watchMessages().listen(...)
       └─ ignora mensagens de outras salas e IDs já exibidos
```

### Recuperação E2EE

Acessada pelo ícone de nuvem na `HomeView`. A `RecoveryView` recebe a Recovery Key e chama `recoverMatrixEncryption`, que executa `client.encryption().recovery().recover(key)`. A chave não é persistida nem registrada em logs. O racional completo está no [ADR 004](adr/004-persistencia-e-recuperacao-e2ee.md).

## Segurança

* Credenciais da sessão (`access_token`, `refresh_token`, `user_id`, `device_id`, `homeserver`) são persistidas apenas pelo `flutter_secure_storage`, que usa o cofre de credenciais do sistema operacional: Credential Manager/DPAPI no Windows, Keychain no macOS e `libsecret` no Linux.
* A senha do usuário é usada somente na chamada de login e não é armazenada.
* A Recovery Key não é armazenada nem registrada em logs.
* Toda a criptografia E2EE é responsabilidade do Matrix Rust SDK. O aplicativo não implementa primitivas criptográficas.
* A comunicação com o homeserver usa HTTPS via `rustls`.

Pontos de segurança ainda pendentes estão listados em [Limitações conhecidas](limitacoes.md).
