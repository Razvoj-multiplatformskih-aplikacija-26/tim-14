import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

// Zajednički okvir za Časove i Verifikaciju: naslov, dugme Osveži desno od njega, i sadržaj ispod.
// Ctrl+R (Windows, Linux) i Cmd+R (macOS) rade isto što i dugme.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.onRefresh, required this.child});

  final String title;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Prečice čuju taster samo kad je fokus negde ispod njih. Tabela i lista imaju autofocus,
    // a njihove prečice (strelice, P, O…) ne znaju za R, pa R sa Ctrl/Cmd stigne dovde.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, control: true, includeRepeats: false): onRefresh,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true, includeRepeats: false): onRefresh,
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.px24,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
                IconButton(onPressed: onRefresh, tooltip: 'Osveži', icon: const Icon(Icons.refresh)),
              ],
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
