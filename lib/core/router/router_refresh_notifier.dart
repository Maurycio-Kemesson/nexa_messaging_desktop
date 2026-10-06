import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this.ref) {
    ref.listen(authViewModelProvider, (_, _) {
      debugPrint('ROUTER: estado de autenticação mudou');
      notifyListeners();
    });
  }

  final Ref ref;
}
