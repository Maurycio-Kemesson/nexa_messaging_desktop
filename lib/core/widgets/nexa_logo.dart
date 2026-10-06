import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NexaLogo extends StatelessWidget {
  const NexaLogo({this.height = 48, super.key});

  final double height;

  static const String assetPath = 'assets/logo-principal-horizontal.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
