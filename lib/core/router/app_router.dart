import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_messaging_desktop/features/recovery/presentation/views/recovery_view.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/auth/presentation/views/auth_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import 'app_routes.dart';
import 'router_refresh_notifier.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.authenticationPath,

    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);

      final isInitialized = authState.isInitialized;
      final isAuthenticated = authState.session != null;

      final isAuthenticationRoute =
          state.matchedLocation == AppRoutes.authenticationPath;

      if (!isInitialized) {
        return null;
      }

      if (!isAuthenticated && !isAuthenticationRoute) {
        return AppRoutes.authenticationPath;
      }

      if (isAuthenticated && isAuthenticationRoute) {
        return AppRoutes.homePath;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.authenticationPath,
        name: AppRoutes.authentication,
        builder: (context, state) => const AuthView(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: AppRoutes.recoveryPath,
        name: AppRoutes.recovery,
        builder: (context, state) => const RecoveryView(),
      ),
    ],
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
