import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// Za sada samo naslov. Red za verifikaciju dolazi u kasnijem koraku.
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px32),
      child: Text('Verifikacija', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
