import 'package:flutter/material.dart';

import '../widgets/rooms_content.dart';

class RoomsView extends StatelessWidget {
  const RoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salas')),
      body: const RoomsContent(),
    );
  }
}
