import 'package:flutter/material.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Usuarios bloqueados'),
            subtitle: const Text('Próximamente'),
            onTap: () => _placeholder(context),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Reportar contenido'),
            subtitle: const Text('Próximamente'),
            onTap: () => _placeholder(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Configuración de privacidad'),
            subtitle: const Text('Usa perfil público en Editar perfil'),
            onTap: () => _placeholder(context),
          ),
        ],
      ),
    );
  }

  void _placeholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disponible próximamente')),
    );
  }
}


