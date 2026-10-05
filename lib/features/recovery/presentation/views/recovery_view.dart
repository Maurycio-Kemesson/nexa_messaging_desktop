import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_messaging_desktop/core/router/app_routes.dart';
import 'package:nexa_messaging_desktop/features/recovery/presentation/recovery_providers.dart';

class RecoveryView extends ConsumerStatefulWidget {
  const RecoveryView({super.key});

  @override
  ConsumerState<RecoveryView> createState() => _RecoveryViewState();
}

class _RecoveryViewState extends ConsumerState<RecoveryView> {
  final TextEditingController _recoveryKeyController = TextEditingController();

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    final recoveryKey = _recoveryKeyController.text.trim();

    if (recoveryKey.isEmpty) {
      return;
    }

    await ref
        .read(recoveryViewModelProvider.notifier)
        .recover(recoveryKey: recoveryKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recoveryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperação E2EE'),
        leading: IconButton(
          onPressed: () {
            context.go(AppRoutes.homePath);
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recuperar chaves de criptografia',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Informe sua Recovery Key para recuperar as chaves '
                  'de criptografia armazenadas no backup do Matrix.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _recoveryKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Key',
                    hintText: 'Digite sua Recovery Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.isLoading ? null : _recover,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Recuperar chaves'),
                ),
                if (state.isSuccess) ...[
                  const SizedBox(height: 16),
                  const Text('Recuperação concluída com sucesso.'),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
