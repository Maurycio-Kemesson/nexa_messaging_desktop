import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final AuthState state = ref.watch(authViewModelProvider);
    final AuthViewModel viewModel = ref.read(authViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nexa Messaging',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _homeserverController,
          enabled: !state.isLoading,
          decoration: const InputDecoration(
            labelText: 'Homeserver',
            hintText: 'https://matrix.org',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _usernameController,
          enabled: !state.isLoading,
          decoration: const InputDecoration(
            labelText: 'Usuário',
            hintText: 'mauryciokemesson',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !state.isLoading,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () {
                  viewModel.login(
                    homeserver: _homeserverController.text.trim(),
                    username: _usernameController.text.trim(),
                    password: _passwordController.text,
                  );
                },
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : const Text('Entrar'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
        if (state.session != null) ...[
          const SizedBox(height: 16),
          Text(
            'Autenticado como ${state.session!.userId}',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
