# Limitações conhecidas

O Nexa prioriza os fluxos essenciais do desafio técnico: autenticação, sessão persistente, salas, histórico, envio e recebimento de mensagens, e recuperação E2EE. Este documento lista o que ainda não é suportado e os comportamentos conhecidos da implementação atual, com a melhoria sugerida para cada item.

## Plataformas

### macOS sem permissão de rede de saída

O app roda em sandbox no macOS (`com.apple.security.app-sandbox`), mas as entitlements não incluem `com.apple.security.network.client`. Sem essa permissão, o sandbox bloqueia as conexões de saída e o cliente não consegue acessar o homeserver.

**Correção:** adicionar a chave abaixo em `macos/Runner/DebugProfile.entitlements` e `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Também pode ser necessário habilitar o **Keychain Sharing** no Xcode para o `flutter_secure_storage`.

### Validação concentrada no Windows

O desenvolvimento e os testes manuais foram feitos principalmente no Windows. macOS e Linux estão configurados (pastas de plataforma, Cargokit e dependências), mas não passaram pela mesma validação de ponta a ponta.

### Identificadores padrão do template

O bundle identifier do macOS (`com.example.nexaMessagingDesktop`) e o application ID do Linux (`com.example.nexa_messaging_desktop`) ainda são os valores gerados pelo template do Flutter. No Windows, os metadados do executável e o título da janela já foram ajustados para "Nexa Messaging".

### Executável do Windows sem assinatura

O instalador e o executável não são assinados digitalmente, então o SmartScreen exibe um aviso na primeira execução. Também não há build ARM64 nem atualização automática. Veja [Distribuição para Windows](distribuicao-windows.md#limitações).

## Autenticação e sessão

### Autenticação somente por usuário e senha

Apenas `m.login.password` é suportado. SSO, OIDC (Matrix Authentication Service), login por QR code e registro de novas contas não estão implementados. Contas criadas com login social, sem senha, não conseguem entrar.

### Logout apenas local

O logout apaga a sessão do `flutter_secure_storage`, mas:

* não chama o logout do Matrix, então o dispositivo **Nexa Desktop** e o access token continuam válidos no servidor;
* não remove o `Client` global do Rust nem interrompe o sync em execução;
* não apaga o SQLite local.

**Melhoria:** expor uma função `logout_matrix` no Rust que chame `client.matrix_auth().logout()`, encerre o sync e limpe o cliente global e, opcionalmente, o store.

### Uma conta por processo

O cliente Matrix é um singleton no Rust e o SQLite usa um diretório fixo (`Nexa Messaging/matrix`), compartilhado por qualquer conta. Por consequência:

* não há suporte a múltiplas contas;
* trocar de conta sem fechar o app pode manter o sync da conta anterior ativo, porque `start_matrix_sync` não reinicia um sync já em execução;
* entrar com outra conta sobre o mesmo store pode gerar conflito de estado. O recomendado é apagar o diretório local antes (ver [Configuração do Matrix](configuracao-matrix.md#redefinindo-o-estado-local)).

**Melhoria:** separar o store por `user_id` e encerrar o cliente anterior no logout.

### Renovação de token não configurada

O login solicita um refresh token, mas o `Client` não é construído com `handle_refresh_tokens()` e os tokens renovados não são gravados de volta no armazenamento seguro. Em homeservers que expiram o access token, a sessão restaurada pode deixar de funcionar e exigir novo login.

### Configuração de criptografia aplicada só no login

`EncryptionSettings` (cross-signing e backups automáticos) é aplicada em `login_matrix`, mas não em `restore_matrix_session`. Em uma sessão restaurada, o download automático de chaves do backup após falha de descriptografia não fica configurado da mesma forma.

### SQLite sem senha

O store é aberto com `sqlite_store(path, None)`, ou seja, sem passphrase. As chaves E2EE ficam protegidas apenas pelas permissões de arquivo do usuário no sistema operacional.

**Melhoria:** gerar uma passphrase aleatória, guardá-la no `flutter_secure_storage` e repassá-la ao `sqlite_store`.

## Mensagens e salas

### Somente mensagens de texto

Apenas eventos `m.room.message` do tipo `m.text` são exibidos. Imagens, arquivos, áudio, vídeo, emotes, notices, edições, reações, respostas, threads, redações e eventos de estado (entradas, saídas, mudança de nome) são ignorados. O envio também é limitado a texto puro (`text_plain`), sem formatação ou Markdown.

### Mensagens não descriptografáveis ocultas

Eventos `UnableToDecrypt` são descartados do histórico sem aviso. O usuário não vê um marcador do tipo "não foi possível descriptografar esta mensagem" e precisa saber que deve usar a recuperação E2EE (ver [ADR 004](adr/004-persistencia-e-recuperacao-e2ee.md)).

### Páginas de histórico com menos itens

Cada página busca 50 **eventos**, não 50 mensagens. Como eventos de estado, mídia e mensagens não descriptografáveis são filtrados, uma página pode trazer poucas mensagens ou nenhuma.

### Lista de salas sem atualização em tempo real

`get_rooms` executa um `sync_once` e devolve as salas uma vez, ao abrir a tela principal. Novas salas, convites e mudanças de nome não aparecem até a lista ser recarregada. Também não há contador de não lidas, última mensagem, avatar, ordenação por atividade, aceite de convites nem criação de salas.

### Envio sem atualização otimista

Após o envio, a ViewModel recarrega a primeira página do histórico, em vez de inserir a mensagem localmente. Não há estado de "enviando", fila offline ou reenvio em caso de falha. Se o usuário tiver paginado mensagens antigas, a lista volta para a página mais recente.

### Remetente exibido como ID

O remetente é exibido pelo Matrix ID (`@usuario:servidor`), sem nome de exibição ou avatar.

### Recursos de mensageria fora do escopo

Indicadores de digitação, confirmações de leitura, presença, notificações do sistema operacional, busca, verificação interativa de dispositivos (emoji/QR) e chamadas não estão implementados.

## Integração Flutter/Rust

### Erros sem tipagem na fronteira Flutter/Rust

As funções retornam `Result<T, String>`. O Flutter recebe apenas a mensagem de erro do SDK e não consegue diferenciar credencial inválida, falha de rede, sessão expirada ou sala inexistente. As mensagens exibidas ao usuário são as mensagens técnicas do SDK, em inglês.

**Melhoria:** criar um `enum` de erro no Rust (por exemplo `NexaError { InvalidCredentials, Network, SessionExpired, ... }`), que o FRB converte em uma classe Dart tratável com `switch`.

### Sync sem controle de ciclo de vida

Não existe função para parar o sync. Se o loop terminar por erro, nada o reinicia automaticamente até uma nova chamada de `startMatrixSync`. Além disso, `startMatrixSync()` é chamada sem `await` no Repository, então um erro na inicialização do sync não chega à interface.

### Broadcast com capacidade limitada

O canal de mensagens em tempo real tem capacidade de 100 itens. Se o Flutter não consumir as mensagens a tempo (por exemplo após um longo período offline seguido de um sync grande), as mensagens excedentes são descartadas do stream (`RecvError::Lagged`). Elas continuam disponíveis no histórico ao recarregar a sala.

## Observabilidade e segurança

### Logs de depuração com dados sensíveis

O Rust escreve logs com `println!` (prefixo `NEXA:`) que incluem `user_id`, `device_id` e o **conteúdo das mensagens recebidas**. O Flutter usa `debugPrint` com informações de rota e de paginação. Esses logs foram úteis durante a investigação de E2EE, mas devem ser removidos ou substituídos por um logger com níveis (`tracing` no Rust) antes de uma distribuição. Esse ponto faz parte da [issue #10 — Revisar segurança e tratamento de erros](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/10).

### Diagnóstico exposto em produção

A rota `/rust-test` e a chamada `checkMatrixBackup()` durante a restauração da sessão existem para diagnóstico e continuam ativas no build de release.

## Testes

### Testes Rust dependentes de rede

Os testes em `rust/src/api/matrix.rs` acessam `https://matrix.org`. O teste `should_login_to_matrix` usa usuário e senha vazios e, portanto, sempre falha. Ele precisa ser marcado com `#[ignore]` ou ler credenciais de variáveis de ambiente.

### Sem testes de integração ou de widget

Os testes cobrem States, Use Cases e ViewModels com repositórios falsos. Não há testes de widget, testes de integração (`integration_test`) nem testes da camada Rust contra um homeserver local.
