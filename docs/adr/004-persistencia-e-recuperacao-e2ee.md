# ADR 004 — Persistência e recuperação das chaves E2EE no cliente Matrix

## Contexto

O Nexa é uma aplicação desktop de mensageria baseada no protocolo Matrix. A comunicação com o homeserver é realizada através do Matrix Rust SDK, integrado ao Flutter por meio do Flutter Rust Bridge. Além da autenticação e sincronização das salas e mensagens, o cliente precisa ser capaz de trabalhar com salas protegidas por criptografia ponta a ponta (E2EE). Durante a implementação do histórico de mensagens, foi identificado um comportamento importante relacionado ao armazenamento das chaves criptográficas.

O cliente conseguia:

* Autenticar no homeserver;
* Restaurar uma sessão previamente salva;
* Iniciar a sincronização do Matrix;
* Recuperar eventos históricos de uma sala;
* Identificar eventos criptografados.

Entretanto, alguns eventos históricos não podiam ser descriptografados. Os logs apresentavam erros:

```text
UnableToDecryptInfo {
    session_id: Some("..."),
    reason: MissingMegolmSession {
        withheld_code: None
    }
}
```

Isso indicava que o evento criptografado existia no homeserver, porém o cliente não possuía localmente a sessão Megolm necessária para descriptografá-lo. O problema exigiu uma investigação específica sobre a relação entre:

```text
Sessão Matrix
    ↓
SQLite local
    ↓
Estado criptográfico
    ↓
Chaves Megolm
    ↓
Backup de chaves no homeserver
    ↓
Recovery Key
```
---

## Problema identificado

Inicialmente, foi considerado que restaurar a sessão Matrix seria suficiente para que o cliente recuperasse todas as informações necessárias para acessar o histórico. Porém, foi identificado que existem duas responsabilidades diferentes:

```text
Restaurar sessão
    ↓
Permite autenticar novamente como o mesmo usuário/dispositivo

Recuperar estado criptográfico
    ↓
Permite recuperar chaves necessárias para descriptografar
mensagens E2EE antigas
```

Portanto, uma sessão autenticada não garante, por si só, que todas as chaves criptográficas necessárias para o histórico estejam disponíveis localmente. Essa distinção foi fundamental para compreender o comportamento observado.

---

## Investigação

### 1. Persistência da sessão

A aplicação passou a armazenar os dados necessários para restaurar a sessão Matrix:

```text
homeserver
user_id
device_id
access_token
refresh_token
```

Essas informações são persistidas utilizando armazenamento seguro no lado Flutter. Durante a inicialização, a aplicação verifica se existe uma sessão persistida e, quando encontrada, solicita ao Rust a restauração da sessão.

O fluxo passou a ser:

```text
Aplicação inicia
      ↓
Verifica sessão persistida
      ↓
Recupera credenciais
      ↓
Cria Matrix Client
      ↓
restore_session()
      ↓
Inicia Matrix Sync
```

Essa etapa funcionou corretamente.

Os logs confirmaram:

```text
NEXA: sessão restaurada com sucesso
NEXA: cliente Matrix armazenado globalmente
NEXA: Matrix sync iniciado
```

---

## 2. Persistência do estado Matrix

Para permitir que o cliente mantenha informações locais relacionadas ao Matrix, foi configurado o armazenamento SQLite do Matrix SDK:

```rust
Client::builder()
    .homeserver_url(&homeserver)
    .sqlite_store(store_path, None)
```

O armazenamento local passou a ser utilizado tanto durante o login quanto durante a restauração da sessão. A aplicação utiliza um diretório persistente específico para os dados do Matrix:

```text
%APPDATA%\Nexa Messaging\matrix
```

Esse armazenamento é importante porque o estado criptográfico não deve depender exclusivamente da memória do processo.

---

## 3. Configuração de criptografia

O cliente foi configurado utilizando as opções de criptografia disponibilizadas pelo Matrix SDK:

```rust
EncryptionSettings {
    auto_enable_cross_signing: true,
    auto_enable_backups: true,
    backup_download_strategy:
        BackupDownloadStrategy::AfterDecryptionFailure,
}
```

A configuração possui três objetivos principais:

### Cross-signing

Permitir o gerenciamento das identidades criptográficas do dispositivo dentro do ecossistema Matrix.

### Backups

Permitir a utilização do backup de chaves armazenado no homeserver.

### Recuperação após falha de descriptografia

Utilizar:

```rust
BackupDownloadStrategy::AfterDecryptionFailure
```

para permitir que o SDK tente recuperar uma chave quando a descriptografia de um evento falhar.

---

## 4. Diagnóstico do backup

Para verificar se o problema estava relacionado à ausência de um backup no homeserver, foi adicionada uma operação de diagnóstico:

```rust
client
    .encryption()
    .backups()
    .fetch_exists_on_server()
```

O resultado foi:

```text
NEXA: backup existe no servidor? true
BACKUP MATRIX: backup_exists=true
```

Esse resultado confirmou que havia um backup de chaves disponível no homeserver. Entretanto, a existência do backup não significa automaticamente que todas as chaves necessárias para todos os eventos históricos estejam disponíveis no estado criptográfico local.

---

## 5. Recovery Key

Durante a investigação foi identificado que o Matrix SDK disponibiliza uma API específica para recuperação das chaves:

```rust
client
    .encryption()
    .recovery()
    .recover(&recovery_key)
```

A Recovery Key é utilizada para permitir que o cliente recupere as chaves criptográficas armazenadas no backup Foi implementada uma operação específica no Rust:

```rust
pub async fn recover_matrix_encryption(
    recovery_key: String,
) -> Result<(), String> {
    let client = get_authenticated_client()?;

    client
        .encryption()
        .recovery()
        .recover(&recovery_key)
        .await
        .map_err(|error| error.to_string())
}
```

A Recovery Key não é persistida nem registrada em logs.

---

## Decisão

O Nexa adotará uma estratégia de persistência e recuperação de estado criptográfico baseada nos recursos nativos do Matrix SDK.

A solução será dividida em dois fluxos diferentes.

### Fluxo normal

Durante o uso normal da aplicação:

```text
Login
  ↓
SQLite local
  ↓
Estado criptográfico local
  ↓
Matrix Sync
  ↓
Mensagens E2EE
```

A aplicação não solicitará a Recovery Key ao usuário em cada login. Enquanto o estado criptográfico local estiver disponível, a aplicação deverá reutilizá-lo.

### Fluxo de recuperação

Quando o estado criptográfico local não possuir determinadas chaves necessárias:

```text
Falha na descriptografia
        ↓
Backup de chaves disponível
        ↓
Usuário fornece Recovery Key
        ↓
Matrix SDK recupera as chaves
        ↓
Estado criptográfico é restaurado
        ↓
Mensagens históricas podem ser descriptografadas
```

A recuperação será tratada como uma operação excepcional, e não como parte obrigatória do fluxo de login.

---

## Integração com a arquitetura

A funcionalidade segue a arquitetura definida para o Nexa:

```text
RecoveryView
     ↓
RecoveryViewModel
     ↓
RecoveryUseCase
     ↓
RecoveryRepository
     ↓
Flutter Rust Bridge
     ↓
Rust
     ↓
Matrix Rust SDK
     ↓
Matrix Homeserver
```

No Flutter, a Recovery Key é recebida pela View e encaminhada ao ViewModel. O ViewModel delega a operação ao Use Case:

```dart
await _recoveryUseCase(
  recoveryKey: recoveryKey,
);
```

O Use Case delega ao Repository:

```dart
return _repository.recover(
  recoveryKey: recoveryKey,
);
```

O Repository utiliza a API gerada pelo Flutter Rust Bridge:

```dart
return rust_api.recoverMatrixEncryption(
  recoveryKey: recoveryKey,
);
```

A operação criptográfica permanece no Rust, onde está localizada a integração com o Matrix SDK.

---

## Desafios encontrados

### 1. Diferenciar autenticação de recuperação criptográfica

O principal desafio foi compreender que uma sessão Matrix restaurada não representa necessariamente todo o estado criptográfico necessário para acessar o histórico. A aplicação poderia estar autenticada corretamente e ainda assim apresentar:

```text
MissingMegolmSession
```

para determinados eventos.

Essa distinção tornou-se uma decisão importante da arquitetura.

---

### 2. Histórico disponível, mas parcialmente descriptografável

O Matrix SDK conseguiu retornar eventos históricos da sala. Porém, alguns eventos não puderam ser convertidos em mensagens porque suas sessões Megolm não estavam disponíveis. O comportamento observado foi semelhante a:

```text
eventos retornados = 29
```

seguido por múltiplas ocorrências de:

```text
MissingMegolmSession
```

enquanto alguns eventos E2EE eram descriptografados corretamente.
Isso demonstrou que:

```text
Evento existente no servidor
        ≠
Evento necessariamente descriptografável pelo cliente
```

---

### 3. Perda do estado criptográfico local

Durante a investigação foi necessário lidar com um cenário em que o armazenamento criptográfico local havia sido perdido. Isso permitiu reproduzir um caso semelhante ao que pode acontecer quando um usuário instala o aplicativo novamente ou utiliza um novo dispositivo. A situação demonstrou a importância de existir um mecanismo de recuperação baseado no backup de chaves.

---

### 4. Recuperação sem expor informações sensíveis

A Recovery Key possui caráter altamente sensível. Por esse motivo, a implementação adotou as seguintes regras:

* Não armazenar a Recovery Key;
* Não registrar a Recovery Key em logs;
* Não incluí-la em entidades persistidas;
* Mantê-la apenas durante a operação de recuperação;
* Não enviá-la para serviços externos além da operação necessária no Matrix SDK.

---

## Resultado

Após a implementação da recuperação, o fluxo foi validado na aplicação. Os logs demonstraram:

```text
NEXA: backup existe no servidor? true
NEXA: iniciando recuperação E2EE...
NEXA: recuperação E2EE concluída
```

Após retornar à aplicação e carregar novamente as conversas, as mensagens históricas anteriormente indisponíveis passaram a ser carregadas corretamente. Esse comportamento confirmou que a Recovery Key estava sendo utilizada corretamente para recuperar o estado criptográfico necessário.

---

## Alternativas consideradas

### Solicitar Recovery Key durante todo login

Foi descartada. Isso prejudicaria a experiência do usuário e não representa o comportamento esperado de um cliente Matrix normal. A Recovery Key deve ser utilizada em cenários de recuperação, não como uma segunda senha obrigatória em cada inicialização.

### Armazenar a Recovery Key localmente

Foi descartada por questões de segurança. Armazenar permanentemente a Recovery Key diminuiria o benefício de possuir uma chave de recuperação protegida e aumentaria o impacto de um comprometimento da máquina.

### Implementar a criptografia diretamente no Flutter

Foi descartada. A comunicação com o Matrix e o gerenciamento criptográfico já são responsabilidades do Matrix Rust SDK. Manter essa responsabilidade no Rust reduz a duplicação de lógica criptográfica e mantém a integração com o SDK em uma única camada.

### Implementar manualmente o gerenciamento das sessões Megolm

Foi descartada. O Matrix SDK já fornece mecanismos para gerenciamento de E2EE, backups e recuperação. Implementar esse comportamento manualmente aumentaria significativamente a complexidade e o risco de erros relacionados à criptografia.

---

## Consequências

### Positivas

* Sessões Matrix podem ser restauradas sem solicitar Recovery Key.
* O estado criptográfico pode utilizar armazenamento persistente.
* O cliente pode recuperar chaves a partir do backup Matrix.
* Mensagens históricas E2EE podem ser recuperadas após perda do estado criptográfico local.
* A criptografia permanece sob responsabilidade do Matrix Rust SDK.
* A Recovery Key não precisa ser armazenada pelo aplicativo.
* O fluxo de recuperação está separado da autenticação normal.

### Negativas

* O cliente passa a depender do armazenamento SQLite local para preservar o estado criptográfico.
* A recuperação depende da existência de um backup válido no homeserver.
* A recuperação depende da disponibilidade da Recovery Key.
* Nem todo evento histórico necessariamente poderá ser recuperado caso a chave correspondente não exista no backup.
* A funcionalidade de recuperação adiciona uma tela e um fluxo adicional à aplicação.
* O comportamento de E2EE depende de APIs e comportamentos específicos da versão do Matrix SDK utilizada.

---

## Melhorias futuras

### 1. Detectar automaticamente falhas de descriptografia

Atualmente, a recuperação pode ser acionada manualmente. Uma evolução seria detectar automaticamente uma quantidade significativa de falhas:

```text
MissingMegolmSession
        ↓
Backup disponível?
        ↓
Sim
        ↓
Orientar usuário sobre recuperação
```

A aplicação poderia apresentar uma mensagem contextual em vez de depender exclusivamente da tela de recuperação.

### 2. Melhorar o fluxo de recuperação

A tela atual representa uma implementação funcional do fluxo. Futuramente, poderia apresentar:

* Explicação mais clara sobre o que é a Recovery Key;
* Confirmação antes da operação;
* Indicador de progresso;
* Resultado detalhado;
* Opção de voltar para a conversa que originou a recuperação.

### 3. Melhorar o diagnóstico de E2EE

O cliente poderia diferenciar estados como:

```text
Backup inexistente
Backup existente
Chave disponível localmente
Chave recuperada
Chave indisponível
Falha de recuperação
```

Isso permitiria apresentar mensagens de erro mais úteis ao usuário.

### 4. Avaliar recuperação automática após falha

O comportamento atual utiliza:

```rust
BackupDownloadStrategy::AfterDecryptionFailure
```

Uma evolução futura poderia avaliar cuidadosamente se determinadas falhas devem disparar uma tentativa automática de recuperação, sempre considerando segurança e experiência do usuário.

### 5. Testes automatizados de recuperação

O fluxo de recuperação pode receber testes específicos para cenários como:

```text
Recovery Key válida
Recovery Key inválida
Backup inexistente
Falha de comunicação com homeserver
Recuperação bem-sucedida
```

Esses testes aumentariam a confiabilidade da funcionalidade.

---

## Limitações conhecidas

A recuperação não garante que qualquer mensagem histórica possa ser descriptografada. Uma mensagem E2EE depende da existência da chave correspondente.

Portanto:

```text
Backup disponível
        ≠
Todas as mensagens históricas recuperáveis
```

O Nexa depende dos mecanismos fornecidos pelo Matrix SDK e pelo homeserver para recuperação das chaves. Além disso, a implementação atual foi desenvolvida para atender ao escopo do desafio técnico e ainda não possui todos os recursos de recuperação encontrados em clientes Matrix completos.

---

## Decisão final

O Nexa utilizará o gerenciamento de criptografia e recuperação de chaves fornecido pelo Matrix Rust SDK, mantendo o estado local em SQLite e utilizando a Recovery Key somente em situações de recuperação. A aplicação não implementará manualmente o protocolo criptográfico nem armazenará permanentemente a Recovery Key.

A decisão busca equilibrar:

```text
Segurança
    +
Persistência
    +
Recuperabilidade
    +
Simplicidade arquitetural
```

mantendo a responsabilidade criptográfica dentro do Matrix Rust SDK e expondo ao Flutter apenas as operações necessárias através do Flutter Rust Bridge.
