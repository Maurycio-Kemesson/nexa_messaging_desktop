import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/home/presentation/viewmodels/home_view_model.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexa Messaging'),
        actions: [
          IconButton(
            onPressed: authState.isLoading
                ? null
                : () {
                    ref.read(authViewModelProvider.notifier).logout();
                  },
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: homeState.isLoading
            ? const CircularProgressIndicator()
            : Text(
                homeState.error ??
                    'Nexa Messaging\n${authState.session?.userId ?? ''}',
              ),
      ),
    );
  }
}
