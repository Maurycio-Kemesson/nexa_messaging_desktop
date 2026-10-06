# ADR 003 — Adoção do Mason para padronização da estrutura de features

## Contexto

O Nexa é uma aplicação desktop multiplataforma desenvolvida com Flutter e possui uma arquitetura baseada em MVVM, Repository Pattern e separação entre apresentação, domínio e infraestrutura. À medida que novas funcionalidades forem adicionadas ao projeto, será necessário criar repetidamente estruturas semelhantes de diretórios e arquivos, como Views, ViewModels, States, Repositories, Use Cases e testes. E no caso a criação manual dessas estruturas pode gerar inconsistências entre as features, diferenças de nomenclatura e arquivos iniciais incompletos ou organizados de maneiras diferentes. Para reduzir esse problema, foi avaliada a utilização de uma ferramenta de scaffolding capaz de gerar automaticamente estruturas padronizadas de código.

## Decisão

Adotar o **Mason** como ferramenta de scaffolding para geração da estrutura inicial das features do Nexa. Os templates do Mason serão mantidos dentro do próprio repositório do projeto, permitindo que a estrutura utilizada para criação de novas funcionalidades seja versionada juntamente com o código da aplicação.

A estrutura dos templates seguirá os princípios arquiteturais definidos no projeto:

```text
Feature
├── data
│   └── repositories
├── domain
│   ├── entities
│   ├── repositories
│   └── usecases
└── presentation
    ├── viewmodels
    ├── views
    ├── widgets
    └── providers
```

Por exemplo, uma nova feature de autenticação poderá ser criada através de:

```bash
mason make feature --name authentication
```

Gerando uma estrutura semelhante a:

```text
features/
└── authentication/
    ├── data/
    │   └── repositories/
    │       └── authentication_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── authentication_entity.dart
    │   ├── repositories/
    │   │   └── authentication_repository.dart
    │   └── usecases/
    │       └── authentication_usecase.dart
    └── presentation/
        ├── viewmodels/
        │   ├── authentication_state.dart
        │   └── authentication_view_model.dart
        ├── views/
        │   └── authentication_view.dart
        ├── widgets/
        │   └── authentication_content.dart
        └── authentication_providers.dart
```

Os templates utilizarão as funcionalidades de transformação de nomes do Mason, permitindo que uma única definição seja reutilizada para diferentes funcionalidades.

Por exemplo:

```text
{{name.snakeCase()}}
{{name.camelCase()}}
{{name.pascalCase()}}
```

Dessa forma, o mesmo template poderá gerar corretamente nomes como:

```text
authentication
Authentication
authenticationRepository
```

## Motivação

A adoção do Mason possui como principais objetivos:

### 1. Padronização da arquitetura

Todas as novas features começam seguindo a mesma estrutura definida para o projeto. Isso reduz a possibilidade de uma funcionalidade ser criada com uma organização diferente das demais.

### 2. Redução de trabalho repetitivo

A criação manual de diretórios e arquivos básicos é uma tarefa repetitiva. Com Mason, a estrutura inicial pode ser criada através de um único comando:

```bash
mason make feature --name authentication
```

Isso permite que o desenvolvedor concentre o esforço na implementação da funcionalidade em vez de criar manualmente arquivos de infraestrutura.

### 3. Consistência entre as features

O template funciona como uma referência executável da arquitetura escolhida. Alterações futuras na estrutura padrão podem ser realizadas no brick e aplicadas às novas features.

### 4. Integração com MVVM e Repository Pattern

O Mason não define a arquitetura da aplicação. Ele apenas automatiza a criação da estrutura escolhida pelo projeto.A arquitetura continua sendo definida pela ADR de MVVM e pelas demais decisões arquiteturais.

Dessa forma:

```text
ADR
 ↓
Define a arquitetura
 ↓
Mason
 ↓
Automatiza a estrutura
 ↓
Feature
```

O Mason, portanto, é uma ferramenta de apoio à arquitetura e não uma camada arquitetural da aplicação.

### 5. Redução de inconsistências

A criação manual de uma feature pode resultar em diferenças acidentais de nomenclatura, organização de diretórios ou arquivos ausentes. O scaffolding reduz esse tipo de inconsistência ao utilizar uma estrutura previamente definida.

## Organização no projeto

Os bricks específicos do Nexa serão mantidos em:

```text
tool/
└── mason/
    └── feature/
        ├── brick.yaml
        ├── README.md
        └── __brick__/
```

O diretório `mason/` utilizado pelo Mason como configuração local não será tratado como código-fonte da arquitetura da aplicação. Os templates do brick serão versionados no repositório para que outros desenvolvedores possam utilizar a mesma estrutura.

## Relação com a arquitetura

A utilização do Mason não altera o fluxo arquitetural definido para o Nexa:

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
Rust
 ↓
Matrix Rust SDK
```

O Mason atua apenas no momento de criação da estrutura inicial:

```text
              Mason
                ↓
        Criação da Feature
                ↓
       ┌────────┴────────┐
       ↓                 ↓
 Presentation          Domain
       ↓                 ↓
 ViewModel          Use Case
 View                Repository
       │                 │
       └────────┬────────┘
                ↓
               Data
                ↓
          RepositoryImpl
```

## Alternativas consideradas

### Criação manual das features

Seria possível criar manualmente os diretórios e arquivos de cada funcionalidade. Essa alternativa possui baixa complexidade inicial, porém aumenta o trabalho repetitivo e a possibilidade de inconsistências entre features.Foi descartada como abordagem principal devido à repetição existente na estrutura arquitetural do projeto.

### Scripts personalizados

Outra possibilidade seria utilizar scripts PowerShell ou Dart para criar os arquivos. Embora scripts possam automatizar a criação da estrutura, o Mason fornece uma solução específica para scaffolding de projetos Flutter/Dart, com suporte a templates, variáveis e transformações de nomes. Por esse motivo, Mason foi considerado mais adequado para esse propósito.

### Não utilizar scaffolding

Também foi considerada a possibilidade de não utilizar nenhuma ferramenta de geração e permitir que cada feature fosse criada individualmente.Essa abordagem oferece maior liberdade, porém reduz a padronização e aumenta a quantidade de trabalho repetitivo. Foi descartada devido à necessidade de manter uma estrutura consistente durante a evolução do projeto.

## Consequências

### Positivas

* Redução de trabalho repetitivo;
* Maior consistência entre as features;
* Padronização de nomenclatura;
* Menor possibilidade de esquecer arquivos estruturais;
* Facilita a criação de novas funcionalidades;
* Mantém a estrutura arquitetural documentada através dos templates;
* Permite evoluir o padrão de scaffolding junto com o projeto.

### Negativas

* Introduz uma ferramenta adicional ao fluxo de desenvolvimento;
* Desenvolvedores precisam conhecer os comandos básicos do Mason;
* Alterações nos templates precisam ser avaliadas para evitar a propagação de uma estrutura inadequada;
* O template pode gerar arquivos que não sejam necessários para funcionalidades muito simples.

Por esse motivo, o Mason será utilizado como **ponto de partida**, e não como uma regra que impeça alterações na estrutura de uma feature quando houver justificativa técnica.

## Regra de uso

O Mason deverá ser utilizado para criação inicial de novas features que sigam o padrão arquitetural do projeto.Após a geração, os arquivos poderão ser modificados, removidos ou complementados conforme as necessidades específicas da funcionalidade.A existência de uma estrutura gerada pelo Mason não significa que todas as camadas devam obrigatoriamente conter lógica ou serem utilizadas.A arquitetura deve permanecer proporcional à complexidade da funcionalidade.

## Referências

* Mason — ferramenta de geração de código para Dart e Flutter: https://pub.dev/packages/mason
* Mason CLI: https://pub.dev/packages/mason_cli
* Flutter — App Architecture: https://docs.flutter.dev/app-architecture
