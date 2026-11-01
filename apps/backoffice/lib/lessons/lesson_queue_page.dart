import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// Za sada samo naslov. Tabove, tabelu i detalj dodaje sledeći korak.
class LessonQueuePage extends StatelessWidget {
  const LessonQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px32),
      child: Text('Časovi', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
