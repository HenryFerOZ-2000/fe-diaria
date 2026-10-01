import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/privacy_security_service.dart';
import 'package:verbum/design_system/design_system.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _service = PrivacySecurityService();
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final users = await _service.getBlockedUsers(uid);
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
      }
    }
  }

  Future<void> _unblockUser(String blockedUid, String displayName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: Text(
          '¿Estás seguro de que quieres desbloquear a $displayName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.unblockUser(uid, blockedUid);
      await _loadBlockedUsers();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario desbloqueado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Scaffold(
      appBar: VAppBar(title: Text('Usuarios bloqueados', style: t.heading)),
      body: _isLoading
          ? const Center(child: VEmptyState(title: 'Cargando', loading: true))
          : _blockedUsers.isEmpty
          ? const Center(
              child: VEmptyState(
                icon: VerbumIcons.prohibit,
                title: 'No hay usuarios bloqueados',
                message:
                    'Cuando bloquees a alguien, aparecerá aquí y podrás '
                    'desbloquearlo cuando quieras.',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBlockedUsers,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  12,
                  VerbumSpace.gutter,
                  32,
                ),
                itemCount: _blockedUsers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  final displayName = user['displayName'] ?? 'Usuario';
                  final photoUrl = user['photoUrl'] as String?;

                  return VSurfaceCard(
                    radius: VerbumRadius.tile,
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        _Avatar(name: displayName, photo: photoUrl, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyStrong,
                          ),
                        ),
                        VButton(
                          label: 'Desbloquear',
                          variant: VButtonVariant.text,
                          compact: true,
                          onPressed: () =>
                              _unblockUser(user['id'], displayName),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Avatar: foto o inicial sobre lavanda.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photo, this.size = 40});

  final String name;
  final String? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = photo?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .34),
      child: Container(
        width: size,
        height: size,
        color: p.surfaceMuted,
        alignment: Alignment.center,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initial(context),
              )
            : _initial(context),
      ),
    );
  }

  Widget _initial(BuildContext context) => Text(
    name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
    style: context.type.bodyStrong.copyWith(
      color: context.palette.rubric,
      fontSize: size * .38,
    ),
  );
}
