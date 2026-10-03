import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/authentication_view_model.dart';

class AuthenticationView extends ConsumerWidget {
  const AuthenticationView({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state = ref.watch(
      authenticationViewModelProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: state.isLoading
            ? const CircularProgressIndicator()
            : Text(
                state.error ??
                    'Authentication',
              ),
      ),
    );
  }
}
