import 'package:go_router/go_router.dart';

import '../../features/rust_test/presentation/views/rust_test_view.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.rustTestPath,
  routes: [
    GoRoute(
      path: AppRoutes.rustTestPath,
      name: AppRoutes.rustTest,
      builder: (context, state) {
        return const RustTestView();
      },
    ),
  ],
);
