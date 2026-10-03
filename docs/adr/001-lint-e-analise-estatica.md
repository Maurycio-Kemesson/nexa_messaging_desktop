# ADR 001 — Lint e análise estática

## Contexto

O projeto necessita manter um padrão consistente de qualidade, legibilidade e segurança do código Dart/Flutter desde o início do desenvolvimento. Como foi  utiliza Flutter, o `flutter_lints` fornece uma base de regras alinhada às boas práticas recomendadas pelo ecossistema.

## Decisão

Adotar o `flutter_lints` como conjunto base de regras e adicionar algumas regras específicas para o projeto.As regras adicionais foram escolhidas principalmente para:

* Incentivar imutabilidade com `final`;
* Melhorar a clareza dos contratos através de tipos de retorno explícitos;
* Incentivar o uso de `const` no Flutter;
* Prevenir problemas com `BuildContext` em operações assíncronas;
* Evitar `print`, reduzindo o risco de exposição acidental de informações sensíveis;
* Garantir o gerenciamento adequado de subscriptions e sinks;
* Evitar tratamento de exceções silencioso.

Arquivos gerados automaticamente, como `.g.dart` e `.freezed.dart`, não serão analisados pelo lint.

## Alternativas consideradas

### Utilizar apenas o `flutter_lints`

Seria a configuração mais simples, porém não contemplaria algumas necessidades específicas do projeto, principalmente relacionadas a gerenciamento de recursos e segurança.

### Utilizar um conjunto muito mais rigoroso de regras

Embora pudesse aumentar a quantidade de verificações, adicionaria complexidade e correções de baixo valor para o escopo e prazo do desafio.

## Consequências

A configuração aumenta a consistência do código e permite identificar problemas durante o desenvolvimento através do `flutter analyze`. Também estabelece um padrão para as demais partes do projeto sem adicionar uma quantidade excessiva de regras que poderiam dificultar o desenvolvimento.
