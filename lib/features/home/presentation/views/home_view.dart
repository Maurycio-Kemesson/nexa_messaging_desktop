import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/views/rooms_view.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../rooms/presentation/viewmodels/rooms_view_model.dart';
import '../../../rooms/presentation/widgets/rooms_content.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(roomsViewModelProvider.notifier).loadRooms(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authViewModelProvider);

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
      body: const RoomsView(),
    );
  }
}
