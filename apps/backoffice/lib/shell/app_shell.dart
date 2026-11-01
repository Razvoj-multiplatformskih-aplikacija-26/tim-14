import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'sidebar.dart';

// Okvir oko svakog dela: sidebar levo, izabrani deo desno. Uži raspored ispod 900 px dolazi kasnije.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.session, required this.location, required this.child});

  final ValueNotifier<User> session;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(session: session, location: location),
          Expanded(child: child),
        ],
      ),
    );
  }
}
