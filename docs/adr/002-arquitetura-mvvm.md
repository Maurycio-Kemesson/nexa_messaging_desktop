# ADR 002 — Adoção da arquitetura MVVM

## Contexto

O Nexa é uma aplicação desktop multiplataforma desenvolvida com Flutter, que precisa manter uma separação clara entre interface, estado da aplicação, regras de negócio e integração com serviços externos. A vaga em questão também destaca a utilização de **MVVM (Model-View-ViewModel)** como parte dos requisitos. Além de ser um dos requisitos da vaga, a escolha está alinhada às recomendações oficiais de arquitetura do Flutter. A documentação do Flutter recomenda a utilização de **Views e ViewModels na camada de UI (MVVM)** e classifica essa prática como uma recomendação forte para aplicações Flutter. A documentação também destaca a separação de responsabilidades como um dos principais princípios para construção de aplicações escaláveis e manuteníveis.

## Decisão

Adotar **MVVM** como padrão arquitetural para a camada de apresentação do Nexa.

A arquitetura será organizada inicialmente da seguinte forma:

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

Responsável pela apresentação da interface e pela interação com o usuário. As Views não devem conter regras de negócio ou lógica relacionada diretamente ao acesso aos dados.

### ViewModel

Responsável por:

* Manter o estado necessário para a View;
* Receber ações do usuário;
* Executar as operações necessárias;
* Transformar dados em um formato adequado para apresentação;
* Expor o estado para a View.

### Use Case

Representa operações específicas da aplicação e concentra regras de negócio que não devem ficar na ViewModel. A utilização dessa camada será aplicada quando houver complexidade suficiente que justifique sua existência, evitando adicionar abstrações desnecessárias.

### Repository

Responsável por abstrair o acesso aos dados e manter a ViewModel desacoplada das implementações específicas de infraestrutura. No Nexa, o Repository será o ponto de acesso da camada Flutter aos dados relacionados ao Matrix.

### Flutter Rust Bridge

Responsável por fazer a comunicação entre Dart/Flutter e Rust.

### Rust / Matrix Rust SDK

Responsável pela integração nativa com o Matrix, mantendo os detalhes específicos do SDK fora da camada de apresentação.

## Motivação

A escolha do MVVM possui três principais motivos:

### 1. Requisito técnico da vaga em quesão 

O desafio solicita explicitamente a utilização de MVVM. Adotar o padrão atende diretamente a esse requisito.

### 2. Alinhamento com as recomendações do Flutter

A documentação oficial do Flutter apresenta MVVM como parte da arquitetura recomendada para aplicações Flutter e recomenda a separação entre Views e ViewModels na camada de UI. A arquitetura oficial também utiliza conceitos como Views, ViewModels, Repositories e Services, mantendo separação de responsabilidades entre as diferentes partes da aplicação.

### 3. Separação de responsabilidades e testabilidade

A separação entre View e ViewModel permite manter os widgets focados na apresentação, enquanto a lógica de estado e interação permanece em classes independentes.

Isso facilita:

* Testes unitários das ViewModels;
* Mnutenção do código;
* Evolução das funcionalidades;
* Substituição de implementações;
* Isolamento da integração com o Matrix;
* Redução da lógica dentro dos widgets.

## Alternativas consideradas


### Clean Architecture completa

Uma implementação completa de Clean Architecture poderia adicionar camadas adicionais, como Domain, Data e Presentation, com maior quantidade de abstrações.Para o escopo do desafio, foi escolhido utilizar os princípios de separação de responsabilidades do MVVM juntamente com Repository e Use Cases quando necessários, evitando complexidade arquitetural que não agregue valor ao problema.

## Consequências

A adoção de MVVM proporciona uma estrutura clara para as funcionalidades do Nexa e facilita a evolução do projeto.Como consequência, haverá um número maior de classes e abstrações do que em uma implementação diretamente baseada em widgets. Essa complexidade adicional é considerada aceitável devido ao escopo do projeto, aos requisitos do desafio e aos benefícios de manutenção e testabilidade. A arquitetura também permite que a integração com o Matrix permaneça isolada da camada de apresentação.

## Referências

* [Flutter — Architecting Flutter apps](https://docs.flutter.dev/app-architecture)
* [Flutter — Architecture recommendations and resources](https://docs.flutter.dev/app-architecture/recommendations)
* [Flutter — Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
* [Flutter — Architecture case study](https://docs.flutter.dev/app-architecture/case-study)
