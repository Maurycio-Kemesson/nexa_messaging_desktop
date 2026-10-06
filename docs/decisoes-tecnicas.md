# Decisões técnicas

Este documento resume as principais decisões técnicas do Nexa. As decisões com mais impacto têm um **Architecture Decision Record (ADR)** com contexto, alternativas e consequências completos.

## ADRs

| ADR | Decisão |
| --- | --- |
| [ADR 001 — Lint e análise estática](adr/001-lint-e-analise-estatica.md) | Usar `flutter_lints` com `flutter analyze` e `dart format` obrigatórios antes de cada PR. |
| [ADR 002 — Arquitetura MVVM](adr/002-arquitetura-mvvm.md) | Usar MVVM na apresentação, com Use Cases e Repositories, isolando o Matrix da UI. |
| [ADR 003 — Mason para padronizar features](adr/003-adocao-mason-para-padronizacao-de-features.md) | Gerar a estrutura de cada feature com um brick do Mason. |
| [ADR 004 — Persistência e recuperação E2EE](adr/004-persistencia-e-recuperacao-e2ee.md) | Persistir o estado criptográfico em SQLite e recuperar chaves com a Recovery Key, sem armazená-la. |

## Resumo das decisões

### Matrix Rust SDK em vez de um cliente Matrix em Dart

A integração com o Matrix fica no Rust, usando o [`matrix-sdk`](https://github.com/matrix-org/matrix-rust-sdk), o SDK oficial mantido pela Matrix.org e usado pelo Element X. Ele já implementa sincronização, armazenamento local e toda a criptografia (Olm/Megolm, cross-signing, backup de chaves). Implementar E2EE em Dart seria uma reescrita de código criptográfico sensível, com risco alto de erro.

### Flutter Rust Bridge para a fronteira Dart/Rust

O FRB gera o código de FFI e serialização a partir das assinaturas Rust, com suporte a `async`, `Option`, `Vec`, structs e streams (`StreamSink`). Isso evita escrever bindings C manualmente e mantém os tipos dos dois lados sincronizados. As versões do runtime Dart, do crate e do codegen são fixadas em `2.13.0`. Detalhes em [Comunicação Flutter/Rust](comunicacao-flutter-rust.md).

### API Rust pequena e orientada a casos de uso

O Rust expõe funções de alto nível (`login_matrix`, `restore_matrix_session`, `logout_matrix`, `get_rooms`, `get_messages`, `send_message`, `subscribe_to_messages`) em vez de expor os objetos do SDK. Os tipos trocados são DTOs simples (`RoomSummary`, `MessageSummary`, `MessagesPage`). Assim, mudanças na API do `matrix-sdk` ficam contidas no Rust, e o Flutter não precisa lidar com handles opacos de objetos Rust.

### Cliente Matrix único e global no Rust

O `Client` autenticado fica em um `OnceLock<Mutex<Option<Client>>>`. O Flutter não precisa guardar nem repassar referências ao cliente: cada função obtém o cliente com `get_authenticated_client()`. A consequência é que o processo suporta uma única conta por vez (ver [Limitações](limitacoes.md#uma-conta-por-vez)).

### Sync em thread dedicada e broadcast para o Flutter

O `client.sync()` é um loop infinito. Ele roda em uma `std::thread` com runtime Tokio próprio, para não ocupar o runtime usado pelas chamadas do FRB. As mensagens recebidas são publicadas em um `tokio::sync::broadcast`, e cada assinatura do Flutter (`subscribe_to_messages`) cria um receptor. Isso desacopla o produtor (sync) dos consumidores (telas) e permite mais de um ouvinte.

### Histórico com paginação por token

`get_messages` usa `room.messages()` com `MessagesOptions::backward()` e lotes de 50 eventos, devolvendo o `end_token` para a próxima página. A paginação acontece quando o usuário rola até o topo da conversa. Essa abordagem usa diretamente a paginação da API do Matrix sem manter uma timeline completa em memória.

### Sessão no cofre do sistema operacional

Os tokens da sessão são persistidos com `flutter_secure_storage`, que usa o Credential Manager no Windows, o Keychain no macOS e o `libsecret` no Linux. A senha nunca é persistida. O estado criptográfico, que é maior e gerenciado pelo SDK, fica no SQLite do próprio `matrix-sdk`.

### Erros como `String` na fronteira

As funções Rust retornam `Result<T, String>`. Isso mantém a fronteira simples e faz o FRB lançar uma exceção no Dart, tratada pelas ViewModels. A troca é a perda de tipagem dos erros (ver [Limitações](limitacoes.md#erros-sem-tipagem-na-fronteira-flutterrust)).

### Riverpod para estado e injeção de dependências

O Riverpod 3 (`Notifier` + `NotifierProvider`) implementa as ViewModels e também a injeção de Repositories e Use Cases. Nos testes, os providers são sobrescritos com implementações falsas, sem depender do Rust nem da rede.

### go_router com redirecionamento por autenticação

A navegação é declarativa com `go_router`. O `redirect` centraliza as regras de acesso (login obrigatório, sem voltar para o login quando autenticado), e o `RouterRefreshNotifier` reavalia as rotas quando o estado de autenticação muda.

### Cargokit para compilar o Rust

O template do FRB inclui o Cargokit (`rust_builder/`), que integra o `cargo build` ao build nativo de cada plataforma (CMake no Windows/Linux, CocoaPods no macOS). Com isso, `flutter run` e `flutter build` funcionam sem passos manuais de compilação do Rust.
