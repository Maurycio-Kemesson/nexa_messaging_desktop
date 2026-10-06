# Configuração do Matrix

O Nexa é um cliente da [Client-Server API do Matrix](https://spec.matrix.org/latest/client-server-api/). Ele não inclui um homeserver: é necessário ter uma conta em um homeserver existente.

## Homeserver

O homeserver é informado na tela de login. O campo vem preenchido com `https://matrix.org`, mas aceita qualquer homeserver compatível (Synapse, Conduit, Dendrite etc.).

Requisitos do homeserver:

* Acessível por **HTTPS**.
* Login por **usuário e senha** (`m.login.password`) habilitado. Login por SSO/OIDC não é suportado. Veja [Limitações](limitacoes.md#autenticação-somente-por-usuário-e-senha).
* A URL deve ser a da Client-Server API (por exemplo `https://matrix.org` ou `https://matrix.seudominio.com`). A descoberta via `.well-known` a partir do nome do servidor não é feita pela tela de login.

Não há variáveis de ambiente ou arquivos de configuração para o Matrix. Todos os parâmetros são informados na interface e a sessão é persistida pelo próprio app.

## Conta de teste

Se você ainda não tem uma conta Matrix, crie uma seguindo o guia oficial em [matrix.org/try-matrix](https://matrix.org/try-matrix/). Para testar com o `matrix.org`:

1. Crie a conta em um cliente oficial, como o [Element Web](https://app.element.io/), usando **usuário e senha**. Contas criadas com login social (Google, GitHub etc.) não têm senha e não conseguem entrar pelo Nexa.
2. Entre em uma ou mais salas e envie algumas mensagens pelo Element.
3. Para testar E2EE, crie uma sala criptografada e configure o **backup de chaves** no Element (Configurações → Segurança e Privacidade → Backup seguro). Guarde a **Recovery Key** gerada.

No Nexa:

| Campo | Exemplo |
| --- | --- |
| Homeserver | `https://matrix.org` |
| Usuário | `seu_usuario` ou `@seu_usuario:matrix.org` |
| Senha | Senha da conta |

## O que acontece no login

O login é feito em `login_matrix` (`rust/src/api/client.rs`):

```rust
Client::builder()
    .homeserver_url(&homeserver)
    .sqlite_store(store_path, None)
    .with_encryption_settings(EncryptionSettings {
        auto_enable_cross_signing: true,
        auto_enable_backups: true,
        backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
    })
    .build()
    .await?;

client
    .matrix_auth()
    .login_username(&username, &password)
    .initial_device_display_name("Nexa Desktop")
    .request_refresh_token()
    .send()
    .await?;
```

* Cada login cria um **novo dispositivo** na conta, com o nome **Nexa Desktop**. Ele aparece na lista de sessões de outros clientes (por exemplo no Element).
* O SDK gera as chaves do dispositivo e as guarda no SQLite local.
* `auto_enable_cross_signing` e `auto_enable_backups` permitem que o SDK configure cross-signing e backup de chaves quando a conta ainda não tem essa configuração.
* `AfterDecryptionFailure` faz o SDK tentar baixar uma chave do backup quando um evento não puder ser descriptografado.
* O SDK pede um refresh token ao servidor, que é guardado junto com a sessão.

## Persistência

São dois armazenamentos com responsabilidades diferentes:

| Armazenamento | Conteúdo | Local |
| --- | --- | --- |
| `flutter_secure_storage` (chave `auth_session`) | `homeserver`, `userId`, `deviceId`, `accessToken`, `refreshToken` | Cofre de credenciais do sistema operacional |
| SQLite do Matrix SDK | Estado das salas, tokens de sincronização, chaves do dispositivo e sessões Olm/Megolm | `<diretório de dados>/Nexa Messaging/matrix` |

O caminho do SQLite em cada plataforma está em [Arquitetura → Persistência local do Matrix](arquitetura.md#persistência-local-do-matrix).

Ao iniciar o app, a sessão salva é lida e passada para `restore_matrix_session`, que recria o `Client` sobre o mesmo SQLite e chama `restore_session`. Não é necessário digitar a senha novamente.

## Criptografia ponta a ponta (E2EE)

As salas criptografadas são tratadas inteiramente pelo Matrix Rust SDK:

* As mensagens enviadas para salas com E2EE são cifradas automaticamente pelo `room.send()`.
* As mensagens recebidas são descriptografadas com as chaves Megolm disponíveis no SQLite.
* Mensagens cuja chave não está disponível (`UnableToDecrypt`) não aparecem no histórico.

### Recuperação das chaves

Um dispositivo novo não tem as chaves das mensagens antigas. Para recuperá-las a partir do backup no servidor:

1. Na tela principal, clique no ícone de nuvem (**Recuperar chaves E2EE**).
2. Informe a **Recovery Key** da conta.
3. Ao concluir, volte para a conversa. As mensagens que tinham chave no backup passam a ser exibidas.

A Recovery Key é usada somente nessa operação e não é armazenada. O racional e os casos testados estão no [ADR 004](adr/004-persistencia-e-recuperacao-e2ee.md).

## Redefinindo o estado local

Para começar do zero (por exemplo, ao trocar de conta ou após um estado inconsistente):

1. Use o botão **Sair**. O app revoga o access token no homeserver, para o sync e apaga o SQLite local e a sessão do armazenamento seguro.
2. Se o homeserver estiver inacessível, a limpeza local ainda acontece. O dispositivo **Nexa Desktop** pode permanecer na conta até o token expirar ou até ser removido por outro cliente. Veja [Limitações](limitacoes.md#logout-sem-o-homeserver-disponível).

Se o app recusar abrir com *the account in the store doesn't match the account in the constructor*, o SQLite local é de outro dispositivo. Feche o app e apague `%APPDATA%\Nexa Messaging`. No próximo login o store é recriado; salas com E2EE podem exigir a Recovery Key.
