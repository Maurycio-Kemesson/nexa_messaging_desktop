import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/{{name.snakeCase()}}_view_model.dart';

class {{name.pascalCase()}}View extends ConsumerWidget {
  const {{name.pascalCase()}}View({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state = ref.watch(
      {{name.camelCase()}}ViewModelProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('{{name.pascalCase()}}'),
      ),
      body: Center(
        child: state.isLoading
            ? const CircularProgressIndicator()
            : Text(
                state.error ??
                    '{{name.pascalCase()}}',
              ),
      ),
    );
  }
}
