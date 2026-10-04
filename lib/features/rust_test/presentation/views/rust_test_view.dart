import 'package:flutter/material.dart';

import '../widgets/rust_test_content.dart';

class RustTestView extends StatelessWidget {
  const RustTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rust Integration Test')),
      body: const Center(child: RustTestContent()),
    );
  }
}
