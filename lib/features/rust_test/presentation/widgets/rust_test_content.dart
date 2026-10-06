import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/rust_test_view_model.dart';

class RustTestContent extends ConsumerWidget {
  const RustTestContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rustTestViewModelProvider);

    final viewModel = ref.read(rustTestViewModelProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.message.isEmpty ? 'Teste a integração' : state.message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: state.isLoading ? null : viewModel.greet,
          child: const Text('Testar Rust'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: state.isLoading ? null : viewModel.connectMatrix,
          child: Text(state.isLoading ? 'Conectando...' : 'Testar Matrix'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
