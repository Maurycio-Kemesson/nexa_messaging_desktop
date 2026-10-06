# Gestão do projeto

As atividades do Nexa foram planejadas e acompanhadas em um quadro do **GitHub Projects**:

**Quadro:** [Nexa Messaging Desktop — GitHub Projects](https://github.com/users/Maurycio-Kemesson/projects/3)

Cada requisito do desafio virou uma **GitHub Issue** no quadro. Cada issue foi desenvolvida em uma branch própria e integrada à `develop` por um Pull Request.

## Divisão das atividades

O trabalho foi dividido em etapas incrementais. Cada etapa depende da anterior e entrega uma parte executável do aplicativo.

```text
Fundação           Integração            Funcionalidades Matrix                 Qualidade e entrega
───────────        ────────────          ───────────────────────────            ───────────────────
#1 Flutter    ──►  #3 Matrix SDK    ──►  #4 Autenticação                ──►   #12 Testes
#2 Rust + FRB                            #5 Sessão                            #10 Segurança e erros
                                         #6 Salas                             #11 Documentação
                                         #7 Histórico
                                         #8 Envio
                                         #9 Atualização em tempo real
```

| Etapa | Issue | Pull Request | Entrega |
| --- | --- | --- | --- |
| Fundação | [#1 Configurar projeto Flutter Desktop](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/1) | [#13](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/13) | Projeto Flutter para Windows, macOS e Linux, com lints e análise estática. |
| Fundação | [#2 Configurar Rust e Flutter Rust Bridge](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/2) | [#14](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/14) | Crate Rust, Cargokit e geração de código do FRB. |
| Integração | [#3 Integrar Matrix Rust SDK](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/3) | [#15](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/15) | Cliente Matrix criado no Rust e chamado pelo Flutter. |
| Funcionalidades | [#4 Implementar autenticação no Matrix](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/4) | [#16](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/16) | Login com homeserver, usuário e senha. |
| Funcionalidades | [#5 Implementar persistência e restauração da sessão](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/5) | [#16](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/16) | Sessão no armazenamento seguro e restauração ao iniciar o app. |
| Funcionalidades | [#6 Implementar listagem de salas](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/6) | [#17](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/17) | Lista e seleção das salas do usuário. |
| Funcionalidades | [#7 Implementar histórico de mensagens](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/7) | [#18](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/18) | Histórico paginado com suporte a salas E2EE. |
| Funcionalidades | [#8 Implementar envio de mensagens](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/8) | [#19](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/19) | Envio de mensagens de texto. |
| Funcionalidades | [#9 Atualização das conversas](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/9) | [#20](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/20) | Sync contínuo e stream de mensagens, além da recuperação E2EE ([ADR 004](adr/004-persistencia-e-recuperacao-e2ee.md)). |
| Qualidade | [#12 Revisar testes dos principais fluxos](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/12) | [#21](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/pull/21) | Testes de State, Use Case e ViewModel das features. |
| Qualidade | [#10 Revisar segurança e tratamento de erros](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/10) | — | Em andamento. |
| Entrega | [#11 Documentar arquitetura e configuração](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/11) | — | Esta documentação. |

## Fluxo de trabalho

```text
Issue no quadro ─► Feature branch ─► TDD ─► Implementação ─► Pull Request ─► develop
```

1. A issue é movida para "em andamento" no quadro.
2. Uma branch é criada a partir da `develop` com o prefixo `feature/` (por exemplo `feature/implement-matrix-message-history`).
3. Os testes da ViewModel e do Use Case são escritos junto com a implementação. Para features novas, a estrutura inicial é gerada pelo brick do Mason ([ADR 003](adr/003-adocao-mason-para-padronizacao-de-features.md)).
4. Antes do Pull Request, os comandos abaixo precisam passar:

   ```bash
   dart format .
   flutter analyze
   flutter test
   ```

5. O Pull Request é integrado à `develop`, e a issue é fechada no quadro.

```bash
git checkout develop
git pull origin develop
git checkout -b feature/nome-da-funcionalidade
```

### Conventional Commits

Os commits seguem a convenção [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: implementar autenticação Matrix
fix: corrigir tratamento de credenciais inválidas
test: adicionar testes de autenticação
refactor: simplificar fluxo de autenticação
docs: documentar arquitetura de autenticação
chore: configurar analyzer e lints
```
