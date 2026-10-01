import 'package:flutter/material.dart';
import 'package:verbum/design_system/design_system.dart';

class SessionsDevicesScreen extends StatelessWidget {
  const SessionsDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Text('Sesiones y dispositivos', style: context.type.heading),
      ),
      body: const Center(
        child: VEmptyState(
          icon: VerbumIcons.devices,
          title: 'Próximamente',
          message:
              'Esta funcionalidad te permitirá ver y gestionar todas tus '
              'sesiones activas y dispositivos conectados.',
        ),
      ),
    );
  }
}
