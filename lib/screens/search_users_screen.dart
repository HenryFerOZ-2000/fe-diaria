import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/social_service.dart';
import 'profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _social = SocialService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar usuarios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por username',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? const Center(child: Text('Escribe para buscar'))
                : StreamBuilder(
                    stream: _social.searchUsers(_query),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Sin resultados'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final doc = docs[idx];
                          final data = doc.data();
                          final username = data['username'] ?? '';
                          final displayName = data['displayName'] ?? username;
                          final photoURL = data['photoURL'] as String?;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                              child: photoURL == null
                                  ? Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(displayName),
                            subtitle: Text('@$username'),
                            onTap: () {
                              Navigator.of(context).pushNamed('/public-profile', arguments: doc.id);
                            },
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}


