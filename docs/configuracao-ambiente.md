# Configuração do ambiente e execução

Este documento descreve as ferramentas necessárias, a preparação do ambiente em cada plataforma desktop e os comandos para executar, testar e gerar o código de integração do Nexa.

## Plataformas suportadas

| Plataforma | Status | Observações |
| --- | --- | --- |
| Windows 10/11 (x64) | Suportada | Plataforma principal de desenvolvimento e validação. |
| macOS | Configurada | Requer ajuste nas entitlements para acesso à rede. Veja [Limitações](limitacoes.md#macos-sem-permissão-de-rede-de-saída). |
| Linux (x64) | Configurada | Requer bibliotecas do sistema para GTK e para o armazenamento seguro (`libsecret`). |

As pastas `android/`, `ios/` e `web/` não fazem parte do projeto. O escopo é exclusivamente desktop.

## Versões utilizadas

| Ferramenta | Versão |
| --- | --- |
| Flutter | 3.41.6 (canal `stable`, revisão `db50e20168`) |
| Dart | 3.11.4 |
| Rust / Cargo | 1.99.0 (toolchain `stable`) |
| Flutter Rust Bridge | 2.13.0 (runtime Dart, crate Rust e codegen) |
| Matrix Rust SDK (`matrix-sdk`) | 0.19.1 |

A versão do Flutter Rust Bridge precisa ser **exatamente a mesma** no `pubspec.yaml` (`flutter_rust_bridge: 2.13.0`), no `rust/Cargo.toml` (`flutter_rust_bridge = "=2.13.0"`) e no `flutter_rust_bridge_codegen`. Versões diferentes geram incompatibilidade entre o código gerado e o runtime.

## Ferramentas necessárias

### Flutter e Dart

Instale o Flutter seguindo a [documentação oficial](https://docs.flutter.dev/get-started/install) e confirme:

```bash
flutter --version
flutter doctor
```

O `flutter doctor` deve indicar o suporte desktop da plataforma em uso como configurado.

### Rust

Instale o Rust pelo [rustup](https://rustup.rs/):

```bash
rustup default stable
rustc --version
cargo --version
```

O build do Rust é disparado automaticamente pelo `flutter run`/`flutter build` através do **Cargokit** (pasta `rust_builder/`). Não é necessário executar `cargo build` manualmente para rodar o aplicativo.

### Flutter Rust Bridge codegen

Necessário apenas quando a API Rust exposta ao Flutter for alterada:

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
flutter_rust_bridge_codegen --version
```

## Dependências por plataforma

O `matrix-sdk` compila o SQLite embutido (`bundled-sqlite`) e utiliza `rustls` com `aws-lc-rs`, o que exige um compilador C e o **CMake** em todas as plataformas.

### Windows

* Visual Studio 2022 com a carga de trabalho **Desenvolvimento para desktop com C++** (inclui MSVC, Windows SDK e CMake).
* Toolchain Rust MSVC (`stable-x86_64-pc-windows-msvc`), que é o padrão do rustup no Windows.

### macOS

* Xcode e Command Line Tools (`xcode-select --install`).
* CocoaPods (`sudo gem install cocoapods` ou `brew install cocoapods`).
* CMake (`brew install cmake`).

### Linux (Debian/Ubuntu)

```bash
sudo apt-get install clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsecret-1-dev libjsoncpp-dev
```

O `flutter_secure_storage` utiliza o `libsecret`, portanto é necessário um serviço de keyring ativo na sessão (GNOME Keyring ou KWallet).

## Configuração do projeto

```bash
git clone https://github.com/Maurycio-Kemesson/nexa_messaging_desktop.git
cd nexa_messaging_desktop
flutter pub get
flutter devices
```

## Executando o aplicativo

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

A primeira execução é mais demorada porque o Cargokit compila o crate Rust e todas as dependências do `matrix-sdk`. As execuções seguintes reaproveitam o cache do Cargo.

Os logs de diagnóstico do Rust (prefixo `NEXA:`) e do Flutter (prefixos `AUTH:`, `ROUTER:`, `REPOSITORY:`, `MESSAGES:`) aparecem no terminal do `flutter run`.

## Build de release

```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

Os artefatos ficam em `build/<plataforma>/`.

No Windows, o script `tool/build_windows_release.ps1` gera o build, o `.zip` portátil e o instalador (Inno Setup) em `dist/`. Veja [Distribuição para Windows](distribuicao-windows.md).

## Regenerando o código do Flutter Rust Bridge

Sempre que uma função pública em `rust/src/api/` for criada, removida ou tiver a assinatura alterada:

```bash
flutter_rust_bridge_codegen generate
```

O comando lê o `flutter_rust_bridge.yaml`:

```yaml
rust_input: crate::api
rust_root: rust/
dart_output: lib/src/rust
```

E atualiza:

* `rust/src/frb_generated.rs`
* `lib/src/rust/frb_generated*.dart`
* `lib/src/rust/api/*.dart`

Durante o desenvolvimento é possível manter a geração automática com `flutter_rust_bridge_codegen generate --watch`. Os arquivos gerados são versionados e não devem ser editados manualmente.

## Testes e qualidade

```bash
dart format .
flutter analyze
flutter test
```

Os testes Flutter (`test/features/`) cobrem States, Use Cases, ViewModels e as telas de login e de mensagens, utilizando implementações falsas dos repositórios. Eles não dependem do Rust nem de rede. A estratégia completa está em [Testes](testes.md).

## Gerando novas features

O projeto utiliza um brick do [Mason](https://github.com/felangel/mason) para padronizar a estrutura das features (ver [ADR 003](adr/003-adocao-mason-para-padronizacao-de-features.md)):

```bash
dart pub global activate mason_cli
mason get
mason make feature --name nome_da_feature
```

## Problemas comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| Erro de versão do Flutter Rust Bridge ao iniciar (`content hash` diferente) | Código gerado desatualizado em relação ao Rust | Executar `flutter_rust_bridge_codegen generate`. |
| Falha ao compilar `aws-lc-sys` ou `libsqlite3-sys` | Falta de CMake ou compilador C | Instalar as dependências da plataforma listadas acima. |
| Erro do `flutter_secure_storage` no Linux | Keyring indisponível ou `libsecret` ausente | Instalar `libsecret-1-dev` e garantir um keyring ativo. |
| `CMakeCache.txt directory ... is different` no Windows | Build anterior feito a partir de outro caminho | Compilar pelo mesmo caminho ou apagar `build\windows`. |
| Erros de caminho muito longo ao compilar o Rust no Windows | Limite de 260 caracteres em pastas profundas | Usar `subst` para uma unidade curta. Ver [Distribuição para Windows](distribuicao-windows.md#caminhos-longos). |
| Falha de conexão com o homeserver no macOS | Sandbox sem `com.apple.security.network.client` | A chave já está nas entitlements de Debug e Release. Se o problema persistir, ver [Limitações](limitacoes.md#macos-sem-validação-de-ponta-a-ponta). |
