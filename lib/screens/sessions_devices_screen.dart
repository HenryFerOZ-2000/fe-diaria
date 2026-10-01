import 'package:flutter/material.dart';
import 'package:verbum/design_system/design_system.dart';

class SessionsDevicesScreen extends StatelessWidget {
  const SessionsDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Text(
          'Sesiones y dispositivos',
          style: VerbumFonts.serif(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VIcon(VerbumIcons.devices, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Próximamente',
              style: VerbumFonts.sans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Esta funcionalidad te permitirá ver y gestionar todas tus sesiones activas y dispositivos conectados.',
                textAlign: TextAlign.center,
                style: VerbumFonts.sans(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
