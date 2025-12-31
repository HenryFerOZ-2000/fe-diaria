import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/profile_service.dart';

class FollowersListScreen extends StatelessWidget {
  const FollowersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final uid = args is String ? args : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Perfil no disponible')));
    }
    final profileService = ProfileService();
    return Scaffold(
      appBar: AppBar(title: const Text('Seguidores')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: profileService.followers(uid, limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar seguidores'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Sin seguidores aún'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final followerId = docs[index].id;
              return _UserListTile(uid: followerId);
            },
          );
        },
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final String uid;
  const _UserListTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: profileService.getUser(uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = data?['displayName'] ?? 'Usuario';
        final username = data?['username'] ?? '';
        final photoURL = data?['photoURL'] as String?;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(displayName),
          subtitle: Text('@$username'),
          onTap: () => Navigator.of(context).pushNamed('/public-profile', arguments: uid),
        );
      },
    );
  }
}


