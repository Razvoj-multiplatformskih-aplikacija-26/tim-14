import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'sidebar.dart';

// Ispod ove širine prozora sidebar od 248 px uzima previše mesta, pa prelazi u fioku.
const _narrowBelow = 900.0;

// Okvir oko svakog dela: sidebar levo, izabrani deo desno. Na uskom prozoru sidebar je u fioki iza ☰ u gornjoj traci.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.session, required this.location, required this.child});

  final ValueNotifier<User> session;
  final String location;
  final Widget child;

  // Ovde LayoutBuilder meri ceo prozor, jer je okvir oko svake strane.
  // Isti Scaffold za obe širine, menjaju se samo traka i fioka. Strana ostaje u istom Expanded,
  // a Row poredi decu i od kraja, pa strana nije napravljena iz početka kad sidebar nestane ili se vrati.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBelow;
        final border = AppExtraColors.of(context).border;
        return Scaffold(
          appBar: narrow
              ? AppBar(
                  title: const Text('Backoffice'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  shape: Border(bottom: BorderSide(color: border)),
                )
              : null,
          // Scaffold sam dodaje ☰ u traku kad ima fioku.
          drawer: narrow
              ? Drawer(
                  width: 248,
                  shape: const RoundedRectangleBorder(),
                  child: Sidebar(session: session, location: location),
                )
              : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow) Sidebar(session: session, location: location),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
