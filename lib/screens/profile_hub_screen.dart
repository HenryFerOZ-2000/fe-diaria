import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/profile_service.dart';
import 'welcome_auth_screen.dart';

class ProfileHubScreen extends StatelessWidget {
  ProfileHubScreen({super.key});

  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  void _logout(BuildContext context) async {
    try {
      await context.read<app_auth.AuthProvider>().signOut();
    } catch (_) {
      await _auth.signOut();
    }
    if (context.mounted) {
      // Navegar a la pantalla de bienvenida y limpiar el stack de navegación
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final displayName = data['displayName'] ?? 'Usuario';
    final username = data['username'] ?? '';
    final photoURL = data['photoURL'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('@$username', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Si no hay usuario, navegar directamente a la pantalla de inicio de sesión
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
            (route) => false,
          );
        }
      });
      // Mostrar un loading mientras navega
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileService.userStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Perfil no encontrado'));
          }
          final data = snapshot.data!.data() ?? {};
          return ListView(
            children: [
              _buildHeader(data),
              _buildTile(
                icon: Icons.edit,
                title: 'Editar perfil',
                onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
              ),
              _buildTile(
                icon: Icons.chat_bubble_outline,
                title: 'Mis oraciones / posts',
                onTap: () => Navigator.of(context).pushNamed('/my-profile', arguments: 0),
              ),
              _buildTile(
                icon: Icons.local_fire_department_outlined,
                title: 'Mis rachas',
                onTap: () => Navigator.of(context).pushNamed('/streak'),
              ),
              _buildTile(
                icon: Icons.insights_outlined,
                title: 'Mis datos espirituales',
                onTap: () => Navigator.of(context).pushNamed('/spiritual-stats'),
              ),
              _buildTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Plan / Suscripción',
                onTap: () => Navigator.of(context).pushNamed('/plan'),
              ),
              _buildTile(
                icon: Icons.lock_outline,
                title: 'Privacidad y seguridad',
                onTap: () => Navigator.of(context).pushNamed('/privacy-safety'),
              ),
              _buildTile(
                icon: Icons.help_outline,
                title: 'Ayuda / Soporte',
                onTap: () => Navigator.of(context).pushNamed('/help-support'),
              ),
              _buildTile(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

