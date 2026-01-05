import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/privacy_security_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
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
        content: Text('¿Estás seguro de que quieres desbloquear a $displayName?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desbloqueado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usuarios bloqueados',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay usuarios bloqueados',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBlockedUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _blockedUsers[index];
                      final displayName = user['displayName'] ?? 'Usuario';
                      final photoUrl = user['photoUrl'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          trailing: TextButton(
                            onPressed: () => _unblockUser(user['id'], displayName),
                            child: const Text('Desbloquear'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

