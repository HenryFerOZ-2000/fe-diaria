import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: 'Perfil',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (auth.isSignedIn)
              CircleAvatar(
                radius: 42,
                backgroundColor: colorScheme.primary.withOpacity(0.15),
                backgroundImage: auth.user?.photoUrl != null
                    ? NetworkImage(auth.user!.photoUrl!)
                    : null,
                child: auth.user?.photoUrl == null
                    ? Icon(Icons.person, size: 42, color: colorScheme.primary)
                    : null,
              )
            else
              CircleAvatar(
                radius: 42,
                backgroundColor: colorScheme.primary.withOpacity(0.15),
                child: Icon(Icons.person, size: 42, color: colorScheme.primary),
              ),
            const SizedBox(height: 12),
            Text(
              auth.isSignedIn ? (auth.user?.displayName ?? 'Usuario') : 'Invitado',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              auth.isSignedIn ? (auth.user?.email ?? '') : 'No has iniciado sesión',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (!auth.isSignedIn)
              GoogleSignInButton(
                onPressed: () async {
                  try {
                    await context.read<AuthProvider>().signIn();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sesión iniciada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final errorMsg = e.toString().replaceAll('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            errorMsg.length > 100 
                              ? '${errorMsg.substring(0, 100)}...\n\nVer FIX_GOOGLE_SIGNIN.md para más detalles'
                              : errorMsg,
                            style: const TextStyle(fontSize: 12),
                          ),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
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
            if (auth.isSignedIn)
              _profileButton(
                context,
                Icons.logout,
                'Cerrar sesión',
                () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                  }
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

