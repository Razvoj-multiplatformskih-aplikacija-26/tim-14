import 'package:flutter/material.dart';

// Privremeno, dok se ne napravi lista profesora.
class ProfessorsScreen extends StatelessWidget {
  const ProfessorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profesori')),
      body: const Center(child: Text('Lista profesora stiže uskoro.')),
    );
  }
}
