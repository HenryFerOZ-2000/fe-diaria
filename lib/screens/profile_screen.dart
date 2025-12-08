import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: 'Perfil',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child: Icon(Icons.person, size: 42, color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Usuario',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'usuario@email.com',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            _profileButton(context, Icons.edit_outlined, 'Editar perfil', () {
              // TODO: conectar con pantalla de edición real
            }),
            _profileButton(context, Icons.local_fire_department_outlined, 'Mis rachas', () {
              // TODO: conectar con pantalla de rachas
            }),
            _profileButton(context, Icons.bar_chart_outlined, 'Mis datos espirituales', () {
              // TODO: conectar con métricas reales
            }),
            const SizedBox(height: 12),
            _profileButton(
              context,
              Icons.logout,
              'Cerrar sesión',
              () {
                // TODO: implementar logout real
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : colorScheme.primary),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isDestructive ? Colors.red : colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

