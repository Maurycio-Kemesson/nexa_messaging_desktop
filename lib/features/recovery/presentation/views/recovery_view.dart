import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_messaging_desktop/core/router/app_routes.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
import 'package:nexa_messaging_desktop/core/widgets/nexa_logo.dart';
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
    final TextTheme textTheme = Theme.of(context).textTheme;

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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NexaLogo(height: 36),
                    const SizedBox(height: 24),
                    Text(
                      'Recuperar chaves de criptografia',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Informe sua Recovery Key para recuperar as chaves '
                      'de criptografia armazenadas no backup do Matrix.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _recoveryKeyController,
                      obscureText: true,
                      onSubmitted: (_) => _recover(),
                      decoration: const InputDecoration(
                        labelText: 'Recovery Key',
                        hintText: 'Digite sua Recovery Key',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state.isLoading ? null : _recover,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navy,
                              ),
                            )
                          : const Text('Recuperar chaves'),
                    ),
                    if (state.isSuccess) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recuperação concluída com sucesso.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.lime,
                        ),
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
