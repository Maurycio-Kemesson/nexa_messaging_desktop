# Distribuição para Windows

O Nexa é distribuído para Windows em dois formatos, publicados no [GitHub Releases](https://github.com/Maurycio-Kemesson/nexa_messaging_desktop/releases):

| Arquivo | Tamanho aproximado | Uso |
| --- | --- | --- |
| `nexa-messaging-<versão>-windows-x64-setup.exe` | 21 MB | Instalador com atalho no Menu Iniciar, ícone opcional na área de trabalho e desinstalação pelo Windows. |
| `nexa-messaging-<versão>-windows-x64.zip` | 30 MB | Versão portátil: extrair e executar `nexa_messaging_desktop.exe`, sem instalação. |
| `SHA256SUMS.txt` | — | Hashes SHA-256 para conferir a integridade dos arquivos. |

Requisitos para executar: Windows 10 ou 11 de 64 bits. Não é necessário ter Flutter, Rust ou o Visual C++ Redistributable instalados.

## Instalando

### Instalador

1. Baixe o `...-setup.exe` da página de releases.
2. Execute o arquivo. Como o executável não é assinado digitalmente, o Windows SmartScreen pode exibir **"O Windows protegeu o computador"**. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. Siga o assistente, disponível em português e inglês.

O instalador não exige permissão de administrador. Por padrão, ele instala para o usuário atual em `%LOCALAPPDATA%\Programs\Nexa Messaging`. Na primeira tela é possível escolher instalar para todos os usuários, o que instala em `C:\Program Files\Nexa Messaging` e pede elevação.

Instalação silenciosa, útil para scripts:

```powershell
.\nexa-messaging-1.0.0-windows-x64-setup.exe /VERYSILENT /CURRENTUSER
```

### Versão portátil

1. Baixe o `.zip` e extraia em qualquer pasta.
2. Execute `nexa_messaging_desktop.exe`.

O executável precisa ficar junto das DLLs e da pasta `data/`. Copiar apenas o `.exe` para outro lugar não funciona.

### Conferindo a integridade

```powershell
Get-FileHash .\nexa-messaging-1.0.0-windows-x64-setup.exe -Algorithm SHA256
```

O hash deve ser igual ao listado no `SHA256SUMS.txt` do mesmo release.

## Desinstalando

Use **Configurações → Aplicativos → Nexa Messaging → Desinstalar**.

A desinstalação remove os arquivos do aplicativo, mas **mantém os dados do usuário** para que uma reinstalação continue com a mesma sessão e as mesmas chaves E2EE:

* `%APPDATA%\Nexa Messaging\matrix`: estado do Matrix e chaves criptográficas (SQLite);
* a sessão salva pelo `flutter_secure_storage` no Gerenciador de Credenciais do Windows.

Para remover tudo, faça logout no app antes de desinstalar e apague a pasta `%APPDATA%\Nexa Messaging`.

## Conteúdo do pacote

```text
nexa_messaging_desktop.exe                    executável (runner Flutter)
flutter_windows.dll                           engine do Flutter
rust_lib_nexa_messaging_desktop.dll           camada Rust + Matrix Rust SDK
*_plugin.dll, dartjni.dll                     plugins Flutter (secure storage, connectivity, url_launcher)
msvcp140.dll, vcruntime140.dll,
vcruntime140_1.dll                            runtime Visual C++ (implantação local)
data/app.so                                   código Dart compilado (AOT)
data/icudtl.dat, data/flutter_assets/         recursos do Flutter
```

As DLLs do runtime Visual C++ são copiadas da pasta `VC\Redist` do Visual Studio (implantação local, permitida pela Microsoft). Isso evita o erro `MSVCP140.dll não encontrado` em máquinas sem o Visual C++ Redistributable.

## Gerando os artefatos

Pré-requisitos, além do ambiente de desenvolvimento do Windows ([Configuração do ambiente](configuracao-ambiente.md)):

```powershell
winget install --id JRSoftware.InnoSetup -e
```

Na raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_windows_release.ps1
```

O script `tool/build_windows_release.ps1`:

1. lê a versão do `pubspec.yaml` (`version: 1.0.0+1` vira `1.0.0`);
2. executa `flutter build windows --release`;
3. copia as DLLs do runtime Visual C++ para `build\windows\x64\runner\Release`;
4. gera o `.zip` portátil em `dist/`;
5. compila o instalador com o Inno Setup a partir de `installer/windows/nexa_messaging_desktop.iss`;
6. grava os hashes em `dist/SHA256SUMS.txt`.

Opções:

| Opção | Efeito |
| --- | --- |
| `-SkipBuild` | Reaproveita o build existente e só empacota. |
| `-SkipInstaller` | Gera apenas o `.zip`, sem precisar do Inno Setup. |

A pasta `dist/` está no `.gitignore`. Os binários não devem ser versionados no repositório, e sim anexados ao release.

### Caminhos longos

O build do `matrix-sdk` cria caminhos que podem passar do limite de 260 caracteres do Windows quando o projeto está em uma pasta profunda. Se o build falhar com erros de arquivo não encontrado ou caminho muito longo, mapeie a pasta pai para uma unidade curta e execute o build a partir dela:

```powershell
subst N: "C:\caminho\ate\a\pasta\pai"
cd N:\nexa_messaging_desktop
powershell -ExecutionPolicy Bypass -File .\tool\build_windows_release.ps1
subst N: /D
```

O CMake grava o caminho absoluto no cache. Se o projeto já foi compilado por outro caminho, o build falha com `CMakeCache.txt directory ... is different`. Nesse caso, compile pelo mesmo caminho usado antes ou apague `build\windows`.

## Publicando um release

1. Atualize a versão em `pubspec.yaml`.
2. Gere os artefatos com o script.
3. Crie a tag e o release no GitHub, por exemplo `v1.0.0`, e anexe os três arquivos de `dist/`.

## Limitações

* O executável e o instalador **não são assinados digitalmente**, por isso o SmartScreen exibe um aviso na primeira execução.
* Somente **x64**. Não há build para Windows ARM64.
* Não há atualização automática. Novas versões são instaladas por cima da anterior com o novo instalador.
