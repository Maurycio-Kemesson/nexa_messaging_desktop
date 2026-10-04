import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/rust_test_view_model.dart';

class RustTestContent extends ConsumerWidget {
  const RustTestContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rustTestViewModelProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.message.isEmpty ? 'Clique para testar o Rust' : state.message,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () {
                  ref.read(rustTestViewModelProvider.notifier).greet();
                },
          child: const Text('Testar Rust'),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(state.error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
