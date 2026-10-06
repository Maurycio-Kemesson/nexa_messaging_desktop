# Limitações conhecidas

O Nexa prioriza os fluxos essenciais do desafio técnico: autenticação, sessão persistente, salas, histórico, envio e recebimento de mensagens, e recuperação E2EE. Este documento lista o que ainda não é suportado e os comportamentos conhecidos da implementação atual, com a melhoria sugerida para cada item.

## Plataformas

### macOS sem validação de ponta a ponta

As entitlements de Debug e Release incluem `com.apple.security.network.client`, necessária para o sandbox liberar as conexões com o homeserver. O app ainda não foi executado em um Mac, e pode ser necessário habilitar o **Keychain Sharing** no Xcode para o `flutter_secure_storage`.

### Validação concentrada no Windows

O desenvolvimento e os testes manuais foram feitos principalmente no Windows. macOS e Linux estão configurados (pastas de plataforma, Cargokit e dependências), mas não passaram pela mesma validação de ponta a ponta.

### Identificadores padrão do template

O bundle identifier do macOS (`com.example.nexaMessagingDesktop`) e o application ID do Linux (`com.example.nexa_messaging_desktop`) ainda são os valores gerados pelo template do Flutter. No Windows, os metadados do executável e o título da janela já foram ajustados para "Nexa Messaging".

### Executável do Windows sem assinatura

O instalador e o executável não são assinados digitalmente, então o SmartScreen exibe um aviso na primeira execução. Também não há build ARM64 nem atualização automática. Veja [Distribuição para Windows](distribuicao-windows.md#limitações).

## Autenticação e sessão

### Autenticação somente por usuário e senha

Apenas `m.login.password` é suportado. SSO, OIDC (Matrix Authentication Service), login por QR code e registro de novas contas não estão implementados. Contas criadas com login social, sem senha, não conseguem entrar.

### Logout sem o homeserver disponível

`logout_matrix` para o sync, revoga o access token no homeserver (o dispositivo **Nexa Desktop** deixa de existir), descarta o `Client` global e apaga o SQLite local. A limpeza local acontece mesmo se o homeserver estiver inacessível. Nesse caso o erro é exibido, mas o token continua válido no servidor até expirar ou até o dispositivo ser removido por outro cliente.

Se o Windows mantiver algum arquivo do SQLite aberto, a remoção do store pode falhar. O erro é registrado no console e o próximo login reaproveita o diretório.

### Uma conta por vez

O cliente Matrix é um singleton no Rust e o SQLite usa um diretório fixo (`Nexa Messaging/matrix`). Como o logout encerra o sync e apaga esse diretório, é possível trocar de conta sem fechar o app, mas não há suporte a várias contas conectadas ao mesmo tempo.

**Melhoria:** separar o store por `user_id` e manter um `Client` por conta.

### Renovação de token não configurada

O login solicita um refresh token, mas o `Client` não é construído com `handle_refresh_tokens()` e os tokens renovados não são gravados de volta no armazenamento seguro. Em homeservers que expiram o access token, a sessão restaurada pode deixar de funcionar e exigir novo login.

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

### Sync sem reinício automático

O sync é encerrado no logout, mas, se o loop terminar por erro de rede, nada o reinicia até uma nova chamada de `startMatrixSync` (novo login ou reabertura do app). Erros durante o sync são apenas registrados no console e não chegam à interface.

**Melhoria:** reiniciar o sync com backoff exponencial e expor o estado da conexão em um `Stream` para a interface.

### Broadcast com capacidade limitada

O canal de mensagens em tempo real tem capacidade de 100 itens. Se o Flutter não consumir as mensagens a tempo (por exemplo após um longo período offline seguido de um sync grande), as mensagens excedentes são descartadas do stream (`RecvError::Lagged`). Elas continuam disponíveis no histórico ao recarregar a sala.

## Observabilidade e segurança

### Logs sem níveis

Os logs de depuração com `user_id`, `device_id` e conteúdo de mensagens foram removidos. Restam apenas mensagens de erro com `eprintln!` no Rust, sem dados do usuário, e não há logger com níveis nem coleta de diagnóstico.

**Melhoria:** adotar `tracing` no Rust, com nível configurável e sem registrar conteúdo de mensagens.

## Testes

### Sem testes da camada Rust nem de integração

Os testes Flutter cobrem States, Use Cases, ViewModels e as telas de login e de mensagens, sempre com repositórios falsos. Não há testes de integração (`integration_test`) nem testes da camada Rust contra um homeserver local (por exemplo, Synapse ou Conduit em Docker).
