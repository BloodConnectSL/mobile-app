import 'package:flutter/material.dart';

class PranaLogo extends StatelessWidget {
  const PranaLogo({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Prana — community blood donation',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.asset(
        'assets/brand/prana-logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    ),
  );
}
