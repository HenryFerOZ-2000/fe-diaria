import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambiar contraseña'),
            subtitle: const Text('Próximamente'),
            onTap: () => _placeholder(context),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Vincular Google'),
            subtitle: const Text('Próximamente'),
            onTap: () => _placeholder(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Eliminar cuenta'),
            subtitle: const Text('Placeholder seguro'),
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


