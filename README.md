# Nexa

Cliente de mensageria desktop multiplataforma desenvolvido com **Flutter**, **Rust**, **Matrix Rust SDK** e **Flutter Rust Bridge**.

**Repositório:** [github.com/Maurycio-Kemesson/nexa_messaging_desktop](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop)

## Sobre o projeto

O **Nexa** é um cliente de mensageria desktop desenvolvido como parte de um desafio técnico.

A aplicação foi projetada para funcionar nas seguintes plataformas:

* Windows
* macOS
* Linux

O cliente se comunica com um **Matrix Homeserver** utilizando o **Matrix Rust SDK**, com a integração entre Flutter e Rust realizada através do **Flutter Rust Bridge**.

## Arquitetura

A comunicação principal da aplicação segue o fluxo:

```text
Flutter
   │
   ├── View
   ├── ViewModel
   ├── Use Case
   └── Repository
          │
          ▼
Flutter Rust Bridge
          │
          ▼
        Rust
          │
          ▼
  Matrix Rust SDK
          │
          ▼
  Matrix Homeserver
```

A camada de apresentação utiliza **MVVM**, mantendo a interface desacoplada da implementação de comunicação com o Matrix.

## Requisitos

Para executar o projeto, serão necessárias as seguintes ferramentas:

* Flutter
* Dart
* Git
* Rust
* Cargo

> A configuração do ambiente Rust será detalhada neste README após a integração do Rust ao projeto.

### Versão do Flutter

O projeto está sendo desenvolvido utilizando:

```text
Flutter 3.41.6
Dart 3.11.4
DevTools 2.54.2
Canal: stable
```

Versão do Flutter:

```text
db50e20168
```

### Verificar a instalação do Flutter

Execute:

```bash
flutter --version
```

E:

```bash
flutter doctor
```

O `flutter doctor` deve indicar que as dependências necessárias para desenvolvimento desktop estão corretamente configuradas.

## Configuração do projeto

Clone o repositório:

```bash
git clone https://github.com/Maurycio-Kemesson/nexa_messaging_desktop.git
```

Entre no diretório:

```bash
cd nexa_messaging_desktop
```

Instale as dependências do Flutter:

```bash
flutter pub get
```

Verifique os dispositivos desktop disponíveis:

```bash
flutter devices
```

## Executando o projeto

### Windows

```bash
flutter run -d windows
```

### macOS

```bash
flutter run -d macos
```

### Linux

```bash
flutter run -d linux
```

> Para executar o projeto em cada plataforma, é necessário possuir o ambiente de desenvolvimento correspondente devidamente configurado.

## Testes e análise

Executar os testes:

```bash
flutter test
```

Executar a análise estática:

```bash
flutter analyze
```

Formatar o código:

```bash
dart format .
```

Antes de abrir um Pull Request, a expectativa é que os seguintes comandos sejam executados com sucesso:

```bash
dart format .
flutter analyze
flutter test
```

## Fluxo de desenvolvimento

O desenvolvimento utiliza **GitHub Issues**, branches por funcionalidade, **TDD**, Conventional Commits e Pull Requests.

O fluxo principal é:

```text
GitHub Issue
      ↓
Feature Branch
      ↓
TDD
      ↓
Implementação
      ↓
Testes
      ↓
Pull Request
      ↓
develop
```

Exemplo de criação de uma branch:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/matrix-authentication
```

### Conventional Commits

Os commits seguem a convenção Conventional Commits.

Exemplos:

```text
feat: implementar autenticação Matrix
fix: corrigir tratamento de credenciais inválidas
test: adicionar testes de autenticação
refactor: simplificar fluxo de autenticação
docs: documentar arquitetura de autenticação
chore: configurar analyzer e lints
```

## Arquitetura da aplicação

A aplicação Flutter utiliza uma arquitetura baseada em **MVVM**, organizada em camadas.

```text
View
 ↓
ViewModel
 ↓
Use Case
 ↓
Repository
 ↓
Flutter Rust Bridge
 ↓
Matrix Rust SDK
```

### View

Responsável pela interface e interação visual com o usuário.

### ViewModel

Responsável pelo estado da tela e pela coordenação das ações realizadas pelo usuário.

A ViewModel não acessa diretamente o Matrix SDK.

### Use Case

Representa uma ação ou regra de negócio específica da aplicação.

Exemplos:

```text
Login
Logout
Listar salas
Buscar mensagens
Enviar mensagem
Restaurar sessão
```

### Repository

Abstrai o acesso aos dados e impede que as camadas superiores dependam diretamente da implementação do Matrix.

### Flutter Rust Bridge

Responsável pela comunicação entre o código Dart/Flutter e o código Rust.

### Rust

Concentra a integração nativa com o **Matrix Rust SDK**.

## Comunicação com o Matrix

A comunicação com o Matrix segue o fluxo:

```text
Flutter
   ↓
Flutter Rust Bridge
   ↓
Rust
   ↓
Matrix Rust SDK
   ↓
Matrix Homeserver
```

Essa abordagem mantém a integração com o Matrix isolada da camada de apresentação do Flutter.

## Decisões técnicas

As principais decisões técnicas do projeto são documentadas utilizando **Architecture Decision Records (ADR)**.

### ADRs

* [ADR 001 — Lint e análise estática](docs/adr/001-lint-e-analise-estatica.md)


> Os ADRs serão adicionados conforme as decisões técnicas forem implementadas e validadas durante o desenvolvimento.

## Segurança

A segurança é considerada desde a arquitetura da aplicação.

Entre as medidas adotadas estão:

* evitar exposição de informações sensíveis em logs;
* isolamento da integração com o Matrix;
* separação entre apresentação e infraestrutura;
* tratamento explícito de erros;
* gerenciamento adequado de subscriptions e recursos;
* análise estática do código.

As decisões específicas relacionadas à segurança serão documentadas nos respectivos ADRs.

## Status do projeto

O projeto está sendo desenvolvido de forma incremental de acordo com os requisitos do desafio técnico.

### Implementado

* [ ] [Criação do projeto Flutter Desktop](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/1)
* [ ] [Configuração do Rust](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/2)
* [ ] [Configuração do Flutter Rust Bridge](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/3)
* [ ] [Integração com Matrix Rust SDK](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/4)
* [ ] [Autenticação no Matrix Homeserver](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/5)
* [ ] [Persistência da sessão](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/6)
* [ ] [Restauração da sessão](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/7)
* [ ] [Logout](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/8)
* [ ] [Listagem de salas](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/9)
* [ ] [Seleção de sala](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/10)
* [ ] [Histórico de mensagens](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/11)
* [ ] [Revisar testes dos principais fluxos](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/issues/12)

## Limitações

O projeto prioriza os fluxos essenciais solicitados no desafio técnico.

Funcionalidades fora do escopo inicial poderão não ser implementadas, como funcionalidades avançadas de mensageria ou recursos que não sejam necessários para demonstrar os requisitos principais.

As limitações conhecidas serão registradas nesta seção conforme o desenvolvimento avançar.

## Licença

Este projeto foi desenvolvido como parte de um desafio técnico.

