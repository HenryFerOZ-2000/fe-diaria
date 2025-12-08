import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/profile_header.dart';
import '../services/storage_service.dart';

/// Pantalla de perfil del usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Datos del usuario (por ahora estáticos, en el futuro vendrán de Firebase/Storage)
  String _userName = 'Usuario';
  String _userEmail = 'usuario@ejemplo.com';
  String? _userAvatar;
  int _streak = 7;
  int _daysCompleted = 45;
  int _likesReceived = 120;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Intentar cargar datos del usuario desde StorageService
    // Por ahora usamos valores por defecto
    setState(() {
      final storage = StorageService();
      _userName = storage.getUserName().isNotEmpty ? storage.getUserName() : 'Usuario';
      _userEmail = storage.getUserEmail() ?? 'usuario@ejemplo.com';
      // En el futuro: cargar avatar, racha, días completados, likes desde Firebase
    });
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: const Text('Funcionalidad de edición de perfil próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica de cierre de sesión
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Perfil',
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header del perfil
            ProfileHeader(
              userName: _userName,
              userEmail: _userEmail,
              userAvatar: _userAvatar,
              streak: _streak,
              daysCompleted: _daysCompleted,
              likesReceived: _likesReceived,
              onEditProfile: _editProfile,
            ),
            // Opciones adicionales
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _ProfileOption(
                    icon: Icons.settings,
                    title: 'Configuración',
                    onTap: () {
                      // Navegar a configuración (ya existe)
                    },
                  ),
                  _ProfileOption(
                    icon: Icons.favorite,
                    title: 'Mis favoritos',
                    onTap: () {
                      // Navegar a favoritos
                    },
                  ),
                  _ProfileOption(
                    icon: Icons.history,
                    title: 'Historial',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad de historial próximamente'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _ProfileOption(
                    icon: Icons.help_outline,
                    title: 'Ayuda y soporte',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad de ayuda próximamente'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Botón cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryLight,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

