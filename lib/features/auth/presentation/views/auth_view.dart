import 'package:flutter/material.dart';

import '../widgets/auth_content.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: SizedBox(width: 420, child: AuthContent()),
        ),
      ),
    );
  }
}
