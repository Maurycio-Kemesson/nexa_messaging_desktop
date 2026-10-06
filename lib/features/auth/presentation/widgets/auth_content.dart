import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
import 'package:nexa_messaging_desktop/core/widgets/nexa_logo.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_state.dart';

import '../viewmodels/auth_view_model.dart';

class AuthContent extends ConsumerStatefulWidget {
  const AuthContent({super.key});

  @override
  ConsumerState<AuthContent> createState() => _AuthContentState();
}

class _AuthContentState extends ConsumerState<AuthContent> {
  final TextEditingController _homeserverController = TextEditingController(
    text: 'https://matrix.org',
  );

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _homeserverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _submit() {
    final AuthState state = ref.read(authViewModelProvider);
    if (state.isLoading) {
      return;
    }

    ref
        .read(authViewModelProvider.notifier)
        .login(
          homeserver: _homeserverController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState state = ref.watch(authViewModelProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: NexaLogo(height: 56)),
        const SizedBox(height: 28),
        Text(
          'Entre na sua conta',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Use o homeserver Matrix e suas credenciais para continuar.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _homeserverController,
          enabled: !state.isLoading,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Homeserver',
            hintText: 'https://matrix.org',
            prefixIcon: Icon(Icons.dns_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          enabled: !state.isLoading,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usuário',
            hintText: 'mauryciokemesson',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !state.isLoading,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.navy,
                  ),
                )
              : const Text('Entrar'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ],
        if (state.session != null) ...[
          const SizedBox(height: 16),
          Text(
            'Autenticado como ${state.session!.userId}',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.teal),
          ),
        ],
      ],
    );
  }
}
