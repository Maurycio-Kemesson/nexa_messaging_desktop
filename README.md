# Nexa

Cliente de mensageria desktop multiplataforma desenvolvido com **Flutter**, **Rust**, **Matrix Rust SDK** e **Flutter Rust Bridge**.

**Repositório:** [github.com/Maurycio-Kemesson/nexa_messaging_desktop](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop)
**Quadro do projeto:** [GitHub Projects — Nexa Messaging Desktop](https://github.com/users/Maurycio-Kemesson/projects/3)

## Sumário

* [Sobre o projeto](#sobre-o-projeto)
* [Plataformas suportadas](#plataformas-suportadas)
* [Download (Windows)](#download-windows)
* [Início rápido](#início-rápido)
* [Arquitetura em resumo](#arquitetura-em-resumo)
* [Funcionalidades](#funcionalidades)
* [Testes](#testes)
* [Documentação completa](#documentação-completa)
* [Status do projeto](#status-do-projeto)
* [Licença](#licença)

## Sobre o projeto

O **Nexa** é um cliente de mensageria desktop desenvolvido como parte de um desafio técnico. Ele se conecta a um **Matrix Homeserver** através do **Matrix Rust SDK**, e a integração entre Flutter e Rust é feita pelo **Flutter Rust Bridge**.

| Tecnologia | Versão |
| --- | --- |
| Flutter / Dart | 3.41.6 / 3.11.4 |
| Rust | 1.99.0 (stable) |
| Flutter Rust Bridge | 2.13.0 |
| Matrix Rust SDK | 0.19.1 |
| Riverpod / go_router | 3.3 / 17.5 |

## Plataformas suportadas

| Plataforma | Status |
| --- | --- |
| Windows 10/11 (x64) | Suportada (plataforma principal de desenvolvimento) |
| macOS | Configurada; permissão de rede nas entitlements já incluída ([detalhes](docs/limitacoes.md#macos-sem-validação-de-ponta-a-ponta)) |
| Linux (x64) | Configurada; requer `libgtk-3-dev` e `libsecret-1-dev` |

Android, iOS e Web estão fora do escopo.

## Download (Windows)

Para testar sem configurar o ambiente de desenvolvimento, baixe a versão mais recente em [Releases](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/releases):

* **`nexa-messaging-<versão>-windows-x64-setup.exe`**: instalador. Não exige administrador e inclui atalho no Menu Iniciar e desinstalador.
* **`nexa-messaging-<versão>-windows-x64.zip`**: versão portátil. Basta extrair e executar `nexa_messaging_desktop.exe`.

Requer Windows 10/11 x64 e uma [conta Matrix](#conta-matrix). Se ainda não tiver uma, crie em [matrix.org/try-matrix](https://matrix.org/try-matrix/). O executável não é assinado, então o SmartScreen pode exibir um aviso: clique em **Mais informações → Executar assim mesmo**. Detalhes e instruções para gerar os pacotes estão em [Distribuição para Windows](docs/distribuicao-windows.md).

## Início rápido

Pré-requisitos: Flutter 3.41+, Rust stable, CMake e o toolchain C/C++ da plataforma. A lista completa por sistema operacional está em [Configuração do ambiente](docs/configuracao-ambiente.md).

```bash
git clone https://github.com/Maurycio-Kemesson/nexa_messaging_desktop.git
cd nexa_messaging_desktop
flutter pub get

flutter run -d windows   # ou: -d macos | -d linux
```

O Rust é compilado automaticamente durante o `flutter run` pelo Cargokit. A primeira execução demora mais por causa da compilação do `matrix-sdk`.

### Conta Matrix

Para entrar no Nexa você precisa de uma conta Matrix. O Nexa é apenas o cliente e não cria contas.

* **Já tem conta:** use o homeserver, o usuário e a senha dela.
* **Não tem conta:** crie uma em [matrix.org/try-matrix](https://matrix.org/try-matrix/). O jeito mais simples é usar o Element Web no servidor `matrix.org`.

A conta precisa ter **usuário e senha**. Contas criadas com login social (Google, GitHub, Apple etc.) não têm senha e não conseguem entrar pelo Nexa.

Na tela de login, informe o homeserver (padrão `https://matrix.org`), o usuário e a senha. Veja [Configuração do Matrix](docs/configuracao-matrix.md) para preparar salas de teste e configurar o E2EE.

Qualidade antes de cada Pull Request:

```bash
dart format .
flutter analyze
flutter test
```

Após alterar a API Rust em `rust/src/api/`:

```bash
flutter_rust_bridge_codegen generate
```

## Arquitetura em resumo

```text
Flutter                                         Rust
┌──────────────────────────────────────┐        ┌───────────────────────────┐
│ View → ViewModel → Use Case → Repo   │  FRB   │ rust/src/api              │
│        (Riverpod)          │         │ ─────► │   ↓                       │
│                            ▼         │ ◄───── │ Matrix Rust SDK ─► SQLite │
│               flutter_secure_storage │ Stream └─────────┬─────────────────┘
└──────────────────────────────────────┘                  │ HTTPS
                                                          ▼
                                                  Matrix Homeserver
```

* A apresentação segue **MVVM** com Use Cases e Repositories. Somente os Repositories conhecem o código gerado pelo FRB.
* O Rust concentra toda a comunicação com o Matrix, a sincronização e a criptografia ponta a ponta.
* Chamadas Flutter → Rust são `Future`s. Novas mensagens chegam do Rust ao Flutter por um `Stream` (`StreamSink` do FRB).
* A sessão fica no cofre de credenciais do sistema operacional. O estado do Matrix e as chaves E2EE ficam no SQLite do SDK.

Detalhes em [Arquitetura](docs/arquitetura.md) e [Comunicação Flutter/Rust](docs/comunicacao-flutter-rust.md).

## Funcionalidades

* Login no homeserver com usuário e senha.
* Persistência e restauração automática da sessão.
* Logout.
* Listagem e seleção de salas.
* Histórico de mensagens com paginação, incluindo salas com E2EE.
* Envio de mensagens de texto.
* Recebimento de mensagens em tempo real.
* Recuperação das chaves E2EE com a Recovery Key.

## Testes

O projeto tem testes de State, Use Case, ViewModel e widget das features `auth`, `home`, `rooms`, `messages` e `recovery`. As ViewModels e as telas são testadas com Repositories falsos injetados pelo Riverpod, então os testes não dependem do Rust nem de rede.

```bash
flutter test
```

Estratégia, cobertura por feature e como escrever novos testes: [Testes](docs/testes.md).

## Documentação completa

| Documento | Conteúdo |
| --- | --- |
| [Configuração do ambiente](docs/configuracao-ambiente.md) | Plataformas, versões, dependências por SO, execução, build, codegen do FRB, testes e problemas comuns. |
| [Distribuição para Windows](docs/distribuicao-windows.md) | Instalador e versão portátil, conteúdo do pacote, geração com Inno Setup e publicação de releases. |
| [Configuração do Matrix](docs/configuracao-matrix.md) | Homeserver, conta de teste, login, persistência, E2EE, recuperação de chaves e reset do estado local. |
| [Arquitetura](docs/arquitetura.md) | Camadas, estrutura das features, navegação, camada Rust, fluxos principais e segurança. |
| [Comunicação Flutter/Rust](docs/comunicacao-flutter-rust.md) | Funcionamento do FRB, funções e tipos expostos, Futures, Streams, erros e concorrência. |
| [Testes](docs/testes.md) | Estratégia de testes unitários, cobertura por feature, fakes, Riverpod e testes Rust. |
| [Decisões técnicas](docs/decisoes-tecnicas.md) | Resumo das decisões e índice dos ADRs. |
| [Limitações conhecidas](docs/limitacoes.md) | O que não é suportado e melhorias sugeridas. |
| [Gestão do projeto](docs/gestao-do-projeto.md) | Quadro do GitHub Projects, divisão das atividades em issues, fluxo de branches e commits. |

### ADRs

* [ADR 001 — Lint e análise estática](docs/adr/001-lint-e-analise-estatica.md)
* [ADR 002 — Arquitetura MVVM](docs/adr/002-arquitetura-mvvm.md)
* [ADR 003 — Mason para padronização de features](docs/adr/003-adocao-mason-para-padronizacao-de-features.md)
* [ADR 004 — Persistência e recuperação E2EE](docs/adr/004-persistencia-e-recuperacao-e2ee.md)

## Status do projeto

As atividades são acompanhadas no [quadro do GitHub Projects](https://github.com/users/Maurycio-Kemesson/projects/3). A divisão completa, com os Pull Requests de cada etapa, está em [Gestão do projeto](docs/gestao-do-projeto.md).

* [x] [#1 Configurar projeto Flutter Desktop](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/1)
* [x] [#2 Configurar Rust e Flutter Rust Bridge](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/2)
* [x] [#3 Integrar Matrix Rust SDK](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/3)
* [x] [#4 Implementar autenticação no Matrix](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/4)
* [x] [#5 Implementar persistência e restauração da sessão](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/5)
* [x] [#6 Implementar listagem de salas](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/6)
* [x] [#7 Implementar histórico de mensagens](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/7)
* [x] [#8 Implementar envio de mensagens](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/8)
* [x] [#9 Atualização das conversas](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/9)
* [ ] [#10 Revisar segurança e tratamento de erros](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/10)
* [x] [#11 Documentar arquitetura e configuração](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/11)
* [x] [#12 Revisar testes dos principais fluxos](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/12)

## Licença

Este projeto foi desenvolvido como parte de um desafio técnico. Veja [LICENSE](LICENSE).
