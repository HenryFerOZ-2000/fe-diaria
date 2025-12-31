import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('FAQ'),
            subtitle: Text('Próximamente'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contacto'),
            subtitle: const Text('soporte@ejemplo.com'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('mailto: soporte@ejemplo.com')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y Privacidad'),
            subtitle: const Text('Enlace externo'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir términos (placeholder)')),
              );
            },
          ),
        ],
      ),
    );
  }
}


