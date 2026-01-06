import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/profile_service.dart';
import '../services/favorites_service.dart';
import 'welcome_auth_screen.dart';

class MySocialProfileScreen extends StatefulWidget {
  final int? initialTabIndex;
  const MySocialProfileScreen({super.key, this.initialTabIndex});

  @override
  State<MySocialProfileScreen> createState() => _MySocialProfileScreenState();
}

class _MySocialProfileScreenState extends State<MySocialProfileScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();
  final _favorites = FavoritesService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTabIndex ?? 0).clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openFollowers(String uid) {
    Navigator.of(context).pushNamed('/followers', arguments: uid);
  }

  void _openFollowing(String uid) {
    Navigator.of(context).pushNamed('/following', arguments: uid);
  }

  void _goToPostsTab() {
    _tabController.animateTo(0);
  }

  void _openEditProfile() {
    Navigator.of(context).pushNamed('/edit-profile');
  }

  Widget _metrics(String label, int value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text('$value', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
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
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfile,
          ),
        ],
      ),
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
          final displayName = data['displayName'] ?? 'Usuario';
          final username = data['username'] ?? '';
          final photoURL = data['photoURL'] as String?;
          final bio = data['bio'] ?? '';
          final followers = (data['followersCount'] ?? data['followerCount'] ?? 0) as int;
          final following = (data['followingCount'] ?? 0) as int;
          final posts = (data['postCount'] ?? data['postsCount'] ?? 0) as int;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
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
                          Text(displayName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('@$username', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                          if (bio.toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(bio, style: GoogleFonts.inter(fontSize: 14)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _metrics('Seguidores', followers, () => _openFollowers(uid)),
                              _metrics('Siguiendo', following, () => _openFollowing(uid)),
                              _metrics('Posts', posts, _goToPostsTab),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openEditProfile,
                    child: const Text('Editar perfil'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Guardados'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(uid: uid, profileService: _profileService),
                    _FavoritesTab(favorites: _favorites),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final String uid;
  final ProfileService profileService;
  const _PostsTab({required this.uid, required this.profileService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: profileService.userPosts(uid, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar posts'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Sin publicaciones todavía'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final text = data['text'] as String? ?? '';
            final created = data['createdAt'] as Timestamp?;
            final time = created != null ? created.toDate().toLocal().toString() : '';
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: GoogleFonts.inter(fontSize: 15, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(time, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  final FavoritesService favorites;
  const _FavoritesTab({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: favorites.favoritesStream(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar guardados'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Sin guardados'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final type = data['type'] as String? ?? '';
            final refId = data['refId'] as String? ?? '';
            final created = data['createdAt'] as Timestamp?;
            final time = created != null ? created.toDate().toLocal().toString() : '';
            return ListTile(
              leading: Icon(type == 'post' ? Icons.chat_bubble : Icons.menu_book_outlined),
              title: Text(type == 'post' ? 'Post guardado' : 'Verso guardado'),
              subtitle: Text(refId),
              trailing: Text(time, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrir detalle próximamente')),
                );
              },
            );
          },
        );
      },
    );
  }
}
