import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_messaging_desktop/core/theme/app_colors.dart';
import 'package:nexa_messaging_desktop/core/widgets/nexa_logo.dart';
import 'package:nexa_messaging_desktop/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:nexa_messaging_desktop/features/messages/presentation/views/messages_view.dart';
import 'package:nexa_messaging_desktop/features/rooms/presentation/widgets/rooms_content.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../rooms/presentation/viewmodels/rooms_view_model.dart';

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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: ColoredBox(
              color: AppColors.navyLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: NexaLogo(height: 36),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      'Conversas',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Expanded(child: RoomsContent()),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              authState.session?.userId ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.go(AppRoutes.recoveryPath);
                          },
                          icon: const Icon(Icons.cloud_outlined),
                          tooltip: 'Recuperar chaves E2EE',
                        ),
                        IconButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  ref
                                      .read(authViewModelProvider.notifier)
                                      .logout();
                                },
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sair',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                final roomsState = ref.watch(roomsViewModelProvider);

                final selectedRoom = roomsState.selectedRoom;

                if (selectedRoom == null) {
                  return const _EmptyChatState();
                }

                return MessagesView(
                  key: ValueKey(selectedRoom.id),
                  roomId: selectedRoom.id,
                  roomName: selectedRoom.name,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NexaLogo(height: 44),
            const SizedBox(height: 24),
            Text(
              'Selecione uma conversa',
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha uma sala à esquerda para ver e enviar mensagens.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
